package QDepo::Controller;

# ABSTRACT: The Controller.

use strict;
use warnings;

use Locale::TextDomain 1.20 qw(QDepo);
use Try::Tiny;
use QDepo::Config;
use QDepo::Config::Toolbar;
use QDepo::Model;
use QDepo::Exceptions;

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

    $self->model->message_log(
        __x('{ert} Starting QDepo {verbose}',
            ert     => 'II',
            verbose => $self->cfg->verbose ? '(verbose)' : '',
        )
    );

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
    my $conn = $self->cfg->connection;
    if ($conn) {
        my $dbname = $conn->{dbname};
        my $driver = $conn->{driver};
        $error = __x(
            'Connect to {driver}: {dbname}',
            driver => $driver,
            dbname => $dbname,
        );
    }

  TRY:
    while ( not $self->model->is_connected ) {

        # Show login dialog if still not connected
        my $return_string = $self->dialog_login($error);
        if ($return_string eq 'cancel') {
            $self->model->message_log(
                __x( '{ert} Login cancelled', ert => 'WW' ) );
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
                        # $error = $e->usermsg;
                        $self->model->message_log(
                            __x('{ert} {logmsg}',
                                ert    => 'WW',
                                logmsg => $logmsg
                            )
                        );
                    }
                }
            };
        }
        else {
            $error = __ 'User and password is required';
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
                $self->model->on_item_selected_load;
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
                $self->view->dialog_progress(__ 'Export data');
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
            $self->load_conn_details;
        }
    );

    #- Admin panel

    #-- Load button
    $self->view->event_handler_for_button(
        'btn_load', sub {
            warn "Load config... (not implemented)\n";
        }
    );

    #-- Default button
    $self->view->event_handler_for_button(
        'btn_defa', sub {
            $self->set_default_mnemonic;
        }
    );

    #-- Add button
    $self->view->event_handler_for_button(
        'btn_add', sub {
            $self->add_new_menmonic;
        }
    );

    #-- Default button
    $self->view->event_handler_for_button(
        'btn_edit', sub {
            warn "Edit config... (not implemented)\n";
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

    my $conf = QDepo::Config::Toolbar->new;  # TODO: should this go to init?
    my $mode = $self->model->get_appmode();

    foreach my $name ( $conf->all_buttons ) {
        my $status = $conf->get_tool($name)->{state}{$mode};
        $self->view->enable_tool( $name, $status );
    }

    my $is_edit = $self->model->is_appmode('edit') ? 1 : 0;

    # Toggle List control state
    $self->view->toggle_list_enable('qlist', !$is_edit );

    # Controls by page Enabled in edit mode
    foreach my $page (qw(list para sql admin )) {
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
    warn 'save_qdf_data not implemented in ', __PACKAGE__, "\n";
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
        my $msg = __ 'Delete marked reports and quit?';
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
    $self->view->get_control('btn_edit')->Enable;

    return;
}

sub load_conn_details {
    my $self = shift;
    my $dt    = $self->model->get_data_table_for('dlist');
    my $item  = $dt->get_item_selected;
    my $mnemo = $dt->get_value($item, 1);
    my $rec   = $self->cfg->get_details_for($mnemo);
    $self->view->controls_write( 'admin', $rec->{connection} );
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

    my @indices = sort { $a <=> $b } keys %{$items}; # populate in order

    foreach my $idx ( @indices ) {
        $self->list_add_item('qlist', $items->{$idx} );
    }

    return;
}

sub populate_fieldlist {
    my $self = shift;

    # Initialize list
    my $data_table = $self->model->get_data_table_for('tlist');
    $data_table->clear_all_items;
    $self->view->refresh_list('tlist');

    my ( $columns, $header );
    my $success = try {
        ( $columns, $header ) = $self->model->get_columns_list;
        1;
    }
    catch {
        if ( my $e = Exception::Base->catch($_) ) {
            if ( $e->isa('Exception::Db::SQL::Parser') ) {
                $self->model->message_log(
                    __x('{ert} {message}: {details}',
                        ert     => 'EE',
                        message => $e->usermsg,
                        details => $e->logmsg,
                    )
                );
            }
        }
        else {
            $self->model->message_log(
                __x('{ert} {message}: {details}',
                    ert     => 'EE',
                    message => __ 'Unknown exception',
                    details => $_,
                )
            );
        }
        return undef;           # required!
    };

    foreach my $rec ( @{$columns} ) {
        $self->list_add_item('tlist', $rec);
    }

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

    my $columns_meta = $self->model->list_meta_data('dlist');

    foreach my $rec ( @{$mnemonics_ref} ) {
        $rec->{default} = ( $rec->{default} == 1 ) ? __('Yes') : q{};
        $self->list_add_item('dlist', $rec);
    }

    my $item = $self->model->dlist_default_item;
    $self->view->select_list_item('dlist', $item);

    return;
}

=head2 list_add_item

Generic method to add a list item to a list control.

    my $rec = {
        mnemonic => "test",
        recno    => 1,
    }

=cut

sub list_add_item {
    my ($self, $list, $rec) = @_;

    my $data_table = $self->model->get_data_table_for($list);
    my $row        = $data_table->get_item_count;
    my $cols_meta  = $self->model->list_meta_data($list);

    my $col = 0;
    foreach my $meta ( @{$cols_meta} ) {
        my $field = $meta->{field};
        my $value
            = $field eq 'recno'
            ? ( $row + 1 )
            : ( $rec->{$field} // q{} )
            ;
        $data_table->set_value( $row, $col, $value );
        $col++;
    }

    $self->view->refresh_list($list);

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
                    $self->view->dialog_error(__ 'Not connected.', $logmsg);
                    $self->model->message_log(
                        __x('{ert} {logmsg}',
                            ert    => 'WW',
                            logmsg => $logmsg
                        )
                    );
                    $self->view->set_status(__ 'No DB!', 'db', 'red' );
                }
            }
        };
    }
    return;
}

sub add_new_menmonic {
    my $self = shift;

    my $name = $self->get_text_dialog();
    my $newconn;
    if ($name) {
        my $success = try {
            $newconn = $self->cfg->new_config_tree($name);
            1;
        }
        catch {
            if ( my $e = Exception::Base->catch($_) ) {
                if ( $e->isa('Exception::IO::PathExists') ) {
                    $self->model->message_log(
                        __x('{ert} {message}: "{pathname}"',
                            ert      => 'EE',
                            message  => $e->message,
                            pathname => $e->pathname,
                        )
                    );
                }
                else {
                    print "!!! OTHER EXCEPTION !!!\n"; # TODO
                }
            }
            return undef;           # required!
        };
        return unless $success;

        $self->model->message_log(
            __x('{ert} New connection: {newconn}',
                ert     => 'II',
                newconn => $newconn,
            )
        );

        # Add to list
        my $rec = {
            default  => 0,
            mnemonic => $name,
        };
        $rec->{default} = ( $rec->{default} == 1 ) ? __('Yes') : q{};
        $self->list_add_item('dlist', $rec);
    }

    return;
}

1;
