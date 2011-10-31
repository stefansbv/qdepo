package TpdaQrt::Tk::View;

use strict;
use warnings;

use File::Spec::Functions qw(abs2rel);
use Tk;
use Tk::widgets qw(NoteBook StatusBar Dialog DialogBox MListbox Checkbutton
    LabFrame );

use base 'Tk::MainWindow';

use TpdaQrt::Config;
use TpdaQrt::Tk::TB;    # ToolBar

=head1 NAME

TpdaQrt::Tk::App - Tk Perl application class

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use TpdaQrt::Tk::Notebook;

    $self->{_nb} = TpdaQrt::Tk::Notebook->new( $gui );

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

    $self->{_cfg} = TpdaQrt::Config->instance();

    $self->title(" TpdaQrt ");

    #-- Menu
    $self->_create_menu();

    #-- ToolBar
    $self->_create_toolbar();

    #-- Statusbar
    $self->_create_statusbar();

    #-- Notebook
    $self->_create_notebook();

    #--- Parameters Tab (page) Panel
    $self->create_para_page();

    #--- SQL Tab (page)
    $self->create_sql_page();

    #--- Configs Tab (page)
    $self->create_config_page();

    #--- Front Tab (page)
    $self->create_report_page();

    return $self;
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
    $co->add_callback(
        sub {
            $self->toggle_status_cn( $_[0] );
        }
    );

    # When the status changes, update gui components
    my $apm = $self->_model->get_appmode_observable;
    $apm->add_callback( sub { $self->update_gui_components(); } );

    #--
    my $upd = $self->_model->get_itemchanged_observable;
    $upd->add_callback(
        sub { $self->controls_populate(); } );

    my $so = $self->_model->get_stdout_observable;
    $so->add_callback( sub { $self->set_status( $_[0], 'ms' ) } );

    my $xo = $self->_model->get_exception_observable;
    $xo->add_callback( sub{ $self->log_msg( @_ ) } );

    my $pr = $self->_model->get_progress_observable;
    $pr->add_callback( sub{ $self->progress_update( @_ ) } );

    return;
}
=head2 update_gui_components

When the application status (mode) changes, update gui components.
Screen controls (widgets) are not handled here, but in controller
module.

=cut

