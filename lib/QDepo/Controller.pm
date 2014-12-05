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
use QDepo::Utils;
use QDepo::Config::Utils;

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

sub cfg {
    my $self = shift;
    return $self->{_cfg};
}

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

    my $default_output = $self->view->get_choice_default();
    $self->model->set_choice($default_output);

    $self->set_event_handlers();
    $self->set_app_mode('idle');

    $self->populate_connlist;
    $self->toggle_controls_page( 'admin', 0 );
#    $self->load_mnemonic;

    return;
}

sub populate_connlist {
    my $self = shift;

    my $mnemonics_ref = $self->cfg->get_mnemonics;
    return unless @{$mnemonics_ref};

    my $current_recno;
    foreach my $rec ( @{$mnemonics_ref} ) {
        $current_recno = $rec->{recno} if $rec->{current} == 1;
        $self->list_add_item('dlist', $rec);
    }
    $self->view->select_list_item('dlist', $current_recno - 1);

    return;
}

sub populate_querylist {
    my $self = shift;
    $self->model->load_qdf_data;             # init
    my $items = $self->model->get_qdf_data;
    return unless scalar keys %{$items};

    $self->model->get_data_table_for('qlist')->clear_all_items;

    my @indices = sort { $a <=> $b } keys %{$items}; # populate in order
    foreach my $idx ( @indices ) {
        $self->list_add_item('qlist', $items->{$idx} );
    }
    return;
}

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

sub dialog_login {
    print 'dialog_login not implemented in ', __PACKAGE__, "\n";
    return;
}

sub set_app_mode {
    my ( $self, $mode ) = @_;

    if ( $mode eq 'sele' ) {
        my $item_no = $self->view->get_list_max_index('qlist') + 1;

        # Set mode to 'idle' if no items
        $mode = 'idle' if $item_no <= 0;
    }

    $self->model->set_mode($mode);

    my %method_for = (
        idle  => 'on_screen_mode_idle',
        edit  => 'on_screen_mode_edit',
        sele  => 'on_screen_mode_sele',
        admin => 'on_screen_mode_admin',
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
    $self->view->toggle_list_enable('qlist');
    $self->view->toggle_list_enable('dlist');
    $self->view->toggle_sql_replace('edit');
    return;
}

sub on_screen_mode_sele {
    my $self = shift;
    $self->view->toggle_sql_replace('sele');
    return;
}

sub on_screen_mode_admin {
    my $self = shift;
    $self->view->toggle_list_enable('qlist');
    $self->view->toggle_list_enable('dlist');
    $self->view->toggle_sql_replace('edit');
    return;
}

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
            $self->populate_info;
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
            $self->load_mnemonic;
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
            $self->model->is_appmode('admin')
                ? $self->set_app_mode('sele')
                : $self->add_new_menmonic;
        }
    );

    #-- Edit button
    $self->view->event_handler_for_button(
        'btn_edit', sub {
            $self->edit_connections;
        }
    );

    #-- Refresh button
    $self->view->event_handler_for_button(
        'btn_refr', sub {
            $self->db_connect unless $self->model->is_connected;
            if ($self->model->is_connected ) {
                $self->populate_info;
            }
        }
    );

    return;
}

sub model {
    my $self = shift;
    return $self->{_model};
}

sub view {
    my $self = shift;
    return $self->{_view};
}

sub toggle_interface_controls {
    my $self = shift;

    my $conf = QDepo::Config::Toolbar->new;  # TODO: should this go to init?
    my $mode = $self->model->get_appmode();

    foreach my $name ( $conf->all_buttons ) {
        my $status = $conf->get_tool($name)->{state}{$mode};
        $self->view->enable_tool( $name, $status );
    }

    my $is_edit  = $self->model->is_appmode('edit')  ? 1 : 0;
    my $is_admin = $self->model->is_appmode('admin') ? 1 : 0;
    my $edit     = ($is_edit or $is_admin);

    # Toggle List control states
    $self->view->toggle_list_enable('qlist', !$edit );
    $self->view->toggle_list_enable('dlist', !$edit );
    $self->view->toggle_list_enable('tlist', !$edit );

    # Toggle refresh button on info page
    $self->view->get_control('btn_refr')->Enable(!$edit);

    $self->toggle_interface_controls_edit($is_edit);
    $self->toggle_interface_controls_admin($is_admin);

    return;
}

