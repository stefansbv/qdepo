package QDepo::Observable;

# ABSTRACT: Obrserver patern implementation

use strict;
use warnings;

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
    $self->{_callbacks}{$callback} = $callback;
    return $self;
}

sub del_callback {
    my ( $self, $callback ) = @_;
    delete $self->{_callbacks}{$callback};
    return $self;
}

sub _docallbacks {
    my $self = shift;
    foreach my $cb ( keys %{ $self->{_callbacks} } ) {
        $self->{_callbacks}{$cb}->( $self->{_data} );
    }
    return;
}

sub set {    ## no critic (ProhibitAmbiguousNames)
    my ( $self, $data ) = @_;
    $self->{_data} = $data;
    $self->_docallbacks();
    return;
}

sub get {    ## no critic (ProhibitAmbiguousNames)
    my $self = shift;
    return $self->{_data};
}

sub unset {
    my $self = shift;
    $self->{_data} = undef;
    return $self;
}

1;

=head2 new

Constructor method.

=head2 add_callback

Add a callback.

=head2 del_callback

Delete a callback.

=head2 _docallbacks

Run callbacks.

=head2 set

Set data value and execute the callbacks.

=head2 get

Return data.

=head2 unset

Set data to undef.

=head1 ACKNOWLEDGEMENTS

From: Cipres::Registry::Observable Author: Rutger Vos, 17/Aug/2006 13:57       
 http://svn.sdsc.edu/repo/CIPRES/cipresdev/branches/guigen \             
/cipres/framework/perl/cipres/lib/Cipres/ Thank You!

Copyright:   Rutger Vos   2006

=cut
