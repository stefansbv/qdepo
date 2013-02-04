package QDepo::Controller;

use strict;
use warnings;

use Try::Tiny;
use QDepo::Config;
use QDepo::Model;
use QDepo::Exceptions;

=head1 NAME

QDepo::Controller - The Controller.

=head1 VERSION

Version 0.39

=cut

our $VERSION = '0.39';

=head1 SYNOPSIS

    use QDepo::Controller;

    my $controller = QDepo::Controller->new();

    $controller->start();

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;

    my $model = QDepo::Model->new();

    my $self = {
        _model => $model,
        _cfg   => QDepo::Config->instance(),
    };

    bless $self, $class;

    return $self;
}

=head2 cfg

Return config instance variable

=cut

sub cfg {
    my $self = shift;

    return $self->{_cfg};
}

=head2 start

Connect if user and pass or if driver is SQLite. Retry and show login
dialog, until connected or fatal error message received from the
RDBMS.

=cut

sub start {
    my $self = shift;

    my $driver = $self->cfg->connection->{driver};
    if (   ( $self->cfg->user and $self->cfg->pass )
        or ( $driver eq 'sqlite' ) )
    {
        $self->model->db_connect();
    }

    # Retry until connected or canceled
    $self->start_delay()
        unless ( $self->model->is_connected
        or $self->cfg->connection->{driver} eq 'sqlite' );

    #- Start

    my $default = $self->view->get_choice_default();
    $self->model->set_choice($default);

    $self->set_event_handlers();
    $self->set_app_mode('idle');

    $self->view->connlist_populate();
    if ( $self->view->get_list_max_index('dlist') >= 0) {
        $self->view->list_item_select('dlist', 'default');
    }

    $self->view->querylist_populate();
    if ( $self->view->get_list_max_index('qlist') >= 0) {
        $self->view->list_item_select('qlist', 'first');
        $self->model->on_item_selected();
        $self->set_app_mode('sele');
    }

    return;
}

=head2 connect_dialog

Show login dialog until connected or canceled.  Called with delay from
Tk::Controller (not yet).

=cut

sub connect_dialog {
    my $self = shift;

    my $error;

  TRY:
    while ( not $self->model->is_connected ) {

        # Show login dialog if still not connected
        my $return_string = $self->dialog_login($error);
        if ($return_string eq 'cancel') {
            $self->model->message_log(qq{II Login cancelled});
            last TRY;
        }

        # Try to connect only if user and pass are provided
        if ($self->cfg->user and $self->cfg->pass ) {
            try {
                $self->model->db_connect();
            }
            catch {
                if ( my $e = Exception::Base->catch($_) ) {
                    if ( $e->isa('QDepo::Exception::Db::Connect') ) {
                        my $logmsg = $e->logmsg;
                        $error = $e->usermsg;
                        $self->model->message_log(qq{EE $logmsg});
                    }
                }
            };
        }
        else {
            $error = 'User and password required';
        }
    }

    return;
}

=head2 dialog_login

Login dialog.

=cut

sub dialog_login {

    print 'dialog_login not implemented in ', __PACKAGE__, "\n";

    return;
}

=head2 set_app_mode

Set application mode.

=cut

