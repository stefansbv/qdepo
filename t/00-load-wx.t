#!/usr/bin/perl
#
use strict;

use Test::More;

BEGIN {
    # Not really needed
    unless ( $ENV{DISPLAY} or $^O eq 'MSWin32' ) {
        plan skip_all => 'Needs DISPLAY';
        exit 0;
    }

    eval { require Wx; };
    if ($@) {
        plan( skip_all => 'WxPerl is required for this test' );
    }
    else {
        plan tests => 9;
    }
}

use_ok('Wx');
diag( "using Wx: $Wx::VERSION" );
use_ok('TpdaQrt::Wx::Notebook');
use_ok('TpdaQrt::Wx::Dialog::Progress');
use_ok('TpdaQrt::Wx::Dialog::Help');
use_ok('TpdaQrt::Wx::Dialog::Login');
use_ok('TpdaQrt::Wx::App');
use_ok('TpdaQrt::Wx::View');
use_ok('TpdaQrt::Wx::ToolBar');
use_ok('TpdaQrt::Wx::Controller');
