package Pdqm::Config;

use strict;
use warnings;

use Data::Dumper;
# use base qw(Class::Accessor);
# use YAML::Tiny;
use Pdqm::Config::Instance;

our $VERSION = 0.01;

sub new {

    my ( $class, $args ) = @_;

    my $self = {};

    bless $self, $class;

    $self->{cf} = Pdqm::Config::Instance->instance( $args );
    # if ( $args->{cfg_ref} ) {
    #     $self->_make_accessors( $args );
    # }

    return $self;
}

sub cfg {
    my $self = shift;

    my $cf = $self->{cf};

    die ref($self) . " requires a config handle to complete an action"
        unless defined $cf and $cf->isa('Pdqm::Config::Instance');

    return $cf->{cfg};
}

# sub _make_accessors {
#     my ( $self, $args ) = @_;

#     my $config = YAML::Tiny::LoadFile( $args->{cfg_ref}{conf_file} );

#     Pdqm::Config->mk_accessors( keys %{$config} );
#     foreach ( keys %{$config} ) {
#         $self->$_( $config->{$_} );
#     }
# }

sub save_config {

    my ( $self, ) = @_;

    # Save the file
    YAML::Tiny::DumpFile( 'recipe.conf.new', $self->{conf} );

    return;
}

# Creating accessors for the config options automaticaly with the help
# of Class::Accessor (from PM node?)

1;