sub set_app_mode {
    my ( $self, $mode ) = @_;

    if ( $mode eq 'sele' ) {
        my $item_no = $self->view->get_list_max_index('qlist') + 1;

        # Set mode to 'idle' if no items
        $mode = 'idle' if $item_no <= 0;
    }

    $self->model->set_mode($mode);

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

=head2 on_screen_mode_idle

Idle mode.

=cut

sub on_screen_mode_idle {
    my $self = shift;

    return;
}

=head2 on_screen_mode_edit

Edit mode.

=cut

sub on_screen_mode_edit {
    my $self = shift;

    $self->view->toggle_list_enable('qlist');
    $self->view->toggle_sql_replace('edit');

    return;
}

=head2 on_screen_mode_sele

Select mode.

=cut

sub on_screen_mode_sele {
    my $self = shift;

    $self->view->toggle_sql_replace('sele');

    return;
}

=head2 set_event_handlers

Setup event handlers for the interface.

=cut

sub set_event_handlers {
    my $self = shift;

    #- Base menu

    #-- Exit
    $self->view->event_handler_for_menu(
        'mn_qt',
        sub {
            $self->on_quit;
        }
    );

    #-- Help
    $self->view->event_handler_for_menu(
        'mn_gd',
        sub {
            $self->guide;
        }
    );

    #-- About
    $self->view->event_handler_for_menu(
        'mn_ab',
        sub {
            $self->about;
        }
    );

    #- Toolbar

    #-- Edit mode
    $self->view->event_handler_for_tb_button(
        'tb_ed',
        sub {
            $self->model->is_appmode('edit')
                ? $self->set_app_mode('sele')
                : $self->set_app_mode('edit');
        }
    );

    #-- Save
    $self->view->event_handler_for_tb_button(
        'tb_sv',
        sub {
            if ( $self->model->is_appmode('edit') ) {
                $self->save_qdf_data();
                $self->set_app_mode('sele');
            }
        }
    );

    #- Run
    $self->view->event_handler_for_tb_button(
        'tb_go',
        sub {
            if ($self->model->is_connected ) {
                $self->view->dialog_progress('Export data');
                $self->process_sql();        # in Controller Wx | Tk
            }
            else {
                $self->view->dialog_error( 'Error', 'Not connected!' );
            }
        }
    );

    #-- Quit
    $self->view->event_handler_for_tb_button(
        'tb_qt',
        sub {
            $self->on_quit;
        }
    );

    #-- Query List
    $self->view->event_handler_for_list(
        'qlist',
        sub {
            $self->model->on_item_selected();
        }
    );

    #-- DB Configs List
    $self->view->event_handler_for_list(
        'dlist',
        sub {
            $self->toggle_admin_buttons();
        }
    );

    #- Admin panel

    #-- Load button
    $self->view->event_handler_for_button(
        'btn_load',
        sub {
            print "Load config...\n";
        }
    );

    #-- Default button
    $self->view->event_handler_for_button(
        'btn_defa',
        sub {
            $self->set_default_mnemonic();
        }
    );

    #-- Add button
    $self->view->event_handler_for_button(
        'btn_add',
        sub {
            my $name = $self->get_text_dialog();
            if ($name) {
                my $new = $self->cfg->config_new($name);
                $self->model->message_log(qq{II New connection: '$new'});
            }
        }
    );

    return;
}

=head2 model

Return model instance variable.

=cut

sub model {
    my $self = shift;

    return $self->{_model};
}

=head2 view

Return view instance variable.

=cut

sub view {
    my $self = shift;

    return $self->{_view};
}

=head2 toggle_interface_controls

Toggle controls (tool bar buttons) appropriate for different states of
the application.

=cut

sub toggle_interface_controls {
    my $self = shift;

    my ( $toolbars, $attribs ) = $self->view->toolbar_names();

    my $mode = $self->model->get_appmode();

    foreach my $name ( @{$toolbars} ) {
        my $status = $attribs->{$name}{state}{$mode};
        $self->view->enable_tool( $name, $status );
    }

    my $is_edit = $self->model->is_appmode('edit') ? 1 : 0;

    # Toggle List control state
    $self->view->toggle_list_enable('qlist', !$is_edit );

    # Controls by page Enabled in edit mode
    foreach my $page (qw(para list conf sql )) {
        $self->toggle_controls_page( $page, $is_edit );
    }

    return;
}

=head2 toggle_controls_page

Toggle the controls on page.

=cut

sub toggle_controls_page {
    my ($self, $page, $is_edit) = @_;

    my $get = 'get_controls_'.$page;
    my $controls = $self->view->$get();

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

            $self->view->set_editable($name, $state, $color);
        }
    }

    return;
}

=head2 save_qdf_data

Save .qdf file.

=cut

sub save_qdf_data {

    print 'save_qdf_data not implemented in ', __PACKAGE__, "\n";

    return;
}

=head2 on_quit

Before quit, ask for permission to delete the marked .qdf files, if
L<has_marks> is true.

=cut

sub on_quit {
    my $self = shift;

    print "Shuting down...\n";

    if ( $self->model->has_marks() ) {
        my $msg = 'Delete marked reports and quit?';
        my $answer = $self->view->action_confirmed($msg);
        if ($answer eq 'yes') {
            $self->list_remove_marked();
        }
        elsif ($answer eq 'cancel') {
            return;
        }
    }

    $self->view->on_close_window(@_);
}

=head2 list_remove_marked

Remove marked items.

=cut

sub list_remove_marked {

    print 'list_remove_marked not implemented in ', __PACKAGE__, "\n";

    return;
}

sub set_default_mnemonic {
    my $self = shift;

    my $item = $self->view->get_list_selected_index('dlist');
    if (defined $item) {
        $self->view->clear_default_mark();
        my $mnemonic = $self->view->set_default_mark($item);
        $self->cfg->set_default_mnemonic($mnemonic);
    }

    $self->toggle_admin_buttons();

    return;
}

sub toggle_admin_buttons {
    my $self = shift;

    my $item = $self->view->get_default_mark('dlist');
    my $sele = $self->view->get_list_selected_index('dlist');

    my $enable = $item == $sele ? 1 : 0;

    $self->view->get_control_named('btn_load')->Enable($enable);
    $self->view->get_control_named('btn_defa')->Enable(not $enable);

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

1; # End of QDepo::Controller
