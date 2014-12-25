package QDepo::Controller;

# ABSTRACT: The Controller.

use strict;
use warnings;

use Scalar::Util qw(blessed);
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
    my $self  = {
        _model => QDepo::Model->new(),
        _cfg   => QDepo::Config->instance(),
    };
    bless $self, $class;
    return $self;
}

sub model {
    my $self = shift;
    return $self->{_model};
}

sub cfg {
    my $self = shift;
    return $self->{_cfg};
}

sub view {
    my $self = shift;
    return $self->{_view};
}

sub start {
    my $self = shift;

    $self->model->message_log(
        __x('{ert} Starting QDepo {verbose}',
            ert     => 'II',
            verbose => $self->cfg->verbose ? '(verbose)' : '',
        )
    );

    $self->model->get_connection_observable->set(0);    # init

    my $default_output = $self->view->get_choice_default();
    $self->model->set_choice($default_output);

    $self->set_event_handlers();
    $self->set_app_mode('idle');

    $self->populate_connlist;
    $self->toggle_controls_page( 'admin', 0 );
    $self->load_mnemonic;

    return;
}

sub populate_connlist {
    my $self          = shift;
    my $mnemonics_ref = $self->cfg->get_mnemonics;
    return unless @{$mnemonics_ref};

    my $current_idx;
    foreach my $rec ( @{$mnemonics_ref} ) {
        $current_idx = $rec->{recno} - 1 if $rec->{current} == 1;
        $self->list_add_item( 'dlist', $rec );
    }
    $self->view->select_list_item( 'dlist', $current_idx );
    return;
}

sub populate_querylist {
    my $self = shift;
    $self->model->load_qdf_data_init;
    my $items = $self->model->get_qdf_data;
    return unless scalar keys %{$items};

    my @indices = sort { $a <=> $b } keys %{$items};    # populate in order
    foreach my $idx (@indices) {
        $self->list_add_item( 'qlist', $items->{$idx} );
    }
    my $dt = $self->model->get_data_table_for('qlist');
    if ( $dt->get_item_count >= 0 ) {
        $self->set_app_mode('sele');
        $self->view->select_list_item( 'qlist', 'first' );
    }
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
            if ( $self->is_connected ) {
                $self->view->dialog_progress( __ 'Export data' );
                $self->model->run_export;
            }
            else {
                $self->model->message_log(
                    __x('{ert} {logmsg}',
                        ert    => 'WW',
                        logmsg => q(Unable to run export, not connected.),
                    )
                );
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
            my ( $view, $event ) = @_;
            my $item = $event->GetIndex;
            my $dt   = $self->model->get_data_table_for('qlist');
            $dt->set_item_selected($item);
            $self->model->on_item_selected_load;
        }
    );

    #-- DB Configs List
    $self->view->event_handler_for_list(
        'dlist',
        sub {
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
        'btn_load',
        sub {
            $self->load_selected_mnemonic;
        }
    );

    #-- Default button
    $self->view->event_handler_for_button(
        'btn_defa',
        sub {
            $self->set_default_mnemonic;
            $self->set_default_item;
        }
    );

    #-- Add button
    $self->view->event_handler_for_button(
        'btn_add',
        sub {
            $self->model->is_appmode('admin')
                ? $self->set_app_mode('sele')
                : $self->add_new_menmonic;
        }
    );

    #-- Edit button
    $self->view->event_handler_for_button(
        'btn_edit',
        sub {
            $self->edit_connections;
        }
    );

    #-- Refresh button
    $self->view->event_handler_for_button(
        'btn_refr',
        sub {
            if ( $self->is_connected ) {
                $self->populate_info;
            }
            else {
                $self->model->message_log(
                    __x('{ert} {logmsg}',
                        ert    => 'WW',
                        logmsg => q(Unable to retrieve info, not connected.),
                    )
                );
            }
        }
    );

    return;
}

