package TpdaQrt::Wx::Controller;

use strict;
use warnings;
use utf8;

use English;
use Wx ':everything';
use Wx::Event qw(EVT_CLOSE EVT_CHOICE EVT_MENU EVT_TOOL EVT_BUTTON
                 EVT_AUINOTEBOOK_PAGE_CHANGED EVT_LIST_ITEM_SELECTED);

require TpdaQrt::Wx::App;

use base qw{TpdaQrt::Controller};

=head1 NAME

TpdaQrt::Wx::Controller - The Controller

=head1 VERSION

Version 0.36

=cut

our $VERSION = '0.36';

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
    $self->_view->GetEventHandler()->AddPendingEvent($event);
}

=head2 _init

Init App.

=cut

sub _init {
    my $self = shift;

    my $app = TpdaQrt::Wx::App->create($self->_model);
    $self->{_app}  = $app;
    $self->{_view} = $app->{_view};

    return;
}

=head2 dialog_login

Login dialog.

=cut

sub dialog_login {
    my $self = shift;

    require TpdaQrt::Wx::Dialog::Login;
    my $pd = TpdaQrt::Wx::Dialog::Login->new();

    my $return_string = '';
    my $dialog = $pd->login( $self->_view );
    if ( $dialog->ShowModal != &Wx::wxID_CANCEL ) {
        $return_string = $dialog->get_login();
    }
    else {
        $return_string = 'shutdown';
    }

    $dialog->Destroy;

    return $return_string;
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
    $self->_view->event_handler_for_tb_button(
        'tb_ad',
        sub {
            my $items_no = $self->_view->get_list_max_index();
            my $rec = $self->_model->report_add($items_no + 1);
            $self->_view->list_populate_item($rec);
            $self->_view->list_item_select('last');
            $self->_model->on_item_selected();
            $self->set_app_mode('edit');
        }
    );

    #-- Remove report
    $self->_view->event_handler_for_tb_button(
        'tb_rm',
        sub {
            $self->toggle_mark_item();
        }
    );

    #- Choice
    $self->_view->event_handler_for_tb_choice(
        'tb_ls',
        sub {
            $self->_model->set_choice($_[1]->GetString);
        }
    );

    return;
}

=head2 process_sql

Get the sql text string from the QDF file, prepare it for execution.

=cut

sub process_sql {
    my $self = shift;

    my $item = $self->_view->get_list_selected_index();
    my $lidata = $self->_view->get_list_item_data($item);
    my ($data) = $self->_model->read_qdf_data_file($item, $lidata->{file} );
    $self->_model->run_export($data);

    return;
}

=head2 toggle_mark_item

Toggle mark on list item.

=cut

sub toggle_mark_item {
    my $self = shift;

    my $item = $self->_view->get_list_selected_index();

    $self->_view->toggle_mark($item);

    my $data = $self->_view->get_list_item_data($item);

    my $nrcrt = $data->{nrcrt};
    if ( exists $data->{mark} ) {
        $nrcrt = "$nrcrt D" if $data->{mark} == 1;
    }

    $self->_view->list_item_edit( $item, $nrcrt );

    return;
}

=head2 list_remove_marked

Scan all items and remove marked ones.

=cut

sub list_remove_marked {
    my $self = shift;

    my $max_index = $self->_view->get_list_max_index();
    foreach my $item (0..$max_index) {
        my $data = $self->_view->get_list_item_data($item);
        while ( my ( $key, $value ) = each( %{$data} ) ) {
            if ( $key eq 'mark' and $data->{mark} == 1 ) {
                $self->_model->report_remove( $data->{file} );
            }
        }
    }

    return;
}

=head2 about

The About dialog.

=cut

sub about {
    my $self = shift;

    my $cfg = TpdaQrt::Config->instance();

    # Framework version
    my $PROGRAM_NAME = ' Tpda QRT ';
    my $PROGRAM_DESC = 'TPDA - Query Repository Tool';
    my $PROGRAM_VER  = $TpdaQrt::VERSION;
    my $LICENSE = $cfg->get_license;

    my $about = Wx::AboutDialogInfo->new;

    $about->SetName($PROGRAM_NAME);
    $about->SetVersion($PROGRAM_VER);
    $about->SetDescription("$PROGRAM_DESC");
    $about->SetCopyright('(c) 2010-2012 Ştefan Suciu <stefan@s2i2.ro>');
    $about->SetLicense($LICENSE);
    #$about->SetWebSite( 'http://tpda.s2i2.ro/', 'The Tpda3 web site');
    $about->AddDeveloper( 'Ştefan Suciu <stefan@s2i2.ro>' );

    Wx::AboutBox( $about );

    return;
}

=head2 guide

Quick help dialog.

=cut

sub guide {
    my $self = shift;

    my $gui = $self->_view;

    require TpdaQrt::Wx::Dialog::Help;
    my $gd = TpdaQrt::Wx::Dialog::Help->new;

    $gd->show_html_help();

    return;
}

sub save_qdf_data {
    my $self = shift;

    my $item = $self->_view->get_list_selected_index();
    my $file = $self->_view->get_qdf_data_file_wx($item);
    my $head = $self->_view->controls_read_page('list');
    my $para = $self->_view->controls_read_page('para');
    my $body = $self->_view->controls_read_page('sql');

    $self->_model->write_qdf_data_file( $file, $head, $para, $body );

    my $title = $head->[0]{title};

    # Update title in list
    $self->_view->list_item_edit( $item, undef, $title);

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

1; # End of TpdaQrt::Wx::Controller