sub toggle_interface_controls_edit {
    my ($self, $is_edit) = @_;

    $self->view->get_control('btn_load')->Enable(!$is_edit);
    $self->view->get_control('btn_defa')->Enable(!$is_edit);
    $self->view->get_control('btn_edit')->Enable(!$is_edit);
    $self->view->get_control('btn_add' )->Enable(!$is_edit);

    # Controls by page Enabled in edit mode
    foreach my $page (qw(list para sql)) {
        $self->toggle_controls_page( $page, $is_edit );
    }

    return;
}

sub toggle_interface_controls_admin {
    my ($self, $is_admin) = @_;

    $self->view->toggle_list_enable( 'dlist', !$is_admin );
    $self->toggle_controls_page( 'admin', $is_admin );

    $self->view->get_control('btn_load')->Enable(!$is_admin);
    $self->view->get_control('btn_defa')->Enable(!$is_admin);
    if ($is_admin) {
        $self->view->get_control('btn_edit')->SetLabel( __ '&Save' );
        $self->view->get_control('btn_add')->SetLabel( __ '&Cancel' );
    }
    else {
        $self->view->get_control('btn_edit')->SetLabel( __ '&Edit' );
        $self->view->get_control('btn_add')->SetLabel( __ '&Add' );
    }

    return;
}

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
            $self->view->set_editable($control, $name, $state, $color);
        }
    }

    return;
}

sub save_qdf_data {
    warn 'save_qdf_data not implemented in ', __PACKAGE__, "\n";
    return;
}

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

sub list_remove_marked {
    print 'list_remove_marked not implemented in ', __PACKAGE__, "\n";
    return;
}

sub set_default_mnemonic {
    my $self = shift;

    my $dt = $self->model->get_data_table_for('dlist');

    my $item_sele = $dt->get_item_selected;
    if ( defined $item_sele ) {
        my $mnemonic = $dt->get_value( $item_sele, 1 );
        $dt->set_item_default($item_sele);
        $self->cfg->save_default_mnemonic($mnemonic);
        $self->toggle_admin_buttons;
    }
    $self->view->refresh_list('dlist');

    return;
}

sub load_mnemonic {
    my $self = shift;
    my $dt_d = $self->model->get_data_table_for('dlist');
    my $item_sele = $dt_d->get_item_selected;
    if ( defined $item_sele ) {
        my $mnemonic = $dt_d->get_value( $item_sele, 1 );
        print "loading mnemonic '$mnemonic'\n";
        $self->cfg->mnemonic($mnemonic);
        $dt_d->set_item_current($item_sele);
        $self->toggle_admin_buttons;
    }
    $self->view->refresh_list('dlist');

    # Query list (from qdf)
    $self->populate_querylist;
    my $dt_q = $self->model->get_data_table_for('qlist');
    my $rec_no = $dt_q->get_item_count;
    if ( $rec_no >= 0) {
        $self->view->select_list_item('qlist', 'first');
        $self->set_app_mode('sele');
        $self->view->{qlist}->SetFocus;
    }
    return;
}

sub toggle_admin_buttons {
    my $self = shift;

    my $dt        = $self->model->get_data_table_for('dlist');
    my $item_sele = $dt->get_item_selected;
    my $item_defa = $dt->get_item_default;
    my $item_load = $dt->get_item_current;

    return
            unless defined($item_sele)
        and defined($item_defa)
        and defined($item_load);

    my $enable_defa = $item_sele == $item_defa ? 0 : 1;
    my $enable_load = $item_sele == $item_load ? 0 : 1;
    $self->view->get_control('btn_load')->Enable($enable_load);
    $self->view->get_control('btn_defa')->Enable($enable_defa);
    $self->view->get_control('btn_edit')->Enable;

    return;
}

sub load_conn_details {
    my $self = shift;
    my $dt    = $self->model->get_data_table_for('dlist');
    my $item  = $dt->get_item_selected;
    my $mnemo = $dt->get_value($item, 1);
    my $rec   = $self->cfg->get_details_for($mnemo);
    $self->view->controls_write_onpage( 'admin', $rec->{connection} );
    return;
}

