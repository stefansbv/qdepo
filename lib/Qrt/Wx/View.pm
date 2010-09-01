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
# |                                                   p a c k a g e   V i e w |
# +---------------------------------------------------------------------------+
package Qrt::Wx::View;

use strict;
use warnings;

use Data::Dumper;

use Wx qw[:everything];
use Wx::Perl::ListCtrl;
# use Wx::Event  qw[:everything];

use Qrt::Config;
use Qrt::Wx::Notebook;
use Qrt::Wx::ToolBar;

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
    $self->SetToolBar( Qrt::Wx::ToolBar->new( $self, wxADJUST_MINSIZE ) );
    $self->{_tb} = $self->GetToolBar;
    $self->{_tb}->Realize;

    #-- Statusbar
    $self->create_statusbar();

    #-- Notebook
    $self->{_nb} = Qrt::Wx::Notebook->new( $self );

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
    #-
    my $co = $self->_model->get_connection_observable;
    $co->add_callback(
        sub { $tb->ToggleTool( $self->get_toolbar_btn_id('tb_cn'), $_[0] ) } );
    #--
    my $em = $self->_model->get_editmode_observable;
    $em->add_callback(
        sub {
            $tb->ToggleTool( $self->get_toolbar_btn_id('tb_ed'), $_[0] );
            $self->toggle_sql_highlight();
        }
    );
    #--
    my $upd = $self->_model->get_itemchanged_observable;
    $upd->add_callback(
        sub { $self->controls_populate(); } );
    #--
    my $so = $self->_model->get_stdout_observable;
    #$so->add_callback( sub{ $self->log_msg( $_[0] ) } );
    $so->add_callback( sub{ $self->status_msg( @_ ) } );
}

sub create_menu {
    my $self = shift;

    my $menu = Wx::MenuBar->new;

    $self->{_menu} = $menu;

    my $menu_app = Wx::Menu->new;
    $menu_app->Append( wxID_EXIT, "E&xit\tAlt+X" );
    $menu->Append( $menu_app, "&App" );

    my $menu_help = Wx::Menu->new();
    $menu_help->AppendString( wxID_HELP, "&Contents...", q{} );
    $menu_help->AppendString( wxID_ABOUT, "&About", q{} );
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
    $self->{_sb} = $sb;

    $self->SetStatusWidths( 260, -1, -2 );
}

