package QDepo::Wx::View;

use strict;
use warnings;

use File::Spec::Functions qw(abs2rel);
use Wx qw[:everything];
use Wx::Event qw(EVT_CLOSE EVT_COMMAND EVT_CHOICE EVT_MENU EVT_TOOL EVT_TIMER
    EVT_TEXT_ENTER EVT_AUINOTEBOOK_PAGE_CHANGED
    EVT_LIST_ITEM_ACTIVATED EVT_LIST_ITEM_SELECTED);
use Wx::Perl::ListCtrl;
use Wx::STC;

use QDepo::Config;
use QDepo::Wx::Notebook;
use QDepo::Wx::ToolBar;
use QDepo::Utils;

use base 'Wx::Frame';

=head1 NAME

QDepo::Wx::App - Wx Perl application class

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

    #- The Frame

    my $self = __PACKAGE__->SUPER::new( @_ );

    Wx::InitAllImageHandlers();

    $self->{_model} = $model;

    $self->{_cfg} = QDepo::Config->instance();

    $self->SetMinSize( Wx::Size->new( 425, 597 ) );
    $self->SetIcon( Wx::GetWxPerlIcon() );

    #-- GUI components

    $self->_create_menu();
    $self->_create_toolbar();
    $self->_create_statusbar();
    $self->{_nb} = QDepo::Wx::Notebook->new( $self );
    $self->_create_para_page();
    $self->_create_sql_page();
    $self->_create_config_page();
    $self->_create_report_page();

    #-- GUI actions

    $self->_set_model_callbacks();

    $self->Fit;

    #-- Event close
    EVT_CLOSE(
        $self,
        sub {
            my $self = shift;
            $self->on_close_window(@_);
        },
    );

    EVT_COMMAND( $self, -1, 9999, \&on_close_window );

    $self->Show(1);

    return $self;
}

=head2 _model

Return model instance

=cut

sub _model {
    my $self = shift;

    $self->{_model};
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
    $pr->add_callback( sub{ $self->progress_update( @_ ) } );

    return;
}

=head2 update_gui_components

When the application status (mode) changes, update gui components.
Screen controls (widgets) are not handled here, but in the controller
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

Create the menubar and the menus. Menus are defined in configuration
files.

=cut

sub _create_menu {
    my $self = shift;

    my $menu = Wx::MenuBar->new;

    $self->{_menu} = $menu;

    $self->make_menus( $self->_cfg->menubar );

    $self->SetMenuBar($menu);

    return;
}

=head2 make_menus

Make menus.

=cut

