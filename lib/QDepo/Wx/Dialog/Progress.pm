package QDepo::Wx::Dialog::Progress;

# ABSTRACT: QDepo progress dialog

use strict;
use warnings;

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

sub Destroy { shift->DESTROY; }

sub DESTROY {
    my $self = shift;
    $self->{dialog}->Destroy if defined( $self->{dialog} );
    $self->{dialog} = undef;
}

1;

=head1 SYNOPSIS

    use QDepo::Wx::Dialog::Progress;

    my $dlg = QDepo::Wx::Dialog::Progress->new();

    $dlg->update();

=head2 new

Constructor.

=head2 _create_progress

Create the dialog.

=head2 update

  $progress->update($value);

Updates the progress bar with a new value and with a new text message.

=head2 Destroy

Simulate Wx's ->Destroy function.

=head2 DESTROY

Destroy (and hide )the dialog if it's still defined.

=head1 ACKNOWLEDGEMENTS

From Padre::Wx::Progress.

Copyright 2008-2011 The Padre development team as listed in Padre.pm.

=cut
