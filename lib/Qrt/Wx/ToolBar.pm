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
# |                                             p a c k a g e   T o o l B a r |
# +---------------------------------------------------------------------------+
package Qrt::Wx::ToolBar;

use strict;
use warnings;

use Qrt::Config;

use Wx qw(:everything);
use base qw{Wx::ToolBar};

=head1 NAME

Qrt::Wx::ToolBar - Create a toolbar


=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

    use Qrt::Wx::ToolBar;
    $self->SetToolBar( Qrt::Wx::ToolBar->new( $self, wxADJUST_MINSIZE ) );
    $self->{_tb} = $self->GetToolBar;
    $self->{_tb}->Realize;


=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {

    my ( $self, $gui ) = @_;

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
    my $cfg = Qrt::Config->instance();
    my $attribs = $cfg->toolbar;
    $self->{ico_p} = $cfg->icons;

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

    $self->{options} = $self->get_choice_options();

    # Create buttons in ID order; use sub defined by 'type'
    foreach my $name (@attribs) {
        my $type = $attribs->{$name}{type};
        $self->$type( $name, $attribs->{$name} );
    }

    return $self;
}

=head2 get_toolbar

Return the toolbar instance variable

=cut

sub get_toolbar {
    my $self = shift;

    return $self->{_toolbar};
}

=head2 item_normal

Create a normal toolbar button

=cut

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

=head2 item_check

Create a check toolbar button

=cut

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

=head2 make_bitmap

Create and return a bitmap object

=cut

sub make_bitmap {

    my ($self, $icon) = @_;

    my $bmp = Wx::Bitmap->new(
        $self->{ico_p} . "/$icon.gif",
        wxBITMAP_TYPE_GIF,
    );

    return $bmp;
}

=head2 item_list

Create a list toolbar button

=cut

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

    $output->SetStringSelection($self->{options}[0]); # Explicit default

    $self->AddControl( $output );

    $self->AddSeparator if $attribs->{sep} =~ m{after};

    return;
}

=head2 get_choice_options

Return all options or the name of the option with index

=cut

sub get_choice_options {
    my ($self, $index) = @_;

    # Options for Wx::Choice from the ToolBar
    # Default is Excel with idx = 0
    $self->{options} = [ 'Calc', 'CSV', 'Excel' ];

    if (defined $index) {
        return $self->{options}[$index];
    }
    else {
        return $self->{options};
    }
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

1; # End of Qrt::Wx::App