sub make_menus {
    my ( $self, $attribs, $position ) = @_;

    $position = $position ||= 0;    # default

    my $menus = QDepo::Utils->sort_hash_by_id($attribs);

    #- Create menus
    foreach my $menu_name ( @{$menus} ) {

        $self->{$menu_name} = Wx::Menu->new();

        my @popups
            = sort { $a <=> $b } keys %{ $attribs->{$menu_name}{popup} };
        foreach my $id (@popups) {
            $self->make_popup_item(
                $self->{$menu_name},
                $attribs->{$menu_name}{popup}{$id},
                $attribs->{$menu_name}{id} . $id,    # menu Id
            );
        }

        $self->{_menu}->Insert(
            $position,
            $self->{$menu_name},
            QDepo::Utils->ins_underline_mark(
                $attribs->{$menu_name}{label},
                $attribs->{$menu_name}{underline}
            ),
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
    my ( $self, $menu, $item, $id ) = @_;

    $menu->AppendSeparator() if $item->{sep} eq 'before';

    # Preserve some default Id's used by Wx
    $id = wxID_ABOUT if $item->{name} eq q{mn_ab};
    $id = wxID_HELP  if $item->{name} eq q{mn_gd};
    $id = wxID_EXIT  if $item->{name} eq q{mn_qt};

    my $label = $item->{label};
    $label .= "\t" . $item->{key} if $item->{key};    # add shortcut key

    $self->{ $item->{name} }
        = $menu->Append( $id,
        QDepo::Utils->ins_underline_mark( $label, $item->{underline}, ),
        );

    $menu->AppendSeparator() if $item->{sep} eq 'after';

    return;
}

=head2 get_menu_popup_item

Return a menu popup by name

=cut

sub get_menu_popup_item {
    my ( $self, $name ) = @_;

    return $self->{$name};
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

    my $tb = QDepo::Wx::ToolBar->new( $self, wxADJUST_MINSIZE );

    my ( $toolbars, $attribs ) = $self->toolbar_names();

    my $ico_path = $self->_cfg->icons;

    $tb->make_toolbar_buttons( $toolbars, $attribs, $ico_path );

    $self->SetToolBar($tb);

    $self->{_tb} = $self->GetToolBar;
    $self->{_tb}->Realize;

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

=head2 _create_statusbar

Create the status bar

=cut

sub _create_statusbar {
    my $self = shift;

    my $sb = $self->CreateStatusBar( 3 );
    $self->{_sb} = $sb;

    $self->SetStatusWidths( 260, -1, -2 );
}

=head2 get_statusbar

Return the status bar handler

=cut

sub get_statusbar {
    my $self = shift;

    return $self->{_sb};
}

=head2 get_notebook

Return the notebook handler

=cut

sub get_notebook {
    my $self = shift;

    return $self->{_nb};
}

=head2 _create_report_page

Create the report page (tab) on the notebook

=cut

sub _create_report_page {
    my $self = shift;

    $self->{_list} = Wx::Perl::ListCtrl->new(
        $self->{_nb}{p1}, -1,
        [ -1, -1 ],
        [ -1, -1 ],
        Wx::wxLC_REPORT | Wx::wxLC_SINGLE_SEL,
    );

    $self->{_list}->InsertColumn( 0, '#',           wxLIST_FORMAT_LEFT, 50  );
    $self->{_list}->InsertColumn( 1, 'Query name', wxLIST_FORMAT_LEFT, 337 );

    #-- Controls

    my $repo_lbl1 = Wx::StaticText->new( $self->{_nb}{p1}, -1, 'Title', );
    $self->{title} =
        Wx::TextCtrl->new( $self->{_nb}{p1}, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $repo_lbl2 = Wx::StaticText->new( $self->{_nb}{p1}, -1, 'Query file', );
    $self->{filename} =
        Wx::TextCtrl->new( $self->{_nb}{p1}, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $repo_lbl3 = Wx::StaticText->new( $self->{_nb}{p1}, -1, 'Output file', );
    $self->{output} =
        Wx::TextCtrl->new( $self->{_nb}{p1}, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $repo_lbl4 = Wx::StaticText->new( $self->{_nb}{p1}, -1, 'Template', );
    $self->{template} =
        Wx::TextCtrl->new( $self->{_nb}{p1}, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    $self->{description} =
        Wx::TextCtrl->new( $self->{_nb}{p1}, -1, q{}, [ -1, -1 ], [ -1, 40 ],
                           wxTE_MULTILINE, );

    #--- Layout

    my $repo_main_sz = Wx::FlexGridSizer->new( 4, 1, 5, 5 );

    #-- Top

    my $repo_top_sz =
      Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $self->{_nb}{p1}, -1, ' Query list ', ),
        wxVERTICAL, );

    $repo_top_sz->Add( $self->{_list}, 1, wxEXPAND, 3 );

    #-- Middle

    my $repo_mid_sz =
      Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $self->{_nb}{p1}, -1, ' Header ', ), wxVERTICAL, );

    my $repo_mid_fgs = Wx::FlexGridSizer->new( 4, 2, 5, 10 );

    $repo_mid_fgs->Add( $repo_lbl1, 0, wxTOP | wxLEFT,  5 );
    $repo_mid_fgs->Add( $self->{title},    0, wxEXPAND | wxTOP, 5 );

    $repo_mid_fgs->Add( $repo_lbl2, 0, wxLEFT,   5 );
    $repo_mid_fgs->Add( $self->{filename}, 0, wxEXPAND, 0 );

    $repo_mid_fgs->Add( $repo_lbl3, 0, wxLEFT,   5 );
    $repo_mid_fgs->Add( $self->{output},   0, wxEXPAND, 0 );

    $repo_mid_fgs->Add( $repo_lbl4, 0, wxLEFT,   5 );
    $repo_mid_fgs->Add( $self->{template},    0, wxEXPAND, 0 );

    # $repo_mid_fgs->AddGrowableRow( 1, 1 );
    $repo_mid_fgs->AddGrowableCol( 1, 1 );

    $repo_mid_sz->Add( $repo_mid_fgs, 0, wxALL | wxGROW, 0 );

    #-- Bottom

    my $repo_bot_sz =
      Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $self->{_nb}{p1}, -1, ' Description ', ),
        wxVERTICAL, );

    $repo_bot_sz->Add( $self->{description}, 1, wxEXPAND );

    #--

    $repo_main_sz->Add( $repo_top_sz, 0, wxALL | wxGROW, 5 );
    $repo_main_sz->Add( $repo_mid_sz, 0, wxALL | wxGROW, 5 );
    $repo_main_sz->Add( $repo_bot_sz, 0, wxALL | wxGROW, 5 );

    $repo_main_sz->AddGrowableRow(0);
    $repo_main_sz->AddGrowableCol(0);

    $self->{_nb}{p1}->SetSizer($repo_main_sz);

    return;
}

=head2 _create_para_page

Create the parameters page (tab) on the notebook

=cut

sub _create_para_page {

    my $self = shift;

    #-- Controls

    my $para_tit_lbl1 =
      Wx::StaticText->new( $self->{_nb}{p2}, -1, 'Label', );
    my $para_tit_lbl2 =
      Wx::StaticText->new( $self->{_nb}{p2}, -1, 'Description', );
    my $para_tit_lbl3 =
      Wx::StaticText->new( $self->{_nb}{p2}, -1, 'Value', );

    my $para_lbl1 = Wx::StaticText->new( $self->{_nb}{p2}, -1, 'value1', );
    $self->{descr1} =
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, q{}, [ -1, -1 ], [ 170, -1 ], );
    $self->{value1} =
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $para_lbl2 = Wx::StaticText->new( $self->{_nb}{p2}, -1, 'value2', );
    $self->{descr2} =
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, q{}, [ -1, -1 ], [ 170, -1 ], );
    $self->{value2} =
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $para_lbl3 = Wx::StaticText->new( $self->{_nb}{p2}, -1, 'value3', );
    $self->{descr3} =
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, q{}, [ -1, -1 ], [ 170, -1 ], );
    $self->{value3} =
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $para_lbl4 = Wx::StaticText->new( $self->{_nb}{p2}, -1, 'value4', );
    $self->{descr4} =
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, q{}, [ -1, -1 ], [ 170, -1 ], );
    $self->{value4} =
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $para_lbl5 = Wx::StaticText->new( $self->{_nb}{p2}, -1, 'value5', );
    $self->{descr5} =
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, q{}, [ -1, -1 ], [ 170, -1 ], );
    $self->{value5} =
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    #-- Layout

    my $para_fgs = Wx::FlexGridSizer->new( 6, 3, 5, 10 );

    $para_fgs->Add( $para_tit_lbl1, 0, wxTOP | wxLEFT, 10 );
    $para_fgs->Add( $para_tit_lbl2, 0, wxTOP | wxLEFT, 10 );
    $para_fgs->Add( $para_tit_lbl3, 0, wxTOP | wxLEFT, 10 );

    $para_fgs->Add( $para_lbl1, 0, wxTOP | wxLEFT,   5 );
    $para_fgs->Add( $self->{descr1},   0, wxEXPAND | wxTOP, 5 );
    $para_fgs->Add( $self->{value1},   1, wxEXPAND | wxTOP, 5 );

    $para_fgs->Add( $para_lbl2, 0, wxLEFT,   5 );
    $para_fgs->Add( $self->{descr2},   1, wxEXPAND, 0 );
    $para_fgs->Add( $self->{value2},   1, wxEXPAND, 0 );

    $para_fgs->Add( $para_lbl3, 0, wxLEFT,   5 );
    $para_fgs->Add( $self->{descr3},   1, wxEXPAND, 0 );
    $para_fgs->Add( $self->{value3},   1, wxEXPAND, 0 );

    $para_fgs->Add( $para_lbl4, 0, wxLEFT,   5 );
    $para_fgs->Add( $self->{descr4},   1, wxEXPAND, 0 );
    $para_fgs->Add( $self->{value4},   1, wxEXPAND, 0 );

    $para_fgs->Add( $para_lbl5, 0, wxLEFT,   5 );
    $para_fgs->Add( $self->{descr5},   1, wxEXPAND, 0 );
    $para_fgs->Add( $self->{value5},   1, wxEXPAND, 0 );

    $para_fgs->AddGrowableCol(2);

    my $para_main_sz = Wx::BoxSizer->new(wxHORIZONTAL);

    my $para_sbs =
      Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $self->{_nb}{p2}, -1, ' Parameters ', ), wxVERTICAL,
      );

    $para_sbs->Add( $para_fgs, 0, wxEXPAND, 3 );
    $para_main_sz->Add( $para_sbs, 1, wxALL | wxGROW, 5 );

    $self->{_nb}{p2}->SetSizer( $para_main_sz );
}

