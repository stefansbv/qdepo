package QDepo::Wx::View;

# ABSTRACT: The View

use strict;
use warnings;
use Carp;

use Locale::TextDomain 1.20 qw(QDepo);
use File::Spec::Functions qw(abs2rel);
use Scalar::Util qw(looks_like_number);
use Wx qw(wxID_ABOUT wxID_HELP wxID_EXIT wxTE_MULTILINE wxEXPAND
    wxHORIZONTAL wxVERTICAL wxTOP wxLEFT wxRIGHT wxALL wxGROW
    wxALIGN_CENTRE wxICON_ERROR wxSTC_MARGIN_SYMBOL
    wxSTC_STYLE_DEFAULT wxDEFAULT wxNORMAL wxSTC_LEX_MSSQL
    wxSTC_STYLE_BRACELIGHT wxSTC_STYLE_BRACEBAD
    wxSTC_WRAP_NONE wxOK wxYES wxNO wxYES_NO wxCANCEL
    wxFULL_REPAINT_ON_RESIZE wxNO_FULL_REPAINT_ON_RESIZE
    wxCLIP_CHILDREN wxCB_SORT wxCB_READONLY);
use Wx::Event qw(EVT_CLOSE EVT_COMMAND EVT_CHOICE EVT_MENU EVT_TOOL EVT_TIMER
    EVT_TEXT_ENTER EVT_AUINOTEBOOK_PAGE_CHANGED EVT_BUTTON
    EVT_LIST_ITEM_SELECTED);

use QDepo::Config;
use QDepo::Config::Menu;
use QDepo::Config::Toolbar;
use QDepo::Wx::Notebook;
use QDepo::Wx::ToolBar;
use QDepo::Wx::ListCtrl;
use QDepo::Wx::LogView;
use QDepo::Wx::Editor;
use QDepo::Utils;

use base 'Wx::Frame';

sub new {
    my $class = shift;
    my $model = shift;

    #- The Frame

    my $self = __PACKAGE__->SUPER::new(@_);

    Wx::InitAllImageHandlers();

    $self->{_model} = $model;

    $self->{_cfg} = QDepo::Config->instance();

    $self->SetMinSize( Wx::Size->new( 425, 660 ) );
    $self->SetIcon( Wx::GetWxPerlIcon() );

    #-- GUI components

    my $main_bsz = Wx::BoxSizer->new(wxHORIZONTAL);

    $self->_build_menu();
    $self->_build_toolbar();
    $self->_build_statusbar();

    $self->_build_splitter($main_bsz);

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

    $self->SetSizer($main_bsz);
    $self->Show(1);

    return $self;
}

sub model {
    my $self = shift;
    return $self->{_model};
}

sub cfg {
    my $self = shift;
    return $self->{_cfg};
}

sub _set_model_callbacks {
    my $self = shift;

    my $co = $self->model->get_connection_observable;
    $co->add_callback( sub { $self->toggle_status_cn( $_[0] ); } );

    # When the status changes, update gui components
    my $apm = $self->model->get_appmode_observable;
    $apm->add_callback( sub { $self->update_gui_components } );

    my $upd = $self->model->get_itemchanged_observable;
    $upd->add_callback(
        sub {
            $self->querylist_form_clear;
            $self->querylist_form_populate;
            $self->toggle_sql_replace;
        }
    );

    my $so = $self->model->get_stdout_observable;
    $so->add_callback( sub { $self->set_status( $_[0], 'ms' ) } );

    my $xo = $self->model->get_message_observable;
    $xo->add_callback( sub { $self->log_msg(@_) } );

    my $pr = $self->model->get_progress_observable;
    $pr->add_callback( sub { $self->progress_update(@_) } );

    return;
}

sub update_gui_components {
    my $self = shift;
    my $mode = $self->model->get_appmode;
    $self->set_status( $mode, 'md' );    # update statusbar
    ( $mode eq 'edit' )
        ? $self->{_tb}->toggle_tool_check( 'tb_ed', 1 )
        : $self->{_tb}->toggle_tool_check( 'tb_ed', 0 );

    return;
}

sub _build_menu {
    my $self = shift;
    my $menu = Wx::MenuBar->new;
    $self->{_menu} = $menu;
    $self->make_menus;
    $self->SetMenuBar($menu);
    return;
}

sub make_menus {
    my $self = shift;

    my $conf = QDepo::Config::Menu->new;

    #- Create menus
    my $pos = 0;
    foreach my $menu_name ( $conf->all_menus ) {
        $self->{$menu_name} = Wx::Menu->new();
        my $menu_href = $conf->get_menu($menu_name);
        my @popups = sort { $a <=> $b } keys %{ $menu_href->{popup} };
        foreach my $id (@popups) {
            $self->make_popup_item(
                $self->{$menu_name},
                $menu_href->{popup}{$id},
                $menu_href->{id} . $id,    # menu Id
            );
        }
        $self->{_menu}->Insert(
            $pos,
            $self->{$menu_name},
            QDepo::Utils->ins_underline_mark(
                $menu_href->{label}, $menu_href->{underline},
            ),
        );
        $pos++;
    }

    return;
}

