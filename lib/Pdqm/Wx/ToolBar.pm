package Pdqm::Wx::ToolBar;

use strict;
use warnings;

use Data::Dumper;

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

    # Get ToolBar button atributes defined in Control.pm
    my $attribs = $self->get_tb_attr();

    #-- Sort by id

    #- Keep only key and id for sorting
    my %temp = map { $_ => $attribs->{$_}{id} } keys %$attribs;

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

### - where to put this?
#-- Define atributes for ToolBar buttons

sub get_tb_attr {
    my ($self) = @_;

    return {
        tb_cn => {
            id      =>  1001,
            type    => 'item_check',
            icon    => 'connectyes16',
            action  => 'toggle connect',
            tooltip => 'Connect/disconnect',
            help    => 'Connect/disconnect from the database',
            sep     => 'after',
        },
        tb_sv => {
            id      =>  1002,
            type    => 'item_normal',
            icon    => 'filesave16',
            action  => 'report_save',
            tooltip => 'Save',
            help    => 'Save query definition file',
            sep     => '',
        },
        tb_rf => {
            id      =>  1003,
            type    => 'item_normal',
            icon    => 'actreload16',
            action  => 'report_data_refresh',
            tooltip => 'Refresh',
            help    => 'Refresh data',
            sep     => 'after',
        },
        tb_ad => {
            id      =>  1004,
            type    => 'item_normal',
            icon    => 'actitemadd16',
            action  => 'report_add',
            tooltip => 'Add report',
            help    => 'Create new query definition file',
            sep     => '',
        },
        tb_rm => {
            id      =>  1005,
            type    => 'item_normal',
            icon    => 'actitemdelete16',
            action  => 'report_remove',
            tooltip => 'Remove',
            help    => 'Remove query definition file',
            sep     => '',
        },
        tb_ed => {
            id      =>  1006,
            type    => 'item_check',
            icon    => 'edit16',
            action  => 'report_edit',
            tooltip => 'Edit',
            help    => 'Edit mode on/off',
            sep     => 'after',
        },
        tb_ls => {
            id      =>  1007,
            type    => 'item_list',
            action  => 'choice_change',
            sep     => 'after',
        },
        tb_go => {
            id    =>  1008,
            type    => 'item_normal',
            icon    => 'navforward16',
            action  => 'report_run',
            tooltip => 'Run',
            help    => 'Run export',
            sep     => 'after',
        },
        tb_qt => {
            id    =>  1009,
            type    => 'item_normal',
            icon    => 'actexit16',
            action  => 'button_exit',
            tooltip => 'Quit',
            help    => 'Quit the application',
            sep     => '',
        },
    };
}

### or this? !!!

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
