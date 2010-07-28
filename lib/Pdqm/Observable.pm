# +---------------------------------------------------------------------------+
# | Name     : Pdqm (Perl Database Query Manager)                             |
# | Author   : Stefan Suciu  [ stefansbv 'at' users . sourceforge . net ]     |
# | Website  :                                                                |
# |                                                                           |
# | Copyright (C) 2010  Stefan Suciu                                          |
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
package Pdqm::Observable;

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
