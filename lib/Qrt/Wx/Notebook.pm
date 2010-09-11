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
# |                                           p a c k a g e   N o t e b o o k |
# +---------------------------------------------------------------------------+
package Qrt::Wx::Notebook;

use strict;
use warnings;

use Wx qw(:everything);  # TODO: Eventualy change this!
use Wx::AUI;

use base qw{Wx::AuiNotebook};

=head1 NAME

Qrt::Wx::Notebook - Create a notebook


=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

    use Qrt::Wx::Notebook;

    $self->{_nb} = Qrt::Wx::Notebook->new( $gui );


=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {

    my ( $class, $gui ) = @_;

    #- The Notebook

    my $self = $class->SUPER::new(
        $gui,
        -1,
        [-1, -1],
        [-1, -1],
        wxAUI_NB_TAB_FIXED_WIDTH,
    );

    #-- Panels

    $self->{p1} = Wx::Panel->new( $self, -1, wxDefaultPosition, wxDefaultSize );
    $self->{p2} =
        Wx::Panel->new( $self, -1, wxDefaultPosition, wxDefaultSize, );

    $self->{p3} =
        Wx::Panel->new( $self, -1, wxDefaultPosition, wxDefaultSize, );
    $self->{p4} =
        Wx::Panel->new( $self, -1, wxDefaultPosition, wxDefaultSize, );

    #--- Pages

    $self->AddPage( $self->{p1}, 'Query list' );
    $self->AddPage( $self->{p2}, 'Parameters' );
    $self->AddPage( $self->{p3}, 'SQL' );
    $self->AddPage( $self->{p4}, 'Config info' );

    return $self;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>


=head1 BUGS

None known.

Please report any bugs or feature requests to the author.


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1; # End of Qrt::Wx::Notebook
