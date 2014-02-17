package QDepo::Wx::Controller;

use strict;
use warnings;
use utf8;

use Wx ':everything';

require QDepo::Wx::App;

use base qw{QDepo::Controller};

=head1 NAME

QDepo::Wx::Controller - The Controller

=head1 VERSION

Version 0.39

=cut

our $VERSION = '0.39';

=head1 SYNOPSIS

    use QDepo::Wx::Controller;

    my $controller = QDepo::Wx::Controller->new();

    $controller->start();

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;

    my $self = $class->SUPER::new();

    $self->_init;

    $self->set_event_handlers();
    $self->set_event_handlers_keys();

    return $self;
}

=head2 close_app

Generate close event.

=cut

sub close_app {
    my $self = shift;

    my $event = Wx::CommandEvent->new( 9999, -1 );
    $self->view->GetEventHandler()->AddPendingEvent($event);
}

=head2 _init

Init App.

=cut

sub _init {
    my $self = shift;

    my $app = QDepo::Wx::App->create($self->model);
    $self->{_app}  = $app;
    $self->{_view} = $app->{_view};

    return;
}

=head2 start_delay

Show message, delay the database connection. Delay not yet
implemented.

=cut

sub start_delay {
    my $self = shift;

    $self->connect_dialog();

    return;
}

=head2 dialog_login

Login dialog.

=cut

sub dialog_login {
    my ($self, $error) = @_;

    require QDepo::Wx::Dialog::Login;
    my $pd = QDepo::Wx::Dialog::Login->new();

    my $return_string = '';
    my $dialog = $pd->login( $self->view, $error );
    if ( $dialog->ShowModal != &Wx::wxID_CANCEL ) {
        $return_string = $dialog->get_login();
    }
    else {
        $return_string = 'cancel';
    }

    $dialog->Destroy;

    return $return_string;
}

sub get_text_dialog {
    my $self = shift;

    my $dialog = Wx::TextEntryDialog->new(
        $self->view,
        "Enter configuration name",
        "Entry dialog",
    );

    my $name;
    if ( $dialog->ShowModal == wxID_CANCEL ) {
        Wx::LogMessage("User cancelled the dialog");
    }
    else {
        $name = $dialog->GetValue;
    }

    $dialog->Destroy;

    return $name;
}

=head2 set_event_handlers_keys

Set shortcut keys.

=cut

sub set_event_handlers_keys {
    my $self = shift;
    return;
}

=head2 set_event_handlers

Set event handlers Wx.

=cut

sub set_event_handlers {
    my $self = shift;

    $self->SUPER::set_event_handlers();

    #-- Add new report
    $self->view->event_handler_for_tb_button(
        'tb_ad', sub {
            $self->add_new_report;
        }
    );

    #-- Remove report
    $self->view->event_handler_for_tb_button(
        'tb_rm', sub {
            $self->toggle_mark_item();
        }
    );

    #- Choice
    $self->view->event_handler_for_tb_choice(
        'tb_ls', sub {
            $self->model->set_choice($_[1]->GetString);
        }
    );

    return;
}

=head2 process_sql

Get the SQL text string from the QDF file, prepare it for execution.

=cut

sub process_sql {
    my $self = shift;
    $self->model->run_export;
    return;
}

=head2 toggle_mark_item

Toggle deleted mark on list item.

=cut

sub toggle_mark_item {
    my $self = shift;

    my $item  = $self->model->get_query_item;
    my $dt    = $self->model->get_data_table_for('qlist');
    my $mark  = $dt->toggle_item_marked($item);
    my $label = $dt->get_value( $item, 0 );
    $mark
        ? $label .= ' D'
        : $label =~ s{ D}{}g;
    $dt->set_value( $item, 0, $label );
    $self->view->refresh_list('qlist');

    return;
}

=head2 list_remove_marked

Scan all items and remove marked ones.

=cut

sub list_remove_marked {
    my $self = shift;

    my $dt    = $self->model->get_data_table_for('qlist');
    my $items = $dt->get_items_marked;
    foreach my $item ( @{$items} ) {
        my $data = $self->model->get_qdf_data($item);
        $self->model->report_remove( $data->{file} );
    }

    return;
}

sub add_new_report {
    my $self = shift;

    my $dt       = $self->model->get_data_table_for('qlist');
    my $item_new = $dt->get_item_count;
    my $rec      = $self->model->report_add($item_new);
    my $item     = $self->add_qlist_item($rec);
    $dt->set_item_selected($item);
    $self->model->on_item_selected_load;
    $self->view->select_list_item('qlist', 'last');
    $self->set_app_mode('edit');

    return;
}

sub add_qlist_item {
    my ($self, $rec) = @_;

    my $dt = $self->model->get_data_table_for('qlist');

    my @items;
    foreach my $item ( keys %{$rec} ) {
        $dt->set_value( $item, 0, $rec->{$item}{nrcrt} );
        $dt->set_value( $item, 1, $rec->{$item}{title} );
        push @items, $item;
    }

    $self->view->refresh_list('qlist');

    return $items[0];                      # it's only 1
}

=head2 about

The About dialog.

=cut

sub about {
    my $self = shift;

    my $cfg = QDepo::Config->instance();

    # Framework version
    my $PROGRAM_NAME = ' QDepo ';
    my $PROGRAM_DESC = 'QDepo - Query Deposit';
    my $PROGRAM_VER  = $QDepo::VERSION;
    my $LICENSE = QDepo::Config::Utils->get_license();

    my $about = Wx::AboutDialogInfo->new;

    $about->SetName($PROGRAM_NAME);
    $about->SetVersion($PROGRAM_VER);
    $about->SetDescription("$PROGRAM_DESC");
    $about->SetCopyright('(c) 2010-2012 Ştefan Suciu <stefan@s2i2.ro>');
    $about->SetLicense($LICENSE);
    $about->SetWebSite( 'http://qdepo.s2i2.ro/', 'The QDepo web site');
    $about->AddDeveloper( 'Ştefan Suciu <stefan@s2i2.ro>' );

    Wx::AboutBox( $about );

    return;
}

=head2 guide

Quick help dialog.

=cut

sub guide {
    my $self = shift;

    my $gui = $self->view;

    require QDepo::Wx::Dialog::Help;
    my $gd = QDepo::Wx::Dialog::Help->new;

    $gd->show_html_help();

    return;
}

sub save_qdf_data {
    my $self = shift;

    my $item = $self->model->get_query_item;
    my $file = $self->model->get_query_file;
    my $head = $self->view->controls_read_page('list');
    my $para = $self->view->controls_read_page('para');
    my $body = $self->view->controls_read_page('sql');

    $self->model->write_qdf_data_file( $file, $head, $para, $body );

    my $title = $head->[0]{title};

    # Update title in list
    my $dt = $self->model->get_data_table_for('qlist');
    $dt->set_value( $item, 1, $title);

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGEMENTS

Mark Dootson.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of QDepo::Wx::Controller
