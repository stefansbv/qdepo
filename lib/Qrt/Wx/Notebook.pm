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

use Wx qw(:everything);  # Eventualy change this !!!
use Wx::AUI;

use base qw{Wx::AuiNotebook};

sub new {

    my ( $class, $gui, $repo ) = @_;

    #- The Notebook

    my $self = $class->SUPER::new(
        $gui,
        -1,
        [-1, -1],
        [-1, -1],
        wxAUI_NB_TAB_FIXED_WIDTH,
    );

    $self->{repo} = $repo;  # Report app object

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
    $self->AddPage( $self->{p4}, 'Configuration' );

    # # Works but makes interface to not respond to mouse interaction
    # Wx::Event::EVT_AUINOTEBOOK_PAGE_CHANGING(
    #     $self, -1, \&OnPageChanging );

    # # Inspired ... from Kephra ;)
    # Wx::Event::EVT_AUINOTEBOOK_PAGE_CHANGED(
    #     $self,
    #     -1,
    #     sub {
    #         my ( $bar, $event ) = @_;  # bar !!! realy? :)

    #         my $new_pg = $event->GetSelection;
    #         my $old_pg = $event->GetOldSelection;

    #         $self->{repo}->on_page_change($old_pg, $new_pg);

    #         $event->Skip;
    #     });


    return $self;
}

1;
