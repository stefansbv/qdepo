package QDepo::Db::Connection::Mysql;

# ABSTRACT: Connect to a MySQL database

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
    my ($self, $conf) = @_;

    my ( $db, $host, $port ) = ( $args->dbname, $args->host, $args->port );
    my $dsn = qq{dbi:mysql:database=$dbname;host=$host;port=$port};

    $self->{_dbh} = DBI->connect(
        $dsn, $args->user, $args->pass,
            FetchHashKeyName   => 'NAME_lc',
            LongReadLen        => 524288,
            AutoCommit         => 1,
            RaiseError         => 0,
            PrintError         => 0,
            HandleError        => sub { $self->handle_error(); },
        }
    );

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

sub parse_db_error {
    my ($self, $err) = @_;

    my $message_type
       = $err eq q{}                                         ? "nomessage"
       : $err =~ m/Access denied for user ($RE{quoted})/smi  ? "password:$1"
       : $err =~ m/Can't connect to local MySQL server/smi   ? "nolocalconn"
       : $err =~ m/Can't connect to MySQL server on ($RE{quoted})/smi ? "nethost:$1"
       :                                                       "unknown"
       ;

    # Analize and translate

    my ( $type, $name ) = split /:/, $message_type, 2;
    $name = $name ? $name : '';

    my $translations = {
        nomessage   => "Error without message!",
        dbnotfound  => "Database $name not found!",
        password    => "Authentication failed for $name",
        username    => "User name $name not found!",
        network     => "Network problem",
        nethost     => "Network problem: host $name",
        nolocalconn => "Connection problem to local MySQL",
        unknown     => "Database error",
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

1;
