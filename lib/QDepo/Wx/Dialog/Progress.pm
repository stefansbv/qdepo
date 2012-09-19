package QDepo::Wx::Dialog::Progress;

use strict;
use warnings;

=head1 NAME

QDepo::Wx::Dialog::Progress - Progress dialog.

=head1 VERSION

Version 0.39

=cut

our $VERSION = '0.39';

=head1 SYNOPSIS

Show a progress dialog to the user.

    use QDepo::Wx::Dialog::Progress;

    my $dlg = QDepo::Wx::Dialog::Progress->new();

    $dlg->update();

=head1 METHODS

=head2 new

Constructor.

=cut

sub new {
    my $class = shift;

    my ( $main, $title, $max ) = @_;

    my $self = {
        main    => $main,
        title   => $title,
        max     => $max,
        start   => time,
        message => 'Copied 0% ...',
    };

    bless $self, $class;

    return $self;
}

=head2 _create_progress

Create the dialog.

=cut

sub _create_progress {
    my $self = shift;

    # Default flags

    my $flags = Wx::wxPD_ELAPSED_TIME
              | Wx::wxPD_ESTIMATED_TIME
              | Wx::wxPD_REMAINING_TIME
              | Wx::wxPD_AUTO_HIDE
              | Wx::wxPD_CAN_ABORT
              ;

    # Create the progress bar dialog

    $self->{dialog} = Wx::ProgressDialog->new(
        $self->{title},
        $self->{message},
        $self->{max},
        $self->{main},
        $flags,
    );

    return;
}

=head2 update

  $progress->update($value);

Updates the progress bar with a new value and with a new text message.

=cut

sub update {
    my ($self, $value) = @_;

    return unless defined $value;

    if ( !defined $self->{dialog} ) {

        # Lazy mode.  Don't waste CPU time for a box which is
        # destroyed immediately.
        return 1 if $self->{start} >= ( time - 1 );

        $self->_create_progress();
    }

    my $text = "Copied $value\%...";

    return $self->{dialog}->Update( $value, $text );
}

=head2 Destroy

Simulate Wx's ->Destroy function.

=cut

sub Destroy { shift->DESTROY; }

=head2 DESTROY

Destroy (and hide )the dialog if it's still defined.

=cut

sub DESTROY {
    my $self = shift;

    $self->{dialog}->Destroy if defined( $self->{dialog} );

    $self->{dialog} = undef;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGEMENTS

From Padre::Wx::Progress.

=head1 LICENSE AND COPYRIGHT

Copyright 2008-2011 The Padre development team as listed in Padre.pm.
Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of QDepo::Wx::Dialog::Progress
