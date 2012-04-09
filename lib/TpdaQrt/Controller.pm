package TpdaQrt::Controller;

use strict;
use warnings;

use TpdaQrt::Config;
use TpdaQrt::Model;

=head1 NAME

TpdaQrt::Controller - The Controller.

=head1 VERSION

Version 0.33

=cut

our $VERSION = '0.33';

=head1 SYNOPSIS

    use TpdaQrt::Controller;

    my $controller = TpdaQrt::Controller->new();

    $controller->start();

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;

    my $model = TpdaQrt::Model->new();

    my $self = {
        _model => $model,
        _cfg   => TpdaQrt::Config->instance(),
    };

    bless $self, $class;

    return $self;
}

=head2 start

Try to connect first even if we have no user and pass. Retry and show
login dialog, until connected unless fatal error message received from
the RDBMS.

=cut

sub start {
    my $self = shift;

    $self->_view->log_config_options();

    # Try until connected or canceled
    my $return_string = '';
    while ( !$self->_model->is_connected ) {
        $self->_model->db_connect();
        if ( my $message = $self->_model->get_exception ) {
            my ($type, $mesg) = split /#/, $message, 2;
            if ($type =~ m{fatal}imx) {
                my $message = 'Eroare de conectare!';
                $self->_view->dialog_error($message, $mesg);
                $return_string = 'shutdown';
                last;
            }
        }

        # Try with the login dialog if still not connected
        if ( !$self->_model->is_connected ) {
            $return_string = $self->dialog_login();
            last if $return_string eq 'shutdown';
        }
    }

    if ($return_string eq 'shutdown') {
        print "Shuting down ...\n";
        $self->_view->on_quit;
        return;
    }

    #-- Start

    my $default_choice = $self->_view->get_choice_default();
    $self->_model->set_choice($default_choice);

    $self->_set_event_handlers;
    $self->set_app_mode('idle');
    $self->_view->list_populate_all();
    $self->_view->list_item_select_first();
    $self->_model->on_item_selected();
    $self->set_app_mode('sele');

    return;
}

=head2 login_dialog

Login dialog.

=cut

sub dialog_login {

    print 'dialog_login not implemented in ', __PACKAGE__, "\n";

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

=head2 _set_event_handlers

Setup event handlers for the interface.

=cut

sub _set_event_handlers {
    my $self = shift;

    #- Base menu

    #-- Exit
    $self->_view->event_handler_for_menu(
        'mn_qt',
        sub {
            return if !defined $self->ask_to_save;
            $self->_view->on_quit;
        }
    );

    #-- Help
    $self->_view->event_handler_for_menu(
        'mn_gd',
        sub {
            $self->guide;
        }
    );

    #-- About
    $self->_view->event_handler_for_menu(
        'mn_ab',
        sub {
            $self->about;
        }
    );

    #- Toolbar

    #-- Edit mode
    $self->_view->event_handler_for_tb_button(
        'tb_ed',
        sub {
            $self->_model->is_appmode('edit')
                ? $self->set_app_mode('sele')
                : $self->set_app_mode('edit');
        }
    );

    #-- Save
    $self->_view->event_handler_for_tb_button(
        'tb_sv',
        sub {
            if ( $self->_model->is_appmode('edit') ) {
                $self->save_query_def();
                $self->set_app_mode('sele');
            }
        }
    );

    #-- Add new report
    $self->_view->event_handler_for_tb_button(
        'tb_ad',
        sub {
            my $max_item = $self->_view->get_list_max_index();
            my $rec = $self->_model->report_add($max_item);
            $self->_view->list_populate_item($rec);
            $self->set_app_mode('edit');
        }
    );

    #-- Remove report
    $self->_view->event_handler_for_tb_button(
        'tb_rm',
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
        }
    );

    #- Choice
    $self->_view->event_handler_for_tb_choice(
        'tb_ls',
        sub {
            my $text = $self->_view->get_choice('tb_ls');
            $self->_model->set_choice($text);
        }
    );

    #- Run
    $self->_view->event_handler_for_tb_button(
        'tb_go',
        sub {
            if ($self->_model->is_connected ) {
                $self->_view->dialog_progress('Export data');
                $self->process_sql();
            }
            else {
                $self->_view->dialog_error( 'Error', 'Not connected!' );
            }
        }
    );

    #-- Quit
    $self->_view->event_handler_for_tb_button(
        'tb_qt',
        sub {
            $self->_view->on_quit;
        }
    );

    #-- List
    $self->_view->event_handler_for_list(
        sub {
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

    my $is_edit = $self->_model->is_appmode('edit') ? 1 : 0;

    # Toggle List control state
    $self->_view->toggle_list_enable( !$is_edit );

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

            my ($state, $color);
            if ($is_edit) {
                $state = $control->{$name}[1];  # normal | disabled
                $color = $control->{$name}[2];  # name
            }
            else {
                $state = 'disabled';
            }

            $self->_view->set_editable($name, $state, $color);
        }
    }

    return;
}

=head2 dialog_progress

Progress dialog.

=cut

sub dialog_progress {

    print 'dialog_progress not implemented in ', __PACKAGE__, "\n";

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

    print 'process_sql not implemented in ', __PACKAGE__, "\n";

    return;
}

=head2 list_populate_all

Populate all other pages except the configuration page

=cut

sub list_populate_all {
    my $self = shift;

    my $indices = $self->_model->get_qdf_data();

    return unless scalar keys %{$indices};

    # Populate list in sorted order
    my @indices = sort { $a <=> $b } keys %{$indices};

    # Clear list
    $self->list_item_clear_all();

    foreach my $idx ( @indices ) {
        my $nrcrt = $indices->{$idx}{nrcrt};
        my $title = $indices->{$idx}{title};
        my $file  = $indices->{$idx}{file};

        $self->_view->list_item_insert($nrcrt, $title);
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

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of TpdaQrt::Controller