=head2 _create_sql_page

Create the SQL page (tab) on the notebook

=cut

sub _create_sql_page {
    my $self = shift;

    #--- SQL Tab (page)

    #-- Controls

    my $sql_sb = Wx::StaticBox->new( $self->{_nb}{p3}, -1, ' SQL ', );

    $self->{sql} = Wx::StyledTextCtrl->new(
        $self->{_nb}{p3},
        -1,
        [ -1, -1 ],
        [ -1, -1 ],
    );

    $self->{sql}->SetMarginType( 1, wxSTC_MARGIN_SYMBOL );
    $self->{sql}->SetMarginWidth( 1, 10 );
    $self->{sql}->StyleSetFont( wxSTC_STYLE_DEFAULT,
        Wx::Font->new( 10, wxDEFAULT, wxNORMAL, wxNORMAL, 0, 'Courier New' ) );
    # $self->{sql}->SetLexer( wxSTC_LEX_SQL );
    $self->{sql}->SetLexer( wxSTC_LEX_MSSQL );
    # List0
    $self->{sql}->SetKeyWords(0,
    q{all and any ascending between by cast collate containing day
descending distinct escape exists from full group having in
index inner into is join left like merge month natural not
null on order outer plan right select singular some sort starting
transaction union upper user where with year} );
    # List1
    $self->{sql}->SetKeyWords(1,
    q{blob char decimal integer number varchar} );
    # List2 Only for MSSQL?
    $self->{sql}->SetKeyWords(2,
    q{avg count gen_id max min sum} );
    $self->{sql}->SetTabWidth(4);
    $self->{sql}->SetIndent(4);
    $self->{sql}->SetHighlightGuide(4);

    $self->{sql}->StyleClearAll();

    # Global default styles for all languages
    $self->{sql}->StyleSetSpec( wxSTC_STYLE_BRACELIGHT,
                                "fore:#FFFFFF,back:#0000FF,bold" );
    $self->{sql}->StyleSetSpec( wxSTC_STYLE_BRACEBAD,
                                "fore:#000000,back:#FF0000,bold" );

    # MSSQL - works with wxSTC_LEX_MSSQL
    $self->{sql}->StyleSetSpec(0, "fore:#000000");            #*Default
    $self->{sql}->StyleSetSpec(1, "fore:#ff7373,italic");     #*Comment
    $self->{sql}->StyleSetSpec(2, "fore:#007f7f,italic");     #*Commentline
    $self->{sql}->StyleSetSpec(3, "fore:#0000ff");            #*Number
    $self->{sql}->StyleSetSpec(4, "fore:#dca3a3");            #*Singlequoted
    $self->{sql}->StyleSetSpec(5, "fore:#3f3f3f");            #*Operation
    $self->{sql}->StyleSetSpec(6, "fore:#000000");            #*Identifier
    $self->{sql}->StyleSetSpec(7, "fore:#8cd1d3");            #*@-Variable
    $self->{sql}->StyleSetSpec(8, "fore:#705050");            #*Doublequoted
    $self->{sql}->StyleSetSpec(9, "fore:#dfaf8f");            #*List0
    $self->{sql}->StyleSetSpec(10,"fore:#94c0f3");            #*List1
    $self->{sql}->StyleSetSpec(11,"fore:#705030");            #*List2

    #-- Layout

    my $sql_main_sz = Wx::BoxSizer->new(wxVERTICAL);
    my $sql_sbs = Wx::StaticBoxSizer->new( $sql_sb, wxHORIZONTAL, );

    $sql_sbs->Add( $self->{sql}, 1, wxEXPAND, 0 );
    $sql_main_sz->Add( $sql_sbs, 1, wxALL | wxEXPAND, 5 );

    $self->{_nb}{p3}->SetSizer( $sql_main_sz );
}