sub toggle_interface_controls {
    my $self = shift;

    my $conf = QDepo::Config::Toolbar->new;
    my $mode = $self->model->get_appmode();

    foreach my $name ( $conf->all_buttons ) {
        my $status = $conf->get_tool($name)->{state}{$mode};
        $self->view->enable_tool( $name, $status );
    }

    my $is_edit  = $self->model->is_appmode('edit')  ? 1 : 0;
    my $is_admin = $self->model->is_appmode('admin') ? 1 : 0;
    my $edit = ( $is_edit or $is_admin );

    # Toggle List control states
    $self->view->toggle_list_enable( 'qlist', !$edit );
    $self->view->toggle_list_enable( 'dlist', !$edit );
    $self->view->toggle_list_enable( 'tlist', !$edit );

    # Toggle refresh button on info page
    $self->view->get_control('btn_refr')->Enable( !$edit );
    $self->view->get_control('btn_refr')->Enable( $mode ne 'idle' );

    $self->toggle_interface_controls_edit($is_edit);
    $self->toggle_interface_controls_admin($is_admin);

    return;
}

sub toggle_interface_controls_edit {
    my ( $self, $is_edit ) = @_;

    $self->view->get_control('btn_load')->Enable( !$is_edit );
    $self->view->get_control('btn_defa')->Enable( !$is_edit );
    $self->view->get_control('btn_edit')->Enable( !$is_edit );
    $self->view->get_control('btn_add')->Enable( !$is_edit );

    # Controls by page Enabled in edit mode
    foreach my $page (qw(list para sql)) {
        $self->toggle_controls_page( $page, $is_edit );
    }

    return;
}

sub toggle_interface_controls_admin {
    my ( $self, $is_admin ) = @_;

    $self->view->toggle_list_enable( 'dlist', !$is_admin );
    $self->toggle_controls_page( 'admin', $is_admin );

    $self->view->get_control('btn_load')->Enable( !$is_admin );
    $self->view->get_control('btn_defa')->Enable( !$is_admin );
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
    my ( $self, $page, $is_edit ) = @_;

    my $get      = 'get_controls_' . $page;
    my $controls = $self->view->$get();

    foreach my $control ( @{$controls} ) {
        foreach my $name ( keys %{$control} ) {
            my ( $state, $color );
            if ($is_edit) {
                $state = $control->{$name}[1];    # normal | disabled
                $color = $control->{$name}[2];    # name
            }
            else {
                $state = 'disabled';
            }
            $self->view->set_editable( $control, $name, $state, $color );
        }
    }

    return;
}

sub on_page_p1_activate {
    my $self = shift;
    return;
}

sub on_page_p2_activate {
    my $self = shift;
    ### Does not work: no mouse interaction!!!
    # if ( $self->is_connected ) {
    #     $self->populate_info;
    # }
    # else {
    #     $self->model->message_log(
    #         __x('{ert} {logmsg}',
    #             ert    => 'WW',
    #             logmsg => q(Unable to retrieve info, not connected.),
    #         )
    #     );
    # }
    ###
    return;
}

sub on_page_p3_activate {
    my $self = shift;
    return;
}

sub on_page_p4_activate {
    my $self = shift;
    return;
}

sub save_qdf_data {
    warn 'save_qdf_data not implemented in ', __PACKAGE__, "\n";
    return;
}

sub on_quit {
    my ( $self, @args ) = @_;
    print "Shuting down...\n";
    my $dt = $self->model->get_data_table_for('qlist');
    if ( $dt->has_items_marked ) {
        my $msg    = __ 'Delete marked reports and quit?';
        my $answer = $self->view->action_confirmed($msg);
        if ( $answer eq 'yes' ) {
            $self->list_remove_marked;
        }
        elsif ( $answer eq 'cancel' ) {
            return;
        }
    }
    $self->view->on_close_window(@args);
    return;
}

sub list_remove_marked {
    print 'list_remove_marked not implemented in ', __PACKAGE__, "\n";
    return;
}

sub set_default_item {
    my $self      = shift;
    my $dt        = $self->model->get_data_table_for('dlist');
    my $item_sele = $dt->get_item_selected;
    $dt->set_item_default($item_sele) if defined $item_sele;
    return;
}

sub get_selected_mnemonic {
    my $self = shift;
    my $dt   = $self->model->get_data_table_for('dlist');
    my $item = $dt->get_item_selected;
    return $dt->get_value( $item, 1 ) if defined $item;
    return;
}

