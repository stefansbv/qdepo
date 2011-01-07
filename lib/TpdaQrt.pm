package TpdaQrt;

use 5.008005;
use strict;
use warnings;

use TpdaQrt::Config;
use TpdaQrt::Wx::App;

=head1 NAME

TpdaQrt::Db - Tpda TpdaQrt database operations module

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

    use TpdaQrt;

    my $app = TpdaQrt->new( $opts );

    $app->run;

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my ($class, $args) = @_;

    my $self = {};

    bless $self, $class;

    $self->_init($args);

    return $self;
}

=head2 _init

Initialize the configurations module and create the WxPerl
application instance.

=cut

sub _init {
    my ( $self, $args ) = @_;

    TpdaQrt::Config->instance($args);

    $self->{gui} = TpdaQrt::Wx::App->create();
}

=head2 run

Execute the application

=cut

sub run {
    my $self = shift;
    $self->{gui}->MainLoop;
}

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

1; # End of TpdaQrt