=head2 _create_config_page

Create the configuration info page (tab) on the notebook.

Using the MySQL lexer for very basic syntax highlighting. This was
chosen because permits the definition of 3 custom lists. For this
purpose three key word lists are defined with a keyword in each. B<EE>
is for error, B<II> for information and B<WW> for warning. Words in
the lists must be lower case.

=cut

sub _create_config_page {
    my $self = shift;

    #-- Controls

    #- Log text control

    $self->{log} = Wx::StyledTextCtrl->new(
        $self->{_nb}{p4},
        -1,
        [ -1, -1 ],
        [ -1, -1 ],
    );

    # $self->{log}->SetUseHorizontalScrollBar(0); # turn off scrollbars
    # $self->{log}->SetUseVerticalScrollBar(0);
    $self->{log}->SetMarginType( 1, wxSTC_MARGIN_SYMBOL );
    $self->{log}->SetMarginWidth( 1, 10 );
    $self->{log}->StyleSetFont( wxSTC_STYLE_DEFAULT,
        Wx::Font->new( 10, wxDEFAULT, wxNORMAL, wxNORMAL, 0, 'Courier New' ) );
    $self->{log}->SetLexer( wxSTC_LEX_MSSQL );
    $self->{log}->SetWrapMode(wxSTC_WRAP_NONE); # wxSTC_WRAP_WORD

    # List0
    $self->{log}->SetKeyWords(0, q{ii} );
    # List1
    $self->{log}->SetKeyWords(1, q{ee} );
    # List2

    $self->{log}->SetKeyWords(2, q{ww} );
    $self->{log}->SetTabWidth(4);
    $self->{log}->SetIndent(4);
    $self->{log}->SetHighlightGuide(4);
    $self->{log}->StyleClearAll();

    # MSSQL - works with wxSTC_LEX_MSSQL
    $self->{log}->StyleSetSpec(4, "fore:#dca3a3");            #*Singlequoted
    $self->{log}->StyleSetSpec(8, "fore:#705050");            #*Doublequoted
    $self->{log}->StyleSetSpec(9, "fore:#00ff00");            #*List0
    $self->{log}->StyleSetSpec(10,"fore:#ff0000");            #*List1
    $self->{log}->StyleSetSpec(11,"fore:#0000ff");            #*List2

    #--- Layout

    my $conf_main_sz = Wx::FlexGridSizer->new( 2, 1, 5, 5 );

    #-- Top - removed :)

    #-- Bottom

    my $conf_bot_sz =
      Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $self->{_nb}{p4}, -1, ' Log ', ),
        wxVERTICAL, );

    $conf_bot_sz->Add( $self->{log}, 1, wxEXPAND );

    #--

    # $conf_main_sz->Add( $conf_top_sz, 0, wxALL | wxGROW, 5 );
    $conf_main_sz->Add( $conf_bot_sz, 0, wxALL | wxGROW, 5 );

    $conf_main_sz->AddGrowableRow(0);
    $conf_main_sz->AddGrowableCol(0);

    $self->{_nb}{p4}->SetSizer($conf_main_sz);
}

