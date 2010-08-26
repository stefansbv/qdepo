# +---------------------------------------------------------------------------+
# | Name     : Qrt (Perl Database Query Manager)                             |
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
# |                                             p a c k a g e   T o o l B a r |
# +---------------------------------------------------------------------------+
package Qrt::Wx::ToolBar;

use strict;
use warnings;

use Qrt::Config;

use Wx qw(:everything);
use base qw{Wx::ToolBar};

sub new {

    my ( $self, $gui ) = @_;

    #- The ToolBar

    $self = $self->SUPER::new(
        $gui,
        -1,
        [-1, -1],
        [-1, -1],
        wxTB_HORIZONTAL | wxNO_BORDER | wxTB_FLAT | wxTB_DOCKABLE,
        5050,
    );

    $self->SetToolBitmapSize( Wx::Size->new( 16, 16 ) );
    $self->SetMargins( 4, 4 );

    # Get ToolBar button atributes
    my $cnf = Qrt::Config->new();
    my $attribs = $cnf->cfg->toolbar;

    #-- Sort by id

    #- Keep only key and id for sorting
    my %temp = map { $_ => $attribs->{$_}{id} } keys %$attribs;

    # Save for later use :) Access from View.pm
    $self->{_tb_btn} = \%temp;

    #- Sort with  ST
    my @attribs = map  { $_->[0] }
        sort { $a->[1] <=> $b->[1] }
        map  { [ $_ => $temp{$_} ] }
        keys %temp;

    # Get options from Control.pm for Wx::Choice
    $self->{options} = $self->get_choice_options();

    # Create buttons in ID order; use sub defined by 'type'
    foreach my $name (@attribs) {
        my $type = $attribs->{$name}{type};
        $self->$type( $name, $attribs->{$name} );
    }

    return $self;
}

sub get_toolbar {
    my $self = shift;
    return $self->{_toolbar};
}

sub item_normal {

    my ($self, $name, $attribs) = @_;

    $self->AddSeparator if $attribs->{sep} =~ m{before};

    # Add the button
    $self->{$name} = $self->AddTool(
        $attribs->{id},
        $self->make_bitmap( $attribs->{icon} ),
        wxNullBitmap,
        wxITEM_NORMAL,
        undef,
        $attribs->{tooltip},
        $attribs->{help},
    );

    $self->AddSeparator if $attribs->{sep} =~ m{after};

    return;
}

sub item_check {

    # I know, another copy of a sub with only one diff is
    #  at least unusual :)

    my ($self, $name, $attribs) = @_;

    $self->AddSeparator if $attribs->{sep} =~ m{before};

    # Add the button
    $self->{name} = $self->AddCheckTool(
        $attribs->{id},
        $name,
        $self->make_bitmap( $attribs->{icon} ),
        wxNullBitmap, # bmpDisabled=wxNullBitmap other doesn't work
        $attribs->{tooltip},
        $attribs->{help},
    );

    $self->AddSeparator if $attribs->{sep} =~ m{after};

    return;
}

sub make_bitmap {

    my ($self, $icon_file) = @_;

    my $icon = $icon_file;
    my $bmp = Wx::Bitmap->new(
        "icons/$icon.gif",
        wxBITMAP_TYPE_GIF,
    );

    return $bmp;
}

sub item_list {

    my ($self, $name, $attribs) = @_;

    # 'sep' must be at least empty string in config;
    $self->AddSeparator if $attribs->{sep} =~ m{before};

    my $output =  Wx::Choice->new(
        $self,
        $attribs->{id},
        [-1,  -1],
        [100, -1],
        $self->{options},
        # wxCB_SORT,
    );

    $self->AddControl( $output );

    $self->AddSeparator if $attribs->{sep} =~ m{after};

    return;
}

sub get_choice_options {

    # Return all options or the name of the option with index

    my ($self, $index) = @_;

    # Options for Wx::Choice from the ToolBar
    # Default is Excel with idx = 0
    $self->{options} = [ 'Excel', 'Calc', 'Writer', 'CSV' ];

    if (defined $index) {
        return $self->{options}[$index];
    }
    else {
        return $self->{options};
    }
}

1;
