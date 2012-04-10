package TpdaQrt::Tk::Controller;

use strict;
use warnings;

use English;
use Tk;
use Tk::Font;
use utf8;

require TpdaQrt::Tk::View;

use base qw{TpdaQrt::Controller};

=head1 NAME

TpdaQrt::Tk::Controller - The Controller

=head1 VERSION

Version 0.33

=cut

our $VERSION = '0.33';

=head1 SYNOPSIS

    use TpdaQrt::Tk::Controller;

    my $controller = TpdaQrt::Tk::Controller->new();

    $controller->start();

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;

    my $self = $class->SUPER::new();

    $self->_init;

    $self->set_event_handlers_keys();

    return $self;
}

=head2 _init

Init App.

=cut

sub _init {
    my $self = shift;

    my $view = TpdaQrt::Tk::View->new($self->_model);
    $self->{_app}  = $view;                  # an alias as for Wx ...
    $self->{_view} = $view;

    $self->fix_geometry;

    return;
}

=head2 dialog_login

Login dialog.

=cut

sub dialog_login {
    my $self = shift;

    require TpdaQrt::Tk::Dialog::Login;
    my $pd = TpdaQrt::Tk::Dialog::Login->new;

    return $pd->login( $self->_view );
}

=head2 fix_geometry

Add 4px to the width of the window to better fit the MListbox.

=cut

sub fix_geometry {
    my $self = shift;

    my $geom = $self->_view->get_geometry;

    my ($width) = $geom =~ m{(\d+)x};

    $width += 4;

    $geom =~ s{(\d+)x}{${width}x};

    $self->_view->geometry($geom);

    return;
}

sub set_event_handlers_keys {
    my $self = shift;

    #-- Make some key bindings

    #-- Quit Ctrl-q
    $self->_view->bind(
        '<Control-q>' => sub {
            $self->on_quit;
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

    return;
}

=head2 set_event_handlers

Set event handlers Tk.

=cut

sub set_event_handlers {
    my $self = shift;

    $self->SUPER::set_event_handlers();

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
            $self->_model->set_choice( $_[0] );
        }
    );

    return;
}

=head2 process_sql

Get the sql text string from the QDF file, prepare it for execution.

=cut

sub process_sql {
    my $self = shift;

    my $item   = $self->_view->get_list_selected_index();
    my ($data) = $self->_model->read_qdf_data($item);
    $self->_model->run_export($data);

    return;
}

=head2 on_quit

Before quit ask for permission to delete the marked qdf files, if
marked records exists.

=cut

sub on_quit {
    my $self = shift;

    if ( $self->_model->has_marks() ) {
        my $msg = 'Delete marked query definition files?';
        if ( $self->_view->action_confirmed($msg) ) {
            $self->list_remove_marked();
        }
    }

    $self->_view->on_quit();

    return;
}

=head2 toggle_mark_item

Toggle mark on list item.

=cut

sub toggle_mark_item {
    my $self = shift;

    my $item = $self->_view->get_list_selected_index();

    my $rec = $self->_model->get_qdf_data_tk($item, 'toggle mark');
    my $nrcrt = $rec->{nrcrt};
    if ( exists $rec->{mark} ) {
        $nrcrt = "$nrcrt D" if $rec->{mark} == 1;
    }

    $self->_view->list_item_edit( $item, $nrcrt );

    return;
}

sub list_remove_marked {
    my $self = shift;

    my $recs = $self->_model->get_qdf_data_tk();

    foreach my $idx ( keys %{$recs} ) {
        if ( exists $recs->{$idx}{mark} and $recs->{$idx}{mark} == 1 ) {
            $self->_model->report_remove($recs->{$idx}{file});
        }
    }

    return;
}

=head2 guide

Quick help dialog.

=cut

sub guide {
    my $self = shift;

    my $gui = $self->_view;

    require TpdaQrt::Tk::Dialog::Help;
    my $gd = TpdaQrt::Tk::Dialog::Help->new;

    $gd->help_dialog($gui);

    return;
}

=head2 about

About application dialog.

=cut

sub about {
    my $self = shift;

    my $gui = $self->_view;

    # Create a dialog.
    my $dbox = $gui->DialogBox(
        -title   => 'Despre ... ',
        -buttons => ['Close'],
    );

    # Windows has the annoying habit of setting the background color
    # for the Text widget differently from the rest of the window.  So
    # get the dialog box background color for later use.
    my $bg = $dbox->cget('-background');

    # Insert a text widget to display the information.
    my $text = $dbox->add(
        'Text',
        -height     => 12,
        -width      => 35,
        -background => $bg
    );

    # Define some fonts.
    my $textfont = $text->cget('-font')->Clone( -family => 'Helvetica' );
    my $italicfont = $textfont->Clone( -slant => 'italic' );
    $text->tag(
        'configure', 'italic',
        -font    => $italicfont,
        -justify => 'center',
    );
    $text->tag(
        'configure', 'normal',
        -font    => $textfont,
        -justify => 'center',
    );

    # Framework version
    my $PROGRAM_NAME = 'TPDA - Query Repository Tool';
    my $PROGRAM_VER  = $TpdaQrt::VERSION;

    # Add the about text.
    $text->insert( 'end', "\n" );
    $text->insert( 'end', $PROGRAM_NAME . "\n", 'normal' );
    $text->insert( 'end', "Version " . $PROGRAM_VER . "\n", 'normal' );
    $text->insert( 'end', "Author: Ștefan Suciu\n", 'normal' );
    $text->insert( 'end', "Copyright 2010-2012\n", 'normal' );
    $text->insert( 'end', "GNU General Public License (GPL)\n", 'normal' );
    $text->insert( 'end', 'stefan@s2i2.ro',
        'italic' );
    $text->insert( 'end', "\n\n" );
    $text->insert( 'end', "Perl " . $PERL_VERSION . "\n", 'normal' );
    $text->insert( 'end', "Tk v" . $Tk::VERSION . "\n", 'normal' );

    $text->configure( -state => 'disabled' );
    $text->pack(
        -expand => 1,
        -fill   => 'both'
    );
    $dbox->Show();

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of TpdaQrt::Tk::Controller