=head2 dialog_error

Error message dialog.

=cut

sub dialog_error {
    my ( $self, $message, $details ) = @_;

    Wx::MessageBox( "$message\n$details", 'Error', wxOK | wxICON_ERROR,
        $self );

    return;
}

=head2 action_confirmed

Yes, No, Cancel message dialog.

=cut

sub action_confirmed {
    my ( $self, $msg ) = @_;

    my ($answer) = Wx::MessageBox(
        $msg,
        'Confirm',
        wxYES_NO | wxCANCEL,
        undef,
    );

    my $return_answer = ($answer == wxYES)     ? 'yes'
                      : ($answer == wxNO)      ? 'no'
                      : ($answer == wxCANCEL)  ? 'cancel'
                      :                          'unknown'
                      ;

    return $return_answer;
}

=head2 get_toolbar_btn

Return a toolbar button by name.

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

#     my $idx = $self->get_toolbar_btn($name)->GetCurrentSelection;

#     return $self->{_tb}->get_choice_options($idx);
# }

=head2 get_listcontrol

Return the list control handler.

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
        { description => [ $self->{description}, 'normal', 'white', 'e' ] },
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
        { sql => [ $self->{sql}, 'normal'  , 'white', 's' ] },
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

Set text item from list control row and col

=cut

