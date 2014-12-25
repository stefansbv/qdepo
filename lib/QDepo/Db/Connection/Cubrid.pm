package QDepo::Db::Connection::Cubrid;

# ABSTRACT: Connect to a CUBRID database

use strict;
use warnings;
use Carp;

use DBI;
use Try::Tiny;
use Regexp::Common;

# use QDepo::Exceptions; not yet...

sub new {
    my ( $class, $p ) = @_;
    my $model = delete $p->{model}
        or croak 'Missing "model" parameter to new()';
    my $self = {};
    $self->{model} = $model;
    bless $self, $class;
    return $self;
}

sub db_connect {
    my ( $self, $args ) = @_;

    my ( $db, $host, $port ) = ( $args->dbname, $args->host, $args->port );
    my $dsn = qq{dbi:cubrid:database=$db;host=$host;port=$port};

    $self->{_dbh} = DBI->connect(
        $dsn, $args->user, $args->pass,
        {   FetchHashKeyName => 'NAME_lc',
            AutoCommit       => 1,
            RaiseError       => 0,
            PrintError       => 0,
            LongReadLen      => 524288,
            HandleError      => sub { $self->handle_error(); },
        }
    );

    return $self->{_dbh};
}

sub handle_error {
    my $self = shift;

    if ( defined $self->{_dbh} and $self->{_dbh}->isa('DBI::db') ) {
        Exception::Db::SQL->throw(
            logmsg  => $self->{_dbh}->errstr,
            usermsg => 'SQL error',
        );
    }
    else {
        Exception::Db::Connect->throw(
            logmsg  => DBI->errstr,
            usermsg => 'Connection error!',
        );
    }

    return;
}

1;
