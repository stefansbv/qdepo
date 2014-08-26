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
        $self->db_connect;
    }

    #- Start

    my $default = $self->view->get_choice_default();
    $self->model->set_choice($default);

    $self->set_event_handlers();
    $self->set_app_mode('idle');

    # Connections list
    $self->populate_connlist;

    # Query list (from qdf)
    $self->populate_querylist;
    my $dt = $self->model->get_data_table_for('qlist');
    my $rec_no = $dt->get_item_count;
    if ( $rec_no >= 0) {
        $self->view->select_list_item('qlist', 'first');
        $self->set_app_mode('sele');
    }

    return;
}

=head2 connect_dialog

Show login dialog until connected or canceled.

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
                $self->model->dbh;
            }
            catch {
                if ( my $e = Exception::Base->catch($_) ) {
                    if ( $e->isa('Exception::Db::Connect') ) {
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
            unless ($self->model->is_connected ) {
                $self->db_connect;
            }
            if ($self->model->is_connected ) {
                $self->view->dialog_progress('Export data');
                $self->model->run_export;
            }
        }
    );

    #-- Quit
    $self->view->event_handler_for_tb_button(
        'tb_qt', sub {
            $self->on_quit;
        }
    );

    #-- Query List
    $self->view->event_handler_for_list(
        'qlist', sub {
            my ( $view, $event ) = @_;
            my $item = $event->GetIndex;
            my $dt   = $self->model->get_data_table_for('qlist');
            $dt->set_item_selected($item);
            # Refresh controlls
            $self->model->on_item_selected_load;
        }
    );

    #-- DB Configs List
    $self->view->event_handler_for_list(
        'dlist', sub {
            my ( $view, $event ) = @_;
            my $item = $event->GetIndex;
            my $dt   = $self->model->get_data_table_for('dlist');
            $dt->set_item_selected($item);
            $self->toggle_admin_buttons;
        }
    );

    #- Admin panel

    #-- Load button
    $self->view->event_handler_for_button(
        'btn_load', sub {
            print "Load config... (not implemented)\n";
        }
    );

    #-- Default button
    $self->view->event_handler_for_button(
        'btn_defa', sub {
            $self->set_default_mnemonic();
        }
    );

    #-- Add button
    $self->view->event_handler_for_button(
        'btn_add', sub {
            my $name = $self->get_text_dialog();
            if ($name) {
                # TODO
                my $new = $self->cfg->new_config_tree($name);
                $self->model->message_log(qq{II New connection: '$new'});
            }
        }
    );

    #-- Refresh button
    $self->view->event_handler_for_button(
        'btn_refr', sub {
            $self->db_connect unless $self->model->is_connected;
            if ($self->model->is_connected ) {
                $self->populate_fieldlist;
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

    my $dt = $self->model->get_data_table_for('qlist');
    if ( $dt->has_items_marked ) {
        my $msg = 'Delete marked reports and quit?';
        my $answer = $self->view->action_confirmed($msg);
        if ($answer eq 'yes') {
            $self->list_remove_marked;
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

    my $dt = $self->model->get_data_table_for('dlist');

    my $item_defa = $dt->get_item_default;
    if (defined $item_defa) {
        $dt->set_value( $item_defa, 2, '' ); # clear label
    }

    my $item_sele = $dt->get_item_selected;
    if ( defined $item_sele ) {
        my $mnemonic = $dt->get_value( $item_sele, 1 );
        $dt->set_value( $item_sele, 2, 'yes' );
        $dt->set_item_default($item_sele);
        $self->cfg->set_default_mnemonic($mnemonic);
        $self->toggle_admin_buttons;
    }

    $self->view->refresh_list('dlist');

    return;
}

sub toggle_admin_buttons {
    my $self = shift;

    my $dt        = $self->model->get_data_table_for('dlist');
    my $item_sele = $dt->get_item_selected;
    my $item_defa = $dt->get_item_default;

    return unless defined($item_sele) and defined($item_defa);

    my $enable = $item_sele == $item_defa ? 1 : 0;
    $self->view->get_control('btn_load')->Enable($enable);
    $self->view->get_control('btn_defa')->Enable(not $enable);

    return;
}

=head2 populate_querylist

Populate the query list.

=cut

sub populate_querylist {
    my $self = shift;

    $self->model->load_qdf_data;             # init

    my $items = $self->model->get_qdf_data;

    return unless scalar keys %{$items};

    my $dt = $self->model->get_data_table_for('qlist');

    my @indices = sort { $a <=> $b } keys %{$items}; # populate in order

    my $columns_meta = $self->model->get_query_list_cols;

    my $row = 0;
    foreach my $idx ( @indices ) {
        my $col = 0;
        foreach my $meta ( @{$columns_meta} ) {
            my $value = $items->{$idx}{ $meta->{field} };
            $dt->set_value( $row, $col, $value );
            $col++;
        }
        $row++;
    }

    $self->view->refresh_list('qlist');

    return;
}

sub populate_fieldlist {
    my $self = shift;

    my ( $columns, $header ) = $self->model->get_columns_list;

    return unless @{$header};

    my $dt = $self->model->get_data_table_for('tlist');

    my $columns_meta = $self->model->get_table_list_cols;

    my $row = 0;
    foreach my $rec ( @{$columns} ) {
        my $col = 0;
        foreach my $meta ( @{$columns_meta} ) {
            my $value = $rec->{ $meta->{field} };
            $dt->set_value( $row, $col, $value );
            $col++;
        }
        $row++;
    }

    $self->view->refresh_list('tlist');

    return;
}

=head2 populate_connlist

Populate list with items.

=cut

sub populate_connlist {
    my $self = shift;

    my $mnemonics_ref = $self->cfg->get_mnemonics;

    return unless @{$mnemonics_ref};

    my $dt = $self->model->get_data_table_for('dlist');

    my $columns_meta = $self->model->get_db_list_cols;

    my $row = 0;
    foreach my $rec ( @{$mnemonics_ref} ) {
        my $col = 0;
        foreach my $meta ( @{$columns_meta} ) {
            my $value = $rec->{ $meta->{field} } // '';
            $dt->set_value( $row, $col, $value );
            $col++;
        }
        $row++;
    }

    $self->model->dlist_default_item;

    my $item = $dt->get_item_default;
    $item = $dt->set_value( $item, 2, 'yes' );

    $self->view->refresh_list('dlist');

    return;
}

sub db_connect {
    my $self = shift;
    unless ( $self->model->is_connected ) {
        try { $self->model->dbh; }
        catch {
            if ( my $e = Exception::Base->catch($_) ) {
                if ( $e->isa('Exception::Db::Connect::Auth') ) {
                    $self->connect_dialog();
                }
                elsif ( $e->isa('Exception::Db::Connect') ) {
                    my $logmsg = $e->usermsg;
                    $self->view->dialog_error('Not connected.', $logmsg);
                    $self->model->message_log(qq{EE $logmsg});
                    $self->view->set_status( 'No DB!', 'db', 'red' );
                }
            }
        };
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

1; # End of QDepo::Controller