sub get_app_menus_list {
    my $self = shift;

    my $attribs = $self->cfg->appmenubar;
    my $menus = QDepo::Utils->sort_hash_by( 'id', $attribs );

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

sub get_menu_popup_item {
    my ( $self, $name ) = @_;
    return $self->{$name};
}

sub get_menubar {
    my $self = shift;
    return $self->{_menu};
}

sub _build_toolbar {
    my $self = shift;

    my $tb = QDepo::Wx::ToolBar->new($self);    # wxADJUST_MINSIZE#

    my $conf     = QDepo::Config::Toolbar->new;
    my @toolbars = $conf->all_buttons;
    my $ico_path = $self->cfg->icons;

    foreach my $name (@toolbars) {
        my $attribs = $conf->get_tool($name);
        $tb->make_toolbar_button( $name, $attribs, $ico_path );
    }

    $tb->set_initial_mode( \@toolbars );

    $self->SetToolBar($tb);

    $self->{_tb} = $self->GetToolBar;
    $self->{_tb}->Realize;

    return;
}

sub enable_tool {
    my ( $self, $btn_name, $state ) = @_;
    $self->{_tb}->enable_tool( $btn_name, $state );
    return;
}

sub _build_statusbar {
    my $self = shift;
    my $sb   = $self->CreateStatusBar(4);
    $self->{_sb} = $sb;
    $self->SetStatusWidths( 180, 35, -3, -2 );
    return;
}

sub get_statusbar {
    my $self = shift;
    return $self->{_sb};
}

sub get_notebook {
    my $self = shift;
    return $self->{_nb};
}

sub _build_splitter {
    my ( $self, $main_bsz ) = @_;

    my $min_pane_size = 50;
    my $sash_pos      = 450;

    $self->{_gap} = Wx::wxVERSION >= 3 ? 8 : 2;   # add more space for Wx >= 3

    my $spw = Wx::SplitterWindow->new(
        $self, -1,
        [ -1, -1 ],
        [ -1, -1 ],
        wxNO_FULL_REPAINT_ON_RESIZE | wxCLIP_CHILDREN,
    );
    $main_bsz->Add( $spw, 1, wxEXPAND | wxALL, 0 );

    my $panel_top = Wx::Panel->new(
        $spw, -1,
        [ -1, -1 ],
        [ -1, -1 ],
        wxFULL_REPAINT_ON_RESIZE, 'topPanel',
    );
    my $panel_bot = Wx::Panel->new(
        $spw, -1,
        [ -1, -1 ],
        [ -1, -1 ],
        wxFULL_REPAINT_ON_RESIZE, 'botPanel',
    );

    my $sizer_top = Wx::BoxSizer->new(wxVERTICAL);
    $panel_top->SetSizer($sizer_top);

    my $sizer_bot = Wx::BoxSizer->new(wxVERTICAL);
    $panel_bot->SetSizer($sizer_bot);

    $self->{log} = QDepo::Wx::LogView->new($panel_bot);
    $self->{log}->SetReadOnly(1);    # log is readonly

    my $log_sbs = Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $panel_bot, -1, __ 'Log' ), wxVERTICAL );
    $log_sbs->Add( -1, $self->{_gap} );
    $log_sbs->Add( $self->{log}, 1, wxEXPAND, 0 );
    $sizer_bot->Add( $log_sbs, 1, wxALL | wxEXPAND, 5 );

    $spw->SplitHorizontally( $panel_top, $panel_bot, $sash_pos );
    $spw->SetMinimumPaneSize($min_pane_size);

    $self->{_nb} = QDepo::Wx::Notebook->new($panel_top);
    $sizer_top->Add( $self->{_nb}, 1, wxEXPAND | wxALL, 0 );

    $self->_build_page_querylist;
    $self->_build_page_info;
    $self->_build_page_sql;
    $self->_build_page_admin;

    return;
}

sub on_notebook_page_changed {
    my ( $self, $callback ) = @_;
    my $nb = $self->get_notebook;
    EVT_AUINOTEBOOK_PAGE_CHANGED $self, $nb->GetId, $callback;
    return;
}

sub get_nb_current_page {
    my $self = shift;
    return $self->get_notebook->get_current;
}

sub set_nb_current {
    my ( $self, $page ) = @_;
    my $nb = $self->get_notebook;
    $nb->{nb_prev} = $nb->{nb_curr};    # previous tab name
    $nb->{nb_curr} = $page;             # current tab name
    return;
}