sub update_gui_components {
    my $self = shift;

    my $mode = $self->_model->get_appmode();

    $self->set_status( $mode, 'md' );    # update statusbar

    if ($mode eq 'edit') {
        $self->{_tb}->toggle_tool_check( 'tb_ed', 1 );
        $self->toggle_sql_replace();
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

    #- Menu bar

    $self->{_menu} = $self->Menu();

    # Get MenuBar atributes

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
    my $menus = TpdaQrt::Utils->sort_hash_by_id($attribs);

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
    my $menus   = TpdaQrt::Utils->sort_hash_by_id($attribs);

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

    # TODO: Change the config file so we don't need this sorting anymore
    # or better keep them sorted and ready to use in config
    my $toolbars = TpdaQrt::Utils->sort_hash_by_id($attribs);

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
    $self->{progres} = 0;
    $self->{_sb}{pr} = $sb->addProgressBar(
        -length     => 100,
        -from       => 0,
        -to         => 100,
        -variable   => \$self->{progres},
        -foreground => 'blue',
    );

    # Second label for modified status
    $self->{_sb}{ss} = $sb->addLabel(
        -width      => 3,
        -relief     => 'sunken',
        -anchor     => 'center',
        -side       => 'right',
        -background => 'lightyellow',
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

=head2 create_report_page

Create the report page (tab) on the notebook

=cut

sub create_report_page {
    my $self = shift;

    # Frame box
    my $frm_box = $self->{_nb}{p1}->LabFrame(
        -foreground => 'blue',
        -label      => 'Search results',
        -labelside  => 'acrosstop'
    )->pack( -expand => 1, -fill => 'both' );

    $self->{_list} = $frm_box->Scrolled(
        'MListbox',
        -scrollbars         => 'osoe',
        -background         => 'white',
        -textwidth          => 10,
        -highlightthickness => 2,
        -width              => 0,
        -selectmode         => 'browse',
        -relief             => 'sunken',
        -columns            => [
            [ -text => '#', -textwidth => 10, ],
            [ -text => 'Query name', -textwidth => 40, ],
        ],
    );

    $self->{_list}->pack( -expand => 1, -fill => 'both' );

    #--- Frame_Mid

    my $frame_mid = $self->{_nb}{p1}->LabFrame(
        -label      => 'Frame_Mid',
        -labelside  => 'acrosstop',
        -foreground => 'blue',
    );
    $frame_mid->pack(
        -expand => 1,
        -fill   => 'x',
    );

    #-- Controls

    my $bg  = $self->cget('-background');
    my $f1d = 90;

    #-- title

    my $ltitle = $frame_mid->Label( -text => 'Title' );
    $ltitle->form(
        -top     => [ %0, 0 ],
        -left    => [ %0, 5 ],
    );
    my $etitle = $frame_mid->Entry(
        -width              => 40,
        -disabledbackground => $bg,
        -disabledforeground => 'black',
    );
    $etitle->form(
        -top  => [ '&', $ltitle, 0 ],
        -left => [ %0, $f1d ],
    );

    #-- filename

    my $lfilename = $frame_mid->Label( -text => 'File name' );
    $lfilename->form(
        -top  => [ $ltitle, 8 ],
        -left => [ %0, 5 ],
    );
    my $efilename = $frame_mid->Entry(
        -width              => 40,
        -disabledbackground => $bg,
        -disabledforeground => 'black',
    );
    $efilename->form(
        -top  => [ '&', $lfilename, 0 ],
        -left => [ %0, $f1d ],
    );

    #-- output

    my $loutput = $frame_mid->Label( -text => 'Output' );
    $loutput->form(
        -top  => [ $lfilename, 8 ],
        -left => [ %0, 5 ],
    );
    my $eoutput = $frame_mid->Entry(
        -width              => 40,
        -disabledbackground => $bg,
        -disabledforeground => 'black',
    );
    $eoutput->form(
        -top  => [ '&', $loutput, 0 ],
        -left => [ %0, $f1d ],
    );

    #-- template

    my $ltemplate = $frame_mid->Label( -text => 'Template' );
    $ltemplate->form(
        -top  => [ $loutput, 8 ],
        -left => [ %0,       5 ],
    );
    my $etemplate = $frame_mid->Entry(
        -width              => 40,
        -disabledbackground => $bg,
        -disabledforeground => 'black',
    );
    $etemplate->form(
        -top       => [ '&', $ltemplate, 0 ],
        -left      => [ %0,  $f1d ],
        -padbottom => 5,
    );

    #--- Frame_Bot

    my $frame_bot = $self->{_nb}{p1}->LabFrame(
        -label      => 'Frame_Bot',
        -labelside  => 'acrosstop',
        -foreground => 'blue',
    );
    $frame_bot->pack(
        -side   => 'left',
        -expand => 1,
        -fill   => 'x',
    );

    #-- description

    my $tdescription = $frame_bot->Scrolled(
        'Text',
        -width      => 40,
        -height     => 3,
        -wrap       => 'word',
        -scrollbars => 'e',
        -background => 'white',
    );
    $tdescription->pack(
        -expand => 1,
        -fill   => 'both',
        -padx   => 5,
        -pady   => 5,
    );

    return;
}

=head2 create_para_page

Create the parameters page (tab) on the notebook

=cut

sub create_para_page {
    my $self = shift;

    #--- Frame Top0

    my $frame_top0 = $self->{_nb}{p2}->LabFrame(
        -label      => 'Frame_top',
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

    my $bg  = $self->cget('-background');
    my $f1d = 90;

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
    );

    #-- descr1

    my $edescr1 = $frame_top->Entry(
        -width              => 30,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $edescr1->grid(
        -row    => 1,
        -column => 1,
    );

    #-- value1

    my $evalue1 = $frame_top->Entry(
        -width              => 20,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $evalue1->grid(
        -row    => 1,
        -column => 2,
    );

    #-- 2

    #-- $para_lbl2

    my $para_lbl2 = $frame_top->Label( -text => 'value2' );
    $para_lbl2->grid(
        -row    => 2,
        -column => 0,
    );

    #-- descr2

    my $edescr2 = $frame_top->Entry(
        -width              => 30,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $edescr2->grid(
        -row    => 2,
        -column => 1,
    );

    #-- value2

    my $evalue2 = $frame_top->Entry(
        -width              => 20,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $evalue2->grid(
        -row    => 2,
        -column => 2,
    );

    #-- 3

    #-- $para_lbl3

    my $para_lbl3 = $frame_top->Label( -text => 'value3' );
    $para_lbl3->grid(
        -row    => 3,
        -column => 0,
    );

    #-- descr3

    my $edescr3 = $frame_top->Entry(
        -width              => 30,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $edescr3->grid(
        -row    => 3,
        -column => 1,
    );

    #-- value3

    my $evalue3 = $frame_top->Entry(
        -width              => 20,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $evalue3->grid(
        -row    => 3,
        -column => 2,
    );

    #-- 4

    #-- $para_lbl4

    my $para_lbl4 = $frame_top->Label( -text => 'value4' );
    $para_lbl4->grid(
        -row    => 4,
        -column => 0,
    );

    #-- descr4

    my $edescr4 = $frame_top->Entry(
        -width              => 30,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $edescr4->grid(
        -row    => 4,
        -column => 1,
    );

    #-- value4

    my $evalue4 = $frame_top->Entry(
        -width              => 20,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $evalue4->grid(
        -row    => 4,
        -column => 2,
    );

    #-- 5

    #-- $para_lbl5

    my $para_lbl5 = $frame_top->Label( -text => 'value5' );
    $para_lbl5->grid(
        -row    => 5,
        -column => 0,
    );

    #-- descr5

    my $edescr5 = $frame_top->Entry(
        -width              => 30,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $edescr5->grid(
        -row    => 5,
        -column => 1,
    );

    #-- value5

    my $evalue5 = $frame_top->Entry(
        -width              => 20,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $evalue5->grid(
        -row    => 5,
        -column => 2,
    );

    return;
}

=head2 create_sql_page

Create the SQL page (tab) on the notebook

=cut

sub create_sql_page {
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

    #-- sqltext

    my $esqltext = $frame_top->Scrolled(
        'Text',
        -width      => 40,
        -height     => 3,
        -wrap       => 'word',
        -scrollbars => 'soe',
        -background => 'white',
    );
    $esqltext->pack(
        -expand => 1,
        -fill   => 'both',
        -padx   => 5,
        -pady   => 5,
    );

    return;
}

=head2 create_config_page

Create the Log info page (tab) on the notebook.

=cut

sub create_config_page {
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

    #-- logtext

    my $elogtext = $frame_top->Scrolled(
        'Text',
        -width      => 40,
        -height     => 3,
        -wrap       => 'word',
        -scrollbars => 'soe',
        -background => 'white',
    );
    $elogtext->pack(
        -expand => 1,
        -fill   => 'both',
        -padx   => 5,
        -pady   => 5,
    );

    return;
}

=head2 dialog_popup

Define a dialog popup.

=cut

sub dialog_popup {
}

=head2 action_confirmed

Yes - No message dialog.

=cut

sub action_confirmed {
    my ( $self, $msg ) = @_;
}

=head2 get_toolbar_btn

Return a toolbar button when we know the its name

=cut

sub get_toolbar_btn {
    my ( $self, $name ) = @_;

    return $self->{_tb}->get_toolbar_btn($name);
}

=head2 status_message

Message types:

=over

=item error  message with I<darkred> color

=item warn   message with I<yellow> color

=item info   message with I<darkgreen> color

=back

=cut

sub status_message {
    my ($self, $text) = @_;

    (my $type, $text) = split /#/, $text, 2;

    my $color;
  SWITCH: {
        $type eq 'error' && do { $color = 'darkred';   last SWITCH; };
        $type eq 'info'  && do { $color = 'darkgreen'; last SWITCH; };
        $type eq 'warn'  && do { $color = 'orange';    last SWITCH; };

        # Default
        $color = 'red';
    }

    $self->set_status( $text, 'ms', $color );

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
    elsif ( $sb_id eq 'ss' ) {

        #         _scrdata_rec       status text
        my $str
            = !defined $text ? ''
            : $text          ? 'M'
            :                  'S';
        $sb->configure( -textvariable => \$str ) if defined $str;
    }
    else {
        $sb->configure( -textvariable => \$text ) if defined $text;
        $sb->configure( -foreground   => $color ) if defined $color;
    }

    return;
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

    $self->create_notebook_panel( 'p1', 'Query List' );
    $self->create_notebook_panel( 'p2', 'Parameters' );
    $self->create_notebook_panel( 'p3', 'SQL Query' );
    $self->create_notebook_panel( 'p4', 'Log Info' );

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

=head2 create_notebook_panel

Create a NoteBook panel

=cut

sub create_notebook_panel {
    my ( $self, $panel, $label ) = @_;

    $self->{_nb}{$panel} = $self->{_nb}->add(
        $panel,
        -label     => $label,
        -underline => 0,
    );

    return;
}

=head2 get_nb_current_page

Return the current page of the Tk::NoteBook widget.

=cut

sub get_nb_current_page {
    my $self = shift;

    my $nb = $self->get_notebook;

    return unless ref $nb;

    return $nb->raised();
}

sub set_nb_current {
    my ( $self, $page ) = @_;

    $self->{nb_prev} = $self->{nb_curr};    # previous tab name
    $self->{nb_curr} = $page;               # current tab name

    return;
}

=head2 get_nb_previous_page

NOTE: $nb->info('focusprev') doesn't work.

=cut

sub get_nb_previous_page {
    my $self = shift;

    return $self->{nb_prev};
}

=head2 nb_set_page_state

Enable/disable notebook pages.

=cut

sub nb_set_page_state {
    my ($self, $page, $state) = @_;

    $self->get_notebook()->pageconfigure( $page, -state => $state );

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

=head2 toggle_status_cn

Toggle the icon in the status bar

=cut

sub toggle_status_cn {
    my ( $self, $status ) = @_;

    if ($status) {
        $self->set_status( 'connectyes16', 'cn' );
        $self->set_status( $self->_cfg->connection->{dbname},
            'db', 'darkgreen' );
    }
    else {
        $self->set_status( 'connectno16', 'cn' );
        $self->set_status( '',            'db' );
    }

    return;
}

=head2 on_quit

Destroy window on quit

=cut

sub on_quit {
    my $self = shift;

    $self->destroy();

    return;
}

=head2 get_listcontrol

Return the record list handler

=cut

sub get_listcontrol {
    my $self = shift;

    return $self->{_list};
}

=head2 make_list_header

Prepare the header for list in the List tab.

=cut

sub make_list_header {
    my ( $self, $header_look, $header_cols, $fields ) = @_;

    #- Delete existing columns
    $self->get_listcontrol->selectionClear( 0, 'end' );
    $self->get_listcontrol->columnDelete( 0, 'end' );

    #- Make header
    $self->{lookup} = [];
    my $colcnt = 0;

    #-- For lookup columns

    foreach my $col ( @{$header_look} ) {
        $self->list_header( $fields->{$col}, $colcnt );

        # Save index of columns to return
        push @{ $self->{lookup} }, $colcnt;

        $colcnt++;
    }

    #-- For the rest of the columns

    foreach my $col ( @{$header_cols} ) {
        $self->list_header( $fields->{$col}, $colcnt );
        $colcnt++;
    }

    return;
}

=head2 list_header

Make header for the list in the List tab.

=cut

sub list_header {
    my ( $self, $col, $colcnt ) = @_;

    # Label
    $self->get_listcontrol->columnInsert( 'end', -text => $col->{label} );

    # Background
    $self->get_listcontrol->columnGet($colcnt)->Subwidget('heading')
        ->configure( -background => 'tan' );

    # Width
    $self->get_listcontrol->columnGet($colcnt)->Subwidget('heading')
        ->configure( -width => $col->{width} );

    # Sort order, (A)lpha is default
    if ( defined $col->{order} ) {
        if ( $col->{order} eq 'N' ) {
            $self->get_listcontrol->columnGet($colcnt)
                ->configure( -comparecommand => sub { $_[0] <=> $_[1] } );
        }
    }
    else {
        print "WW: No sort option for '$col'\n";
    }

    return;
}

=head2 list_item_clear_all

Delete all list control items

=cut

sub list_item_clear_all {
    my $self = shift;

    $self->get_listcontrol->selectionClear( 0, 'end' );
    $self->get_listcontrol->delete( 0, 'end' );

    return;
}

=head2 list_populate

Populate list with data from query result.

=cut

sub list_populate {
    my ( $self, $ary_ref ) = @_;

    my $row_count;

    if ( Exists( $self->get_listcontrol ) ) {
        eval { $row_count = $self->get_listcontrol->size(); };
        if ($@) {
            warn "Error: $@";
            $row_count = 0;
        }
    }
    else {
        warn "No MList!\n";
        return;
    }

    my $record_count = scalar @{$ary_ref};

    # Data
    foreach my $record ( @{$ary_ref} ) {
        $self->get_listcontrol->insert( 'end', $record );
        $self->get_listcontrol->see('end');
        $row_count++;
#        $self->set_status( "$row_count records fetched", 'ms' );
        $self->get_listcontrol->update;

        # Progress bar
        my $p = floor( $row_count * 10 / $record_count ) * 10;
        if ( $p % 10 == 0 ) { $self->{progres} = $p; }
    }

#    $self->set_status( "$row_count records listed", 'ms' );

    # Activate and select last
    $self->get_listcontrol->selectionClear( 0, 'end' );
    $self->get_listcontrol->activate('end');
    $self->get_listcontrol->selectionSet('end');
    $self->get_listcontrol->see('active');
    $self->{progres} = 0;

    return $record_count;
}

=head2 list_raise

Raise I<List> tab and set focus to list.

=cut

sub list_raise {
    my $self = shift;

    $self->{_nb}->raise('lst');
    $self->get_listcontrol->focus;

    return;
}

=head2 get_list_max_index

Return the max index from the list control

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

    return $row_count;
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
        @returned = TpdaQrt::Utils->trim(@returned) if @returned;
    }

    return \@returned;
}

=head2 list_remove_selected

Remove the selected row from the list.

First it compares the Pk and the Fk values from the screen, with the
selected row contents in the list.

=cut

sub list_remove_selected {
    my ( $self, $pk_val, $fk_val ) = @_;

    my $sel = $self->list_read_selected();
    if ( !ref $sel ) {
        print "EE: Nothing selected!, use brute force? :)\n";
        return;
    }

    my $fk_idx = $self->{lookup}[1];

    my $found;
    if ( $sel->[0] eq $pk_val ) {

        # Check fk, if defined
        if ( defined $fk_idx ) {
            $found = 1 if $sel->[1] eq $fk_val;
        }
        else {
            $found = 1;
        }
    }
    else {
        print "EE: No matching list row!\n";
        return;
    }

    #- OK, found, delete from list

    my @selected;
    eval { @selected = $self->get_listcontrol->curselection(); };
    if ($@) {
        warn "Error: $@";

        # $self->refresh_sb( 'll', 'No record selected' );
        return;
    }
    else {
        my $indecs = pop @selected;    # first row in case of multiselect
        if ( defined $indecs ) {
            $self->get_listcontrol->delete($indecs);
        }
        else {
            print "EE: Nothing selected!\n";
        }
    }

    return;
}

=head2 list_locate

This should be never needed and is not used.  Using brute force to
locate the record in the list. ;)

=cut

sub list_locate {
    my ( $self, $pk_val, $fk_val ) = @_;

    my $pk_idx = $self->{lookup}[0];    # indices for Pk and Fk cols
    my $fk_idx = $self->{lookup}[1];
    my $idx;

    my @returned = $self->get_listcontrol->get( 0, 'end' );
    my $i = 0;
    foreach my $rec (@returned) {
        if ( $rec->[$pk_idx] eq $pk_val ) {

            # Check fk, if defined
            if ( defined $fk_idx ) {
                if ( $rec->[$fk_idx] eq $fk_val ) {
                    $idx = $i;
                    last;    # found!
                }
            }
            else {
                $idx = $i;
                last;        # found!
            }
        }

        $i++;
    }

    return $idx;
}

=head2 list_populate_all

Populate all other pages except the configuration page

=cut

sub list_populate_all {
    my $self = shift;

    my $titles = $self->_model->get_list_data();

    # Clear list
    $self->list_item_clear_all();

    # Populate list in sorted order
    my @titles = sort { $a <=> $b } keys %{$titles};
    foreach my $indice ( @titles ) {
        my $nrcrt = $titles->{$indice}[0];
        my $title = $titles->{$indice}[1];
        my $file  = $titles->{$indice}[2];
        # print "$nrcrt -> $title\n";
        $self->get_listcontrol->insert( 'end', [$nrcrt, $title] );
    }

    # Set item 0 selected on start
    $self->list_item_select_first();

    return;
}

sub list_item_select_first {
    my $self = shift;

    # Activate and select last
    $self->get_listcontrol->selectionClear( 0, 'end' );
    $self->get_listcontrol->activate(0);
    $self->get_listcontrol->selectionSet(0);
    $self->get_listcontrol->see('active');

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of TpdaQrt::Tk::View