sub set_list_text {
    my ($self, $row, $col, $text) = @_;

    $self->get_listcontrol->SetItemText( $row, $col, $text );

    return;
}

=head2 list_item_edit

Edit and existing item. If undef is passed for nrcrt or title, keep
the existing value.

=cut

sub list_item_edit {
    my ( $self, $row, $nrcrt, $title ) = @_;

    if ($nrcrt) {
        $self->set_list_text($row, 0, $nrcrt);
    }
    if ($title) {
        $self->set_list_text($row, 1, $title);
    }

    return;
}

=head2 list_item_select

Select the first/last item in list.

=cut

sub list_item_select {
    my ($self, $what) = @_;

    my $items_no = $self->get_list_max_index() + 1;

    return unless $items_no > 0;             # nothing to select

    my $item
        = $what eq 'first' ? 0
        : $what eq 'last'  ? ($items_no - 1)
        :                    undef # default
        ;

    return unless defined $item;

    $self->get_listcontrol->Select( $item, 1 );
    $self->get_listcontrol->EnsureVisible($item);

    return;
}

=head2 get_list_max_index

Return the maximum index from the list control (item count - 1).

=cut

sub get_list_max_index {
    my $self = shift;

    return ( $self->get_listcontrol->GetItemCount() - 1 );
}

=head2 get_list_selected_index

Return the selected index from the list control.

=cut

sub get_list_selected_index {
    my $self = shift;

    return $self->get_listcontrol->GetSelection();
}

=head2 list_item_insert

Insert item in list control.

=cut

sub list_item_insert {
    my ( $self, $item, $nrcrt, $title, $file ) = @_;

    $self->list_item_string_insert($item);
    $self->set_list_text($item, 0, $nrcrt);
    $self->set_list_text($item, 1, $title);
    $self->set_list_item_data(
        $item,
        {
            file  => $file,
            nrcrt => $nrcrt,
        },
    );    # set data

    return;
}

=head2 set_list_item_data

Set list item data.

=cut

sub set_list_item_data {
    my ($self, $item, $data_new) = @_;

    my $data = $self->get_list_item_data($item);

    while ( my ( $key, $value ) = each( %{$data_new} ) ) {
        $data->{$key} = $value;
    }

    $self->get_listcontrol->SetItemData( $item, $data );

    return;
}

=head2 get_list_item_data

Set list item data.

=cut

sub get_list_item_data {
    my ($self, $item) = @_;

    return $self->get_listcontrol->GetItemData( $item );
}

=head2 toggle_mark

Toggle delete mark on list item.

=cut

sub toggle_mark {
    my ($self, $item) = @_;

    my $data = $self->get_list_item_data($item);

    if ( exists $data->{mark} ) {
        ( $data->{mark} == 1 )
            ? $self->set_list_item_data($item, { mark => 0 } )
            : $self->set_list_item_data($item, { mark => 1 } )
            ;
    }
    else {
        $self->set_list_item_data($item, { mark => 1 } ); # set mark
    }

    # Keep a count of marks
    $self->get_list_item_data($item)->{mark} == 1
        ? $self->_model->{_marks}++
        : $self->_model->{_marks}--
        ;

    return;
}

=head2 list_item_string_insert

Insert string item in list control

=cut

sub list_item_string_insert {
    my ($self, $item) = @_;

    $self->get_listcontrol->InsertStringItem( $item, 'dummy' );

    return;
}

=head2 list_item_clear

Delete list control item

=cut

sub list_item_clear {
    my ($self, $item) = @_;
    $self->get_listcontrol->DeleteItem($item);
}

=head2 list_item_clear_all

Delete all list control items.

=cut

sub list_item_clear_all {
    my ($self) = @_;

    $self->get_listcontrol->DeleteAllItems;
}

=head2 list_remove_item

Remove item from list control and select the first item.

=cut

