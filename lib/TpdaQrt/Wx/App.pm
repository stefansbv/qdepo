package TpdaQrt::Wx::App;

use strict;
use warnings;

use TpdaQrt::Wx::Controller;
use base qw(Wx::App);

=head1 NAME

TpdaQrt::Wx::App - Wx Perl application class

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

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
    my $self = shift->new;

    my $controller = TpdaQrt::Wx::Controller->new();

    $controller->start();

    return $self;
}

=head2 OnInit

Override OnInit from WxPerl

=cut

sub OnInit { 1 }


=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 - 2011 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of TpdaQrt::Wx::App