sub set_default_mnemonic {
    my $self     = shift;
    my $mnemonic = $self->get_selected_mnemonic;
    if ($mnemonic) {
        $self->cfg->save_default_mnemonic($mnemonic);
        $self->toggle_admin_buttons;
    }
    $self->view->refresh_list('dlist');
    return;
}

sub load_mnemonic {
    my $self = shift;
    unless ( $self->cfg->mnemonic ) {
        $self->model->message_log(
            __x( '{ert} No configuration mnemonic loaded', ert => 'WW' ) );
        return;
    }
    my $mnemonic = $self->cfg->mnemonic;
    $self->model->message_log(
        __x(qq({ert} Loading mnemonic "{mnemonic}"),
            ert      => 'II',
            mnemonic => $mnemonic,
        )
    );
    $self->toggle_admin_buttons;
    $self->view->refresh_list('dlist');
    $self->view->focus_list('qlist');
    $self->populate_querylist;
    return;
}

sub load_selected_mnemonic {
    my $self = shift;

    # Init
    $self->model->disconnect;
    $self->model->get_data_table_for('qlist')->clear_all_items;
    $self->view->refresh_list('qlist');
    $self->model->get_data_table_for('tlist')->clear_all_items;
    $self->view->refresh_list('tlist');
    $self->view->querylist_form_clear;

    my $dt        = $self->model->get_data_table_for('dlist');
    my $item_sele = $dt->get_item_selected;
    if ( defined $item_sele ) {
        my $mnemonic = $dt->get_value( $item_sele, 1 );
        $self->model->message_log(
            __x(qq({ert} Loading selected mnemonic "{mnemonic}"),
                ert      => 'II',
                mnemonic => $mnemonic,
            )
        );
        $dt->set_item_current($item_sele);
        $self->view->set_status( $mnemonic, 'mn', 'green' );
        $self->cfg->mnemonic($mnemonic);
        $self->toggle_admin_buttons;
        $self->view->refresh_list('dlist');
        $self->populate_querylist;
        $self->model->on_item_selected_load;    # force load
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
    my $self  = shift;
    my $dt    = $self->model->get_data_table_for('dlist');
    my $item  = $dt->get_item_selected;
    my $mnemo = $dt->get_value( $item, 1 );
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
        $self->db_exception( $_, "populate info" );
        return;    # required!
    }
    finally {
        my $table_names;
        $table_names = join ', ', @{$tables} if ref $tables;
        $table_names ||= 'Unknown!';
        $self->view->controls_write_onpage( 'info',
            { table_name => $table_names } );
    };
    return unless $success;

    # Populate fields list
    foreach my $rec ( @{$columns} ) {
        $self->list_add_item( 'tlist', $rec );
    }

    return;
}

