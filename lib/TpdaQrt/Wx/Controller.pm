package TpdaQrt::Wx::Controller;

use strict;
use warnings;

use Wx ':everything';
use Wx::Event qw(EVT_CLOSE EVT_CHOICE EVT_MENU EVT_TOOL EVT_BUTTON
                 EVT_AUINOTEBOOK_PAGE_CHANGED EVT_LIST_ITEM_SELECTED);

use TpdaQrt::Config;
use TpdaQrt::Model;
use TpdaQrt::Wx::App;
use TpdaQrt::Wx::View;

=head1 NAME

TpdaQrt::Wx::Controller - The Controller

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    use TpdaQrt::Wx::Controller;

    my $controller = TpdaQrt::Wx::Controller->new();

    $controller->start();

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;

    my $model = TpdaQrt::Model->new();

    my $app = TpdaQrt::Wx::App->create($model);

    my $self = {
        _model  => $model,
        _app    => $app,
        _view   => $app->{_view},
        _cfg    => TpdaQrt::Config->instance(),
    };

    bless $self, $class;

    $self->_set_event_handlers;

    return $self;
}

=head2 start

Populate list with titles, Log configuration options, set default
choice for export and initial mode.

TODO: make a more general method

=cut

sub start {
    my ($self, ) = @_;

    $self->_view->log_config_options();

    # Connect to database at start
    $self->_model->db_connect();

    my $default_choice = $self->_view->get_choice_default();
    $self->_model->set_choice($default_choice);

    $self->set_app_mode('idle');

    $self->_view->list_populate_all();

    $self->_view->list_item_select_first();
    $self->_model->on_item_selected();
    $self->set_app_mode('sele');

    return;
}

=head2 set_app_mode

Set application mode

=cut

sub set_app_mode {
    my ( $self, $mode ) = @_;

    if ( $mode eq 'sele' ) {
        my $item_no = $self->_view->get_list_max_index();

        # Set mode to 'idle' if no items
        $mode = 'idle' if $item_no <= 0;
    }

    $self->_model->set_mode($mode);

    my %method_for = (
        idle => 'on_screen_mode_idle',
        edit => 'on_screen_mode_edit',
        sele => 'on_screen_mode_sele',
    );

    $self->toggle_interface_controls;

    if ( my $method_name = $method_for{$mode} ) {
        $self->$method_name();
    }

    return 1;
}

sub on_screen_mode_idle {
    my $self = shift;

    return;
}

sub on_screen_mode_edit {
    my $self = shift;

    $self->_view->toggle_sql_replace('edit');

    return;
}

sub on_screen_mode_sele {
    my $self = shift;

    $self->_view->toggle_sql_replace('sele');

    return;
}

=head2 about

The About dialog

=cut

my $about = sub {
    my ( $self, $event ) = @_;

    Wx::MessageBox(
        "TPDA - Query Repository Tool v0.11\n(C) 2010 - 2011 Stefan Suciu\n\n"
            . " - WxPerl $Wx::VERSION\n"
            . " - " . Wx::wxVERSION_STRING,
        "About TPDA-QRT",

        wxOK | wxICON_INFORMATION,
        $self
    );
};

=head2 _set_event_handlers

Setup event handlers for the interface.

=cut

sub _set_event_handlers {
    my $self = shift;

    #- Menu
    EVT_MENU $self->_view, wxID_ABOUT, $about; # Change icons !!!

    EVT_MENU $self->_view, wxID_HELP, $about;

    EVT_MENU $self->_view, wxID_EXIT,
        sub {
            $self->_view->on_quit;
        };

    #- Toolbar

    #-- Edit
    EVT_TOOL $self->_view, $self->_view->get_toolbar_btn('tb_ed')->GetId,
        sub {
            $self->_model->is_appmode('edit')
                ? $self->set_app_mode('sele')
                : $self->set_app_mode('edit');
        };

    #-- Save
    EVT_TOOL $self->_view, $self->_view->get_toolbar_btn('tb_sv')->GetId,
        sub {
            if ( $self->_model->is_appmode('edit') ) {
                $self->save_query_def();
                $self->set_app_mode('sele');
            }
        };

    #-- Add report
    EVT_TOOL $self->_view, $self->_view->get_toolbar_btn('tb_ad')->GetId,
        sub {
            my $max_item = $self->_view->get_list_max_index();
            my $rec = $self->_model->report_add($max_item);
            $self->_view->list_populate_item($rec);
            $self->set_app_mode('edit');
        };

    #-- Remove report
    EVT_TOOL $self->_view, $self->_view->get_toolbar_btn('tb_rm')->GetId,
        sub {
            my $msg = 'Delete query definition file?';
            if ( $self->_view->action_confirmed($msg) ) {
                my $file = $self->_view->list_remove_item();
                if ($file) {
                    $self->_model->report_remove($file);
                }
            }
            else {
                $self->_view->log_msg("II delete canceled");
            }
        };

    #- Choice
    EVT_CHOICE $self->_view, $self->_view->get_toolbar_btn('tb_ls')->GetId,
        sub {
            my $text = $_[1]->GetString;
            $self->_model->set_choice($text);
        };

    #- Run
    EVT_TOOL $self->_view, $self->_view->get_toolbar_btn('tb_go')->GetId,
        sub {
            if ($self->_model->is_connected ) {
                $self->_view->progress_dialog('Export data');
                $self->process_sql();
            }
            else {
                $self->_view->dialog_popup( 'Error', 'Not connected!' );
            }
        };

    #-- Quit
    EVT_TOOL $self->_view, $self->_view->get_toolbar_btn('tb_qt')->GetId,
        sub {
            $self->_view->on_quit;
        };

    #- List controll
    EVT_LIST_ITEM_SELECTED $self->_view, $self->_view->get_listcontrol, sub {
        $self->_model->on_item_selected();
    };

    #- Frame : Deep recursion on subroutine "TpdaQrt::Wx::View::on_quit"
    # EVT_CLOSE $self->_view,
    #     sub {
    #         $self->_view->on_quit;
    #     };

    #-- Make some key bindings

    #-- Quit Ctrl-q
    # $self->_view->bind(
    #     '<Control-q>' => sub {
    #         $self->_view->on_quit;
    #     }
    # );
}

