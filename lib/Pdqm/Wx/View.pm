package Pdqm::Wx::View;

use strict;
use warnings;

use Data::Dumper;

use Wx qw[:everything];
use Wx::Perl::ListCtrl;
# use Wx::Event  qw[:everything];

use Pdqm::Wx::Notebook;
use Pdqm::Wx::ToolBar;

use base 'Wx::Frame';

sub new {
    my $class = shift;
    my $model = shift;

    #- The Frame

    my $self = __PACKAGE__->SUPER::new( @_ );

    Wx::InitAllImageHandlers();

    $self->{_model} = $model;

    $self->SetMinSize( Wx::Size->new( 425, 597 ) );
    $self->SetIcon( Wx::GetWxPerlIcon() );

    #-- Menu
    $self->create_menu();

    #-- ToolBar
    $self->SetToolBar( Pdqm::Wx::ToolBar->new( $self, wxADJUST_MINSIZE ) );
    $self->{_tb} = $self->GetToolBar;
    $self->{_tb}->Realize;

    #-- Statusbar
    $self->create_statusbar();

    #-- Notebook
    $self->{_nb} = Pdqm::Wx::Notebook->new( $self );

    #--- Parameters Tab (page) Panel
    $self->create_para_page();

    #--- SQL Tab (page)
    $self->create_sql_page();

    #--- Configs Tab (page)
    $self->create_config_page();

    #--- Front Tab (page)
    $self->create_report_page();

    $self->_set_model_callbacks();

    return $self;
}

sub _model {
    my $self = shift;

    $self->{_model};
}

sub _set_model_callbacks {
    my $self = shift;

    my $tb = $self->get_toolbar();
    my $co = $self->_model->get_connection_observable;
    $co->add_callback( sub { $tb->ToggleTool( 1001, $_[0] ) } );
    #--
    # my $so = $self->_model->get_stdout_observable;
    # $so->add_callback( sub{ $self->log_msg( $_[0] ) } );
    #--
    #  my $ro = $self->_model->get_updated_observable;
    # $ro->add_callback( sub { $self->list_populate_all;
    #                          $self->get_updated_observable->set( 0 );
    #                      } );
}

sub create_menu {
    my $self = shift;

    my $menu = Wx::MenuBar->new;

    $self->{_menu} = $menu;

    my $menu_app = Wx::Menu->new;
    $menu_app->Append( wxID_EXIT, "E&xit\tAlt+X" );
    $menu->Append( $menu_app, "&App" );

    my $menu_help = Wx::Menu->new();
    $menu_help->AppendString( wxID_HELP, "&Contents...", "" );
    $menu_help->AppendString( wxID_ABOUT, "&About", "" );
    $menu->Append( $menu_help, "&Help" );

    $self->SetMenuBar($menu);
}

sub get_menubar {
    my $self = shift;
    return $self->{_menu};
}

sub create_statusbar {
    my $self = shift;

    my $sb = $self->CreateStatusBar( 3 );
    $self->{_stbar} = $sb;

    $self->SetStatusWidths( 260, -1, -2 );
}

sub get_notebook {
    my $self = shift;

    return $self->{_nb};
}

