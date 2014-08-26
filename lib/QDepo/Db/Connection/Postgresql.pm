package QDepo::Db::Connection::Postgresql;

# ABSTRACT: Connect to a PostgreSQL database

use strict;
use warnings;

use QDepo::Exceptions;
use Try::Tiny;
use DBI;

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

Connect to the database.

=cut

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

=head2 handle_error

Log errors.

=cut

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

=head1 ACKNOWLEDGEMENTS

Information schema queries by Lorenzo Alberton from
http://www.alberton.info/postgresql_meta_info.html
