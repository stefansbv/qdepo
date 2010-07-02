package Pdqm::Config;

use strict;
use warnings;

use Data::Dumper;

use base ('Class::Accessor');
use YAML::Tiny;

our $VERSION = 0.01;

sub new {

    my ( $class, $args ) = @_;

    my $self = {};

    bless $self, $class;

    if ( $args->{conf_file} ) {
        $self->_make_accessors( $args );
    }

    return $self;
}

sub _make_accessors {
    my ( $self, $args ) = @_;

    my $config = YAML::Tiny::LoadFile( $args->{conf_file} );

    print Dumper(     $config );
    Pdqm::Config->mk_accessors( keys %{$config} );
    foreach ( keys %{$config} ) {
        $self->$_( $config->{$_} );
    }
}

sub save_config {

    my ( $self, ) = @_;

    # Save the file
    YAML::Tiny::DumpFile( 'recipe.conf.new', $self->{conf} );

    return;
}

# Creating accessors for the config options automaticaly with the help
# of Class::Accessor (from PM node?)

1;
