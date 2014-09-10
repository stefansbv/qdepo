package QDepo::Db::Connection::Postgresql;

# ABSTRACT: Connect to a PostgreSQL database

use strict;
use warnings;

use DBI;
use Try::Tiny;
use Regexp::Common;

use QDepo::Exceptions;


sub new {
    my ($class, $model) = @_;
    my $self = {};
    $self->{model} = $model;
    bless $self, $class;
    return $self;
}


sub db_connect {
    my ( $self, $conf ) = @_;

    my ($dbname, $host, $port) = @{$conf}{qw(dbname host port)};
    my ($driver, $user, $pass) = @{$conf}{qw(driver user pass)};

    my $dsn = qq{dbi:Pg:dbname=$dbname;host=$host;port=$port};

    $self->{_dbh} = DBI->connect(
        $dsn, $user, $pass,
        {   FetchHashKeyName => 'NAME_lc',
            AutoCommit       => 1,
            RaiseError       => 1,
            PrintError       => 0,
            LongReadLen      => 524288,
            HandleError      => sub { $self->handle_error() },
            pg_enable_utf8   => 1,
        }
    );

    ## Date format
    # set: datestyle = 'iso' in postgresql.conf
    ##

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
    my ($self, $pg) = @_;

    my $message_type =
         $pg eq q{}                                          ? "nomessage"
       : $pg =~ m/database ($RE{quoted}) does not exist/smi  ? "dbnotfound:$1"
       : $pg =~ m/ERROR:  column ($RE{quoted}) of relation ($RE{quoted}) does not exist/smi
                                                            ? "colnotfound:$2.$1"
       : $pg =~ m/ERROR:  null value in column ($RE{quoted})/smi ? "nullvalue:$1"
       : $pg =~ m/ERROR:  syntax error at or near ($RE{quoted})/smi ? "syntax:$1"
       : $pg =~ m/violates check constraint ($RE{quoted})/smi ? "checkconstr:$1"
       : $pg =~ m/relation ($RE{quoted}) does not exist/smi  ? "relnotfound:$1"
       : $pg =~ m/authentication failed .* ($RE{quoted})/smi ? "password:$1"
       : $pg =~ m/no password supplied/smi                   ? "password"
       : $pg =~ m/FATAL:  role ($RE{quoted}) does not exist/smi ? "username:$1"
       : $pg =~ m/no route to host/smi                       ? "network"
       : $pg =~ m/DETAIL:  Key ($RE{balanced}{-parens=>'()'})=/smi ? "duplicate:$1"
       : $pg =~ m/permission denied for relation/smi         ? "relforbid"
       : $pg =~ m/could not connect to server/smi            ? "servererror"
       : $pg =~ m/not connected/smi                          ? "notconn"
       :                                                       "unknown";

    # Analize and translate

    my ( $type, $name ) = split /:/, $message_type, 2;
    $name = $name ? $name : '';

    my $translations = {
        dbnotfound  => "error#Database $name does not exists",
        relnotfound => "error#Relation $name does not exists",
        password    => "info#Authentication failed for $name",
        password    => "info#Authentication failed, password?",
        username    => "error#Wrong user name: $name",
        network     => "error#Network problem",
        unknown     => "error#Database error",
        servererror => "error#Server not available",
        duplicate   => "error#Duplicate $name",
        colnotfound => "error#Column not found $name",
        checkconstr => "error#Check: $name",
        nullvalue   => "error#Null value for $name",
        relforbid   => "error#Permission denied",
        notconn     => "error#Not connected",
        syntax      => "error#SQL syntax error",
    };

    my $message;
    if (exists $translations->{$type} ) {
        $message = $translations->{$type}
    }
    else {
        # $log->error('EE: Translation error for: $pg!');
        print "EE: Translation error for: $pg!\n";
    }

    return $message;
}


sub table_exists {
    my ( $self, $table ) = @_;

    die "'table_exists' requires a 'table' parameter!" unless $table;

    my $table_name = (split /\./, $table)[-1]; # remove schema name

    my $sql = qq( SELECT COUNT(table_name)
                FROM information_schema.tables
                WHERE table_type = 'BASE TABLE'
                    AND table_schema NOT IN
                    ('pg_catalog', 'information_schema')
                    AND table_name = '$table_name';
    );

    my $val_ret;
    try {
        ($val_ret) = $self->{_dbh}->selectrow_array($sql);
    }
    catch {
        Exception::Db::Connect->throw(
            logmsg  => "error#Transaction aborted because $_",
            usermsg => 'error#Database error',
        );
    };

    return $val_ret;
}


sub table_info_short {
    my ( $self, $table ) = @_;

    die "'table_info_short' requires a 'table' parameter!" unless $table;

    my $table_name = (split /\./, $table)[-1]; # remove schema name

    my $sql = qq( SELECT ordinal_position  AS pos
                    , column_name       AS name
                    , data_type         AS type
                    , column_default    AS defa
                    , is_nullable
                    , character_maximum_length AS length
                    , numeric_precision AS prec
                    , numeric_scale     AS scale
               FROM information_schema.columns
               WHERE table_name = '$table_name'
               ORDER BY ordinal_position;
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
            logmsg  => "error#Transaction aborted because $_",
            usermsg => 'error#Database error',
        );
    };

    return $flds_ref;
}


1;

=head1 ACKNOWLEDGEMENTS

Information schema queries by Lorenzo Alberton from
http://www.alberton.info/postgresql_meta_info.html
