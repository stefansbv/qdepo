package TpdaQrt::Tk::Controller;

use strict;
use warnings;

use Data::Dumper;
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

    $self->_model->load_qdf_data();

    $self->_view->list_populate_all();

    $self->set_app_mode('sele');

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
        }
    );

    #-- Refresh
    $self->_view->get_toolbar_btn('tb_rf')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_model->on_item_selected();
        }
    );

    #-- Add report
    $self->_view->get_toolbar_btn('tb_ad')->bind(
        '<ButtonRelease-1>' => sub {
            my $rec = $self->_model->report_add();
            $self->_view->list_populate_item($rec);
            $self->set_app_mode('edit');
        }
    );

    #-- Remove report
    $self->_view->get_toolbar_btn('tb_rm')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_view->list_mark_item();
        }
    );

    #-- Save
    $self->_view->get_toolbar_btn('tb_sv')->bind(
        '<ButtonRelease-1>' => sub {
            if ( $self->_model->is_appmode('edit') ) {
                $self->save_query_def();
                $self->set_app_mode('sele');
            }
        }
    );

    #-- Edit
    $self->_view->get_toolbar_btn('tb_ed')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_model->is_appmode('edit')
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
            $self->_model->is_appmode('edit')
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

    my $is_edit = $self->_model->is_appmode('edit') ? 1 : 0;

    # Toggle List control
    my $list = $self->_view->get_listcontrol();
    if ($is_edit) {
        # $list->configure(-state => 'disabled'); doesn't work!
    }
    else {
        # $list->configure(-state => 'normal');
    }

    # Controls by page Enabled in edit mode
    foreach my $page ( qw(para list conf sql ) ) {
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
                $state = $control->{$name}->[1];  # normal | disabled
                $color = $control->{$name}->[2];  # name
            }
            else {
                $state = 'disabled';
            }

            $control->{$name}[0]->configure(-state      => $state);
            $control->{$name}[0]->configure(-background => $color) if $color;
        }
    }
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

    $self->_model->save_query_def( $item, $head, $para, $body );

    # Update title in list

    my $title = $head->[0]{title};

    $self->_view->list_item_edit( $item, undef, $title );

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
