package Pdqm::Config;

use strict;
use warnings;

use Data::Dumper;
use YAML::Tiny;

our $VERSION = 0.01;

sub new {

    my $class = shift;

    my $self = {};

    bless $self, $class;

    $self->{conf} = {};

    $self->_init;

    return $self;
}

sub _init {

    my ($self) = @_;

    # Open the config
    $self->{conf} = YAML::Tiny::LoadFile('/home/fane/project/dbqr/recipe.conf');

    return;
}

sub get_config {

    my ($self, $section) = @_;

    return $self->{conf}{$section} ;
}

sub save_config {

    my ($self, ) = @_;

    # Save the file
    YAML::Tiny::DumpFile( 'recipe.conf.new', $self->{conf} );

    return;
}

1;
