package QDepo::Db;

# ABSTRACT: The Database operations module

use strict;
use warnings;

use Scalar::Util qw(blessed);

use QDepo::Db::Connection;

use base qw(Class::Singleton);

=head1 SYNOPSIS

Create a new connection instance only once and use it many times.

    use QDepo::Db;

    my $dbi = QDepo::Db->instance($args); # first time init

    my $dbi = QDepo::Db->instance();      # later, in other modules

    my $dbh = $dbi->dbh;

=head1 METHODS

=head2 _new_instance

Constructor method, the first and only time a new instance is created.
All parameters passed to the instance() method are forwarded to this
method. (From I<Class::Singleton> docs).

=cut

sub _new_instance {
    my ($class, $model) = @_;

    my $conn = QDepo::Db::Connection->new($model);

    return bless { conn => $conn }, $class;
}

=head2 db_connect

Connect when there already is an instance.

=cut

sub db_connect {
    my ($self, $model) = @_;
    my $conn = QDepo::Db::Connection->new($model);
    $self->{conn} = $conn;
    return $self;
}

=head2 dbh

Return database handle.

=cut

sub dbh {
    my $self = shift;
    return $self->{conn}{dbh};
}

=head2 dbc

Module instance

=cut

sub dbc {
    my $self = shift;
    return $self->{conn}{dbc};
}

=head2 DESTROY

Destroy method.

=cut

sub DESTROY {
    my $self = shift;

    if ( blessed $self->{conn}{dbh} and $self->{conn}{dbh}->isa('DBI::db') ) {
        $self->{conn}{dbh}->disconnect;
    }

    return;
}

1;

=head1 ACKNOWLEDGEMENTS

Inspired from PerlMonks node [id://609543] by GrandFather.
