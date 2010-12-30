#!/usr/bin/perl
#
# Inspired from Padre ;)
#

use strict;
use warnings;
use Test::More tests => 20;

use_ok('Wx');
diag( "using Wx: $Wx::VERSION" );

use_ok('TpdaQrt');
use_ok('TpdaQrt::Config');
use_ok('TpdaQrt::Config::Utils');
use_ok('TpdaQrt::Db');
use_ok('TpdaQrt::Db::Connection');
use_ok('TpdaQrt::Db::Connection::Firebird');
use_ok('TpdaQrt::Db::Connection::Postgresql');
use_ok('TpdaQrt::FileIO');
use_ok('TpdaQrt::Model');
use_ok('TpdaQrt::Observable');
use_ok('TpdaQrt::Output');
use_ok('TpdaQrt::Output::Calc');
use_ok('TpdaQrt::Output::Csv');
use_ok('TpdaQrt::Output::Excel');
use_ok('TpdaQrt::Wx::App');
use_ok('TpdaQrt::Wx::Controller');
use_ok('TpdaQrt::Wx::Notebook');
use_ok('TpdaQrt::Wx::ToolBar');
use_ok('TpdaQrt::Wx::View');
