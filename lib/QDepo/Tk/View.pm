package QDepo::Tk::View;

use strict;
use warnings;
use Ouch;

use File::Spec::Functions qw(abs2rel);
use Tk;
use Tk::widgets qw(NoteBook StatusBar Dialog DialogBox MListbox Checkbutton
    LabFrame MsgBox);

use QDepo::Config;
use QDepo::Tk::TB;    # ToolBar
use QDepo::Utils;

use base 'Tk::MainWindow';

=head1 NAME

QDepo::Tk::App - Tk Perl application class

=head1 VERSION

Version 0.39

=cut

our $VERSION = '0.39';

=head1 SYNOPSIS

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;
    my $model = shift;

    #- The MainWindow

    my $self = __PACKAGE__->SUPER::new(@_);

    $self->{_model} = $model;

    $self->{_cfg} = QDepo::Config->instance();

    $self->title(" QDepo ");

    #- Load resource file, if found

    my $resource = $self->{_cfg}->xresource_file();
    if ($resource) {
        if ( -f $resource ) {
            $model->message_log("II: Reading resource from '$resource'");
            $self->optionReadfile( $resource, 'widgetDefault' );
        }
        else {
            $model->message_log("II: Resource not found: '$resource'");
        }
    }

    $self->{bg} = $self->cget('-background');

    $self->change_look();

    #-- GUI components

    $self->_create_menu();
    $self->_create_toolbar();
    $self->_create_statusbar();
    $self->_create_notebook();
    $self->_create_para_page();
    $self->_create_sql_page();
    $self->_create_config_page();
    $self->_create_report_page();

    #-- GUI actions

    $self->_set_model_callbacks();

    return $self;
}

sub change_look {
    my $self = shift;

    # Operating system
    my ( $os, $fontglob, $fonttext );
    if ( $^O eq 'MSWin32' ) {
        $os = 'win32';

        # Default fonts
        $fontglob = '{MS Sans Serif} 8';
        $fonttext = '{Courier New} 8';
    }
    else {
        $os = 'linux';

        # New fonts
        $fontglob = '{MS Sans Serif} 10';
        $fonttext = '{Terminus} 11';         # Courier New
    }

    # Change the font and fg color
    $self->optionAdd("*font", $fontglob, "userDefault");
    # $self->optionAdd("*importantText*foreground", "red", "userDefault");
    $self->optionAdd("*importantText*font", $fonttext, "userDefault");

    # Change the background color and troughcolor for some widgets:
    for (qw(Entry MListbox Text)) {
        $self->optionAdd("*$_.background", "white", "userDefault");
    }

    return;
}

=head2 w_geometry

Return window geometry

=cut

sub get_geometry {
    my $self = shift;

    $self->update;

    my $wsys = $self->windowingsystem;
    my $name = $self->name;
    my $geom = $self->geometry;

    # All dimensions are in pixels.
    my $sh = $self->screenheight;
    my $sw = $self->screenwidth;

    # print "\nSystem   = $wsys\n";
    # print "Name     = $name\n";
    # print "Geometry = $geom\n";
    # print "Screen   = $sw x $sh\n";

    return $geom;
}

=head2 _model

Return model instance

=cut

sub _model {
    my $self = shift;

    return $self->{_model};
}

=head2 _cfg

Return config instance variable

=cut

sub _cfg {
    my $self = shift;

    return $self->{_cfg};
}

=head2 _set_model_callbacks

Define the model callbacks

=cut

sub _set_model_callbacks {
    my $self = shift;

    my $co = $self->_model->get_connection_observable;
    $co->add_callback( sub { $self->toggle_status_cn( $_[0] ); } );

    # When the status changes, update gui components
    my $apm = $self->_model->get_appmode_observable;
    $apm->add_callback( sub { $self->update_gui_components } );

    my $upd = $self->_model->get_itemchanged_observable;
    $upd->add_callback(
        sub {
            $self->controls_populate;
            $self->toggle_sql_replace;
        }
    );

    my $so = $self->_model->get_stdout_observable;
    $so->add_callback( sub { $self->set_status( $_[0], 'ms' ) } );

    my $xo = $self->_model->get_message_observable;
    $xo->add_callback( sub{ $self->log_msg( @_ ) } );

    my $pr = $self->_model->get_progress_observable;
    $pr->add_callback(
        sub {
            $self->{progress} = $_[0];
            $self->update;
        }
    );

    # Set continue to true
    $self->_model->set_continue(1);

    return;
}

=head2 update_gui_components

When the application status (mode) changes, update gui components.
Screen controls (widgets) are not handled here, but in controller
module.

=cut

sub update_gui_components {
    my $self = shift;

    my $mode = $self->_model->get_appmode;

    $self->set_status( $mode, 'md' );    # update statusbar

    if ($mode eq 'edit') {
        $self->{_tb}->toggle_tool_check( 'tb_ed', 1 );
    }
    else {
        $self->{_tb}->toggle_tool_check( 'tb_ed', 0 );
    }

    return;
}

=head2 _create_menu

Create the menu

=cut

sub _create_menu {
    my $self = shift;

    $self->{_menu} = $self->Menu();

    my $attribs = $self->_cfg->menubar;

    $self->make_menus($attribs);

    $self->configure( -menu => $self->{_menu} );

    return;
}

=head2 make_menus

Make menus

=cut

