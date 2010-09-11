# +---------------------------------------------------------------------------+
# | Name     : tpda-qrt (TPDA - Query Repository Tool)                        |
# | Author   : Stefan Suciu  [ stefansbv 'at' users . sourceforge . net ]     |
# | Website  : http://tpda-qrt.sourceforge.net                                |
# |                                                                           |
# | Copyright (C) 2004-2010  Stefan Suciu                                     |
# |                                                                           |
# | This program is free software; you can redistribute it and/or modify      |
# | it under the terms of the GNU General Public License as published by      |
# | the Free Software Foundation; either version 2 of the License, or         |
# | (at your option) any later version.                                       |
# |                                                                           |
# | This program is distributed in the hope that it will be useful,           |
# | but WITHOUT ANY WARRANTY; without even the implied warranty of            |
# | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             |
# | GNU General Public License for more details.                              |
# |                                                                           |
# | You should have received a copy of the GNU General Public License         |
# | along with this program; if not, write to the Free Software               |
# | Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA |
# +---------------------------------------------------------------------------+
# |
# +---------------------------------------------------------------------------+
# |                                       p a c k a g e   O b s e r v a b l e |
# +---------------------------------------------------------------------------+
package Qrt::Observable;

use strict;
use warnings;

=head1 NAME

Qrt::Observable - Obrserver patern implementation


=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

    use Qrt::Observable;

    sub new {
        my $class = shift;

        my $self = {
            _data1 => Qrt::Observable->new(),
            _data2 => Qrt::Observable->new(),
        };

        bless $self, $class;

        return $self;
    }


=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my ( $class, $value ) = @_;

    my $self = {
        _data      => $value,
        _callbacks => {},
    };

    bless $self, $class;

    return $self;
}

=head2 add_callback

Add a callback

=cut

sub add_callback {
    my ( $self, $callback ) = @_;

    $self->{_callbacks}->{$callback} = $callback;

    return $self;
}

=head2 del_callback

Delete a callback

=cut

sub del_callback {
    my ( $self, $callback ) = @_;

    delete $self->{_callbacks}->{$callback};

    return $self;
}

=head2 _docallbacks

Run callbacks

=cut

sub _docallbacks {
    my $self = shift;

    foreach my $cb ( keys %{ $self->{_callbacks} } ) {
        $self->{_callbacks}->{$cb}->( $self->{_data} );
    }
}

=head2 set

Set data value

=cut

sub set {
    my ( $self, $data ) = @_;

    $self->{_data} = $data;
    $self->_docallbacks();
}

=head2 get

Return data

=cut

sub get {
    my $self = shift;

    return $self->{_data};
}

=head2 unset

Set data to undef

=cut

sub unset {
    my $self = shift;

    $self->{_data} = undef;

    return $self;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>


=head1 BUGS

None known.

Please report any bugs or feature requests to the author.


=head1 ACKNOWLEDGEMENTS

From: Cipres::Registry::Observable
Author: Rutger Vos, 17/Aug/2006 13:57
        http://svn.sdsc.edu/repo/CIPRES/cipresdev/branches/guigen \
             /cipres/framework/perl/cipres/lib/Cipres/
Thank You!


=head1 LICENSE AND COPYRIGHT

Copyright:
  Rutger Vos   2006
  Stefan Suciu 2010

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1; # End of Qrt::Db
