package QDepo::Db::Connection;

# ABSTRACT: Connect to various databases

use strict;
use warnings;

use Scalar::Util qw(blessed);
use DBI;
use Try::Tiny;
use QDepo::Exceptions;

require QDepo::Config;

=head2 new

Constructor method, the first and only time a new instance is created.
All parameters passed to the instance() method are forwarded to this
method. (From I<Class::Singleton> docs).

=cut

sub new {
    my ($class, $model) = @_;
    my $self = bless {}, $class;
    $self->_connect($model);
    return $self;
}

=head2 _connect

Connect method, uses I<QDepo::Config> module for configuration.

Using separate modules for each RDBMS, because ...

=cut

sub _connect {
    my ($self, $model) = @_;

    my $inst = QDepo::Config->instance;
    my $conf = $inst->connection;

    $conf->{user} = $inst->user;    # add user and pass to
    $conf->{pass} = $inst->pass;    #  connection options

    my $driver = $conf->{driver};
    my $dbname = $conf->{dbname};
    my $db;

  SWITCH: for ( $driver ) {
        /^$/ && do warn "No driver name?\n";
        /cubrid/i && do {
            require QDepo::Db::Connection::Cubrid;
            $db = QDepo::Db::Connection::Cubrid->new($model);
            last SWITCH;
        };
        /firebird/i && do {
            require QDepo::Db::Connection::Firebird;
            $db = QDepo::Db::Connection::Firebird->new($model);
            last SWITCH;
        };
        /postgresql/i && do {
            require QDepo::Db::Connection::Postgresql;
            $db = QDepo::Db::Connection::Postgresql->new($model);
            last SWITCH;
        };
        /mysql/i && do {
            require QDepo::Db::Connection::Mysql;
            $db = QDepo::Db::Connection::Mysql->new($model);
            last SWITCH;
        };
        /sqlite/i && do {
            require QDepo::Db::Connection::Sqlite;
            $db = QDepo::Db::Connection::Sqlite->new($model);
            last SWITCH;
        };
        # Default
        warn "Database $driver not supported!\n";
        return;
    }

    $self->{dbc} = $db;

    if ( ( !$inst->user or !$inst->pass ) and ( $driver ne 'sqlite' ) ) {
        Exception::Db::Connect::Auth->throw(
            logmsg  => "info#Not connected",
            usermsg => 'info#Need user and pass',
        );
    }

    try {
        $self->{dbh} = $db->db_connect($conf);
        if (blessed $model) {
            $model->get_connection_observable->set(1);
        }
    }
    catch {
        if ( my $e = Exception::Base->catch($_) ) {
            if ( $e->isa('Exception::Db::Connect') ) {
                Exception::Db::Connect::Auth->throw(
                    logmsg  => "info#Not connected",
                    usermsg => 'info#Need user and pass',
                );
            }
            else {
                print 'DBError: ', $e->can('logmsg') ? $e->logmsg : $_
                    if $inst->verbose;
                Exception::Db::Connect->throw(
                    logmsg  => "error#$_",
                    usermsg => 'error#Database error',
                );
            }
        }
    };

    return;
}

1;
