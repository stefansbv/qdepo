package TpdaQrt::Tk::Controller;

use strict;
use warnings;
use Carp;

use Tk;
# use Tk::Font;
# use Tk::DialogBox;

use TpdaQrt::Config;
use TpdaQrt::Utils;
use TpdaQrt::Model;
use TpdaQrt::Tk::View;

=head1 NAME

TpdaQrt::Tk::Controller - The Controller

=head1 VERSION

Version 0.14

=cut

our $VERSION = '0.14';

=head1 SYNOPSIS

    use TpdaQrt::Tk::Controller;

    my $controller = TpdaQrt::Tk::Controller->new();

    $controller->start();

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my ( $class, $app ) = @_;

    my $model = TpdaQrt::Model->new();

    my $view = TpdaQrt::Tk::View->new($model);

    my $self = {
        _model => $model,
        _app   => $view,                         # an alias as for Wx ...
        _view  => $view,
        _cfg   => TpdaQrt::Config->instance(),
    };

    bless $self, $class;

    $self->_set_event_handlers();

    return $self;
}

=head2 start

Check if we have user and pass, if not, show dialog.  Connect to
database.

=cut

sub start {
    my $self = shift;

#    $self->_view->log_config_options();

    # Connect to database at start
    $self->_model->db_connect();

    my $default_choice = $self->_view->get_choice_default();
    $self->_model->set_choice("0:$default_choice");

    $self->set_app_mode('idle');

    $self->_view->list_populate_all();

    $self->set_app_mode('sele');

    $self->_model->on_item_selected();

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
    print " on_screen_mode_idle\n";
    return;
}

sub on_screen_mode_edit {
    my $self = shift;

    print " on_screen_mode_edit\n";
    # $self->screen_write( undef, 'clear' );    # Empty the main controls

    # #    $self->control_tmatrix_write();
    # $self->controls_state_set('off');
    # $self->_log->trace("Mode has changed to 'idle'");

    return;
}

sub on_screen_mode_sele {
    my $self = shift;

    return;
}

=head2 _set_event_handlers

Setup event handlers for the interface.

=cut

sub _set_event_handlers {
    my $self = shift;

    #- Base menu

    #-- Exit
    $self->_view->get_menu_popup_item('mn_qt')->configure(
        -command => sub {
            $self->_view->on_quit;
        }
    );

    #-- Help
    $self->_view->get_menu_popup_item('mn_gd')->configure(
        -command => sub {
            $self->guide;
        }
    );

    #-- About
    $self->_view->get_menu_popup_item('mn_ab')->configure(
        -command => sub {
            $self->about;
        }
    );

    #- Toolbar

    #-- Connect
    $self->_view->get_toolbar_btn('tb_cn')->bind(
        '<ButtonRelease-1>' => sub {
            if ($self->_model->is_connected ) {
                $self->_view->dialog_popup( 'Info', 'Already connected!' );
            }
            else {
                $self->_model->db_connect;
            }

            $self->_model->on_item_selected(@_);
        }
    );

    #-- Refresh
    $self->_view->get_toolbar_btn('tb_rf')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_model->on_item_selected(@_);
        }
    );

    #-- Add report
    $self->_view->get_toolbar_btn('tb_ad')->bind(
        '<ButtonRelease-1>' => sub {
            my $rec = $self->_model->report_add();
            $self->_view->list_populate_item($rec);
        }
    );

    #-- Remove report
    $self->_view->get_toolbar_btn('tb_rm')->bind(
        '<ButtonRelease-1>' => sub {
            my $msg = 'Delete query definition file?';
            if ( $self->_view->action_confirmed($msg) ) {
                my $file_fqn = $self->_view->list_remove_item();
                if ($file_fqn) {
                    $self->_model->report_remove($file_fqn);
                }
            }
            else {
                $self->_view->log_msg("II delete canceled");
            }
        }
    );

    #-- Save
    $self->_view->get_toolbar_btn('tb_sv')->bind(
        '<ButtonRelease-1>' => sub {
            if ( $self->_model->is_mode('edit') ) {
                $self->_view->save_query_def();
                $self->set_app_mode('sele');
            }
        }
    );

    #-- Edit
    $self->_view->get_toolbar_btn('tb_ed')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_model->is_mode('edit')
                ? $self->set_app_mode('sele')
                : $self->set_app_mode('edit');
        }
    );

    #- Choice
    $self->_view->get_toolbar_btn('tb_ls')->bind(
        '<ButtonRelease-1>' => sub {
            # my $choice = $_[1]->GetSelection;
            # my $text   = $_[1]->GetString;
            # $self->_model->set_choice("$choice:$text");
        }
    );

    #- Run
    $self->_view->get_toolbar_btn('tb_go')->bind(
        '<ButtonRelease-1>' => sub {
            if ($self->_model->is_connected ) {
                $self->_view->progress_dialog('Export data');
                $self->_view->process_sql();
            }
            else {
                $self->_view->dialog_popup( 'Error', 'Not connected!' );
            }
        }
    );

    #-- Quit
    $self->_view->get_toolbar_btn('tb_qt')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_view->on_quit;
        }
    );

    #-- Make some key bindings

    #-- Quit Ctrl-q
    $self->_view->bind(
        '<Control-q>' => sub {
            $self->_view->on_quit;
        }
    );

    #-- Reload - F5
    $self->_view->bind(
        '<F5>' => sub {
            $self->_model->is_mode('edit')
                ? $self->record_reload()
                : $self->_view->set_status( 'Not edit mode', 'ms', 'orange' );
        }
    );

    #-- Execute run - F9
    $self->_view->bind(
        '<F9>' => sub {
        }
    );

    #- List controll
    $self->_view->get_listcontrol->bindRows(
        '<Button-1>', sub {
            $self->_model->on_item_selected();
        }
    );

    return;
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

    return;
}

