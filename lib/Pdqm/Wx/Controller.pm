# +---------------------------------------------------------------------------+
# | Name     : Pdqm (Perl Database Query Manager)                             |
# | Author   : Stefan Suciu  [ stefansbv 'at' users . sourceforge . net ]     |
# | Website  :                                                                |
# |                                                                           |
# | Copyright (C) 2010  Stefan Suciu                                          |
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
# |                                       p a c k a g e   C o n t r o l l e r |
# +---------------------------------------------------------------------------+
package Pdqm::Wx::Controller;

use strict;
use warnings;

use Wx ':everything';
use Wx::Event qw(EVT_CLOSE EVT_MENU EVT_TOOL EVT_BUTTON
                 EVT_AUINOTEBOOK_PAGE_CHANGED EVT_LIST_ITEM_SELECTED);

use Pdqm::Model;
use Pdqm::Wx::View;

sub new {
    my ( $class, $app ) = @_;

    my $model = Pdqm::Model->new( { conf_file => 'share/config/pdqm.yml'} );

    my $view = Pdqm::Wx::View->new(
        $model,
        undef,
        -1,
        'Perl Database Query Manager',
        [ -1, -1 ],
        [ -1, -1 ],
        wxDEFAULT_FRAME_STYLE,
    );

    my $self = {
        _model    => $model,
        _view     => $view,
        _nbook    => $view->get_notebook,
        _toolbar  => $view->get_toolbar,
        _list     => $view->get_listcontrol,
    };

    bless $self, $class;

    $self->_set_event_handlers;

    $self->_view->Show( 1 );

    return $self;
}

sub start {
    my ($self, ) = @_;

    # Populate list with titles
    $self->_view->list_populate_all();

    # Connect to database
    # $self->_model->db_connect();

    # Initial mode
    $self->_model->set_idlemode();
    $self->toggle_controls;
}

my $closeWin = sub {
    my ( $self, $event ) = @_;

    $self->Destroy();
};

my $about = sub {
    my ( $self, $event ) = @_;

    Wx::MessageBox(
        "PDQM v0.10\n(C) 2010 Stefan Suciu",
        "About Perl Database Query Manager",
        wxOK | wxICON_INFORMATION,
        $self
    );
};

my $exit = sub {
    my ( $self, $event ) = @_;

    $self->Close( 1 );
};

sub _set_event_handlers {
    my $self = shift;

    #- Menu
    EVT_MENU $self->_view, wxID_ABOUT, $about; # Change icons !!!
    EVT_MENU $self->_view, wxID_HELP, $about;
    EVT_MENU $self->_view, wxID_EXIT,  $exit;

    #- Toolbar
    EVT_TOOL $self->_view, $self->_view->get_toolbar_btn('tb_cn'), sub {
        $self->_model->is_connected
            ? $self->_model->db_disconnect
            : $self->_model->db_connect;
    };
    EVT_TOOL $self->_view, $self->_view->get_toolbar_btn('tb_rf'), sub {
        print " refreshing :)\n";
    };

    # Disable editmode when save
    EVT_TOOL $self->_view, $self->_view->get_toolbar_btn('tb_sv'), sub {
        if ($self->_model->is_editmode) {
            $self->_model->save_query_def;
            $self->_model->set_idlemode;
            $self->toggle_controls;
        }
    };

    EVT_TOOL $self->_view, $self->_view->get_toolbar_btn('tb_ed'), sub {
        $self->_model->is_editmode
            ? $self->_model->set_idlemode
            : $self->_model->set_editmode;
        $self->toggle_controls;
    };

    EVT_TOOL $self->_view, $self->_view->get_toolbar_btn('tb_go'), sub {
        $self->_model->is_connected
          ? $self->_model->run_export
          : $self->_view->popup( 'Error', 'Not connected' );
    };

    EVT_TOOL $self->_view, $self->_view->get_toolbar_btn('tb_qt'), $exit;

    #- NoteBook
    EVT_AUINOTEBOOK_PAGE_CHANGED $self->_view, $self->{_nbook}, sub {
         my ( $nb, $event ) = @_;
         my $new_pg = $event->GetSelection;
         my $old_pg = $event->GetOldSelection;
         $self->_model->on_page_change($new_pg, $old_pg);
         $event->Skip;
    };

    #- List controll
    EVT_LIST_ITEM_SELECTED $self->_view, $self->{_list}, sub {
        $self->_model->on_item_selected(@_);
    };

    #- Frame
    EVT_CLOSE $self->_view, $closeWin;
}

sub _model {
    my $self = shift;

    return $self->{_model};
}

sub _view {
    my $self = shift;

    return $self->{_view};
}

sub toggle_controls {
    my $self = shift;

    my $status = $self->_model->is_editmode ? 0 : 1;

    # Tool buttons
    $self->{_toolbar}->EnableTool( 1002, !$status );
    $self->{_toolbar}->EnableTool( 1003, $status );
    $self->{_toolbar}->EnableTool( 1004, $status );
    $self->{_toolbar}->EnableTool( 1005, $status );
    $self->{_toolbar}->EnableTool( 1007, $status );
    $self->{_toolbar}->EnableTool( 1008, $status );
    $self->{_toolbar}->EnableTool( 1009, $status );

    # List control
    $self->{_list}->Enable($status);

    # Controls by page Enabled in edit mode
    foreach my $page (qw(para list sql)) {
        $self->toggle_controls_page($page, !$status);
    }
}

sub toggle_controls_page {
    my ($self, $page, $status) = @_;

    my $get = 'get_controls_'.$page;
    my $controls = $self->_view->$get();

    foreach my $control ( @{$controls} ) {
        $control->Enable($status);
    }
}

1;
