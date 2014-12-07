package QDepo::Db;

# ABSTRACT: The Database operations module

use strict;
use warnings;

use Scalar::Util qw(blessed);

use QDepo::Db::Connection;

sub new {
    my ($class, $model) = @_;
    my $conn = QDepo::Db::Connection->new($model);
    my $self = {
        conn  => $conn,
        model => $model,
    };
    return bless $self, $class;
}

sub model {
    my $self = shift;
    return $self->{model};
}

sub dbh {
    my $self = shift;
    return $self->{conn}{dbh};
}

sub dbc {
    my $self = shift;
    return $self->{conn}{dbc};
}

sub disconnect {
    my $self = shift;
    if ( blessed $self->{conn}{dbh} and $self->{conn}{dbh}->isa('DBI::db') ) {
        $self->{conn}{dbh}->disconnect;
        $self->model->get_connection_observable->set(0);
    }
    return;
}

sub DESTROY {
    my $self = shift;
    $self->disconnect;
}

1;

=head1 SYNOPSIS

Create a new connection instance only once and use it many times.

    use QDepo::Db;

    my $dbi = QDepo::Db->new($args);

    my $dbh = $dbi->dbh;

=head1 METHODS

=head2 new

Constructor method, creates a new instance.

=head2 db_connect

Connect when there already is an instance.

=head2 dbh

Return database handle.

=head2 dbc

Module instance

=head2 DESTROY

Destroy method.

=head1 ACKNOWLEDGEMENTS

Inspired from PerlMonks node [id://609543] by GrandFather.

=cut
