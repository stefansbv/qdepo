package Pdqm;

use strict;
use warnings;

use Pdqm::Config;
use Pdqm::Wx::App;

sub new {
    my ($class, $args) = @_;

    my $self = {};

    bless $self, $class;

    $self->_init($args);

    return $self;
}

sub _init {
    my ( $self, $args ) = @_;

    # Initialize config for the first time
    my $cnf = Pdqm::Config->new($args);

    # Create Wx application
    $self->{gui} = Pdqm::Wx::App->create();
}

sub run {
    my $self = shift;
    $self->{gui}->MainLoop;
}

1;
