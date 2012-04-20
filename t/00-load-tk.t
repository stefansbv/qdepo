#
# TpdaQrt Tk use test script
#
use strict;

use Test::More;

BEGIN {
    # Not really needed
    unless ( $ENV{DISPLAY} or $^O eq 'MSWin32' ) {
        plan skip_all => 'Needs DISPLAY';
        exit 0;
    }

    eval { require Tk; };
    if ($@) {
        plan( skip_all => 'Perl Tk is required for this test' );
    }
    else {
        plan tests => 6;
    }
}

use_ok('Tk');
diag( "using Tk: $Tk::VERSION" );
use_ok('TpdaQrt::Tk::Dialog::Help');
use_ok('TpdaQrt::Tk::Dialog::Login');
use_ok('TpdaQrt::Tk::View');
use_ok('TpdaQrt::Tk::TB');
use_ok('TpdaQrt::Tk::Controller');

#-- done