sub list_add_item {
    my ( $self, $list, $rec ) = @_;
    my $data_table = $self->model->get_data_table_for($list);
    my $cols_meta  = $self->model->list_meta_data($list);
    my $row        = $data_table->get_item_count;
    my $col        = 0;
    foreach my $meta ( @{$cols_meta} ) {
        my $field = $meta->{field};
        my $value
            = $field eq q{}     ? q{}
            : $field eq 'recno' ? ( $row + 1 )
            :                     ( $rec->{$field} // q{} );
        $data_table->set_value( $row, $col, $value );
        $col++;
    }
    $data_table->set_item_default($row)
        if exists $rec->{default} and $rec->{default} == 1;
    if ( exists $rec->{current} and $rec->{current} == 1 ) {
        $data_table->set_item_current($row);
        $self->view->set_status( $rec->{mnemonic}, 'mn', 'green' );
    }
    $self->view->refresh_list($list);
    return $row;
}

sub is_connected {
    my $self = shift;
    unless ( $self->model->is_connected ) {
        try { $self->model->db_connect; 1; }
        catch {
            $self->db_connect_auth_exception( $_, "is connected" );
        };
    }
    return $self->model->is_connected;
}

sub db_connect_auth_exception {
    my ( $self, $exc, $context ) = @_;
    if ( my $e = Exception::Base->catch($exc) ) {
        if ( $e->isa('Exception::Db::Connect::Auth') ) {
            $self->connect_dialog_loop;
        }
        elsif ( $e->isa('Exception::Db::Connect') ) {
            my $logmsg = $e->usermsg;
            $self->model->message_log(
                __x('{ert} {logmsg}',
                    ert    => 'EE',
                    logmsg => $logmsg
                )
            );
            $self->view->set_status( __ 'Not connected', 'db', 'red' );
        }
    }
    return;
}

sub connect_dialog_loop {
    my $self = shift;
    my $error;
    my $conn = $self->cfg->connection;
    if ( blessed $conn) {
        $error = __x(
            'Connect to {driver}: {dbname}',
            driver => $conn->driver,
            dbname => $conn->dbname,
        );
    }

TRY:
    while ( not $self->model->is_connected ) {

        # Show login dialog if still not connected
        my $return_string = $self->dialog_login($error);
        if ( $return_string eq 'cancel' ) {
            $self->model->message_log(
                __x( '{ert} Login cancelled', ert => 'WW' ) );
            last TRY;
        }

        # Try to connect only if user and pass are provided
        if ( $self->cfg->user and $self->cfg->pass ) {
            my $success = try { $self->model->db_connect; 1; }
            catch {
                if ( my $e = Exception::Base->catch($_) ) {
                    if ( $e->isa('Exception::Db::Connect::Auth') ) {
                        $error = __ 'Wrong user and/or password';
                    }
                    elsif ( $e->isa('Exception::Db::Connect') ) {
                        my $logmsg = $e->usermsg;
                        $self->model->message_log(
                            __x('{ert} {logmsg}',
                                ert    => 'EE',
                                logmsg => $logmsg
                            )
                        );
                        last TRY;
                    }
                }
                return;    # required!
            };
            last TRY if $success;
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
            $self->io_exception( $_, "add new menmonic" );
            return;    # required!
        };
        return unless $success;

        $self->model->message_log(
            __x('{ert} New connection: {newconn}',
                ert     => 'II',
                newconn => $newconn,
            )
        );
        my $rec = {
            default  => 0,
            mnemonic => $name,
        };    # add to list
        my $item = $self->list_add_item( 'dlist', $rec );
        $self->view->select_list_item( 'dlist', $item );
    }

    return;
}

sub edit_connections {
    my $self = shift;

    if ( $self->model->is_appmode('admin') ) {
        my $dt       = $self->model->get_data_table_for('dlist');
        my $mnemonic = $self->get_selected_mnemonic;
        unless ($mnemonic) {
            $self->model->message_log(
                __x( '{ert} No selected mnemonic', ert => 'WW' ) );
            return;
        }

        # Save connection data
        my $yaml_file = $self->cfg->config_file_name($mnemonic);
        my $conn_aref = $self->view->controls_read_frompage('admin');
        my $conn_data = QDepo::Utils->transform_data($conn_aref);

        try {
            QDepo::Config::Utils->write_yaml( $yaml_file, 'connection',
                $conn_data );
        }
        catch {
            $self->io_exception( $_, "edit connections" );
        };
        $self->model->message_log(
            __x('{ert} Saved: "{filename}"',
                ert      => 'II',
                filename => $yaml_file,
            )
        );
        $self->set_app_mode('sele');
    }
    else {
        $self->set_app_mode('admin');
    }

    return;
}

sub db_connect_exception {
    my ( $self, $exc, $context ) = @_;
    if ( my $e = Exception::Base->catch($exc) ) {
        if ( $e->isa('Exception::Db::Connect') ) {
            my $logmsg  = $e->logmsg;
            my $usermsg = $e->usermsg;
            $self->model->message_log(
                __x('{ert} {usermsg}',
                    ert     => 'WW',
                    usermsg => $usermsg,
                )
            );
        }
        else {
            $self->model->message_log(
                __x('{ert} {message}: {details}',
                    ert     => 'EE',
                    message => __ 'Unknown error',
                    details => $_,
                )
            );
        }
    }
    return;
}

sub db_exception {
    my ( $self, $exc, $context ) = @_;
    if ( my $e = Exception::Base->catch($exc) ) {
        if ( $e->isa('Exception::Db::Connect') ) {
            my $logmsg  = $e->logmsg;
            my $usermsg = $e->usermsg;
            $self->model->message_log(
                __x('{ert} {usermsg}',
                    ert     => 'WW',
                    usermsg => $usermsg,
                )
            );
        }
        elsif ( $e->isa('Exception::Db::SQL::Parser') ) {
            ( my $logmsg = $e->logmsg ) =~ s{\n}{\ }xm;
            $self->model->message_log(
                __x('{ert} {message}: {details}',
                    ert     => 'WW',
                    message => $e->usermsg,
                    details => $logmsg,
                )
            );
        }
        elsif ( $e->isa('Exception::Db::SQL::NoObject') ) {
            $self->model->message_log(
                __x('{ert} {message}',
                    ert     => 'EE',
                    message => $e->usermsg,
                )
            );
        }
        else {
            $self->model->message_log(
                __x('{ert} {message}: {details}',
                    ert     => 'EE',
                    message => __ 'Unknown error',
                    details => $_,
                )
            );
        }
    }
    return;
}

sub io_exception {
    my ( $self, $exc, $context ) = @_;
    if ( my $e = Exception::Base->catch($_) ) {
        if ( $e->isa('Exception::IO::WriteError') ) {
            $self->model->message_log(
                __x('{ert} Save failed: {message} ({filename})',
                    ert      => 'EE',
                    message  => $e->message,
                    filename => $e->filename,
                )
            );
        }
    }
    elsif ( $e->isa('Exception::IO::PathExists') ) {
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
            )
        );
    }
    return;
}

