package TpdaQrt::Tk::TB;

use strict;
use warnings;

use Tk;
use base qw{Tk::Derived Tk::ToolBar};

Tk::Widget->Construct('TB');

=head1 NAME

TpdaQrt::Tk::TB - Create a toolbar

=head1 VERSION

Version 0.35

=cut

our $VERSION = '0.35';

=head1 SYNOPSIS

    use TpdaQrt::Tk::TB;

    $tb = $self->TB();

    $tb->make_toolbar_buttons( $buttons, $attribs );

Where the parameters are for example:

    $buttons = ['tb1', 'tb2'];       # array ref of the names in order

    $attribs = {                     # attributes
        tb_name => {
            id      => 1001,
            type    => '_item_normal',
            icon    => 'connectyes16',
            tooltip => 'Connect',
            help    => 'Connect to the database',
            sep     => 'after',
        },
    };

=head1 METHODS

=head2 Populate

Constructor method.

=cut

sub Populate {
    my ( $self, $args ) = @_;

    $self->SUPER::Populate($args);

    return;
}

=head2 make_toolbar_buttons

Make main toolbar buttons.

=cut

sub make_toolbar_buttons {
    my ( $self, $toolbars, $attribs ) = @_;

    # Options for Wx::Choice from the ToolBar
    # Default is Excel with idx = 0
    $self->{options} = [ 'Excel', 'ODF', 'Calc', 'CSV' ];

    # Create buttons in ID order; use sub defined by 'type'
    foreach my $name ( @{$toolbars} ) {
        my $type = $attribs->{$name}{type};
        $self->$type( $name, $attribs->{$name} );

        # Initial state disabled, except quit and attach button
        next if $name eq 'tb_qt';
        next if $name eq 'tb_at';            # not used

        # Skip buttons from Help window
        next if $name eq 'tb3gd';            # not used
        next if $name eq 'tb3gp';            # not used
        next if $name eq 'tb3qt';            # not used

        $self->enable_tool( $name, 'disabled' );
    }

    return;
}

=head2 _item_normal

Create a normal toolbar button.

A callback can be defined in the attribs data structure like a
methodname string or a code reference.

=cut

sub _item_normal {
    my ( $self, $name, $attribs ) = @_;

    $self->separator if $attribs->{sep} =~ m{before};

    my $callback = ref $attribs->{method} eq 'CODE' ? $attribs->{method} : '';

    if ($callback) {
        $self->{$name} = $self->ToolButton(
            -image   => $attribs->{icon},
            -tip     => $attribs->{tooltip},
            -command => $callback,
        );
    }
    else {
        $self->{$name} = $self->ToolButton(
            -image => $attribs->{icon},
            -tip   => $attribs->{tooltip},
        );
    }

    $self->separator if $attribs->{sep} =~ m{after};

    return;
}

=head2 _item_check

Create a check toolbar button.

A callback can be defined in the attribs data structure like a
methodname string or a code reference.

=cut

sub _item_check {
    my ( $self, $name, $attribs ) = @_;

    $self->separator if $attribs->{sep} =~ m{before};

    my $callback = ref $attribs->{method} eq 'CODE' ? $attribs->{method} : '';

    if ($callback) {
        $self->{$name} = $self->ToolButton(
            -image       => $attribs->{icon},
            -type        => 'Checkbutton',
            -indicatoron => 0,
            -tip         => $attribs->{tooltip},
            -command     => $callback,
        );
    }
    else {
        $self->{$name} = $self->ToolButton(
            -image       => $attribs->{icon},
            -type        => 'Checkbutton',
            -indicatoron => 0,
            -tip         => $attribs->{tooltip},
        );
    }

    $self->separator if $attribs->{sep} =~ m{after};

    return;
}

=head2 _item_list

Create a list toolbar button, based on Optionmenu.

=cut

sub _item_list {
    my ( $self, $name, $attribs ) = @_;

    $self->separator if $attribs->{sep} =~ m{before};

    $self->{$name} = $self->ToolOptionmenu(
        -indicatoron => 0,
        -tip         => $attribs->{tooltip},
        -options     => $self->{options},
    );

    $self->separator if $attribs->{sep} =~ m{after};

    return;
}

=head2 get_toolbar_btn

Return a toolbar button when we know the its name

=cut

sub get_toolbar_btn {
    my ( $self, $name ) = @_;

    return $self->{$name};
}

=head2 get_choice_options

Return all options or the name of the option with index

=cut

sub get_choice_options {
    my ( $self, $index ) = @_;

    if ( defined $index ) {
        return $self->{options}[$index];
    }
    else {
        return $self->{options};
    }
}

=head2 enable_tool

Toggle tool bar button.  If state is defined then set to state do not
toggle.

State can come as 0 | 1 and normal | disabled.

=cut

sub enable_tool {
    my ( $self, $btn_name, $state ) = @_;

    my $tb_btn = $self->get_toolbar_btn($btn_name);

    my $other;
    if ($state) {
        if ( $state =~ m{norma|disabled}x ) {
            $other = $state;
        }
        else {
            $other = $state ? 'normal' : 'disabled';
        }
    }
    else {
        $state = $tb_btn->cget( -state );
        $other = $state eq 'normal' ? 'disabled' : 'normal';
    }

    $tb_btn->configure( -state => $other );

    return;
}

=head2 toggle_tool_check

Toggle a toolbar checkbutton.

=cut

sub toggle_tool_check {
    my ( $self, $btn_name, $state ) = @_;

    my $tb_btn = $self->get_toolbar_btn($btn_name);

    if ($state) {
        $tb_btn->select;
    }
    else {
        $tb_btn->deselect;
    }

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of TpdaQrt::Tk::TB
