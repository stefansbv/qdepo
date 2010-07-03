package Pdqm;

use strict;
use warnings;

use Data::Dumper;

use Pdqm::Config;
use Pdqm::Wx::App;

sub new {
    my ($class, $opts) = @_;
    #my ($class) = @_;

    my $self = {};

    bless $self, $class;

    $self->_init($opts);
    #$self->_init();

    return $self;
}

sub _init {
    my ( $self, $opts ) = @_;
    # my ($self) = @_;

    # Config
    $self->{cnf} = Pdqm::Config->new($opts);

    # $self->{gui} = Pdqm::Wx::App->create($self);
    $self->{gui} = Pdqm::Wx::App->create();
}

sub run {
    my $self = shift;
    $self->{gui}->MainLoop;
}

1;
