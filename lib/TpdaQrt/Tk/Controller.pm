package TpdaQrt::Tk::Controller;

use strict;
use warnings;
use Carp;

use Tk;
use Tk::Font;
use Tk::DialogBox;

use TpdaQrt::Utils;
use TpdaQrt::Config;
use TpdaQrt::Model;
use TpdaQrt::Tk::View;

use File::Basename;
use File::Spec::Functions qw(catfile);

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

=over

=item _rscrcls  - class name of the current I<record> screen

=item _rscrobj  - current I<record> screen object

=item _dscrcls  - class name of the current I<detail> screen

=item _dscrobj  - current I<detail> screen object

=item _tblkeys  - primary and foreign keys and values record

=item _scrdata  - current screen data

=back

=cut

sub new {
    my ( $class, $app ) = @_;

    my $model = TpdaQrt::Model->new();

    my $view = TpdaQrt::Tk::View->new($model);

    my $self = {
        _model   => $model,
        _view    => $view,
        # _nbook   => $view->get_notebook,
        # _toolbar => $view->get_toolbar,
        # _list    => $view->get_listcontrol,
    };

    bless $self, $class;

#    $self->_set_event_handlers();

    return $self;
}

=head2 start

Check if we have user and pass, if not, show dialog.  Connect to
database.

=cut

sub start {
    my $self = shift;

    # $self->_view->list_populate_all();

    # $self->_view->log_config_options();

    # # Connect to database at start
    # $self->_model->db_connect();

    # my $default_choice = $self->_view->get_choice_default();
    # $self->_model->set_choice("0:$default_choice");

    # $self->_model->set_idlemode();
    # $self->toggle_controls;

    return;
}

=head2 _set_event_handlers

Setup event handlers for the interface.

=cut

