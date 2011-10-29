package TpdaQrt;

use 5.008005;
use strict;
use warnings;

# use TpdaQrt::Config;
# use TpdaQrt::Wx::App;

=head1 NAME

TpdaQrt::Db - Tpda TpdaQrt database operations module

=head1 VERSION

Version 0.30

=cut

our $VERSION = '0.30';

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

    my $cfg = TpdaQrt::Config->instance($args);

    # $self->{gui} = TpdaQrt::Wx::App->create();

    my $widgetset = $cfg->widgetset();

    unless ($widgetset) {
        print "Required configuration not found: 'widgetset'\n";
        exit;
    }

    if ( $widgetset =~ m{wx}ix ) {
        require TpdaQrt::Wx::Controller;
        $self->{gui} = TpdaQrt::Wx::Controller->new();

        # $self->{_log}->info('Using Wx ...');
    }
    elsif ( $widgetset =~ m{tk}ix ) {
        require TpdaQrt::Tk::Controller;
        $self->{gui} = TpdaQrt::Tk::Controller->new();

        # $self->{_log}->info('Using Tk ...');
    }
    else {
        warn "Unknown widget set!\n";

        # $self->{_log}->debug('Unknown widget set!');

        exit;
    }

    $self->{gui}->start();    # stuff to run at start

    return;
}

=head2 run

Execute the application

=cut

sub run {
    my $self = shift;

    $self->{gui}{_app}->MainLoop();

    return;
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