sub populate_info {
    my $self = shift;

    # Initialize list
    my $data_table = $self->model->get_data_table_for('tlist');
    $data_table->clear_all_items;
    $self->view->refresh_list('tlist');

    my ( $columns, $header, $tables );
    my $success = try {
        ( $columns, $header, $tables ) = $self->model->parse_sql_text;
        1;
    }
    catch {
        if ( my $e = Exception::Base->catch($_) ) {
            if ( $e->isa('Exception::Db::SQL::Parser') ) {
                ( my $logmsg = $e->logmsg ) =~ s{\n}{ }m;
                $self->model->message_log(
                    __x('{ert} {message}: {details}',
                        ert     => 'WW',
                        message => $e->usermsg,
                        details => $logmsg,
                    )
                );
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
    }
    finally {
        # Table names
        my $table_names;
        $table_names = join ', ', @{$tables} if ref $tables;
        $table_names ||= 'Unknown!';
        $self->view->controls_write_onpage( 'info',
            { table_name => $table_names } );
    };
    return unless $success;

    # Fields list
    foreach my $rec ( @{$columns} ) {
        $self->list_add_item('tlist', $rec);
    }

    return;
}

sub list_add_item {
    my ($self, $list, $rec) = @_;
    my $data_table = $self->model->get_data_table_for($list);
    my $cols_meta  = $self->model->list_meta_data($list);
    my $row = $data_table->get_item_count;
    my $col = 0;
    foreach my $meta ( @{$cols_meta} ) {
        my $field = $meta->{field};
        my $value
            = $field eq q{}       ? q{}
            : $field eq 'recno'   ? ( $row + 1 )
            :                       ( $rec->{$field} // q{} );
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
                    $self->model->message_log(
                        __x('{ert} {message} {error}',
                            ert     => 'EE',
                            message => __ 'Unknown exception',
                            error   => $_,
                        ) );
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
#        $rec->{default} = ( $rec->{default} == 1 ) ? __('Yes') : q{};
        $self->list_add_item('dlist', $rec);
    }

    return;
}

sub edit_connections {
    my $self = shift;

    if ( $self->model->is_appmode('admin') ) {

        # Save connection data
        my $yaml_file = $self->cfg->config_file_name;
        my $conn_aref = $self->view->controls_read_frompage('admin');
        my $conn_data = QDepo::Utils->transform_data($conn_aref);

        try {
            QDepo::Config::Utils->write_yaml( $yaml_file, 'connection',
                $conn_data );
        }
        catch {
            if ( my $e = Exception::Base->catch($_) ) {
                if ( $e->isa('Exception::IO::WriteError') ) {
                    $self->model->message_log(
                        __x('{ert} Save failed: {message} ({filename})',
                            ert      => 'EE',
                            message  => $e->message,
                            filename => $e->filename,
                        ) );
                }
                else {
                    $self->model->message_log(
                    __x('{ert} {message}',
                        ert     => 'EE',
                        message => __ 'Unknown exception',
                    ) );
                }
            }
            else {
                $self->model->message_log(
                    __x('{ert} Saved {filename}',
                        ert      => 'EE',
                        filename => $yaml_file,
                    )
                );
            }
        };
        $self->set_app_mode('sele');
    }
    else {
        $self->set_app_mode('admin');
    }

    return;
}

1;

=head1 SYNOPSIS

    use QDepo::Controller;

    my $controller = QDepo::Controller->new();

    $controller->start();

=head2 new

Constructor method.

=head2 cfg

Return config instance variable

=head2 start

Connect if user and pass or if driver is SQLite. Retry and show login
dialog, until connected or fatal error message received from the
RDBMS.

=head2 connect_dialog

Show login dialog until connected or canceled.

=head2 dialog_login

Login dialog.

=head2 set_app_mode

Set application mode.

=head2 on_screen_mode_idle

Idle mode.

=head2 on_screen_mode_edit

Edit mode.

=head2 on_screen_mode_sele

Select mode.

=head2 set_event_handlers

Setup event handlers for the interface.

=head2 model

Return model instance variable.

=head2 view

Return view instance variable.

=head2 toggle_interface_controls

Toggle controls (tool bar buttons) appropriate for different states of
the application.

=head2 toggle_controls_page

Toggle the controls on page.

=head2 save_qdf_data

Save .qdf file.

=head2 on_quit

Before quit, ask for permission to delete the marked .qdf files, if
L<has_marks> is true.

=head2 list_remove_marked

Remove marked items.

=head2 populate_querylist

Populate the query list.

=head2 populate_connlist

Populate list with items.

=head2 list_add_item

Generic method to add a list item to a list control.

    my $rec = {
        mnemonic => "test",
        recno    => 1,
    }

=cut
