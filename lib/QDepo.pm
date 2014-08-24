package QDepo;

use 5.008009;
use strict;
use warnings;

require QDepo::Config;

=head1 NAME

QDepo - Query Deposit.

=head1 VERSION

Version 0.39

=cut

our $VERSION = '0.39';

=head1 SYNOPSIS

    use QDepo;

    my $app = QDepo->new( $opts );

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

Initialize the configurations module and create the PerlTk or the
wxPerl application instance.

=cut

sub _init {
    my ( $self, $args ) = @_;

    my $cfg = QDepo::Config->instance($args);

    my $widgetset = $cfg->cfiface->{widgetset};

    unless ($widgetset) {
        die "Required configuration not found: 'widgetset'\n";
    }

    if ( $widgetset =~ m{wx}ix ) {
        require QDepo::Wx::Controller;
        $self->{gui} = QDepo::Wx::Controller->new();
    }
    elsif ( $widgetset =~ m{tk}ix ) {
        require QDepo::Tk::Controller;
        $self->{gui} = QDepo::Tk::Controller->new();
    }
    else {
        ouch "ConfigError", "Unknown widget set!: '$widgetset'";
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

QDepo - A desktop application for retrieving and exporting data from
relational database systems to spreadsheet files, also formerly known
as "TPDA - Query Repository Tool".

Currently supported export formats: CSV, Excel, OpenOffice Calc.
Database management systems support: Firebird, PostgreSQL, MySQL and
SQLite.

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

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

1; # End of QDepo
