#!/usr/bin/perl
#
# Inspired from Padre ;)
#

use strict;
use warnings;
use Test::More tests => 19;

use_ok('Wx');
diag( "using Wx: $Wx::VERSION" );

use_ok('Qrt');
use_ok('Qrt::Config');
use_ok('Qrt::Config::Utils');
use_ok('Qrt::Db');
use_ok('Qrt::Db::Connection');
use_ok('Qrt::Db::Connection::Firebird');
use_ok('Qrt::Db::Connection::Postgresql');
use_ok('Qrt::FileIO');
use_ok('Qrt::Model');
use_ok('Qrt::Observable');
use_ok('Qrt::Output::Calc');
use_ok('Qrt::Output::Csv');
use_ok('Qrt::Output::Excel');
use_ok('Qrt::Wx::App');
use_ok('Qrt::Wx::Controller');
use_ok('Qrt::Wx::Notebook');
use_ok('Qrt::Wx::ToolBar');
use_ok('Qrt::Wx::View');
