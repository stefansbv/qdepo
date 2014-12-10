package QDepo::Db::Connection;

# ABSTRACT: Connect to various databases

use strict;
use warnings;

use Scalar::Util qw(blessed);
use DBI;
use Try::Tiny;
use QDepo::Exceptions;
use Locale::TextDomain 1.20 qw(QDepo);

require QDepo::Config;

sub new {
    my ($class, $model) = @_;
    my $self = {};
    $self->{_model} = $model;
    bless $self, $class;
    $self->_connect;
    return $self;
}

sub model {
    my $self = shift;
    return $self->{_model};
}

sub _connect {
    my $self = shift;

    my $conf = QDepo::Config->instance;
    my $conn = $conf->connection;
    my $db   = $self->load({
        model  => $self->model,
        driver => $conn->driver,
    });
    $self->{dbc} = $db;

    try {
        $self->{dbh} = $db->db_connect($conn);
    }
    catch {
        if ( my $e = Exception::Base->catch($_) ) {
            if ( $e->isa('Exception::Db::Connect') ) {
                $e->throw;
            }
        }
    };
    if (    blessed $self->model
        and blessed $self->{dbh}
        and $self->{dbh}->isa('DBI::db') )
    {
        $self->model->get_connection_observable->set(1); # connected
    }
    return;
}

sub load {
    my ( $self, $p ) = @_;
    my $driver = delete $p->{driver}
        or die 'Missing "driver" parameter to load()';
    $driver = ucfirst $driver;

    # Load the driver class.
    my $pkg = __PACKAGE__ . "::$driver";
    try { eval "require $pkg" or die "Unable to load $pkg"; }
    catch {
        $self->model->message_log(
            __x('{ert} {driver} engine is not implemented',
                ert    => 'EE',
                driver => $driver,
            )
        );
    };
    return $pkg->new( $p );
}

1;

__END__

=pod

=head2 new

Constructor method, the first and only time a new instance is created.
All parameters passed to the instance() method are forwarded to this
method. (From I<Class::Singleton> docs).

=head2 _connect

Connect method, uses I<QDepo::Config> module for configuration.

Using separate modules for each RDBMS, because ...

=head3 C<load>

This method and it's documenattion is copied/inspired from the Sqitch
project.  Thanks!

  my $cmd = QDepo::Db::Connection->load(%params);

A factory method for instantiating engines. It loads the subclass for
the specified engine and calls C<new>, passing the Model
object. Supported parameters are:

=over

=item C<model>

The QDepo::Model object.

=item C<driver>

The driver (engine) module name.

=back

=cut
