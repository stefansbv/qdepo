package QDepo::Wx::ToolBar;

# ABSTRACT: A ToolBar Control

use strict;
use warnings;

use Locale::TextDomain 1.20 qw(QDepo);
use Wx qw(:everything);
use base qw{Wx::ToolBar};


sub new {
    my ( $self, $gui ) = @_;

    $self = $self->SUPER::new(
        $gui, -1,
        [ -1, -1 ],
        [ -1, -1 ],
        wxTB_HORIZONTAL | wxNO_BORDER | wxTB_FLAT | wxTB_DOCKABLE, 5050,
    );

    $self->SetToolBitmapSize( Wx::Size->new( 16, 16 ) );
    $self->SetMargins( 4, 4 );

    # Options for Wx::Choice from the ToolBar
    # Default is Excel with idx = 0
    $self->{options} = [ 'Excel', 'ODF', 'Calc', 'CSV' ];

    return $self;
}


sub make_toolbar_button {
    my ( $self, $name, $attribs, $ico_path ) = @_;
    my $type = $attribs->{type};
    $self->$type( $name, $attribs, $ico_path );
    return;
}


sub set_initial_mode {
    my ($self, $names) = @_;
    foreach my $name ( @{$names} ) {

        # Initial state disabled, except quit button
        next if $name eq 'tb_qt';
        $self->enable_tool( $name, 0 );    # 0 = disabled
    }
    return;
}


sub _item_normal {
    my ( $self, $name, $attribs, $ico_path ) = @_;

    $self->AddSeparator if $attribs->{sep} =~ m{before};

    # Add the button
    $self->{$name} = $self->AddTool(
        $attribs->{id}, $self->make_bitmap( $ico_path, $attribs->{icon} ),
        wxNullBitmap,   wxITEM_NORMAL,
        undef,          $attribs->{tooltip},
        $attribs->{help},
    );

    $self->AddSeparator if $attribs->{sep} =~ m{after};

    return;
}


sub _item_check {
    my ( $self, $name, $attribs, $ico_path ) = @_;

    $self->AddSeparator if $attribs->{sep} =~ m{before};

    # Add the button
    $self->{$name} = $self->AddTool(
        $attribs->{id}, $self->make_bitmap( $ico_path, $attribs->{icon} ),
        wxNullBitmap,   wxITEM_CHECK,
        undef,          $attribs->{tooltip},
        $attribs->{help},
    );

    $self->AddSeparator if $attribs->{sep} =~ m{after};

    return;
}


sub _item_list {
    my ( $self, $name, $attribs ) = @_;

    # 'sep' must be at least empty string in config;
    $self->AddSeparator if $attribs->{sep} =~ m{before};

    $self->{$name} = Wx::Choice->new(
        $self,
        $attribs->{id},
        [ -1,  -1 ],
        [ 100, -1 ],
        $self->{options},
        # wxCB_SORT,
    );

    $self->{$name}->SetStringSelection( $self->{options}[0] ); # default
    $self->AddControl( $self->{$name} );
    $self->AddSeparator if $attribs->{sep} =~ m{after};

    return;
}


sub get_toolbar_btn {
    my ( $self, $name ) = @_;
    return $self->{$name};
}


sub get_choice_options {
    my ( $self, $index ) = @_;
    if ( defined $index ) {
        return $self->{options}[$index];
    }
    else {
        return $self->{options};
    }
}


sub enable_tool {
    my ( $self, $btn_name, $state ) = @_;

    my $tb_btn_id = $self->get_toolbar_btn($btn_name)->GetId;

    my $new_state;
    if ( defined $state ) {

    SWITCH: for ($state) {
            /^$/        && do { $new_state = 0; last SWITCH; };
            /normal/i   && do { $new_state = 1; last SWITCH; };
            /disabled/i && do { $new_state = 0; last SWITCH; };

            # If other value like 1 | 0
            $new_state = $state ? 1 : 0;
        }
    }
    else {

        # Undef state: toggle
        # print " toggle ";
        $new_state = !$self->GetToolState($tb_btn_id);
    }

    # print "set to $new_state\n";
    $self->EnableTool( $tb_btn_id, $new_state );

    return;
}


sub toggle_tool_check {
    my ( $self, $btn_name, $state ) = @_;
    my $tb_btn_id = $self->get_toolbar_btn($btn_name)->GetId;
    $self->ToggleTool( $tb_btn_id, $state );
    return;
}


sub make_bitmap {
    my ( $self, $ico_path, $icon ) = @_;
    my $bmp = Wx::Bitmap->new( $ico_path . "/$icon.gif", wxBITMAP_TYPE_ANY, );
    return $bmp;
}

1;

=head1 SYNOPSIS

    use QDepo::Wx::ToolBar;
    $self->SetToolBar( QDepo::Wx::ToolBar->new( $self, wxADJUST_MINSIZE ) );
    $self->{_tb} = $self->GetToolBar;
    $self->{_tb}->Realize;

=head2 new

Constructor method.

=head2 make_toolbar_button

Make toolbar button.

=head2 set_initial_mode

Disable some of the toolbar buttons.

=head2 _item_normal

Create a normal toolbar button

=head2 _item_check

Create a check toolbar button

=head2 _item_list

Create a list toolbar button. Not used.

=head2 get_toolbar_btn

Return a toolbar button by name.

=head2 get_choice_options

Return all options or the name of the option with index

=head2 enable_tool

Toggle tool bar button.  If state is defined then set to state, do not
toggle.

State can come as 0 | 1 and normal | disabled.  Because toolbar.yml is
used for both Tk and Wx, this sub is more complex that is should be.

=head2 toggle_tool_check

Toggle a toolbar checkbutton.  State can come as 0 | 1.

=head2 make_bitmap

Create and return a bitmap object, of any type.

=cut
