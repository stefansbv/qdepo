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
use_ok('QDepo::Wx::Notebook');
use_ok('QDepo::Wx::Dialog::Progress');
use_ok('QDepo::Wx::Dialog::Help');
use_ok('QDepo::Wx::Dialog::Login');
use_ok('QDepo::Wx::App');
use_ok('QDepo::Wx::View');
use_ok('QDepo::Wx::ToolBar');
use_ok('QDepo::Wx::Controller');