1;

=head1 SYNOPSIS

    use QDepo::Controller;

    my $controller = QDepo::Controller->new();

    $controller->start();

=head1 DESCRIPTION

This module provides the implementation for the L<controller> aka L<C> from the
MVC pattern.  There is also a derived class with an implementation specific for
the Wx interface.

=head2 Methods

=head3 new

Constructor method.

Builds and returns a new Controller object.  Holds the following instance
variables:

=over

=item C<model>

=item C<cfg>

=item C<view>

=back

=head3 model

Return the Model module instance variable.

=head3 cfg

Return the Config module instance variable.  The Config module is created using
the singleton pattern.

=head3 view

Return the View module instance variable.

=head3 start

Connect if user and pass or if driver is SQLite. Retry and show login dialog,
until connected or fatal error message received from the RDBMS.

=head3 populate_connlist

Populate list with items.

=head3 populate_querylist

Populate the query list.

=head3 connect_dialog_loop

Show login dialog until connected or canceled.

=head3 dialog_login

Login dialog.

=head3 set_app_mode

Set application mode.

=head3 on_screen_mode_idle

Idle mode.

=head3 on_screen_mode_edit

Edit mode.

=head3 on_screen_mode_sele

Select mode.

=head3 on_screen_mode_admin

=head3 set_event_handlers

Setup event handlers for the interface.

=head3 toggle_interface_controls

Toggle controls (tool bar buttons) appropriate for different states of the
application.

=head3 toggle_interface_controls_edit

=head3 toggle_interface_controls_admin

=head3 toggle_controls_page

Toggle the controls on page.

=head3 on_page_p1_activate

Empty method.

=head3 on_page_p2_activate

Empty method.

=head3 on_page_p3_activate

Empty method.

=head3 on_page_p4_activate

Empty method.

=head3 save_qdf_data

Save .qdf file.

=head3 on_quit

Before quit, ask for permission to delete the marked .qdf files, if
L<has_marks> is true.

=head3 list_remove_marked

Remove marked items.

=head3 set_default_item

=head3 get_selected_mnemonic

=head3 set_default_mnemonic

=head3 load_mnemonic

=head3 load_selected_mnemonic

=head3 toggle_admin_buttons

=head3 load_conn_details

=head3 populate_info

=head3 list_add_item

Generic method to add a list item to a list control.

    my $rec = {
        mnemonic => "test",
        recno    => 1,
    }

=head3 is_connected

=head3 add_new_menmonic

=head3 edit_connections

=head3 db_connect_exception

=head3 db_exception

=head3 io_exception

=cut