#     # List control
#     $self->{_list}->Enable(!$is_edit);

#     # Controls by page Enabled in edit mode
#     foreach my $page ( qw(para list conf sql ) ) {
#         $self->toggle_controls_page( $page, $is_edit );
#     }
# }

# =head2 toggle_controls_page

# Toggle the controls on page

# =cut

# sub toggle_controls_page {
#     my ($self, $page, $is_edit) = @_;

#     my $get = 'get_controls_'.$page;
#     my $controls = $self->_view->$get();

#     foreach my $control ( @{$controls} ) {
#         foreach my $name ( keys %{$control} ) {

#             my $state = $control->{$name}->[1];  # normal | disabled
#             my $color = $control->{$name}->[2];  # name

#             # Controls state are defined in View as strings
#             # Here we need to transform them to 0|1
#             my $editable;
#             if (!$is_edit) {
#                 $editable = 0;
#                 $color = 'lightgrey'; # Default color for disabled ctrl
#             }
#             else {
#                 $editable = $state eq 'normal' ? 1 : 0;
#             }

#             if ($page ne 'sql') {
#                 $control->{$name}->[0]->SetEditable($editable);
#             }
#             else {
#                 $control->{$name}->[0]->Enable($editable);
#             }

#             $control->{$name}->[0]->SetBackgroundColour(
#                 Wx::Colour->new( $color ),
#             );
#         }
#     }
# }

=head2 dialog_progress

Progress dialog.

=cut

sub dialog_progress {
    my ($self, $event, $max) = @_;

    # my $dialog = Wx::ProgressDialog->new(
    #     'Progress dialog example',
    #     'An example',
    #     $max,
    #     $self,
    #     wxPD_CAN_ABORT | wxPD_APP_MODAL | wxPD_ELAPSED_TIME
    #         | wxPD_ESTIMATED_TIME | wxPD_REMAINING_TIME
    # );

    # my $usercontinue = 1;
    # foreach (1 .. $max) {
    #     $usercontinue = $dialog->Update($_);
    #     last if $usercontinue == 0;
    # }

    # $dialog->Destroy;

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

1;    # End of TpdaQrt::Tk::Controller
