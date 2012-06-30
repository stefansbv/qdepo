package TpdaQrt::Wx::App;

use strict;
use warnings;

use Wx q(:everything);
use base qw(Wx::App);

require TpdaQrt::Wx::View;

=head1 NAME

TpdaQrt::Wx::App - Wx Perl application class

=head1 VERSION

Version 0.36

=cut

our $VERSION = '0.36';

=head1 SYNOPSIS

    use TpdaQrt::Wx::App;
    use TpdaQrt::Wx::Controller;

    $gui = TpdaQrt::Wx::App->create();

    $gui->MainLoop;

=head1 METHODS

=head2 create

Constructor method.

=cut

sub create {
    my $self  = shift->new;
    my $model = shift;

    $self->{_view} = TpdaQrt::Wx::View->new(
        $model, undef, -1, 'TpdaQrt::wxPerl',
        [ -1, -1 ],
        [ -1, -1 ],
        wxDEFAULT_FRAME_STYLE,
    );

    $self->{_view}->Show(1);

    return $self;
}

=head2 OnInit

Override OnInit from WxPerl

=cut

sub OnInit { 1 }

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

1; # End of TpdaQrt::Wx::App