sub list_remove_item {
    my $self = shift;

    my $item = $self->get_list_selected_index();
    my $file = $self->get_list_item_data($item);

    # Remove from list
    $self->list_item_clear($item);

    # Set item 0 selected
    $self->list_item_select('first');

    return $file;
}

=head2 log_config_options

Log configuration options with data from the Config module

=cut

sub log_config_options {
    my $self = shift;

    my $cfg  = QDepo::Config->instance();
    my $path = $cfg->output;

    while ( my ( $key, $value ) = each( %{$path} ) ) {
        $self->log_msg("II Config: '$key' set to '$value'");
    }
}

=head2 list_populate_all

Populate list with items.

=cut

sub list_populate_all {
    my $self = shift;

    my $items = $self->_model->load_qdf_data_wx();

    return unless scalar keys %{$items};

    # Populate list in sorted order
    my @indices = sort { $a <=> $b } keys %{$items};

    # Clear list
    $self->list_item_clear_all();

    foreach my $idx ( @indices ) {
        my $nrcrt = $items->{$idx}{nrcrt};
        my $title = $items->{$idx}{title};
        my $file  = $items->{$idx}{file};

        $self->list_item_insert($idx, $nrcrt, $title, $file);
    }

    return;
}

=head2 list_populate_item

Add new item in list control.

=cut

sub list_populate_item {
    my ( $self, $rec ) = @_;

    my ($idx) = keys %{$rec};
    my $r     = $rec->{$idx};

    $self->list_item_insert( $idx, $r->{nrcrt}, $r->{title}, $r->{file} );

    return;
}

=head2 controls_populate

Populate controls with data from XML

=cut

