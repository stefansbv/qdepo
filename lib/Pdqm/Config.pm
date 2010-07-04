package Pdqm::Config;

# Creating accessors for the config options automaticaly with the help
# of Class::Accessor
#
# Inspired from PM node: perlmeditation [id://234012]
# by trs80 (Priest) on Feb 10, 2003 at 04:25 UTC

use strict;
use warnings;

use Data::Dumper;

use File::HomeDir;
use File::Spec::Functions;

use Pdqm::Config::Instance;

our $VERSION = 0.04;

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

sub process_configs {
    my ($self, ) = @_;

    my $home_path  = File::HomeDir->my_home;

    my $rdfext  = $self->cfg->rex->{rdfext};
    my $rdfpath = $self->cfg->rex->{rdfpath};

    my $rdfpath_qn = catdir($home_path, '.reports/Contracte' ,);

    return $rdfext;
}

sub save_config {

    my ( $self, ) = @_;

    # Save the file
    YAML::Tiny::DumpFile( 'recipe.conf.new', $self->{conf} );

    return;
}

1;
