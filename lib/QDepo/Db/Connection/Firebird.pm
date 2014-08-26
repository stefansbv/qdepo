package QDepo::Db::Connection::Firebird;

# ABSTRACT: Connect to a Firebird database

use strict;
use warnings;

use DBI;
use Try::Tiny;
use Regexp::Common;

use QDepo::Exceptions;

=head2 new

Constructor.

=cut

sub new {
    my ($class, $model) = @_;

    my $self = {};
    $self->{model} = $model;
    bless $self, $class;

    return $self;
}

=head2 db_connect

Connect to database

=cut

sub db_connect {
    my ($self, $conf) = @_;

    my ( $dbname, $host, $port ) = @{$conf}{qw(dbname host port)};
    my ( $driver, $user, $pass ) = @{$conf}{qw(driver user pass)};

    my $dsn = qq{dbi:Firebird:dbname=$dbname;host=$host;port=$port};
    $dsn   .= q{;ib_dialect=3;ib_charset=UTF8};

    $self->{_dbh} = DBI->connect(
        $dsn, $user, $pass, {
            FetchHashKeyName   => 'NAME_lc',
            LongReadLen        => 524288,
            AutoCommit         => 1,
            RaiseError         => 0,
            PrintError         => 0,
            ib_enable_utf8     => 1,
            ib_timestampformat => '%Y-%m-%dT%H:%M',
            ib_dateformat      => '%Y-%m-%dT',
            ib_timeformat      => 'T%H:%M',
            HandleError        => sub { $self->handle_error() },
        }
    );                                       # date format: ISO8601

    return $self->{_dbh};
}

=head2 handle_error

Handle errors.  Makes a distinction between a connection error and
other errors.

=cut

sub handle_error {
    my $self = shift;

    if ( defined $self->{_dbh} and $self->{_dbh}->isa('DBI::db') ) {
        my $errorstr = $self->{_dbh}->errstr;
        Exception::Db::SQL->throw(
            logmsg  => $errorstr,
            usermsg => $self->parse_error($errorstr),
        );
    }
    else {
        my $errorstr = DBI->errstr;
        Exception::Db::Connect->throw(
            logmsg  => $errorstr,
            usermsg => $self->parse_error($errorstr),
        );
    }

    return;
}

=head2 parse_error

Parse a database error message, and translate it for the user.

=cut

sub parse_error {
    my ( $self, $fb ) = @_;

    # my $log = get_logger();

    # print "\nFB: $fb\n\n";

    my $message_type
        = $fb eq q{} ? "nomessage"
        : $fb =~ m/operation for file ($RE{quoted})/smi ? "dbnotfound:$1"
        : $fb =~ m/\-Table unknown\s*\-(.*)\-/smi       ? "relnotfound:$1"
        : $fb =~ m/Your user name and password/smi      ? "userpass"
        : $fb =~ m/no route to host/smi                 ? "network"
        : $fb =~ m/network request to host ($RE{quoted})/smi ? "nethost:$1"
        : $fb =~ m/install_driver($RE{balanced}{-parens=>'()'})/smi
                                                        ? "driver:$1"
        : $fb =~ m/not connected/smi                    ? "notconn"
        :                                                 "unknown";

    # Analize and translate

    my ( $type, $name ) = split /:/, $message_type, 2;
    $name = $name ? $name : '';

    my $translations = {
        driver      => "error#Database driver $name not found",
        dbnotfound  => "error#Database $name not found",
        relnotfound => "error#Relation $name not found",
        userpass    => "error#Authentication failed",
        nethost     => "error#Network problem: host $name",
        network     => "error#Network problem",
        unknown     => "error#Database error",
        notconn     => "error#Not connected",
    };

    my $message;
    if ( exists $translations->{$type} ) {
        $message = $translations->{$type};
    }
    else {
        # $log->error('EE: Translation error for: $fb!');
        print "EE: Translation error for: $fb!\n";
    }

    return $message;
}

=head2 table_info_short

Table info 'short'.  The 'table_info' method from the Firebird driver
doesn't seem to be reliable.

=cut

sub table_info_short {
    my ( $self, $table ) = @_;

    $table = uc $table;

    my $sql = qq(SELECT RDB\$FIELD_POSITION AS pos
                    , LOWER(r.RDB\$FIELD_NAME) AS name
                    , r.RDB\$DEFAULT_VALUE AS defa
                    , r.RDB\$NULL_FLAG AS is_nullable
                    , f.RDB\$FIELD_LENGTH AS length
                    , f.RDB\$FIELD_PRECISION AS prec
                    , CASE
                        WHEN f.RDB\$FIELD_SCALE > 0 THEN (f.RDB\$FIELD_SCALE)
                        WHEN f.RDB\$FIELD_SCALE < 0 THEN (f.RDB\$FIELD_SCALE * -1)
                        ELSE 0
                      END AS scale
                    , CASE f.RDB\$FIELD_TYPE
                        WHEN 261 THEN 'blob'
                        WHEN 14  THEN 'char'
                        WHEN 40  THEN 'cstring'
                        WHEN 11  THEN 'd_float'
                        WHEN 27  THEN 'double'
                        WHEN 10  THEN 'float'
                        WHEN 16  THEN
                          CASE f.RDB\$FIELD_SCALE
                            WHEN 0 THEN 'int64'
                            ELSE 'numeric'
                          END
                        WHEN 8   THEN
                          CASE f.RDB\$FIELD_SCALE
                            WHEN 0 THEN 'integer'
                            ELSE 'numeric'
                          END
                        WHEN 9   THEN 'quad'
                        WHEN 7   THEN
                          CASE f.RDB\$FIELD_SCALE
                            WHEN 0 THEN 'smallint'
                            ELSE 'numeric'
                          END
                        WHEN 12  THEN 'date'
                        WHEN 13  THEN 'time'
                        WHEN 35  THEN 'timestamp'
                        WHEN 37  THEN 'varchar'
                      ELSE 'UNKNOWN'
                      END AS type
                    FROM RDB\$RELATION_FIELDS r
                       LEFT JOIN RDB\$FIELDS f
                            ON r.RDB\$FIELD_SOURCE = f.RDB\$FIELD_NAME
                    WHERE r.RDB\$RELATION_NAME = '$table'
                    ORDER BY r.RDB\$FIELD_POSITION;
    );

    $self->{_dbh}{ChopBlanks} = 1;    # trim CHAR fields

    my $flds_ref;
    try {
        my $sth = $self->{_dbh}->prepare($sql);
        $sth->execute;
        $flds_ref = $sth->fetchall_hashref('name');
    }
    catch {
        # $self->{model}->exception_log("Transaction aborted because $_");
        print "Transaction aborted because $_\n";
    };

    return $flds_ref;
}

1;