sub _build_page_querylist {
    my $self = shift;
    my $page = $self->{_nb}{p1};

    $self->model->init_data_table('qlist');
    my $dtq = $self->model->get_data_table_for('qlist');
    $self->{qlist} = QDepo::Wx::ListCtrl->new( $page, $dtq );

    my $header = $self->model->list_meta_data('qlist');
    $self->{qlist}->add_columns($header);

    #--- Layout

    my $qlist_main_sz = Wx::FlexGridSizer->new( 3, 1, 0, 5 );

    my $qlist_top_sz = Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $page, -1, __ 'Query list', ), wxVERTICAL, );
    $qlist_top_sz->Add( -1, $self->{_gap} );

    $qlist_top_sz->Add( $self->{qlist}, 1, wxEXPAND, 3 );

    my $qlist_sizer = $self->_build_ctrls_querylist($page);

    my $qlist_bot_sz = Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $page, -1, __ 'Description', ), wxVERTICAL, );
    $qlist_bot_sz->Add( -1, $self->{_gap} );

    $qlist_bot_sz->Add( $self->{description}, 0, wxEXPAND );

    $qlist_main_sz->Add( $qlist_top_sz, 0, wxALL | wxGROW, 5 );
    $qlist_main_sz->Add( $qlist_sizer,  0, wxALL | wxGROW, 5 );
    $qlist_main_sz->Add( $qlist_bot_sz, 0, wxALL | wxGROW, 5 );

    $qlist_main_sz->AddGrowableRow(0);
    $qlist_main_sz->AddGrowableCol(0);

    $page->SetSizer($qlist_main_sz);

    return;
}

sub _build_page_info {
    my $self = shift;
    my $page = $self->{_nb}{p2};

    #--  Controls

    $self->{table_name}
        = Wx::TextCtrl->new( $page, -1, q{}, [ -1, -1 ], [ -1, -1 ], );
    $self->{table_name}
        ->SetBackgroundColour( Wx::Colour->new( 220, 220, 220 ) );
    $self->{table_name}
        ->SetForegroundColour( Wx::Colour->new( 100, 100, 250 ) );
    $self->{table_name}->SetEditable(0);

    # Fields table
    $self->model->init_data_table('tlist');
    my $dtt = $self->model->get_data_table_for('tlist');
    $self->{tlist} = QDepo::Wx::ListCtrl->new( $page, $dtt );
    my $header = $self->model->list_meta_data('tlist');
    $self->{tlist}->add_columns($header);

    # Info button
    $self->{btn_refr}
        = Wx::Button->new( $page, -1, __ 'Info', [ -1, -1 ], [ -1, 23 ], );
    $self->{btn_refr}->Enable(1);

    #-- Layout

    my $info_main_sz = Wx::FlexGridSizer->new( 3, 1, 0, 5 );

    my $info_top_sz = Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $page, -1, __ 'Table name' ), wxVERTICAL );
    $info_top_sz->Add( -1, $self->{_gap} );
    $info_top_sz->Add( $self->{table_name}, 0, wxTOP | wxEXPAND, 0 );

    my $info_mid_sz = Wx::BoxSizer->new(wxVERTICAL);
    $info_mid_sz->Add( $self->{btn_refr}, 0, wxTOP | wxEXPAND, 5 );
    $info_mid_sz->Add( -1, 5 );

    my $info_bot_sz = Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $page, -1, __ 'Fields' ), wxVERTICAL );
    $info_bot_sz->Add( -1, $self->{_gap} );
    $info_bot_sz->Add( $self->{tlist}, 1, wxEXPAND );

    $info_main_sz->Add( $info_top_sz, 1, wxALL | wxEXPAND, 5 );
    $info_main_sz->Add( $info_bot_sz, 1, wxALL | wxGROW,   5 );
    $info_main_sz->Add( $info_mid_sz, 1, wxALIGN_CENTRE );

    $info_main_sz->AddGrowableRow(1);
    $info_main_sz->AddGrowableCol(0);

    $page->SetSizer($info_main_sz);

    return;
}

sub _build_page_sql {
    my $self = shift;
    my $page = $self->{_nb}{p3};

    #--- SQL Tab (page)

    #-- Controls

    my $sql_sb = Wx::StaticBox->new( $page, -1, __ 'SQL', );
    $self->{sql} = QDepo::Wx::Editor->new($page);

    my $para_sizer = $self->_build_ctrls_parameter($page);

    #-- Layout

    my $sql_main_sz = Wx::BoxSizer->new(wxVERTICAL);
    my $sql_sbs = Wx::StaticBoxSizer->new( $sql_sb, wxVERTICAL, );
    $sql_sbs->Add( -1, $self->{_gap} );
    $sql_sbs->Add( $self->{sql}, 1, wxEXPAND, 0 );
    $sql_main_sz->Add( $sql_sbs,    1, wxALL | wxEXPAND, 5 );
    $sql_main_sz->Add( $para_sizer, 0, wxALL | wxEXPAND, 5 );

    $page->SetSizer($sql_main_sz);

    return;
}