sub _set_event_handlers {
    my $self = shift;

    $self->_log->trace('Setup event handlers');

    #- Base menu

    #-- Toggle find mode - Menu
    $self->_view->get_menu_popup_item('mn_fm')->configure(
        -command => sub {
            return if !defined $self->ask_to_save;

            # From add mode forbid find mode
            $self->toggle_mode_find() if !$self->_model->is_mode('add');

        }
    );

    #-- Toggle execute find - Menu
    $self->_view->get_menu_popup_item('mn_fe')->configure(
        -command => sub {
            $self->_model->is_mode('find')
                ? $self->record_find_execute
                : $self->_view->set_status( 'Not find mode', 'ms', 'orange' );
        }
    );

    #-- Toggle execute count - Menu
    $self->_view->get_menu_popup_item('mn_fc')->configure(
        -command => sub {
            $self->_model->is_mode('find')
                ? $self->record_find_count
                : $self->_view->set_status( 'Not find mode', 'ms', 'orange' );
        }
    );

    #-- Exit
    $self->_view->get_menu_popup_item('mn_qt')->configure(
        -command => sub {
            return if !defined $self->ask_to_save;
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

    #-- Preview RepMan report
    $self->_view->get_menu_popup_item('mn_pr')->configure(
        -command => sub { $self->repman; }
    );

    #-- Edit RepMan report metadata
    $self->_view->get_menu_popup_item('mn_er')->configure(
        -command => sub { $self->screen_module_load('Reports','tools'); }
    );

    #-- Save geometry
    $self->_view->get_menu_popup_item('mn_sg')->configure(
        -command => sub {
            $self->save_geometry();
        }
    );

    #- Custom application menu from menu.yml

    my $appmenus = $self->_view->get_app_menus_list();
    foreach my $item ( @{$appmenus} ) {
        $self->_view->get_menu_popup_item($item)->configure(
            -command => sub {
                $self->screen_module_load($item);
            }
        );
    }

    #- Toolbar

    #-- Attach to desktop - pin (save geometry to config file)
    $self->_view->get_toolbar_btn('tb_at')->bind(
        '<ButtonRelease-1>' => sub {
            $self->save_geometry();
        }
    );

    #-- Find mode
    $self->_view->get_toolbar_btn('tb_fm')->bind(
        '<ButtonRelease-1>' => sub {

            # From add mode forbid find mode
            $self->toggle_mode_find() if !$self->_model->is_mode('add');
        }
    );

    #-- Find execute
    $self->_view->get_toolbar_btn('tb_fe')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_model->is_mode('find')
                ? $self->record_find_execute
                : $self->_view->set_status( 'Not find mode', 'ms', 'orange' );
        }
    );

    #-- Find count
    $self->_view->get_toolbar_btn('tb_fc')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_model->is_mode('find')
                ? $self->record_find_count
                : $self->_view->set_status( 'Not find mode', 'ms', 'orange' );
        }
    );

    #-- Print (preview) default report button
    $self->_view->get_toolbar_btn('tb_pr')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_model->is_mode('edit')
                ? $self->screen_report_print()
                : $self->_view->set_status( 'Not edit mode', 'ms', 'orange' );
        }
    );

    #-- Generate default document button
    $self->_view->get_toolbar_btn('tb_gr')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_model->is_mode('edit')
                ? $self->screen_document_generate()
                : $self->_view->set_status( 'Not edit mode', 'ms', 'orange' );
        }
    );

    #-- Take note
    $self->_view->get_toolbar_btn('tb_tn')->bind(
        '<ButtonRelease-1>' => sub {
            (          $self->_model->is_mode('edit')
                    or $self->_model->is_mode('add')
                )
                ? $self->take_note()
                : $self->_view->set_status( 'Not add|edit mode',
                'ms', 'orange' );
        }
    );

    #-- Restore note
    $self->_view->get_toolbar_btn('tb_tr')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_model->is_mode('add')
                ? $self->restore_note()
                : $self->_view->set_status( 'Not add mode', 'ms', 'orange' );
        }
    );

    #-- Clear screen
    $self->_view->get_toolbar_btn('tb_cl')->bind(
        '<ButtonRelease-1>' => sub {
            (          $self->_model->is_mode('edit')
                    or $self->_model->is_mode('add')
                )
                ? $self->screen_clear()
                : $self->_view->set_status( 'Not add|edit mode',
                'ms', 'orange' );
        }
    );

    #-- Reload
    $self->_view->get_toolbar_btn('tb_rr')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_model->is_mode('edit')
                ? $self->record_reload()
                : $self->_view->set_status( 'Not edit mode', 'ms', 'orange' );
        }
    );

    #-- Add mode
    $self->_view->get_toolbar_btn('tb_ad')->bind(
        '<ButtonRelease-1>' => sub {
            $self->toggle_mode_add() if $self->{_rscrcls};
        }
    );

    #-- Delete
    $self->_view->get_toolbar_btn('tb_rm')->bind(
        '<ButtonRelease-1>' => sub {
            $self->event_record_delete();
        }
    );

    #-- Save record
    $self->_view->get_toolbar_btn('tb_sv')->bind(
        '<ButtonRelease-1>' => sub {
            $self->record_save();
        }
    );

    #-- Quit
    $self->_view->get_toolbar_btn('tb_qt')->bind(
        '<ButtonRelease-1>' => sub {
            return if !defined $self->ask_to_save;
            $self->_view->on_quit;
        }
    );

    #-- Make some key bindings

    #-- Quit Ctrl-q
    $self->_view->bind(
        '<Control-q>' => sub {
            return if !defined $self->ask_to_save;
            $self->_view->on_quit;
        }
    );

    #-- Reload - F5
    $self->_view->bind(
        '<F5>' => sub {
            $self->_model->is_mode('edit')
                ? $self->record_reload()
                : $self->_view->set_status( 'Not edit mode', 'ms', 'orange' );
        }
    );

    #-- Toggle find mode - F7
    $self->_view->bind(
        '<F7>' => sub {

            # From add mode forbid find mode
            $self->toggle_mode_find()
                if $self->{_rscrcls} and !$self->_model->is_mode('add');
        }
    );

    #-- Execute find - F8
    $self->_view->bind(
        '<F8>' => sub {
            ( $self->{_rscrcls} and $self->_model->is_mode('find') )
                ? $self->record_find_execute
                : $self->_view->set_status( 'Not find mode', 'ms', 'orange' );
        }
    );

    #-- Execute count - F9
    $self->_view->bind(
        '<F9>' => sub {
            ( $self->{_rscrcls} and $self->_model->is_mode('find') )
                ? $self->record_find_count
                : $self->_view->set_status( 'Not find mode', 'ms', 'orange' );
        }
    );

    return;
}

=head2 DESTROY

Cleanup on destroy.  Remove I<Storable> data files from the
configuration directory.

=cut

sub DESTROY {
    my $self = shift;

    # my $dir = $self->_cfg->configdir;
    # my @files = glob("$dir/*.dat");

    # foreach my $file (@files) {
    #     if ( -f $file ) {
    #         my $cnt = unlink $file;
    #         if ( $cnt == 1 ) {
    #             # print "Cleanup: $file\n";
    #         }
    #         else {
    #             $self->_log->error("EE, cleaning up: $file");
    #         }
    #     }
    # }
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
