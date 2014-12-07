package QDepo::Db::Connection::Firebird;

# ABSTRACT: Connect to a Firebird database

use strict;
use warnings;

use DBI;
use Try::Tiny;
use Regexp::Common;

use QDepo::Exceptions;

sub new {
    my ($class, $p) = @_;
    my $model = delete $p->{model}
        or die 'Missing "model" parameter to new()';
    my $self = {};
    $self->{model} = $model;
    bless $self, $class;
    return $self;
}

sub db_connect {
    my ($self, $args) = @_;

    my ( $db, $host, $port ) = ( $args->dbname, $args->host, $args->port );
    my $dsn = qq{dbi:Firebird:dbname=$db;host=$host;port=$port};
    $dsn   .= q{;ib_dialect=3;ib_charset=UTF8};

    $self->{_dbh} = DBI->connect(
        $dsn, $args->user, $args->pass,
        {   FetchHashKeyName   => 'NAME_lc',
            LongReadLen        => 524288,
            AutoCommit         => 1,
            RaiseError         => 0,
            PrintError         => 0,
            ib_enable_utf8     => 1,
            ib_timestampformat => '%Y-%m-%dT%H:%M',
            ib_dateformat      => '%Y-%m-%dT',
            ib_timeformat      => 'T%H:%M',
            HandleError        => sub { $self->handle_error(); },
        }
    );    # date format: ISO8601

    return $self->{_dbh};
}

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

sub parse_error {
    my ( $self, $err ) = @_;

    my $message_type
        = $err eq q{} ? "nomessage"
        : $err =~ m/operation for file ($RE{quoted})/smi ? "dbnotfound:$1"
        : $err =~ m/\-Table unknown\s*\-(.*)\-/smi       ? "relnotfound:$1"
        : $err =~ m/Your user name and password/smi      ? "userpass"
        : $err =~ m/no route to host/smi                 ? "network"
        : $err =~ m/network request to host ($RE{quoted})/smi ? "nethost:$1"
        : $err =~ m/install_driver($RE{balanced}{-parens=>'()'})/smi
                                                        ? "driver:$1"
        : $err =~ m/not connected/smi                    ? "notconn"
        :                                                 "unknown";

    # Analize and translate

    my ( $type, $name ) = split /:/, $message_type, 2;
    $name = $name ? $name : '';

    my $translations = {
        driver      => "Database driver $name not found",
        dbnotfound  => "Database $name not found",
        relnotfound => "Relation $name not found",
        userpass    => "Authentication failed",
        nethost     => "Network problem: host $name",
        network     => "Network problem",
        unknown     => "Database error",
        notconn     => "Not connected",
    };

    my $message;
    if ( exists $translations->{$type} ) {
        $message = $translations->{$type};
    }
    else {
        $message = $err;
        print "EE: Translation error for: $message!\n";
    }

    return $message;
}

sub table_exists {
    my ( $self, $table ) = @_;

    die "'table_exists' requires a 'table' parameter!" unless $table;

    $table = uc $table;

    my $sql = qq(SELECT COUNT(RDB\$RELATION_NAME)
                     FROM RDB\$RELATIONS
                     WHERE RDB\$SYSTEM_FLAG=0
                         AND RDB\$VIEW_BLR IS NULL
                         AND RDB\$RELATION_NAME = '$table';
    );

    my $val_ret;
    try {
        ($val_ret) = $self->{_dbh}->selectrow_array($sql);
    }
    catch {
        Exception::Db::Connect->throw(
            logmsg  => "Transaction aborted because $_",
            usermsg => 'Database error',
        );
    };

    return $val_ret;
}

sub table_info_short {
    my ( $self, $table ) = @_;

    die "'table_info_short' requires a 'table' parameter!" unless $table;

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
        Exception::Db::Connect->throw(
            logmsg  => "Transaction aborted because $_",
            usermsg => 'Database error',
        );
    };

    return $flds_ref;
}

1;

=head2 handle_error

Handle errors.  Makes a distinction between a connection error and
other errors.

=head1 ACKNOWLEDGEMENTS

Information schema queries inspired from:

 - http://www.alberton.info/firebird_sql_meta_info.html by Lorenzo Alberton
 - Flamerobin Copyright (c) 2004-2013 The FlameRobin Development Team

=cut