sub make_menus {
    my ( $self, $attribs, $position ) = @_;

    $position = 1 if !$position;
    my $menus = QDepo::Utils->sort_hash_by_id($attribs);

    #- Create menus
    foreach my $menu_name ( @{$menus} ) {

        $self->{_menu}{$menu_name} = $self->{_menu}->Menu( -tearoff => 0 );

        my @popups
            = sort { $a <=> $b } keys %{ $attribs->{$menu_name}{popup} };
        foreach my $id (@popups) {
            $self->make_popup_item(
                $self->{_menu}{$menu_name},
                $attribs->{$menu_name}{popup}{$id},
            );
        }

        $self->{_menu}->insert(
            $position,
            'cascade',
            -menu      => $self->{_menu}{$menu_name},
            -label     => $attribs->{$menu_name}{label},
            -underline => $attribs->{$menu_name}{underline},
        );

        $position++;
    }

    return;
}

=head2 get_app_menus_list

Get application menus list, needed for binding the command to load the
screen.  We only need the name of the popup which is also the name of
the screen (and also the name of the module).

=cut

sub get_app_menus_list {
    my $self = shift;

    my $attribs = $self->_cfg->appmenubar;
    my $menus   = QDepo::Utils->sort_hash_by_id($attribs);

    my @menulist;
    foreach my $menu_name ( @{$menus} ) {
        my @popups
            = sort { $a <=> $b } keys %{ $attribs->{$menu_name}{popup} };
        foreach my $item (@popups) {
            push @menulist, $attribs->{$menu_name}{popup}{$item}{name};
        }
    }

    return \@menulist;
}

=head2 make_popup_item

Make popup item

=cut

sub make_popup_item {
    my ( $self, $menu, $item ) = @_;

    $menu->add('separator') if $item->{sep} eq 'before';

    $self->{_menu}{ $item->{name} } = $menu->command(
        -label       => $item->{label},
        -accelerator => $item->{key},
        -underline   => $item->{underline},
    );

    $menu->add('separator') if $item->{sep} eq 'after';

    return;
}

=head2 get_menu_popup_item

Return a menu popup by name

=cut

sub get_menu_popup_item {
    my ( $self, $name ) = @_;

    return $self->{_menu}{$name};
}

=head2 get_menubar

Return the menu bar handler

=cut

sub get_menubar {
    my $self = shift;
    return $self->{_menu};
}

=head2 _create_toolbar

Create toolbar

=cut

sub _create_toolbar {
    my $self = shift;

    $self->{_tb} = $self->TB();

    my ( $toolbars, $attribs ) = $self->toolbar_names();

    $self->{_tb}->make_toolbar_buttons( $toolbars, $attribs );

    return;
}

=head2 toolbar_names

Get Toolbar names as array reference from config.

=cut

sub toolbar_names {
    my $self = shift;

    # Get ToolBar button atributes
    my $attribs = $self->_cfg->toolbar;

    my $toolbars = QDepo::Utils->sort_hash_by_id($attribs);

    return ( $toolbars, $attribs );
}

=head2 enable_tool

Enable|disable tool bar button.

State can come as 0|1 and normal|disabled.

=cut

sub enable_tool {
    my ( $self, $btn_name, $state ) = @_;

    $self->{_tb}->enable_tool( $btn_name, $state );

    return;
}

sub _create_statusbar {
    my $self = shift;

    my $sb = $self->StatusBar();

    # Dummy label for left space
    my $ldumy = $sb->addLabel(
        -width  => 1,
        -relief => 'flat',
    );

    # First label for various messages
    $self->{_sb}{ms} = $sb->addLabel( -relief => 'flat' );

    # Connection icon
    $self->{_sb}{cn} = $sb->addLabel(
        -width  => 20,
        -relief => 'raised',
        -anchor => 'center',
        -side   => 'right',
    );

    # Database name
    $self->{_sb}{db} = $sb->addLabel(
        -width      => 13,
        -anchor     => 'center',
        -side       => 'right',
        -background => 'lightyellow',
    );

    # Progress
    $self->{progress} = 0;
    $self->{_sb}{pr} = $sb->addProgressBar(
        -length     => 60,
        -from       => 0,
        -to         => 100,
        -variable   => \$self->{progress},
        -foreground => 'blue',
    );

    # Mode
    $self->{_sb}{md} = $sb->addLabel(
        -width      => 4,
        -anchor     => 'center',
        -side       => 'right',
        -foreground => 'blue',
        -background => 'lightyellow',
    );

    return;
}

=head2 get_statusbar

Return the status bar handler

=cut

sub get_statusbar {
    my ( $self, $sb_id ) = @_;

    return $self->{_sb}{$sb_id};
}

=head2 _create_notebook

Create the NoteBook and panes.

=cut

sub _create_notebook {
    my $self = shift;

    #- Tk::NoteBook

    $self->{_nb} = $self->NoteBook()->pack(
        -side   => 'top',
        -padx   => 3,
        -pady   => 3,
        -ipadx  => 6,
        -ipady  => 6,
        -fill   => 'both',
        -expand => 1,
    );

    #- Panels

    $self->_create_notebook_panel( 'p1', 'Query List' );
    $self->_create_notebook_panel( 'p2', 'Parameters' );
    $self->_create_notebook_panel( 'p3', 'SQL Query' );
    $self->_create_notebook_panel( 'p4', 'Log Info' );

    $self->{_nb}->pack(
        -side   => 'top',
        -fill   => 'both',
        -padx   => 5,
        -pady   => 5,
        -expand => 1,
    );

    # Initialize
    $self->{_nb}->raise('p1');

    return;
}