sub controls_populate {
    my $self = shift;

    my $item = $self->get_list_selected_index();
    my $lidata = $self->get_list_item_data($item);
    my $file = $lidata->{file};
    my ($data) = $self->_model->read_qdf_data_file( $item, $file );

    my $cfg     = QDepo::Config->instance();
    my $qdfpath = $cfg->qdfpath;

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

Toggle sql replace

=cut

 sub toggle_sql_replace {
    my ($self, $mode) = @_;

    $mode ||= $self->_model->get_appmode;

    my $item = $self->get_list_selected_index();
    my $lidata = $self->get_list_item_data($item);
    my $file   = $lidata->{file};
    my ($data) = $self->_model->read_qdf_data_file($item, $file);

    if ($mode eq 'edit') {
        $self->control_set_value( 'sql', $data->{body}{sql} );
    }
    elsif ($mode eq 'sele') {
        my $para = QDepo::Utils->params_to_hash( $data->{parameters} );
        $self->control_replace_sql_text( $data->{body}{sql}, $para );
    }

    return;
}

sub get_qdf_data_file_wx {
    my ($self, $item) = @_;

    my $lidata = $self->get_list_item_data($item);
    my $file   = $lidata->{file};

    return $file;
}

=head2 control_replace_sql_text

Replace sql text control

=cut

sub control_replace_sql_text {
    my ($self, $sqltext, $params) = @_;

    my ($newtext) = $self->_model->string_replace_pos($sqltext, $params);

    # Write new text to control
    $self->control_set_value('sql', $newtext);
}

=head2 log_msg

Set log message

=cut

sub log_msg {
    my ( $self, $message ) = @_;

    my $control = $self->get_control_by_name('log');

    $self->control_write_s( $control, $message, 'append' );

    return;
}

=head2 set_status

Set status message.

Color is ignored for wxPerl.

=cut

sub set_status {
    my ( $self, $text, $sb_id, $color ) = @_;

    my $sb = $self->get_statusbar();

    if ( $sb_id eq q{db} ) {

        # Database name
        $sb->PushStatusText( $text, 2 ) if defined $text;
    }
    elsif ( $sb_id eq q{ms} ) {

        # Messages
        $sb->PushStatusText( $text, 0 ) if defined $text;
    }
    else {

        # App status
        # my $cw = $self->GetCharWidth();
        # my $ln = length $text;
        # my $cn = () = $text =~ m{i|l}g;
        # my $pl = int( ( 46 - $cw * $ln ) / 2 );
        # $pl = ceil $pl / $cw;
        # print "cw=$cw : ln=$ln : cn=$cn : pl=$pl: $text\n";
        # $text = sprintf( "%*s", $pl, $text );
        $sb->PushStatusText( $text, 1 ) if defined $text;
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

=head2 dialog_progress

Create a progress dialog.

=cut

sub dialog_progress {
    my ($self, $title, $max) = @_;

    $max = (defined $max and $max > 0) ? $max : 100; # default 100

    require QDepo::Wx::Dialog::Progress;
    $self->{progress} = QDepo::Wx::Dialog::Progress->new($self, $title, $max);

    $self->{progress}->Destroy;

    return;
}

=head2 progress_update

Update progress.  If I<Cancel> is pressed, stop (set continue to
false) from the return value of the Update method of
L<Wx::ProgressDialog>.

=cut

sub progress_update {
    my ( $self, $count ) = @_;

    return if !$count;

    if ( defined $self->{progress}
        and $self->{progress}->isa('QDepo::Wx::Dialog::Progress') )
    {
        my $continue = $self->{progress}->update($count);
        $self->_model->set_continue($continue);
    }

    return;
}

=head2 control_set_value

Set new value for a controll.

=cut

sub control_set_value {
    my ($self, $name, $value) = @_;

    $value ||= q{};                 # empty

    my $control = $self->get_control_by_name($name);

    $self->control_write_s($control, $value);

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

Write to a Entry control.

=cut

sub control_write_e {
    my ( $self, $control, $value ) = @_;

    $control->Clear;
    $control->SetValue($value) if defined $value;

    return;
}

=head2 control_write_s

Write to a Wx::StyledTextCtrl.

=cut

sub control_write_s {
    my ( $self, $control, $value, $is_append ) = @_;

    $value ||= q{};                 # empty

    $control->ClearAll unless $is_append;
    $control->AppendText($value);
    $control->AppendText("\n");
    $control->Colourise( 0, $control->GetTextLength );

    return;
}

=head2 controls_read_page

Read all controls from page and return an array reference

=cut

sub controls_read_page {
    my ( $self, $page ) = @_;

    # Get controls name and object from $page
    my $get      = 'get_controls_' . $page;
    my $controls = $self->$get();
    my @records;

    foreach my $control ( @{$controls} ) {
        foreach my $name ( keys %{$control} ) {
            my $value;
            if ($page ne 'sql') {
                $value = $control->{$name}[0]->GetValue();
            }
            else {
                $value = $control->{$name}[0]->GetText();
            }

            push(@records, { $name => $value } ) if ($name and $value);
        }
    }

    return \@records;
}

sub toggle_list_enable {
    my ($self, $state) = @_;

    $self->get_listcontrol()->Enable($state);

    return;
}

sub set_editable {
    my ( $self, $name, $state, $color ) = @_;

    # Controls states are defined in View as strings
    # Here we need to transform them to 0|1
    my $editable = $state eq 'normal' ? 1 : 0;
    $color = 'lightgrey' unless $editable; # default color for disabled

    my $control = $self->get_control_by_name($name);

    if ( $name eq 'sql' ) {
        # For Wx::StyledTextCtrl
        $control->Enable($editable);
    }
    else {
        # For Wx::TextCtrl
        $control->SetEditable($editable);
    }

    $control->SetBackgroundColour( Wx::Colour->new($color)) if $color;

    return ;
}

######################################################################

#-- Event handlers

sub event_handler_for_menu {
    my ($self, $name, $calllback) = @_;

    my $menu_id = $self->get_menu_popup_item($name)->GetId;

    EVT_MENU $self, $menu_id, $calllback;

    return;
}

sub event_handler_for_tb_button {
    my ($self, $name, $calllback) = @_;

    my $tb_id = $self->get_toolbar_btn($name)->GetId;

    EVT_TOOL $self, $tb_id, $calllback;

    return;
}

sub event_handler_for_tb_choice {
    my ($self, $name, $calllback) = @_;

    my $tb_id = $self->get_toolbar_btn($name)->GetId;

    EVT_CHOICE $self, $tb_id, $calllback;

    return;
}

sub event_handler_for_list {
    my ($self, $calllback) = @_;

    #- List controll
    EVT_LIST_ITEM_SELECTED $self, $self->get_listcontrol, $calllback;

    return;
}

=head2 on_close_window

Destroy the window.

=cut

sub on_close_window {
    my ($self, ) = @_;

    $self->Destroy;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of QDepo::Wx::View