=head2 _model

Return model instance variable

=cut

sub _model {
    my $self = shift;

    return $self->{_model};
}

=head2 _view

Return view instance variable

=cut

sub _view {
    my $self = shift;

    return $self->{_view};
}

=head2 toggle_interface_controls

Toggle controls (tool bar buttons) appropriate for different states of
the application.

=cut

sub toggle_interface_controls {
    my $self = shift;

    my ( $toolbars, $attribs ) = $self->{_view}->toolbar_names();

    my $mode = $self->_model->get_appmode();

    foreach my $name ( @{$toolbars} ) {
        my $status = $attribs->{$name}{state}{$mode};
        $self->_view->enable_tool( $name, $status );
    }

    my $is_edit = $self->_model->is_appmode('edit') ? 1 : 0;

    # Toggle List control state
    $self->_view->get_listcontrol()->Enable( !$is_edit );

    # Controls by page Enabled in edit mode
    foreach my $page (qw(para list conf sql )) {
        $self->toggle_controls_page( $page, $is_edit );
    }

    return;
}

=head2 toggle_controls_page

Toggle the controls on page

=cut

sub toggle_controls_page {
    my ($self, $page, $is_edit) = @_;

    my $get = 'get_controls_'.$page;
    my $controls = $self->_view->$get();

    foreach my $control ( @{$controls} ) {
        foreach my $name ( keys %{$control} ) {

            my $state = $control->{$name}[1];  # normal | disabled
            my $color = $control->{$name}[2];  # name

            # Controls state are defined in View as strings
            # Here we need to transform them to 0|1
            my $editable;
            if (!$is_edit) {
                $editable = 0;
                $color = 'lightgrey'; # Default color for disabled ctrl
            }
            else {
                $editable = $state eq 'normal' ? 1 : 0;
            }

            if ($page ne 'sql') {
                $control->{$name}[0]->SetEditable($editable);
            }
            else {
                $control->{$name}->[0]->Enable($editable);
            }

            $control->{$name}->[0]->SetBackgroundColour(
                Wx::Colour->new( $color ),
            ) if $color;
        }
    }

    return;
}

=head2 dialog_progress

Progress dialog.

=cut

sub dialog_progress {
    my ($self, $event, $max) = @_;

    my $dialog = Wx::ProgressDialog->new(
        'Progress dialog example',
        'An example',
        $max,
        $self,
        wxPD_CAN_ABORT | wxPD_APP_MODAL | wxPD_ELAPSED_TIME
            | wxPD_ESTIMATED_TIME | wxPD_REMAINING_TIME
    );

    my $usercontinue = 1;
    foreach (1 .. $max) {
        $usercontinue = $dialog->Update($_);
        last if $usercontinue == 0;
    }

    $dialog->Destroy;

    return;
}

=head2 save_query_def

Save query definition file

=cut

sub save_query_def {
    my $self = shift;

    my $item = $self->_view->get_list_selected_index();

    my $head = $self->_view->controls_read_page('list');
    my $para = $self->_view->controls_read_page('para');
    my $body = $self->_view->controls_read_page('sql');

    my $file = $self->_view->get_list_data($item);

    $self->_model->save_query_def( $item, $head, $para, $body, $file );

    my $title = $head->[0]{title};

    # Update title in list
    $self->_view->set_list_text( $item, 1, $title );

    return;
}

=head2 process_sql

Get the sql text string from the QDF file, prepare it for execution.

=cut

sub process_sql {
    my $self = shift;

    my $item   = $self->_view->get_list_selected_index();
    my $file   = $self->_view->get_list_data($item);
    my ($data) = $self->_model->get_detail_data($item, $file);

    $self->_model->run_export($data);

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 - 2011 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of TpdaQrt::Wx::Controller
