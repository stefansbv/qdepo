package Pdqm::Config::Instance;

use strict;
use warnings;

use base qw(Class::Singleton Class::Accessor);
use YAML::Tiny;

our $VERSION = 0.03;

sub _new_instance {
    my ($class, $args) = @_;

    my $self = bless {}, $class;

    if ( $args->{cfg_ref} ) {
        $self->_make_accessors( $args );
    }

    return $self;
}

sub _make_accessors {
    my ( $self, $args ) = @_;

    my $config = YAML::Tiny::LoadFile( $args->{cfg_ref}{conf_file} );

    __PACKAGE__->mk_accessors( keys %{$config} );
    foreach ( keys %{$config} ) {
        $self->$_( $config->{$_} );
    }
}

1;

__END__