sub get_statusbar {
    my $self = shift;

    return $self->{_sb};
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

    my $repo_lbl4 = Wx::StaticText->new( $self->{_nb}{p1}, -1, 'Sheet name', );
    $self->{sheet} =
        Wx::TextCtrl->new( $self->{_nb}{p1}, -1, q{}, [ -1, -1 ], [ -1, 28 ], );

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

sub create_sql_page {
    my $self = shift;

    #--- SQL Tab (page)

    #-- Controls

    my $sql_sb = Wx::StaticBox->new( $self->{_nb}{p3}, -1, ' SQL ', );

    $self->{sql} = Wx::TextCtrl->new(
        $self->{_nb}{p3}, -1, q{},
        [ -1, -1 ],
        [ -1, -1 ],
        wxTE_MULTILINE | wxTE_RICH2,
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

    my $cnf_lbl1 = Wx::StaticText->new(
        $self->{_nb}{p4},
        -1,
        q{Output files path},
    );
    $self->{path} = Wx::TextCtrl->new(
        $self->{_nb}{p4},
        -1,
        q{},
        [ -1, -1 ],
        [ 170, -1 ],
    );

    my $cnf_fgs = Wx::FlexGridSizer->new( 2, 1, 5, 10 );

    $cnf_fgs->Add( $cnf_lbl1, 0, wxTOP | wxLEFT, 5 );
    $cnf_fgs->Add( $self->{path}, 1, wxEXPAND, 0 );

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

sub dialog_popup {
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

sub get_toolbar_btn_id {
    my ($self, $name) = @_;

    return $self->{_tb}{_tb_btn}{$name};
}

sub get_toolbar {
    my $self = shift;
    return $self->{_tb};
}

sub get_choice_options_default {
    my $self = shift;

    return $self->{_tb}->get_choice_options(0);
}

sub get_listcontrol {
    my $self = shift;
    return $self->{_list};
}

sub get_controls_list {
    my $self = shift;

    return [
        { title       => [ $self->{title}      , 'normal'  , 'white'     ] },
        { filename    => [ $self->{filename}   , 'disabled', 'lightgrey' ] },
        { output      => [ $self->{output}     , 'normal'  , 'white'     ] },
        { sheet       => [ $self->{sheet}      , 'normal'  , 'white'     ] },
        { description => [ $self->{description}, 'normal'  , 'white'     ] },
    ];
}

sub get_controls_para {
    my $self = shift;

    return [
        { descr1 => [ $self->{descr1}, 'normal'  , 'white' ] },
        { value1 => [ $self->{value1}, 'normal'  , 'white' ] },
        { descr2 => [ $self->{descr2}, 'normal'  , 'white' ] },
        { value2 => [ $self->{value2}, 'normal'  , 'white' ] },
        { descr3 => [ $self->{descr3}, 'normal'  , 'white' ] },
        { value3 => [ $self->{value3}, 'normal'  , 'white' ] },
        { descr4 => [ $self->{descr4}, 'normal'  , 'white' ] },
        { value4 => [ $self->{value4}, 'normal'  , 'white' ] },
        { descr5 => [ $self->{descr5}, 'normal'  , 'white' ] },
        { value5 => [ $self->{value5}, 'normal'  , 'white' ] },
    ];
}

sub get_controls_sql {
    my $self = shift;

    return [
        { sql => [ $self->{sql}, 'normal'  , 'white' ] },
    ];
}

sub get_controls_conf {
    my $self = shift;

    return [
        { path => [ $self->{path}, 'disabled', 'lightgrey' ] },
    ];
}

sub get_control_by_name {
    my ($self, $name) = @_;

    return $self->{$name},
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

    my $items_no = $self->get_list_max_index();

    if ( $items_no > 0 ) {
        $self->get_listcontrol->Select(0, 1);
    }
}

sub list_item_select_last {
    my ($self) = @_;

    my $items_no = $self->get_list_max_index();
    my $idx = $items_no - 1;
    $self->get_listcontrol->Select( $idx, 1 );
    $self->get_listcontrol->EnsureVisible($idx);
}

sub get_list_max_index {
    my ($self) = @_;
    return $self->get_listcontrol->GetItemCount();
}

sub get_list_selected_index {
    my ($self) = @_;

    return $self->get_listcontrol->GetSelection();
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

sub populate_config_page {
    my $self = shift;

    my $cnf  = Qrt::Config->new();
    my $path = $cnf->cfg->output;    # query definition files

    $self->controls_write_page('conf', $path );
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
        # print "$nrcrt -> $title\n";
        $self->list_item_insert($indice, $nrcrt, $title, $file);
    }

    # Set item 0 selected on start
    $self->list_item_select_first();
}

sub list_populate_item {
    my ( $self, $rec ) = @_;

    my $idx = $self->get_list_max_index();
    $self->list_item_insert( $idx, $idx + 1, $rec->{title}, $rec->{file} );
    $self->list_item_select_last();
}

sub list_remove_item {
    my $self = shift;

    my $sel_item = $self->get_list_selected_index();
    my $file_fqn = $self->get_list_data($sel_item);

    # Remove from list
    # TODO: Add dialog here !!! ???
    $self->list_item_clear($sel_item);

    # Set item 0 selected
    $self->list_item_select_first();

    return $file_fqn;
}

sub get_detail_data {
    my $self = shift;

    my $sel_item  = $self->get_list_selected_index();
    my $file_fqn  = $self->get_list_data($sel_item);
    my $ddata_ref = $self->_model->get_detail_data($file_fqn);

    return ( $ddata_ref, $file_fqn, $sel_item );
}

sub controls_populate {
    my ($self) = @_;

    my ($ddata_ref, $file_fqn) = $self->get_detail_data();

    #-- Header
    # Write in the control the actual path and filename
    # Remove path until and including .tpda-qrt
    # not working to well !!! ???
    ( my $file_qn = $file_fqn ) =~ s{.*.tpda-qrt/}{};
    # Add real path to control
    $ddata_ref->{header}{filename} = $file_qn;
    $self->controls_write_page('list', $ddata_ref->{header} );

    #-- Parameters
    my $params = $self->params_data_to_hash( $ddata_ref->{parameters} );
    $self->controls_write_page('para', $params );

    #-- SQL
    $self->controls_write_page( 'sql', $ddata_ref->{body} );

    #--- Highlight SQL parameters
    $self->toggle_sql_highlight();
}

sub toggle_sql_highlight {
    my $self = shift;

    #- Detail data
    my ($ddata, $file_fqn) = $self->get_detail_data();

    #-- Parameters
    my $params = $self->params_data_to_hash( $ddata->{parameters} );

    if ( $self->_model->is_editmode ) {
        $self->control_highlight_text($ddata->{body}{sql}, $params );
    }
    else {
        $self->control_replace_highlight_text($ddata->{body}{sql}, $params );
    }
}

sub control_replace_highlight_text {
    my ($self, $sqltext, $params) = @_;

    my ($newtext, $positions) = $self->string_replace_pos($sqltext, $params);

    # Write new text to control
    $self->control_set_value('sql', $newtext);

    foreach my $position ( @{$positions} ) {

        my ($beg, $var, $str) = @{$position};
        my $end = $beg + length($str);

        if ( $beg > 0 and $end > 0 ) {
            $self->control_set_attr( $beg, $end, 'orange', 'lightgrey' );
        }
    }
}

sub control_highlight_text {
    my ($self, $sqltext, $para_ref) = @_;

    # Write text to control ???
    $self->control_set_value('sql', $sqltext);

    while (my ($key, $value) = each ( %{$para_ref} ) ) {

        next unless $key =~ m{value[0-9]}; # Skip 'descr'

        # Find the positions of the string 'value[0-9]' in SQL text
        my ( $beg, $end ) = $self->string_match_pos( $sqltext, $key );
        if ( $beg >= 0 and $end > 0 ) {
            $self->control_set_attr( $beg, $end, 'red', 'white' );
        }
    }
}

sub status_msg {
    my ( $self, $msg ) = @_;

    my ( $text, $sb_id ) = split ':', $msg; # Work around until I learn how
                                            # to pass other parameters ;)
    $self->get_statusbar()->SetStatusText( $text, $sb_id );
}

sub process_sql {

    my $self = shift;

    my ($data, $file_fqn, $item) = $self->get_detail_data();

    my ($bind, $sqltext) = $self->string_replace_for_run(
        $data->{body}{sql},
        $data->{parameters},
    );

    $self->_model->run_export($data->{header}{output}, $bind, $sqltext);
}

#-- utils

sub params_data_to_hash {
    my ($self, $params) = @_;

    # Transform data in simple hash reference format
    # Move this to model ???
    my $parameters;
    foreach my $parameter ( @{ $params->{parameter} } ) {
        my $id = $parameter->{id};
        if ($id) {
            $parameters->{"value$id"} = $parameter->{value};
            $parameters->{"descr$id"} = $parameter->{descr};
        }
    }

    return $parameters;
}

sub string_match_pos {

    my ($self, $text, $value) = @_;

    $text =~ m/($value)/pm;
    my $beg = $-[0];
    my $end = $+[0];

    return ($beg, $end);
}

sub string_replace_pos {

    my ($self, $text, $params) = @_;

    my @strpos;

    while (my ($key, $value) = each ( %{$params} ) ) {
        next unless $key =~ m{value[0-9]}; # Skip 'descr'

        # Replace  text and return the strpos
        $text =~ s/($key)/$value/pm;
        my $pos = $-[0];
        push(@strpos, [ $pos, $key, $value ]);
    }

    # Sorted by $pos
    my @sortedpos = sort { $a->[0] <=> $b->[0] } @strpos;

    return ($text, \@sortedpos);
}

sub string_replace_for_run {

    my ( $self, $sqltext, $params ) = @_;

    my @bind;
    foreach my $rec ( @{ $params->{parameter} } ) {
        my $value = $rec->{value};
        my $p_num = $rec->{id};         # Parameter number for bind_param
        my $var   = 'value' . $p_num;
        $sqltext =~ s/($var)/\?/pm;

        push( @bind, [ $p_num, $value ] );
    }

    return ( \@bind, $sqltext );
}

# end utils
#

sub control_set_attr {
    my ($self, $beg, $end, $fgcolor, $bgcolor) = @_;

    my $ctrl = $self->get_control_by_name('sql');

    $ctrl->SetStyle(
        $beg,
        $end,
        Wx::TextAttr->new(
            Wx::Colour->new($fgcolor),
            Wx::Colour->new($bgcolor),
        )
      );
}

sub control_set_value {
    my ($self, $name, $value) = @_;

    return unless defined $value;

    my $ctrl = $self->get_control_by_name($name);

    $ctrl->SetValue($value);
}

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

            $control->{$name}[0]->SetValue($value);
        }
    }
}

sub controls_read_page {
    my ( $self, $page ) = @_;

    # Get controls name and object from $page
    my $get      = 'get_controls_' . $page;
    my $controls = $self->$get();
    my @records;

    foreach my $control ( @{$controls} ) {
        foreach my $name ( keys %{$control} ) {
            my $value = $control->{$name}[0]->GetValue();
            push(@records, { $name => $value } ) if ($name and $value);
        }
    }

    return \@records;
}

sub save_query_def {
    my $self = shift;

    my (undef, $file_fqn, $item) = $self->get_detail_data();

    my $head = $self->controls_read_page('list');
    my $para = $self->controls_read_page('para');
    my $body = $self->controls_read_page('sql');

    my $new_title =
      $self->_model->save_query_def( $file_fqn, $head, $para, $body );

    # Update title in list
    $self->set_list_text( $item, 1, $new_title );
}

#-- End Perl ListCtrl subs

1;

__END__

=BUGS

Can't change style for TextCtrl, styles are suported only for
multiline text controls!
