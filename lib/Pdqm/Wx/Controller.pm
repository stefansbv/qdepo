package Pdqm::Wx::Controller;

use strict;
use warnings;

use Data::Dumper;

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
        _conn_btn => $view->get_conn_btn,
        _save_btn => $view->get_save_btn,
        _edit_btn => $view->get_edit_btn,
        _refr_btn => $view->get_refr_btn,
        _run_btn  => $view->get_run_btn,
        _exit_btn => $view->get_exit_btn,
        _nbook    => $view->get_notebook,
        _toolbar  => $view->get_toolbar,
        _list     => $view->get_listcontrol,
    };

    bless $self, $class;

    $self->_set_event_handlers;
    $self->_view->Show( 1 );

    return $self;
}

sub _init {
    my ($self) = @_;
    return;
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

sub start {
    my ($self, ) = @_;
    $self->_view->list_populate_all();

    $self->_model->db_connect();
}

sub _set_event_handlers {
    my $self = shift;

    #- Menu
    EVT_MENU $self->_view, wxID_ABOUT, $about; # Change icons !!!
    EVT_MENU $self->_view, wxID_HELP, $about;
    EVT_MENU $self->_view, wxID_EXIT,  $exit;

    #- Toolbar
    EVT_TOOL $self->_view, $self->{_conn_btn}, sub {
        $self->_model->is_connected
            ? $self->_model->db_disconnect
            : $self->_model->db_connect;
    };
    EVT_TOOL $self->_view, $self->{_refr_btn}, sub {
    };

    EVT_TOOL $self->_view, $self->{_edit_btn}, sub {
        $self->_model->set_editmode;
        $self->_model->is_editmode
            ? $self->toggle_controls(0)
            : $self->toggle_controls(1);
    };

    EVT_TOOL $self->_view, $self->{_run_btn}, sub {
        $self->_model->is_connected
          ? $self->_model->run_export
          : $self->_view->popup( 'Error', 'Not connected' );
    };

    EVT_TOOL $self->_view, $self->{_exit_btn}, $exit;

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
    # EVT_SIZE ( BasicFrame::OnSize ) # Experiment with this ???
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
    my ($self, $status) = @_;

    # Tool buttons
    $self->{_toolbar}->EnableTool( 1002, $status );
    $self->{_toolbar}->EnableTool( 1003, $status );
    $self->{_toolbar}->EnableTool( 1004, $status );
    $self->{_toolbar}->EnableTool( 1005, $status );
    $self->{_toolbar}->EnableTool( 1007, $status );
    $self->{_toolbar}->EnableTool( 1008, $status );
    $self->{_toolbar}->EnableTool( 1009, $status );
    # List control
    $self->{_list}->Enable($status);
}

1;
