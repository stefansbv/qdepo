package QDepo;

# ABSTRACT: QDepo (Query Deposit) application main module

use 5.010001;
use strict;
use warnings;

use Locale::TextDomain 1.20 qw(QDepo);
use Locale::Messages qw(bind_textdomain_filter);

require QDepo::Config;
require QDepo::Wx::Controller;

BEGIN {
    # Stolen from Sqitch...
    # Force Locale::TextDomain to encode in UTF-8 and to decode all messages.
    $ENV{OUTPUT_CHARSET} = 'UTF-8';
    bind_textdomain_filter 'QDepo' => \&Encode::decode_utf8;
}

=head1 SYNOPSIS

    use QDepo;

    my $app = QDepo->new( $opts );

    $app->run;

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

Initialize the configurations module and create the wxPerl application
instance.

=cut

sub _init {
    my ( $self, $args ) = @_;
    my $cfg = QDepo::Config->instance($args);
    $self->{gui} = QDepo::Wx::Controller->new();
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

1;

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
