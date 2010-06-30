package Pdqm;

use strict;
use warnings;

use Pdqm::Wx::App;

sub new {
    my $class = shift;

    my $self = {};

    bless $self, $class;

    $self->_init;

    return $self;
}

sub _init {
    my $self = shift;

    Pdqm::Wx::App->new()->MainLoop;
}

1;
