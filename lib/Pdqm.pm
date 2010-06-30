package Pdqm;

use strict;
use warnings;

use Pdqm::Config;
use Pdqm::Wx::App;

sub new {
    my ($class, $opts) = @_;

    my $self = {};

    bless $self, $class;

    $self->_init($opts);

    return $self;
}

sub _init {
    my ( $self, $opts ) = @_;

    # Config
    $self->{cnf} = Pdqm::Config->new($opts);

    $self->{gui} = Pdqm::Wx::App->create($self);
}

sub run {
    my $self = shift;
    $self->{gui}->MainLoop;
}

1;