sub create_report_page {
    my $self = shift;

    $self->{_list} = Wx::Perl::ListCtrl->new(
        $self->{_nb}{p1}, -1,
        [ -1, -1 ],
        [ -1, -1 ],
        Wx::wxLC_REPORT | Wx::wxLC_SINGLE_SEL,
    );

    $self->{_list}->InsertColumn( 0, '#',           wxLIST_FORMAT_LEFT, 50  );
    $self->{_list}->InsertColumn( 1, 'Report name', wxLIST_FORMAT_LEFT, 337 );

    #-- Controls

    my $repo_lbl1 = Wx::StaticText->new( $self->{_nb}{p1}, -1, 'Title', );
    $self->{title} =
      Wx::TextCtrl->new( $self->{_nb}{p1}, -1, "", [ -1, -1 ], [ -1, -1 ], );

    my $repo_lbl2 = Wx::StaticText->new( $self->{_nb}{p1}, -1, 'Report file', );
    $self->{filename} =
        Wx::TextCtrl->new( $self->{_nb}{p1}, -1, "", [ -1, -1 ], [ -1, -1 ], );

    my $repo_lbl3 = Wx::StaticText->new( $self->{_nb}{p1}, -1, 'Output file', );
    $self->{output} =
      Wx::TextCtrl->new( $self->{_nb}{p1}, -1, "", [ -1, -1 ], [ -1, -1 ], );

    my $repo_lbl4 = Wx::StaticText->new( $self->{_nb}{p1}, -1, 'Sheet name', );
    $self->{sheet} =
      Wx::TextCtrl->new( $self->{_nb}{p1}, -1, "", [ -1, -1 ], [ -1, -1 ], );

    $self->{description} =
      Wx::TextCtrl->new( $self->{_nb}{p1}, -1, '', [ -1, -1 ], [ -1, 40 ],
        wxTE_MULTILINE, );

    #--- Layout

    my $repo_main_sz = Wx::FlexGridSizer->new( 4, 1, 5, 5 );

    #-- Top

    my $repo_top_sz =
      Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $self->{_nb}{p1}, -1, ' Report list ', ), wxVERTICAL,
      );

    $repo_top_sz->Add( $self->{_list}, 1, wxEXPAND, 3 );

    #-- Middle

    my $repo_mid_sz =
      Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $self->{_nb}{p1}, -1, ' Header ', ), wxVERTICAL, );

    my $repo_mid_fgs = Wx::FlexGridSizer->new( 4, 2, 5, 10 );

    $repo_mid_fgs->Add( $repo_lbl1, 0, wxTOP | wxLEFT,   5 );
    $repo_mid_fgs->Add( $self->{title},    1, wxEXPAND | wxTOP, 5 );

    $repo_mid_fgs->Add( $repo_lbl2, 0, wxLEFT,   5 );
    $repo_mid_fgs->Add( $self->{filename},    1, wxEXPAND, 0 );

    $repo_mid_fgs->Add( $repo_lbl3, 0, wxLEFT,   5 );
    $repo_mid_fgs->Add( $self->{output},    1, wxEXPAND, 0 );

    $repo_mid_fgs->Add( $repo_lbl4, 0, wxLEFT,   5 );
    $repo_mid_fgs->Add( $self->{sheet},    0, wxEXPAND, 0 );

    $repo_mid_fgs->AddGrowableRow( 1, 1 );
    $repo_mid_fgs->AddGrowableCol( 1, 1 );

    $repo_mid_sz->Add( $repo_mid_fgs, 0, wxALL | wxGROW, 0 );

    #-- Bottom

    my $repo_bot_sz = Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $self->{_nb}{p1}, -1, ' Description ', ), wxVERTICAL,
    );

    $repo_bot_sz->Add( $self->{description}, 1, wxEXPAND );

    #--

    $repo_main_sz->Add( $repo_top_sz, 0, wxALL | wxGROW, 5 );
    $repo_main_sz->Add( $repo_mid_sz, 0, wxALL | wxGROW, 5 );
    $repo_main_sz->Add( $repo_bot_sz, 0, wxALL | wxGROW, 5 );

    $repo_main_sz->AddGrowableRow(0);
    $repo_main_sz->AddGrowableCol(0);

    $self->{_nb}{p1}->SetSizer($repo_main_sz);
}

sub create_para_page {

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
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, "", [ -1, -1 ], [ 170, -1 ], );
    $self->{value1} =
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, "", [ -1, -1 ], [ -1, -1 ], );

    my $para_lbl2 = Wx::StaticText->new( $self->{_nb}{p2}, -1, 'value2', );
    $self->{descr2} =
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, "", [ -1, -1 ], [ 170, -1 ], );
    $self->{value2} =
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, "", [ -1, -1 ], [ -1, -1 ], );

    my $para_lbl3 = Wx::StaticText->new( $self->{_nb}{p2}, -1, 'value3', );
    $self->{descr3} =
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, "", [ -1, -1 ], [ 170, -1 ], );
    $self->{value3} =
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, "", [ -1, -1 ], [ -1, -1 ], );

    my $para_lbl4 = Wx::StaticText->new( $self->{_nb}{p2}, -1, 'value4', );
    $self->{descr4} =
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, "", [ -1, -1 ], [ 170, -1 ], );
    $self->{value4} =
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, "", [ -1, -1 ], [ -1, -1 ], );

    my $para_lbl5 = Wx::StaticText->new( $self->{_nb}{p2}, -1, 'value5', );
    $self->{descr5} =
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, "", [ -1, -1 ], [ 170, -1 ], );
    $self->{value5} =
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, "", [ -1, -1 ], [ -1, -1 ], );

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

