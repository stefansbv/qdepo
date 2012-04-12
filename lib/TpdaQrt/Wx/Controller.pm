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

Version 0.34

=cut

our $VERSION = '0.34';

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
    #$self->set_event_handlers_keys();

    return $self;
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

    return $return_string;
}

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
            my $rec = $self->_model->report_add($items_no);
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
            my $msg = 'Delete query definition file?';
            if ( $self->_view->action_confirmed($msg) ) {
                my $file = $self->_view->list_remove_item();
                $self->_model->report_remove($file);
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
    my $file = $self->_view->get_list_data($item);
    my ($data) = $self->_model->read_qdf_data($item, $file);
    $self->_model->run_export($data);

    return;
}

sub on_quit {
    my $self = shift;

    $self->_view->on_quit();
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

1; # End of TpdaQrt::Wx::Controller