sub _build_page_admin {
    my $self = shift;
    my $page = $self->{_nb}{p4};

    $self->model->init_data_table('dlist');
    my $dt = $self->model->get_data_table_for('dlist');
    $self->{dlist} = QDepo::Wx::ListCtrl->new( $page, $dt );

    my $header = $self->model->list_meta_data('dlist');
    $self->{dlist}->add_columns($header);

    #-- Button

    $self->{btn_load}
        = Wx::Button->new( $page, -1, __ '&Load', [ -1, -1 ], [ -1, 22 ], );
    $self->{btn_load}->Enable(0);

    $self->{btn_defa} = Wx::Button->new( $page, -1, __ '&Default', [ -1, -1 ],
        [ -1, 22 ], );
    $self->{btn_defa}->Enable(0);

    $self->{btn_edit}
        = Wx::Button->new( $page, -1, __ '&Edit', [ -1, -1 ], [ -1, 22 ], );
    $self->{btn_edit}->Enable(0);

    $self->{btn_add}
        = Wx::Button->new( $page, -1, __ '&Add', [ -1, -1 ], [ -1, 22 ], );

    #--- Layout

    my $conf_main_sz = Wx::FlexGridSizer->new( 3, 1, 0, 5 );

    #-- Top

    my $conf_top_sz = Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $page, -1, __ 'Connection', ), wxVERTICAL, );
    $conf_top_sz->Add( -1, $self->{_gap} );

    $conf_top_sz->Add( $self->{dlist}, 1, wxEXPAND, 3 );

    #-- Middle

    my $button_sz = Wx::BoxSizer->new(wxHORIZONTAL);
    $button_sz->Add( $self->{btn_load}, 0, wxLEFT | wxRIGHT | wxEXPAND, 5 );
    $button_sz->Add( $self->{btn_defa}, 0, wxLEFT | wxRIGHT | wxEXPAND, 5 );
    $button_sz->Add( $self->{btn_edit}, 0, wxLEFT | wxRIGHT | wxEXPAND, 5 );
    $button_sz->Add( $self->{btn_add},  0, wxLEFT | wxRIGHT | wxEXPAND, 5 );

    #-- Bottom

    my $conn_mid_sz = $self->_build_ctrls_conn($page);

    $conf_main_sz->Add( $conf_top_sz, 0, wxALL | wxGROW,         5 );
    $conf_main_sz->Add( $button_sz,   0, wxALIGN_CENTRE | wxALL, 5 );
    $conf_main_sz->Add( $conn_mid_sz, 0, wxALL | wxGROW,         5 );

    $conf_main_sz->AddGrowableRow(0);
    $conf_main_sz->AddGrowableCol(0);

    $page->SetSizer($conf_main_sz);

    return;
}