sub create_sql_page {
    my $self = shift;

    #--- SQL Tab (page)

    #-- Controls

    my $sql_sb = Wx::StaticBox->new( $self->{_nb}{p3}, -1, ' SQL ', );

    $self->{sql} = Wx::TextCtrl->new(
        $self->{_nb}{p3}, -1, '',
        [ -1, -1 ],
        [ -1, -1 ],
        wxTE_MULTILINE,
    );

    #-- Layout

    my $sql_main_sz = Wx::BoxSizer->new(wxVERTICAL);
    my $sql_sbs = Wx::StaticBoxSizer->new( $sql_sb, wxHORIZONTAL, );

    $sql_sbs->Add( $self->{sql},      1, wxEXPAND,         0 );
    $sql_main_sz->Add( $sql_sbs, 1, wxALL | wxEXPAND, 5 );

    $self->{_nb}{p3}->SetSizer( $sql_main_sz );
}

sub create_config_page {
    my $self = shift;

    #-- Controls

    my $cnf_lbl0 = Wx::StaticText->new(
        $self->{_nb}{p4},
        -1,
        'Report definition files extension',
    );
    $self->{cnf_tc0} = Wx::TextCtrl->new(
        $self->{_nb}{p4},
        -1,
        q{},
        [ -1, -1 ],
        [ 170, -1 ],
    );

    my $cnf_lbl1 = Wx::StaticText->new(
        $self->{_nb}{p4},
        -1,
        'Report definition files directory',
    );
    $self->{cnf_tc1} = Wx::TextCtrl->new(
        $self->{_nb}{p4},
        -1,
        q{},
        [ -1, -1 ],
        [ 170, -1 ],
    );

    my $cnf_lbl2 = Wx::StaticText->new(
        $self->{_nb}{p4},
        -1,
        q{Output files path (relative to user's home directory)},
    );
    $self->{cnf_tc2} = Wx::TextCtrl->new(
        $self->{_nb}{p4},
        -1,
        q{},
        [ -1, -1 ],
        [ 170, -1 ],
    );

    my $cnf_lbl3 = Wx::StaticText->new(
        $self->{_nb}{p4},
        -1,
        'Template file name',
    );
    $self->{cnf_tc3} = Wx::TextCtrl->new(
        $self->{_nb}{p4},
        -1,
        q{},
        [ -1, -1 ],
        [ 170, -1 ],
    );

    my $cnf_fgs = Wx::FlexGridSizer->new( 8, 1, 5, 10 );

    $cnf_fgs->Add( $cnf_lbl0, 0, wxTOP | wxLEFT, 5 );
    $cnf_fgs->Add( $self->{cnf_tc0}, 1, wxEXPAND, 0 );

    $cnf_fgs->Add( $cnf_lbl1, 0, wxLEFT, 5 );
    $cnf_fgs->Add( $self->{cnf_tc1}, 1, wxEXPAND, 0 );

    $cnf_fgs->Add( $cnf_lbl2, 0, wxLEFT,   5 );
    $cnf_fgs->Add( $self->{cnf_tc2}, 1, wxEXPAND, 0 );

    $cnf_fgs->Add( $cnf_lbl3, 0, wxLEFT,   5 );
    $cnf_fgs->Add( $self->{cnf_tc3}, 1, wxEXPAND, 0 );

    $cnf_fgs->AddGrowableCol(0);

    my $cnf_main_sz = Wx::BoxSizer->new(wxHORIZONTAL);

    my $top_sz_p4 =
        Wx::StaticBoxSizer->new(
            Wx::StaticBox->new( $self->{_nb}{p4}, -1, ' Configurations ', ),
            wxVERTICAL, );

    $top_sz_p4->Add( $cnf_fgs, 0, wxEXPAND, 3 );
    $cnf_main_sz->Add( $top_sz_p4, 1, wxALL | wxGROW, 5 );

    $self->{_nb}{p4}->SetSizer( $cnf_main_sz );
}

sub popup {
    my ( $self, $msgtype, $msg ) = @_;
    if ( $msgtype eq 'Error' ) {
        Wx::MessageBox( $msg, $msgtype, wxOK|wxICON_ERROR, $self )
    }
    elsif ( $msgtype eq 'Warning' ) {
        Wx::MessageBox( $msg, $msgtype, wxOK|wxICON_WARNING, $self )
    }
    else {
        Wx::MessageBox( $msg, $msgtype, wxOK|wxICON_INFORMATION, $self )
    }
}

sub get_conn_btn {
    my $self = shift;
    return 1001;
}

sub get_save_btn {
    my $self = shift;
    return 1002; # _save_btn how to get save tb button id ?
}

sub get_refr_btn {
    my $self = shift;
    return 1003;
}

sub get_edit_btn {
    my $self = shift;
    return 1006;
}

sub get_run_btn {
    my $self = shift;
    return 1008;
}

sub get_exit_btn {
    my $self = shift;
    return 1009;
}

sub get_toolbar {
    my ($self) = @_;
    return $self->{_tb};
}

sub get_listcontrol {
    my ($self) = @_;
    return $self->{_list};
}

#- next ListCtrl

sub get_list_text {
    my ($self, $row, $col) = @_;
    return $self->get_listcontrol->GetItemText( $row, $col );
}

sub set_list_text {
    my ($self, $row, $col, $text) = @_;
    $self->get_listcontrol->SetItemText( $row, $col, $text );
}

sub set_list_data {
    my ($self, $item, $data_href) = @_;
    $self->get_listcontrol->SetItemData( $item, $data_href );
}

sub get_list_data {
    my ($self, $item) = @_;
    return $self->get_listcontrol->GetItemData( $item );
}

sub list_item_select_first {
    my ($self) = @_;

    my $items_no = $self->get_listcontrol->GetItemCount;

    if ( $items_no > 0 ) {
        $self->get_listcontrol->Select(0, 1);
    }
}

sub list_item_select_last {
    my ($self, $indice) = @_;

    $self->get_listcontrol->Select($indice, 1);
    $self->get_listcontrol->EnsureVisible($indice);
}

sub get_list_max_index {
    my ($self) = @_;
    return $self->get_listcontrol->GetItemCount();
}

sub list_item_insert {
    my ( $self, $indice, $nrcrt, $title, $file ) = @_;

    # Remember, always sort by index before insert!
    $self->list_string_item_insert($indice);
    $self->set_list_text($indice, 0, $nrcrt);
    $self->set_list_text($indice, 1, $title);
    # Set data
    $self->set_list_data($indice, $file );
}

sub list_string_item_insert {
    my ($self, $indice) = @_;
    $self->get_listcontrol->InsertStringItem( $indice, 'dummy' );
}

sub list_item_clear {
    my ($self, $item) = @_;
    $self->get_listcontrol->DeleteItem($item);
}

sub list_item_clear_all {
    my ($self) = @_;
    $self->get_listcontrol->DeleteAllItems;
}

sub list_populate_all {

    my ($self) = @_;

    my $titles = $self->_model->get_list_data();

    # Clear list
    $self->list_item_clear_all();

    # Populate list in sorted order
    my @titles = sort { $a <=> $b } keys %{$titles};
    foreach my $indice ( @titles ) {
        my $nrcrt = $titles->{$indice}[0];
        my $title = $titles->{$indice}[1];
        my $file  = $titles->{$indice}[2];
        print "$nrcrt -> $title\n";
        $self->list_item_insert($indice, $nrcrt, $title, $file);
    }

    # Set item 0 selected on start
    $self->list_item_select_first();
}

#-- End Perl ListCtrl subs

1;
