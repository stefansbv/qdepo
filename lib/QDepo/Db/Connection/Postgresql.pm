package QDepo::Db::Connection::Postgresql;

# ABSTRACT: Connect to a PostgreSQL database

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
    my ( $self, $args ) = @_;

    my ( $db, $host, $port ) = ( $args->dbname, $args->host, $args->port );
    my $dsn = qq{dbi:Pg:dbname=$db;host=$host;port=$port};

    $self->{_dbh} = DBI->connect(
        $dsn, $args->user, $args->pass,
        {   FetchHashKeyName => 'NAME_lc',
            AutoCommit       => 1,
            RaiseError       => 0,
            PrintError       => 0,
            LongReadLen      => 524288,
            HandleError      => sub { $self->handle_error(); },
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
        my ($message, $type) = $self->parse_error($errorstr);
        Exception::Db::SQL->throw(
            logmsg  => $errorstr,
            usermsg => $message,
        );
    }
    else {
        my $errorstr = DBI->errstr;
        my ($message, $type) = $self->parse_error($errorstr);
        if ($type eq 'password') {
            Exception::Db::Connect::Auth->throw(
                logmsg  => $errorstr,
                usermsg => $message,
            );
        }
        else {
            Exception::Db::Connect->throw(
                logmsg  => $errorstr,
                usermsg => $message,
            );
        }
    }

    return;
}

sub parse_error {
    my ($self, $err) = @_;

    my $message_type =
         $err eq q{}                                          ? "nomessage"
       : $err =~ m/FATAL:  database ($RE{quoted}) does not exist/smi  ? "dbnotfound:$1"
       : $err =~ m/ERROR:  column ($RE{quoted}) of relation ($RE{quoted}) does not exist/smi
                                                            ? "colnotfound:$2.$1"
       : $err =~ m/ERROR:  null value in column ($RE{quoted})/smi ? "nullvalue:$1"
       : $err =~ m/ERROR:  syntax error at or near ($RE{quoted})/smi ? "syntax:$1"
       : $err =~ m/violates check constraint ($RE{quoted})/smi ? "checkconstr:$1"
       : $err =~ m/relation ($RE{quoted}) does not exist/smi  ? "relnotfound:$1"
       : $err =~ m/authentication failed .* ($RE{quoted})/smi ? "password:$1"
       : $err =~ m/no password supplied/smi                   ? "password"
       : $err =~ m/FATAL:  role ($RE{quoted}) does not exist/smi ? "username:$1"
       : $err =~ m/no route to host/smi                       ? "network"
       : $err =~ m/DETAIL:  Key ($RE{balanced}{-parens=>'()'})=/smi ? "duplicate:$1"
       : $err =~ m/permission denied for relation/smi         ? "relforbid"
       : $err =~ m/could not connect to server/smi            ? "servererror"
       : $err =~ m/not connected/smi                          ? "notconn"
       :                                                       "unknown";

    # Analize and translate

    my ( $type, $name ) = split /:/, $message_type, 2;
    $name = $name ? $name : '';

    my $translations = {
        dbnotfound  => "Database $name does not exists!",
        relnotfound => "Relation $name does not exists",
        password    => "Authentication failed for $name",
        password    => "Authentication failed, password?",
        username    => "Wrong user name: $name",
        network     => "Network problem",
        unknown     => "Database error",
        servererror => "Server not available",
        duplicate   => "Duplicate $name",
        colnotfound => "Column not found $name",
        checkconstr => "Check: $name",
        nullvalue   => "Null value for $name",
        relforbid   => "Permission denied",
        notconn     => "Not connected",
        syntax      => "SQL syntax error",
    };

    my $message;
    if (exists $translations->{$type} ) {
        $message = $translations->{$type};
    }
    else {
        $message = $err;
        print "EE: Translation error for: $message!\n";
    }

    return ($message, $type);
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
            logmsg  => "Transaction aborted because $_",
            usermsg => 'Database error',
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
            logmsg  => "Transaction aborted because $_",
            usermsg => 'Database error',
        );
    };

    return $flds_ref;
}

1;

=head1 ACKNOWLEDGEMENTS

Information schema queries by Lorenzo Alberton from
http://www.alberton.info/postgresql_meta_info.html
