package Pdqm::Observable;

# Very small layout changes.
#
# Original code from:
# Cipres::Registry::Observable
# Author:
#   -- Rutger Vos, 17/Aug/2006 13:57

use strict;
use warnings;

use Data::Dumper;

sub new {
    my ( $class, $value ) = @_;

    my $self = {
        _data      => $value,
        _callbacks => {},
    };

    bless $self, $class;

    return $self;
}

sub add_callback {
    my ( $self, $callback ) = @_;
    $self->{_callbacks}->{$callback} = $callback;
    return $self;
}

sub del_callback {
    my ( $self, $callback ) = @_;
    delete $self->{_callbacks}->{$callback};
    return $self;
}

sub _docallbacks {
    my $self = shift;
    foreach my $cb ( keys %{ $self->{_callbacks} } ) {
        $self->{_callbacks}->{$cb}->( $self->{_data} );
    }
}

sub set {
    my ( $self, $data ) = @_;
    $self->{_data} = $data;
    $self->_docallbacks();
}

sub get {
    my $self = shift;
    return $self->{_data};
}

sub unset {
    my $self = shift;
    $self->{_data} = undef;
    return $self;
}

1;