sub _build_ctrls_parameter {
    my ( $self, $page ) = @_;

    #-- Controls

    my $para_tit_lbl1 = Wx::StaticText->new( $page, -1, __ 'Label', );
    my $para_tit_lbl2 = Wx::StaticText->new( $page, -1, __ 'Description', );
    my $para_tit_lbl3 = Wx::StaticText->new( $page, -1, __ 'Value', );

    my $para_lbl1 = Wx::StaticText->new( $page, -1, 'value1', );
    $self->{descr1}
        = Wx::TextCtrl->new( $page, -1, q{}, [ -1, -1 ], [ 170, -1 ], );
    $self->{value1}
        = Wx::TextCtrl->new( $page, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $para_lbl2 = Wx::StaticText->new( $page, -1, 'value2', );
    $self->{descr2}
        = Wx::TextCtrl->new( $page, -1, q{}, [ -1, -1 ], [ 170, -1 ], );
    $self->{value2}
        = Wx::TextCtrl->new( $page, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $para_lbl3 = Wx::StaticText->new( $page, -1, 'value3', );
    $self->{descr3}
        = Wx::TextCtrl->new( $page, -1, q{}, [ -1, -1 ], [ 170, -1 ], );
    $self->{value3}
        = Wx::TextCtrl->new( $page, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    #-- Layout

    my $sizer = Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $page, -1, __ 'Parameters', ), wxHORIZONTAL, );

    my $para_fgs = Wx::FlexGridSizer->new( 4, 3, 5, 10 );

    $sizer->Add( $para_fgs, 1, wxEXPAND, 3 );
    $para_fgs->AddGrowableCol(2);

    $para_fgs->Add( $para_tit_lbl1, 0, wxTOP | wxLEFT, 10 );
    $para_fgs->Add( $para_tit_lbl2, 0, wxTOP | wxLEFT, 10 );
    $para_fgs->Add( $para_tit_lbl3, 0, wxTOP | wxLEFT, 10 );

    $para_fgs->Add( $para_lbl1,      0, wxTOP | wxLEFT,   5 );
    $para_fgs->Add( $self->{descr1}, 0, wxEXPAND | wxTOP, 5 );
    $para_fgs->Add( $self->{value1}, 1, wxEXPAND | wxTOP, 5 );

    $para_fgs->Add( $para_lbl2,      0, wxLEFT,   5 );
    $para_fgs->Add( $self->{descr2}, 1, wxEXPAND, 0 );
    $para_fgs->Add( $self->{value2}, 1, wxEXPAND, 0 );

    $para_fgs->Add( $para_lbl3,      0, wxLEFT,   5 );
    $para_fgs->Add( $self->{descr3}, 1, wxEXPAND, 0 );
    $para_fgs->Add( $self->{value3}, 1, wxEXPAND, 0 );

    return $sizer;
}

sub _build_ctrls_querylist {
    my ( $self, $page ) = @_;

    #-- Controls

    my $qlist_lbl1 = Wx::StaticText->new( $page, -1, __ 'Title', );
    $self->{title}
        = Wx::TextCtrl->new( $page, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $qlist_lbl2 = Wx::StaticText->new( $page, -1, __ 'Query file', );
    $self->{filename}
        = Wx::TextCtrl->new( $page, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $qlist_lbl3 = Wx::StaticText->new( $page, -1, __ 'Output file', );
    $self->{output}
        = Wx::TextCtrl->new( $page, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $qlist_lbl4 = Wx::StaticText->new( $page, -1, __ 'Template', );
    $self->{template}
        = Wx::TextCtrl->new( $page, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    $self->{description} = Wx::TextCtrl->new(
        $page, -1, q{},
        [ -1, -1 ],
        [ -1, 40 ],
        wxTE_MULTILINE,
    );

    #-- Layout

    my $sizer = Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $page, -1, __ 'Header' ), wxVERTICAL );
    $sizer->Add( -1, $self->{_gap} );

    my $fg_sizer = Wx::FlexGridSizer->new( 4, 2, 5, 10 );
    $fg_sizer->AddGrowableCol( 1, 1 );

    $fg_sizer->Add( $qlist_lbl1,    0, wxTOP | wxLEFT,   5 );
    $fg_sizer->Add( $self->{title}, 0, wxEXPAND | wxTOP, 5 );

    $fg_sizer->Add( $qlist_lbl2,       0, wxLEFT,   5 );
    $fg_sizer->Add( $self->{filename}, 0, wxEXPAND, 0 );

    $fg_sizer->Add( $qlist_lbl3,     0, wxLEFT,   5 );
    $fg_sizer->Add( $self->{output}, 0, wxEXPAND, 0 );

    $fg_sizer->Add( $qlist_lbl4,       0, wxLEFT,   5 );
    $fg_sizer->Add( $self->{template}, 0, wxEXPAND, 0 );

    $sizer->Add( $fg_sizer, 0, wxALL | wxGROW, 0 );

    return $sizer;
}

sub _build_ctrls_conn {
    my ( $self, $page ) = @_;

    #-- Controls

    my $conn_lbl1 = Wx::StaticText->new( $page, -1, __ 'Driver', );
    my @drivers = (qw{firebird sqlite cubrid postgresql mysql});
    $self->{driver} = Wx::ComboBox->new(
        $page, -1, q{},
        [ -1,  -1 ],
        [ 170, -1 ],
        \@drivers, wxCB_SORT | wxCB_READONLY,
    );

    my $conn_lbl2 = Wx::StaticText->new( $page, -1, __ 'Host', );
    $self->{host}
        = Wx::TextCtrl->new( $page, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $conn_lbl3 = Wx::StaticText->new( $page, -1, __ 'Database', );
    $self->{dbname}
        = Wx::TextCtrl->new( $page, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $conn_lbl4 = Wx::StaticText->new( $page, -1, __ 'Port', );
    $self->{port}
        = Wx::TextCtrl->new( $page, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    #-- Layout

    my $sizer
        = Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $page, -1, __ 'Connection details', ),
        wxVERTICAL );
    $sizer->Add( -1, $self->{_gap} );
    $sizer->Add( -1, 3 );

    my $conn_mid_fgs = Wx::FlexGridSizer->new( 4, 2, 5, 10 );
    $conn_mid_fgs->AddGrowableCol( 1, 1 );

    $conn_mid_fgs->Add( $conn_lbl1,      0, wxTOP | wxLEFT, 5 );
    $conn_mid_fgs->Add( $self->{driver}, 1, wxLEFT,         0 );

    $conn_mid_fgs->Add( $conn_lbl2,    0, wxLEFT,   5 );
    $conn_mid_fgs->Add( $self->{host}, 0, wxEXPAND, 0 );

    $conn_mid_fgs->Add( $conn_lbl3,      0, wxLEFT,   5 );
    $conn_mid_fgs->Add( $self->{dbname}, 0, wxEXPAND, 0 );

    $conn_mid_fgs->Add( $conn_lbl4,    0, wxLEFT,   5 );
    $conn_mid_fgs->Add( $self->{port}, 0, wxEXPAND, 0 );

    $sizer->Add( $conn_mid_fgs, 0, wxALL | wxGROW, 0 );

    return $sizer;
}

sub dialog_error {
    my ( $self, $message, $details ) = @_;

    Wx::MessageBox( "$message\n$details", __ 'Error', wxOK | wxICON_ERROR,
        $self );

    return;
}

sub action_confirmed {
    my ( $self, $msg ) = @_;

    my ($answer)
        = Wx::MessageBox( $msg, __ 'Confirm', wxYES_NO | wxCANCEL, undef, );

    my $return_answer
        = ( $answer == wxYES ) ? 'yes'
        : ( $answer == wxNO )     ? 'no'
        : ( $answer == wxCANCEL ) ? 'cancel'
        :                           'unknown';

    return $return_answer;
}

sub get_toolbar_btn {
    my ( $self, $name ) = @_;
    return $self->{_tb}->get_toolbar_btn($name);
}

sub get_choice_default {
    my $self = shift;
    return $self->{_tb}->get_choice_options(0);
}

sub get_control {
    my ( $self, $name ) = @_;
    return $self->{$name};
}

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

sub get_controls_info {
    my $self = shift;
    return [
        { table_name => [ $self->{table_name}, 'disabled', 'white', 'e' ] },
    ];
}

sub get_controls_para {
    my $self = shift;
    return [
        { descr1 => [ $self->{descr1}, 'normal', 'white', 'e' ] },
        { value1 => [ $self->{value1}, 'normal', 'white', 'e' ] },
        { descr2 => [ $self->{descr2}, 'normal', 'white', 'e' ] },
        { value2 => [ $self->{value2}, 'normal', 'white', 'e' ] },
        { descr3 => [ $self->{descr3}, 'normal', 'white', 'e' ] },
        { value3 => [ $self->{value3}, 'normal', 'white', 'e' ] },
    ];
}

sub get_controls_sql {
    my $self = shift;
    return [ { sql => [ $self->{sql}, 'normal', 'white', 's' ] }, ];
}

sub get_controls_admin {
    my $self = shift;
    return [
        { driver => [ $self->{driver}, 'normal', 'white', 'c' ] },
        { host   => [ $self->{host},   'normal', 'white', 'e' ] },
        { dbname => [ $self->{dbname}, 'normal', 'white', 'e' ] },
        { port   => [ $self->{port},   'normal', 'white', 'e' ] },
    ];
}

sub get_list_max_index {
    my ( $self, $lname ) = @_;
    return ( $self->get_control($lname)->GetItemCount() - 1 );
}

sub log_config_options {
    my $self = shift;
    my $path = $self->cfg->output;
    while ( my ( $key, $value ) = each( %{$path} ) ) {
        $self->log_msg("II Config: '$key' set to '$value'");
    }
    return;
}

sub querylist_form_clear {
    my $self = shift;
    $self->controls_write_onpage( 'list', {} );
    $self->controls_write_onpage( 'para', {} );
    $self->controls_write_onpage( 'sql',  { sql => q{} } );
    return;
}

sub querylist_form_populate {
    my $self = shift;

    #-- Header
    my $data = {};
    $data->{title}       = $self->model->itemdata->title;
    $data->{filename}    = $self->model->itemdata->filename;
    $data->{output}      = $self->model->itemdata->output;
    $data->{description} = $self->model->itemdata->descr;
    $self->controls_write_onpage( 'list', $data );

    #-- Parameters
    my $para = QDepo::Utils->params_to_hash( $self->model->itemdata->params );
    $self->controls_write_onpage( 'para', $para );

    #-- SQL
    $self->controls_write_onpage( 'sql',
        { sql => $self->model->itemdata->sql } );

    return;
}

sub toggle_sql_replace {
    my ( $self, $mode ) = @_;
    $mode ||= $self->model->get_appmode;
    my $data = $self->model->read_qdf_data_file;
    if ( $mode eq 'edit' ) {
        $self->control_set_value( 'sql', $data->{body}{sql} );
    }
    elsif ( $mode eq 'sele' ) {
        my $para = QDepo::Utils->params_to_hash( $data->{parameters} );
        $self->control_replace_sql_text( $data->{body}{sql}, $para );
    }
    return;
}

sub control_replace_sql_text {
    my ( $self, $sqltext, $params ) = @_;
    my ($newtext) = $self->model->string_replace_pos( $sqltext, $params );
    $self->control_set_value( 'sql', $newtext );
    return;
}

sub log_msg {
    my ( $self, $message ) = @_;
    my $control = $self->get_control('log');
    $self->control_write_s( $control, $message, 'append' );
    $control->LineScrollDown;
    return;
}

sub set_status {
    my ( $self, $text, $sb_id, $color ) = @_;
    my $sb = $self->get_statusbar();
    if ( $sb_id eq q{db} ) {
        $sb->PushStatusText( $text, 2 ) if defined $text;    # database name
    }
    elsif ( $sb_id eq q{mn} ) {
        $sb->PushStatusText( $text, 3 ) if defined $text;    # mnemonic
    }
    elsif ( $sb_id eq q{ms} ) {
        $sb->PushStatusText( $text, 0 ) if defined $text;    # messages
    }
    else {
        $sb->PushStatusText( $text, 1 ) if defined $text;    # app status
    }
    return;
}

sub toggle_status_cn {
    my ( $self, $status ) = @_;
    if ($status) {
        my $user = $self->cfg->connection->user || q{};
        my $db = $self->cfg->connection->dbname;
        return unless $db;
        $db =~ s{\A                          # from the start of the string
                    .*                       # replace anything
                    (\\|/)                   # folowed by a \ or a /
                }{}x;
        $self->set_status( "${user}\@${db}", 'db', 'darkgreen' );
    }
    else {
        $self->set_status( 'Not connected', 'db', 'red' );
    }
    return;
}

sub dialog_progress {
    my ( $self, $title, $max ) = @_;
    $max = ( defined $max and $max > 0 ) ? $max : 100;    # default 100
    require QDepo::Wx::Dialog::Progress;
    $self->{progress}
        = QDepo::Wx::Dialog::Progress->new( $self, $title, $max );
    $self->{progress}->Destroy;
    return;
}

sub progress_update {
    my ( $self, $count ) = @_;
    return if !$count;
    if ( defined $self->{progress}
        and $self->{progress}->isa('QDepo::Wx::Dialog::Progress') )
    {
        my $continue = $self->{progress}->update($count);
        $self->model->set_continue($continue);
    }
    return;
}

sub control_set_value {
    my ( $self, $name, $value ) = @_;
    $value ||= q{};    # empty
    my $control = $self->get_control($name);
    $self->control_write_s( $control, $value );
    return;
}

sub controls_write_onpage {
    my ( $self, $page, $data ) = @_;
    my $get      = "get_controls_$page";
    my $controls = $self->$get();
    foreach my $control ( @{$controls} ) {
        foreach my $name ( keys %{$control} ) {
            my $value = $data->{$name};
            if ( defined $value ) {
                $value =~ s/\n$//xmg;    # remove trailing newline
            }
            else {
                $value = q{};            # make empty string
            }
            $self->control_write( $control, $name, $value );
        }
    }
    return;
}

sub control_write {
    my ( $self, $control, $name, $value, $state ) = @_;
    my $ctrltype = $control->{$name}[3];
    my $sub_name = qq{control_write_$ctrltype};
    if ( $self->can($sub_name) ) {
        $self->$sub_name( $control->{$name}[0], $value, $state );
    }
    else {
        warn "WW: No '$ctrltype' ctrl type for writing '$name'!\n";
    }
    return;
}

sub control_write_e {
    my ( $self, $control, $value ) = @_;
    $control->Clear;
    $control->SetValue($value) if defined $value;
    return;
}

sub control_write_s {
    my ( $self, $control, $value, $is_append ) = @_;
    $value //= q{};    # empty not undef
    my $readonly = $control->GetReadOnly;
    $control->SetReadOnly(0);
    $control->ClearAll unless $is_append;
    if ($value) {
        $control->AppendText($value);
        $control->AppendText("\n");
    }
    $control->Colourise( 0, $control->GetTextLength );
    $control->SetReadOnly($readonly);
    return;
}

sub control_write_c {
    my ( $self, $control, $value ) = @_;
    $control->SetValue($value);
    return;
}

sub controls_read_frompage {
    my ( $self, $page ) = @_;
    my $get      = "get_controls_$page";
    my $controls = $self->$get();
    my @records;
    foreach my $control ( @{$controls} ) {
        foreach my $name ( keys %{$control} ) {
            my $value = $self->control_read( $control, $name );
            push( @records, { $name => $value } ) if ( $name and $value );
        }
    }
    return \@records;
}

sub control_read {
    my ( $self, $control, $name ) = @_;
    my $ctrltype = $control->{$name}[3];
    my $sub_name = qq{control_read_$ctrltype};
    return $self->$sub_name( $control->{$name}[0] ) if $self->can($sub_name);
    croak "WW: No '$ctrltype' ctrl type for reading '$name'!\n";
}

sub control_read_e {
    my ( $self, $control ) = @_;
    return $control->GetValue;
}

sub control_read_s {
    my ( $self, $control ) = @_;
    return $control->GetText;
}

sub control_read_c {
    my ( $self, $control ) = @_;
    return $control->GetValue;
}

sub toggle_list_enable {
    my ( $self, $lname, $state ) = @_;
    $self->get_control($lname)->Enable($state);
    return;
}

sub set_editable {
    my ( $self, $control_ref, $name, $state, $color ) = @_;

    # Controls states are defined in View as strings
    # Here we need to transform them to 0|1
    my $editable = $state eq 'normal' ? 1 : 0;
    my $readonly = $state eq 'normal' ? 0 : 1;
    $color = 'lightgrey' unless $editable;    # default color for disabled

    my $control  = $control_ref->{$name}[0];
    my $ctrltype = $control_ref->{$name}[3];

    $control->Enable($editable)      if $ctrltype eq 'c';
    $control->SetEditable($editable) if $ctrltype eq 'e';
    $control->SetReadOnly($readonly) if $ctrltype eq 's';

    $control->SetBackgroundColour( Wx::Colour->new($color) ) if $color;

    return;
}

sub event_handler_for_menu {
    my ( $self, $name, $calllback ) = @_;
    my $menu_id = $self->get_menu_popup_item($name)->GetId;
    EVT_MENU $self, $menu_id, $calllback;
    return;
}

sub event_handler_for_tb_button {
    my ( $self, $name, $calllback ) = @_;
    my $tb_id = $self->get_toolbar_btn($name)->GetId;
    EVT_TOOL $self, $tb_id, $calllback;
    return;
}

sub event_handler_for_tb_choice {
    my ( $self, $name, $calllback ) = @_;
    my $tb_id = $self->get_toolbar_btn($name)->GetId;
    EVT_CHOICE $self, $tb_id, $calllback;
    return;
}

sub event_handler_for_list {
    my ( $self, $name, $calllback ) = @_;
    EVT_LIST_ITEM_SELECTED $self, $self->get_control($name), $calllback;
    return;
}

sub event_handler_for_button {
    my ( $self, $name, $calllback ) = @_;
    EVT_BUTTON( $self, $self->{$name}, $calllback );
    return;
}

sub on_close_window {
    my ( $self, ) = @_;
    $self->Destroy;
    return;
}

sub refresh_list {
    my ( $self, $name ) = @_;
    croak "List name is required for 'refresh_list'" unless $name;
    $self->{$name}->RefreshList;
    return;
}

sub focus_list {
    my ( $self, $name ) = @_;
    croak "List name is required for 'focus_list'" unless $name;
    $self->{$name}->SetFocus;
    return;
}

sub select_list_item {
    my ( $self, $lname, $what ) = @_;

    return unless defined $what;    # required if invalid mnemonic
    croak "List name is required for 'refresh_list'" unless $lname;

    my $items_no = $self->{$lname}->GetItemCount;
    return if $items_no == 0;       # nothing to select

    my $item;
    if ( looks_like_number($what) ) {
        $item = $what;
    }
    else {
        $item
            = $what eq 'first' ? 0
            : $what eq 'last'  ? ( $items_no - 1 )
            : $what                 # default
            ;
    }
    $self->{$lname}->Select( $item, 1 );    # 1|0 = select|deselect
    $self->{$lname}->EnsureVisible($item);
    return $item;
}

1;

=head2 new

Constructor method.

=head2 model

Return model instance

=head2 cfg

Return config instance variable

=head2 _set_model_callbacks

Define the model callbacks

=head2 update_gui_components

When the application status (mode) changes, update gui components. Screen
controls (widgets) are not handled here, but in the controller module.

=head2 _build_menu

Create the menubar and the menus. Menus are defined in configuration files.

=head2 make_menus

Make menus.

=head2 get_app_menus_list

Get application menus list, needed for binding the command to load the screen. 
We only need the name of the popup which is also the name of the screen (and
also the name of the module).

=head2 make_popup_item

Make popup item

=head2 get_menu_popup_item

Return a menu popup by name

=head2 get_menubar

Return the menu bar handler

=head2 _build_toolbar

Create the toolbar.

=head2 enable_tool

Enable|disable tool bar button.

State can come as 0|1 and normal|disabled.

=head2 _build_statusbar

Create the status bar

=head2 get_statusbar

Return the status bar handler

=head2 get_notebook

Return the notebook handler

=head2 _build_page_querylist

Create the report page (tab) on the notebook

=head2 _build_page_sql

Create the SQL page (tab) on the notebook

=head2 _build_page_admin

Create the administration page (tab) on the notebook.

Using the MySQL lexer for very basic syntax highlighting. This was chosen
because permits the definition of 3 custom lists. For this purpose three key
word lists are defined with a keyword in each. B<EE> is for error, B<II> for
information and B<WW> for warning. Words in the lists must be lower case.

=head2 dialog_error

Error message dialog.

=head2 action_confirmed

Yes, No, Cancel message dialog.

=head2 get_toolbar_btn

Return a toolbar button by name.

=head2 get_choice_default

Return the choice default option, the first element in the array.

=head2 get_control

Return the control instance object.

=head2 get_controls_list

Return a AoH with information regarding the controls from the list page.

=head2 get_controls_para

Return a AoH with information regarding the controls from the parameters page.

=head2 get_controls_sql

Return a AoH with information regarding the controls from the SQL page.

=head2 get_controls_admin

Return a AoH with information regarding the connection controls.

=head2 get_list_max_index

Return the maximum index from the list control (item count - 1).

=head2 log_config_options

Log configuration options with data from the Config module

=head2 querylist_form_populate

Populate form controls with data from the qdf file.

=head2 toggle_sql_replace

Toggle sql replace

=head2 control_replace_sql_text

Replace sql text control

=head2 log_msg

Set log message

=head2 set_status

Set status message.

Color is ignored for wxPerl.

=head2 toggle_status_cn

Toggle the icon in the status bar

=head2 dialog_progress

Create a progress dialog.

=head2 progress_update

Update progress.  If I<Cancel> is pressed, stop (set continue to false) from
the return value of the Update method of L<Wx::ProgressDialog>.

=head2 control_set_value

Set new value for a controll.

=head2 controls_write_onpage

Write all controls on page with data

=head2 control_write

Run the appropriate sub according to control (entry widget) type.

=head2 control_write_e

Write to a Entry control.

=head2 control_write_s

Write to a Wx::StyledTextCtrl.

=head2 control_write_c

Write to a Wx::ComboBox.

=head2 controls_read_frompage

Read all controls and return an array reference.

=head2 on_close_window

Destroy the window.

=cut