=head2 _create_notebook_panel

Create a NoteBook panel

=cut

sub _create_notebook_panel {
    my ( $self, $panel, $label ) = @_;

    $self->{_nb}{$panel} = $self->{_nb}->add(
        $panel,
        -label     => $label,
        -underline => 0,
    );

    return;
}

=head2 get_notebook

Return the notebook handler

=cut

sub get_notebook {
    my ( $self, $page ) = @_;

    if ($page) {
        return $self->{_nb}{$page};
    }
    else {
        return $self->{_nb};
    }
}

=head2 _create_report_page

Create the report page (tab) on the notebook

=cut

sub _create_report_page {
    my $self = shift;

    # Frame box
    my $frm_box = $self->{_nb}{p1}->LabFrame(
        -foreground => 'blue',
        -label      => 'Query list',
        -labelside  => 'acrosstop'
    )->pack( -expand => 1, -fill => 'both' );

    $self->{_list} = $frm_box->Scrolled(
        'MListbox',
        -scrollbars         => 'osoe',
        -background         => 'white',
        -textwidth          => 5,
        -highlightthickness => 2,
        -selectmode         => 'single',
        -relief             => 'sunken',
        -height             => 5,
        -sortable           => 0,
    );

    # Header
    $self->{_list}->columnInsert( 'end', -text => '#' );
    $self->{_list}->columnGet(0)->Subwidget("heading")
        ->configure( -background => 'tan' );
    $self->{_list}->columnGet(0)->Subwidget("heading")
        ->configure( -width => 5 );

    $self->{_list}->columnInsert( 'end', -text => 'Raport' );
    $self->{_list}->columnGet(1)->Subwidget("heading")
        ->configure( -background => 'tan' );
    $self->{_list}->columnGet(1)->Subwidget("heading")
        ->configure( -width => 45 );

    $self->{_list}->pack( -expand => 1, -fill => 'both' );

    #--- Frame_Mid

    my $frame_mid = $self->{_nb}{p1}->LabFrame(
        -label      => 'Header',
        -labelside  => 'acrosstop',
        -foreground => 'blue',
    );
    $frame_mid->pack(
        -expand => 0,
        -fill   => 'both',
    );

    #-- Controls

    my $f1d = 90;
    my $cw  = 38;               # controls width

    #-- title

    my $ltitle = $frame_mid->Label( -text => 'Title' );
    $ltitle->form(
        -top     => [ %0, 0 ],
        -left    => [ %0, 0 ],
        -padleft => 5,
    );

    $self->{title} = $frame_mid->Entry(
        -width              => $cw,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $self->{title}->form(
        -top  => [ '&', $ltitle, 0 ],
        -left => [ %0, $f1d ],
    );

    #-- filename

    my $lfilename = $frame_mid->Label( -text => 'File name' );
    $lfilename->form(
        -top     => [ $ltitle, 8 ],
        -left    => [ %0,      0 ],
        -padleft => 5,
    );

    $self->{filename} = $frame_mid->Entry(
        -width              => $cw,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $self->{filename}->form(
        -top  => [ '&', $lfilename, 0 ],
        -left => [ %0, $f1d ],
    );

    #-- output

    my $loutput = $frame_mid->Label( -text => 'Output' );
    $loutput->form(
        -top     => [ $lfilename, 8 ],
        -left    => [ %0,         0 ],
        -padleft => 5,
    );

    $self->{output} = $frame_mid->Entry(
        -width              => $cw,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $self->{output}->form(
        -top  => [ '&', $loutput, 0 ],
        -left => [ %0, $f1d ],
    );

    #-- template

    my $ltemplate = $frame_mid->Label( -text => 'Template' );
    $ltemplate->form(
        -top     => [ $loutput, 8 ],
        -left    => [ %0,       0 ],
        -padleft => 5,
    );

    $self->{template} = $frame_mid->Entry(
        -width              => $cw,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $self->{template}->form(
        -top       => [ '&', $ltemplate, 0 ],
        -left      => [ %0,  $f1d ],
        -padbottom => 5,
    );

    #--- Frame_Bot

    my $frame_bot = $self->{_nb}{p1}->LabFrame(
        -label      => 'Description',
        -labelside  => 'acrosstop',
        -foreground => 'blue',
    );
    $frame_bot->pack(
        -expand => 0,
        -fill   => 'both',
    );

    #-- description

    $self->{description} = $frame_bot->Scrolled(
        'Text',
        -width      => 10,
        -height     => 3,
        -wrap       => 'word',
        -scrollbars => 'e',
        -background => 'white',
    );
    $self->{description}->pack(
        -expand => 1,
        -fill   => 'both',
        -padx   => 5,
        -pady   => 5,
    );

    return;
}

=head2 _create_para_page

Create the parameters page (tab) on the notebook

=cut

sub _create_para_page {
    my $self = shift;

    #--- Frame Top0

    my $frame_top0 = $self->{_nb}{p2}->LabFrame(
        -label      => 'Parameters',
        -labelside  => 'acrosstop',
        -foreground => 'blue',
    );
    $frame_top0->pack(
        -expand => 0,
        -fill   => 'x',
    );

    #--- Frame Top

    my $frame_top = $frame_top0->Frame();
    $frame_top->pack(
        -side   => 'top',
        -expand => 1,
        -fill   => 'x',
    );

    #-- Controls

    # my $f1d = 90;
    my $cwd = 25;               # description controls width
    my $cwv = 15;               # value controls width

    #-- Label

    my $para_tit_lbl1 = $frame_top->Label( -text => 'Label' );
    $para_tit_lbl1->grid(
        -row    => 0,
        -column => 0,
    );


    #-- Description

    my $para_tit_lbl2 = $frame_top->Label( -text => 'Description' );
    $para_tit_lbl2->grid(
        -row    => 0,
        -column => 1,
    );

    #-- Value

    my $para_tit_lbl3 = $frame_top->Label( -text => 'Value' );
    $para_tit_lbl3->grid(
        -row    => 0,
        -column => 2,
    );

    #-- $para_lbl1

    my $para_lbl1 = $frame_top->Label( -text => 'value1' );
    $para_lbl1->grid(
        -row    => 1,
        -column => 0,
        -padx   => 5,
        -pady   => 5,
    );

    #-- descr1

    $self->{descr1} = $frame_top->Entry(
        -width              => $cwd,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $self->{descr1}->grid(
        -row    => 1,
        -column => 1,
        -pady   => 5,
    );

    #-- value1

    $self->{value1} = $frame_top->Entry(
        -width              => $cwv,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $self->{value1}->grid(
        -row    => 1,
        -column => 2,
        -pady   => 5,
    );

    #-- 2

    #-- $para_lbl2

    my $para_lbl2 = $frame_top->Label( -text => 'value2' );
    $para_lbl2->grid(
        -row    => 2,
        -column => 0,
        -padx   => 5,
        -pady   => 5,
    );

    #-- descr2

    $self->{descr2} = $frame_top->Entry(
        -width              => $cwd,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $self->{descr2}->grid(
        -row    => 2,
        -column => 1,
        -pady   => 5,
    );

    #-- value2

    $self->{value2} = $frame_top->Entry(
        -width              => $cwv,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $self->{value2}->grid(
        -row    => 2,
        -column => 2,
        -pady   => 5,
    );

    #-- 3

    #-- $para_lbl3

    my $para_lbl3 = $frame_top->Label( -text => 'value3' );
    $para_lbl3->grid(
        -row    => 3,
        -column => 0,
        -padx   => 5,
        -pady   => 5,
    );

    #-- descr3

    $self->{descr3} = $frame_top->Entry(
        -width              => $cwd,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $self->{descr3}->grid(
        -row    => 3,
        -column => 1,
        -pady   => 5,
    );

    #-- value3

    $self->{value3} = $frame_top->Entry(
        -width              => $cwv,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $self->{value3}->grid(
        -row    => 3,
        -column => 2,
        -pady   => 5,
    );

    #-- 4

    #-- $para_lbl4

    my $para_lbl4 = $frame_top->Label( -text => 'value4' );
    $para_lbl4->grid(
        -row    => 4,
        -column => 0,
        -padx   => 5,
        -pady   => 5,
    );

    #-- descr4

    $self->{descr4} = $frame_top->Entry(
        -width              => $cwd,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $self->{descr4}->grid(
        -row    => 4,
        -column => 1,
        -pady   => 5,
    );

    #-- value4

    $self->{value4} = $frame_top->Entry(
        -width              => $cwv,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $self->{value4}->grid(
        -row    => 4,
        -column => 2,
        -pady   => 5,
    );

    #-- 5

    #-- $para_lbl5

    my $para_lbl5 = $frame_top->Label( -text => 'value5' );
    $para_lbl5->grid(
        -row    => 5,
        -column => 0,
        -padx   => 5,
        -pady   => 5,
    );

    #-- descr5

    $self->{descr5} = $frame_top->Entry(
        -width              => $cwd,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $self->{descr5}->grid(
        -row    => 5,
        -column => 1,
        -pady   => 5,
    );

    #-- value5

    $self->{value5} = $frame_top->Entry(
        -width              => $cwv,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $self->{value5}->grid(
        -row    => 5,
        -column => 2,
        -pady   => 5,
    );

    return;
}

=head2 _create_sql_page

Create the SQL page (tab) on the notebook

=cut

sub _create_sql_page {
    my $self = shift;

    #--- SQL Tab (page)

    #--- Frame_Top

    my $frame_top = $self->{_nb}{p3}->LabFrame(
        -label      => 'SQL',
        -labelside  => 'acrosstop',
        -foreground => 'blue',
    );
    $frame_top->pack(
        -side   => 'left',
        -expand => 1,
        -fill   => 'both',
    );

    #-- SQL text

    $self->{sql} = $frame_top->Scrolled(
        'Text',
        -width      => 40,
        -height     => 3,
        -wrap       => 'word',
        -scrollbars => 'soe',
        -background => 'white',
    );
    $self->{sql}->pack(
        -expand => 1,
        -fill   => 'both',
        -padx   => 5,
        -pady   => 5,
    );

    # Add tags to simulate highlight
    $self->{sql}->tag(qw/configure label -foreground/ => 'yellow');
    $self->{sql}->tag(qw/configure value -foreground/ => 'green');

    return;
}

=head2 _create_config_page

Create the Log info page (tab) on the notebook.

=cut

sub _create_config_page {
    my $self = shift;

    #--- Info Tab (page)

    #--- Frame_Top

    my $frame_top = $self->{_nb}{p4}->LabFrame(
        -label      => 'Log',
        -labelside  => 'acrosstop',
        -foreground => 'blue',
    );
    $frame_top->pack(
        -side   => 'left',
        -expand => 1,
        -fill   => 'both',
    );

    #-- Log text

    $self->{log} = $frame_top->Scrolled(
        'Text',
        -width      => 40,
        -height     => 3,
        -wrap       => 'word',
        -scrollbars => 'soe',
        -background => 'white',
        -state      => 'disabled',
    );
    $self->{log}->pack(
        -expand => 1,
        -fill   => 'both',
        -padx   => 5,
        -pady   => 5,
    );

    return;
}

=head2 dialog_error

Error message dialog.

=cut

sub dialog_error {
    my ( $self, $message, $details ) = @_;

    my $dialog_e = $self->MsgBox(
        -title   => 'Info',
        -type    => 'ok',
        -icon    => 'error',
        -message => $message,
        -detail  => $details,
    );

    return $dialog_e->Show();
}

=head2 action_confirmed

Yes - No message dialog.

=cut

sub action_confirmed {
    my ( $self, $msg ) = @_;

    # Not localisable button labels

    my $dlg = $self->MsgBox(
        -title   => 'Question',
        -type    => 'yesnocancel',
        -icon    => 'question',
        -message => 'Confirmation is required.',
        -detail  => $msg,
    );

    return $dlg->Show();
}

=head2 get_toolbar_btn

Return a toolbar button when we know the its name

=cut

sub get_toolbar_btn {
    my ( $self, $name ) = @_;

    return $self->{_tb}->get_toolbar_btn($name);
}

=head2 get_choice_default

Return the choice default option, the first element in the array.

=cut

sub get_choice_default {
    my $self = shift;

    return $self->{_tb}->get_choice_options(0);
}

# =head2 get_choice

# Return the selected choice.

# =cut

# sub get_choice {
#     my ($self, $name) = @_;

#     my $option_var =$self->get_toolbar_btn($name)->cget(-variable);

#     return ${$option_var};
# }

=head2 get_listcontrol

Return the record list handler

=cut

sub get_listcontrol {
    my $self = shift;

    return $self->{_list};
}

=head2 get_controls_list

Return a AoH with information regarding the controls from the list page.

=cut

sub get_controls_list {
    my $self = shift;

    return [
        { title    => [ $self->{title},    'normal',   'white',     'e' ] },
        { filename => [ $self->{filename}, 'disabled', $self->{bg}, 'e' ] },
        { output   => [ $self->{output},   'normal',   'white',     'e' ] },
        { template => [ $self->{template}, 'normal',   'white',     'e' ] },
        { description => [ $self->{description}, 'normal', 'white', 't' ] },
    ];
}

=head2 get_controls_para

Return a AoH with information regarding the controls from the parameters page.

=cut

sub get_controls_para {
    my $self = shift;

    return [
        { descr1 => [ $self->{descr1}, 'normal', 'white', 'e' ] },
        { value1 => [ $self->{value1}, 'normal', 'white', 'e' ] },
        { descr2 => [ $self->{descr2}, 'normal', 'white', 'e' ] },
        { value2 => [ $self->{value2}, 'normal', 'white', 'e' ] },
        { descr3 => [ $self->{descr3}, 'normal', 'white', 'e' ] },
        { value3 => [ $self->{value3}, 'normal', 'white', 'e' ] },
        { descr4 => [ $self->{descr4}, 'normal', 'white', 'e' ] },
        { value4 => [ $self->{value4}, 'normal', 'white', 'e' ] },
        { descr5 => [ $self->{descr5}, 'normal', 'white', 'e' ] },
        { value5 => [ $self->{value5}, 'normal', 'white', 'e' ] },
    ];
}

=head2 get_controls_sql

Return a AoH with information regarding the controls from the SQL page.

=cut

sub get_controls_sql {
    my $self = shift;

    return [
        { sql => [ $self->{sql}, 'normal'  , 'white', 't' ] },
    ];
}

=head2 get_controls_conf

Return a AoH with information regarding the controls from the
configurations page.

None at this time.

=cut

sub get_controls_conf {
    my $self = shift;

    return [];
}

=head2 get_control_by_name

Return the control instance by name.

=cut

sub get_control_by_name {
    my ($self, $name) = @_;

    return $self->{$name};
}

=head2 set_list_text

Set text for item from list control row and col.

=cut

sub set_list_text {
    my ($self, $row, $col, $text) = @_;

    $self->{_list}->selectionClear(0, 'end');
    $self->{_list}->insert($row, [ $row+1, $text ]);

    return;
}

=head2 list_item_select

Select the first/last item in list.

=cut

sub list_item_select {
    my ($self, $what) = @_;

    my $item
        = $what eq 'first' ?  0
        : $what eq 'last'  ? 'end'
        :                     undef # default
        ;

    return unless defined $item;

    # Activate and select first
    $self->get_listcontrol->selectionClear( 0, 'end' );
    $self->get_listcontrol->activate($item);
    $self->get_listcontrol->selectionSet($item);
    $self->get_listcontrol->see('active');

    return;
}

=head2 get_list_max_index

Return the maximum index from the list control.

=cut

sub get_list_max_index {
    my $self = shift;

    my $row_count;

    if ( Exists( $self->get_listcontrol ) ) {
        eval { $row_count = $self->get_listcontrol->size(); };
        if ($@) {
            warn "Error: $@";
            $row_count = 0;
        }
    }
    else {
        warn "Error, List doesn't exists?\n";
        $row_count = 0;
    }

    return ($row_count - 1);
}

=head2 get_list_selected_index

Return the selected index from the list control.

=cut

sub get_list_selected_index {
    my $self = shift;

    my @selected;
    eval { @selected = $self->get_listcontrol->curselection() };
    if ($@) {
        warn "Error: $@";
        return;
    }
    else {
        return pop @selected;    # first row in case of multiselect
    }
}

=head2 list_item_insert

Insert item in list control

=cut

sub list_item_insert {
    my ( $self, $nrcrt, $title ) = @_;

    $self->get_listcontrol()->insert( 'end', [$nrcrt, $title] );

    return;
}

=head2 list_item_edit

Edit and existing item. If undef is passed for nrcrt or title, keep
the existing value.

=cut

sub list_item_edit {
    my ( $self, $indice, $nrcrt, $title ) = @_;

    my $list = $self->get_listcontrol();

    my @row = $list->getRow($indice);

    $nrcrt = $row[0] if not defined $nrcrt;
    $title = $row[1] if not defined $title;

    $list->delete($indice);
    $list->insert( $indice, [$nrcrt, $title] );
    $list->selectionClear(0, 'end');
    $list->selectionSet($indice);

    return;
}

# =head2 list_remove_selected

# Remove the selected row from the list.

# =cut

# sub list_item_clear {
#     my ($self, $item) = @_;

#     ouch 'NoItem', 'EE: Nothing selected!' unless defined $item;

#     eval {
#         $self->get_listcontrol->delete($item);
#     };
#     if ($@) {
#         ouch 'NoItem', 'EE: List item remove failes!';
#     }

#     return;
# }

=head2 list_item_clear_all

Delete all list control items.

=cut

sub list_item_clear_all {
    my $self = shift;

    #$self->get_listcontrol->removeAllItems();

    $self->get_listcontrol->selectionClear( 0, 'end' );
    $self->get_listcontrol->delete( 0, 'end' );

    return;
}

=head2 list_remove_item

Remove item from list control and select the first item

=cut

sub list_remove_item {
    my $self = shift;

    my $item = $self->get_list_selected_index();
    my $data = $self->_model->get_qdf_data_tk($item);

    # Remove from list
    $self->list_item_clear($item);

    # Set item 0 selected
    $self->list_item_select('first');

    return $data;
}

=head2 log_config_options

Log configuration options with data from the Config module

=cut

sub log_config_options {
    my $self = shift;

    my $path = $self->_cfg->output;

    while ( my ( $key, $value ) = each( %{$path} ) ) {
        $self->log_msg("II Config: '$key' set to '$value'");
    }
}

=head2 list_populate_all

Populate list.

=cut

sub list_populate_all {
    my $self = shift;

    $self->_model->load_qdf_data_tk();
    my $indices = $self->_model->get_qdf_data_tk();

    return unless scalar keys %{$indices};

    # Populate list in sorted order
    my @indices = sort { $a <=> $b } keys %{$indices};

    # Clear list
    $self->list_item_clear_all();

    foreach my $idx ( @indices ) {
        my $nrcrt = $indices->{$idx}{nrcrt};
        my $title = $indices->{$idx}{title};
        my $file  = $indices->{$idx}{file};

        $self->list_item_insert($nrcrt, $title);
    }

    return 1;
}

=head2 list_populate_item

Add new item in list control.

=cut

sub list_populate_item {
    my ( $self, $rec ) = @_;

    my ($idx) = keys %{$rec};
    my $r     = $rec->{$idx};

    $self->list_item_insert( $r->{nrcrt}, $r->{title} );

    return;
}

=head2 controls_populate

Populate controls with data from QDF (XML).

=cut

sub controls_populate {
    my $self = shift;

    my $item = $self->get_list_selected_index();
    my ($data, $file) = $self->_model->read_qdf_data_file($item);

    my $qdfpath = $self->_cfg->qdfpath;

    # Just filename, remove path config path
    my $file_rel = File::Spec->abs2rel( $file, $qdfpath ) ;

    #-- Header
    $data->{header}{filename} = $file_rel;
    $self->controls_write_page('list', $data->{header} );

    #-- Parameters
    my $para = QDepo::Utils->params_to_hash( $data->{parameters} );
    $self->controls_write_page('para', $para );

    #-- SQL
    $self->controls_write_page('sql', $data->{body} );

    return;
}

=head2 toggle_sql_replace

Toggle sql replace.

=cut

sub toggle_sql_replace {
    my ($self, $mode) = @_;

    $mode ||= $self->_model->get_appmode;

    my $item = $self->get_list_selected_index();
    my ($data) = $self->_model->read_qdf_data_file($item);

    if ($mode eq 'edit') {
        $self->control_set_value( 'sql', $data->{body}{sql} );

        my $searchstr = 'value\d+';
        $self->highlight_text($self->{sql}, \$searchstr, 'label', 'regexp');
    }
    elsif ($mode eq 'sele') {
        my $para = QDepo::Utils->params_to_hash( $data->{parameters} );
        $self->control_replace_sql_text( $data->{body}{sql}, $para );
    }

    return;
}

=head2 control_replace_sql_text

Replace sql text control

=cut

sub control_replace_sql_text {
    my ($self, $sqltext, $params) = @_;

    my ($newtext) = $self->_model->string_replace_pos($sqltext, $params);

    # Write new text to control
    $self->control_set_value('sql', $newtext);

    # Highlight (tag) the replaces value
    while (my ($key, $search) = each ( %{$params} ) ) {
        next unless $key =~ m{value[0-9]}; # Skip 'descr'
        $self->highlight_text($self->{sql}, \$search, 'value', 'regexp');
    }

    return;
}

=head2 log_msg

Set log message

=cut

sub log_msg {
    my ( $self, $message ) = @_;

    my $control = $self->get_control_by_name('log');

    $self->control_write_t( $control, $message, 'append' );

    return;
}

=head2 set_status

Display message in the status bar.  Colour name can also be passed to
the method in the message string separated by a # char.

=cut

sub set_status {
    my ( $self, $text, $sb_id, $color ) = @_;

    my $sb = $self->get_statusbar($sb_id);

    if ( $sb_id eq 'cn' ) {
        $sb->configure( -image => $text ) if defined $text;
    }
    else {
        $sb->configure( -textvariable => \$text ) if defined $text;
        $sb->configure( -foreground   => $color ) if defined $color;
    }

    return;
}

=head2 toggle_status_cn

Toggle the icon in the status bar

=cut

sub toggle_status_cn {
    my ( $self, $status ) = @_;

    if ($status) {
        $self->set_status( 'connectyes16', 'cn' );
        $self->set_status( $self->_cfg->conninfo->{dbname},
            'db', 'darkgreen' );
    }
    else {
        $self->set_status( 'connectno16', 'cn' );
        $self->set_status( '',            'db' );
    }

    return;
}

=head2 define_dialogs

Define some dialogs

=cut

sub define_dialogs {
    my $self = shift;

    $self->{dialog1} = $self->Dialog(
        -text           => 'Nothing to search for!',
        -bitmap         => 'info',
        -title          => 'Info',
        -default_button => 'Ok',
        -buttons        => [qw/Ok/]
    );

    $self->{dialog2} = $self->Dialog(
        -text           => 'Add record?',
        -bitmap         => 'question',
        -title          => 'Insert record',
        -default_button => 'Ok',
        -buttons        => [qw/Ok Cancel/]
    );

    # $self->{asksave} = $self->DialogBox(
    #     -title   => 'Save?',
    #     -buttons => [qw{Yes No Cancel}],
    # );
    # $self->{asksave}->geometry('400x300');
    # $self->{asksave}->bind(
    #     '<Escape>',
    #     sub { $self->{asksave}->Subwidget('B_Cancel')->invoke }
    # );

    # # Nice trick to position buttons to the right
    # # Source: PM by lamprecht on Apr 22, 2011 at 22:09 UTC
    # my $bframe = $self->{asksave}->Subwidget('bottom');
    # for ($bframe->children) {
    #     $_->packForget;
    #     $_->pack(-side => 'right',
    #              -padx => 3,
    #              -pady => 3,
    #          );
    # }

    return;
}

=head2 control_set_value

Set new value for a controll.

=cut

sub control_set_value {
    my ($self, $name, $value) = @_;

    $value ||= q{};                 # empty

    my $control = $self->get_control_by_name($name);

    $self->control_write_t($control, $value);

    return;
}

=head2 controls_write_page

Write all controls on page with data

=cut

sub controls_write_page {
    my ($self, $page, $data) = @_;

    # Get controls name and object from $page
    my $get = 'get_controls_'.$page;
    my $controls = $self->$get();

    foreach my $control ( @{$controls} ) {
        foreach my $name ( keys %{$control} ) {

            my $value = $data->{$name};

            # Cleanup value
            if ( defined $value ) {
                $value =~ s/\n$//mg;    # Multiline
            }
            else {
                $value = q{};           # Empty
            }

            $self->control_write( $control, $name, $value, );
        }
    }

    return;
}

=head2 control_write

Run the appropriate sub according to control (entry widget) type.

=cut

sub control_write {
    my ($self, $control, $name, $value, $state) = @_;

    my $ctrltype = $control->{$name}[3];

    my $sub_name = qq{control_write_$ctrltype};
    if ( $self->can($sub_name) ) {
        $self->$sub_name($control->{$name}[0], $value, $state);
    }
    else {
        print "WW: No '$ctrltype' ctrl type for writing '$name'!\n";
    }

    return;
}

=head2 control_write_e

Write to a Tk::Entry widget.  If I<$value> not true, than only delete.

=cut

sub control_write_e {
    my ( $self, $control, $value ) = @_;

    my $state = $control->cget ('-state');

    $control->configure( -state => 'normal' );

    $control->delete( 0, 'end' );
    $control->insert( 0, $value ) if $value;

    $control->configure( -state => $state );

    return;
}

=head2 control_write_t

Write to a Tk::Text widget.  If I<$value> not true, than only delete.

=cut

sub control_write_t {
    my ( $self, $control, $value, $is_append ) = @_;

    my $state = $control->cget ('-state');

    $value = q{} unless defined $value;    # empty

    $control->configure( -state => 'normal' );

    $control->delete( '1.0', 'end' ) unless $is_append;
    if ($value) {
        $control->insert( 'end', $value );
        $control->insert( 'end', "\n" ) if $is_append;
    }

    $control->configure( -state => $state );

    return;
}

=head2 list_read_selected

Read and return selected row (column 0) from list

=cut

sub list_read_selected {
    my $self = shift;

    if ( !$self->has_list_records ) {

        # No records
        return;
    }

    my @selected;
    my $indecs;

    eval { @selected = $self->get_listcontrol->curselection(); };
    if ($@) {
        warn "Error: $@";

        # $self->refresh_sb( 'll', 'No record selected' );
        return;
    }
    else {
        $indecs = pop @selected;    # first row in case of multiselect
        if ( !defined $indecs ) {

            # Activate the last row
            $indecs = 'end';
            $self->get_listcontrol->selectionClear( 0, 'end' );
            $self->get_listcontrol->activate($indecs);
            $self->get_listcontrol->selectionSet($indecs);
            $self->get_listcontrol->see('active');
        }
    }

    # In scalar context, getRow returns the value of column 0
    my @idxs = @{ $self->{lookup} };    # indices for Pk and Fk cols
    my @returned;
    eval { @returned = ( $self->get_listcontrol->getRow($indecs) )[@idxs]; };
    if ($@) {
        warn "Error: $@";

        # $self->refresh_sb( 'll', 'No record selected!' );
        return;
    }
    else {
        @returned = QDepo::Utils->trim(@returned) if @returned;
    }

    return \@returned;
}

=head2 controls_read_page

Read all controls from page and return an array reference.

=cut

sub controls_read_page {
    my ( $self, $page ) = @_;

    # Get controls name and object from $page
    my $get      = 'get_controls_' . $page;
    my $controls = $self->$get();
    my @records;

    foreach my $control ( @{$controls} ) {
        foreach my $name ( keys %{$control} ) {
            my $value = $self->control_read($control, $name);
            push(@records, { $name => $value } ) if ($name and $value);
        }
    }

    return \@records;
}

=head2 control_read

Run the appropriate sub according to control (entry widget) type.

=cut

sub control_read {
    my ($self, $control, $name) = @_;

    my $ctrltype = $control->{$name}[3];

    my $sub_name = qq{control_read_$ctrltype};
    my $value;
    if ( $self->can($sub_name) ) {
        $value = $self->$sub_name($control->{$name}[0]);
    }
    else {
        print "WW: No '$ctrltype' ctrl type for reading '$name'!\n";
    }

    return $value;
}

=head2 control_read_e

Read contents of a Tk::Entry control.

=cut

sub control_read_e {
    my ( $self, $control ) = @_;

    my $value = $control->get;

    if ( $value =~ /\S+/ ) {
        $value = QDepo::Utils->trim($value); # trim spaces
    }

    return $value;
}

=head2 control_read_t

Read contents of a Tk::Text control.

=cut

sub control_read_t {
    my ( $self, $control ) = @_;

    my $value = $control->get( '0.0', 'end' );

    if ( $value =~ /\S+/ ) {
        $value = QDepo::Utils->trim($value); # trim spaces
    }

    return $value;
}

=head2 on_close_window

Destroy window on quit.

=cut

sub on_close_window {
    my $self = shift;

    $self->destroy();

    return;
}

=head2 event_handler_for_menu

Event handlers.

Configure callback for menu

=cut

sub event_handler_for_menu {
    my ( $self, $name, $calllback ) = @_;

    $self->get_menu_popup_item($name)->configure( -command => $calllback );

    return;
}

=head2 event_handler_for_tb_button

Event handlers.

Configure callback for toolbar button.

=cut

sub event_handler_for_tb_button {
    my ( $self, $name, $calllback ) = @_;

    $self->get_toolbar_btn($name)->configure( -command => $calllback );

    return;
}

=head2 event_handler_for_tb_choice

Event handlers.

Configure callback for toolbar choice button.

=cut

sub event_handler_for_tb_choice {
    my ( $self, $name, $calllback ) = @_;

    $self->get_toolbar_btn($name)->configure( -command => $calllback );

    return;
}

=head2 toggle_list_enable

Does not work.

=cut

sub toggle_list_enable {
    my ($self, $state) = @_;

    my $ml = $self->get_listcontrol();

    # Toggle List control
    if ($state) {
        #$ml->configure(-state => 'disabled');
    }
    else {
        #$ml->configure(-state => 'normal');
    }

    return;
}

sub set_editable {
    my ( $self, $name, $state, $color ) = @_;

    my $control = $self->get_control_by_name($name);

    $control->configure( -state => $state );
    $control->configure( -background => $color ) if $color;

    return
}

sub event_handler_for_list {
    my ($self, $calllback) = @_;

    $self->get_listcontrol->bindRows(
        '<Button-1>', $calllback,
    );

    return;
}

=head2 dialog_progress

Progress dialog.

=cut

sub dialog_progress {
    # empty
}

=head2 highlight_text

The utility procedure below searches for all instances of a given
string in a text widget and applies a given tag to each instance found.

Arguments:

  w           The window in which to search.  Must be a text widget.

  string      Reference to the string to search for.  The search is done
              using exact matching only;  no special characters.
  tag         Tag to apply to each instance of a matching string.

=cut

sub highlight_text {
    my ( $self, $w, $string, $tag, $kind ) = @_;

    return unless ref($string) && length(${$string});

    # $w->tagRemove($tag, qw/0.0 end/);
    my ( $current, $length ) = ( '1.0', 0 );

    while (1) {
        $current = $w->search(
            -count => \$length,
            "-$kind", ${$string}, $current, 'end'
        );
        last if not $current;

        #warn "Pos=$current, Count=$length\n";
        $w->tagAdd( $tag, $current, "$current + $length char" );
        $current = $w->index("$current + $length char");
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

1;    # End of QDepo::Tk::View
