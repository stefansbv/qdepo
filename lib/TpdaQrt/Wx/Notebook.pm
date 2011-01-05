package TpdaQrt::Wx::Notebook;

use strict;
use warnings;

use Wx qw(:everything);  # TODO: Eventualy change this!
use Wx::AUI;

use base qw{Wx::AuiNotebook};

=head1 NAME

TpdaQrt::Wx::Notebook - Create a notebook

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use TpdaQrt::Wx::Notebook;

    $self->{_nb} = TpdaQrt::Wx::Notebook->new( $gui );

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {

    my ( $class, $gui ) = @_;

    #- The Notebook

    my $self = $class->SUPER::new(
        $gui,
        -1,
        [-1, -1],
        [-1, -1],
        wxAUI_NB_TAB_FIXED_WIDTH,
    );

    #-- Panels

    $self->{p1} = Wx::Panel->new( $self, -1, wxDefaultPosition, wxDefaultSize );
    $self->{p2} =
        Wx::Panel->new( $self, -1, wxDefaultPosition, wxDefaultSize, );

    $self->{p3} =
        Wx::Panel->new( $self, -1, wxDefaultPosition, wxDefaultSize, );
    $self->{p4} =
        Wx::Panel->new( $self, -1, wxDefaultPosition, wxDefaultSize, );

    #--- Pages

    $self->AddPage( $self->{p1}, 'Query list' );
    $self->AddPage( $self->{p2}, 'Parameters' );
    $self->AddPage( $self->{p3}, 'SQL' );
    $self->AddPage( $self->{p4}, 'Info' );

    return $self;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of TpdaQrt::Wx::Notebook
