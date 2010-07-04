package Pdqm::Config;

use strict;
use warnings;

use Pdqm::Config::Instance;

our $VERSION = 0.03;

sub new {

    my ( $class, $args ) = @_;

    my $self = {};

    bless $self, $class;

    $self->{cfi} = Pdqm::Config::Instance->instance( $args );

    return $self;
}

sub cfg {
    my $self = shift;

    my $cf = $self->{cfi};

    die ref($self) . " requires a config handle!"
        unless defined $cf and $cf->isa('Pdqm::Config::Instance');

    return $cf;
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
