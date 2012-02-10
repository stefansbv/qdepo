package TpdaQrt;

use 5.008005;
use strict;
use warnings;

use TpdaQrt::Config;

=head1 NAME

TPDA - Query Repository Tool.

=head1 VERSION

Version 0.32

=cut

our $VERSION = '0.32';

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

=head1 DESCRIPTION

TPDA - Query Repository Tool - a wxPerl GUI tool for data exporting
and query repository management. Queries are saved in XML files and
can be edited and parametrized.

New: Support for PerlTk.

Currently supported export formats: CSV, Excel, OpenOffice Calc.
Database management systems support: Firebird, PostgreSQL, MySQL and
SQLite.

The idea for this project, was born from the necessity to run, monthly,
the same queries against two small databases, with a couple of
parameters changed at every run, and get the data in spreadsheet
format for further processing.

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGMENTS

The implementation of the MVC pattern is (heavily) based on the
implementation from the Cipres project:

To the author: Rutger Vos, 17/Aug/2006
        http://svn.sdsc.edu/repo/CIPRES/cipresdev/branches/guigen \
             /cipres/framework/perl/cipres/lib/Cipres/

Thank You!

Also a big Thank You! to:

The Open Source movement, and all the authors, contributors and
community behind this great projects:
 Perl and Perl modules
 Padre the Perl IDE
 Firebird and Flamerobin
 Postgresql
 GNU/Linux
 MySQL
 SQLite
 [[http://www.perlmonks.org/][Perl Monks]] (the best Perl support site)
and of course Sourceforge for hosting this project :)

and last but least, to Herbert Breunung for his guidance, hints and
for his Kephra project a very good source of inspiration.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of TpdaQrt
