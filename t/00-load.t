#!/usr/bin/perl
#
use strict;
use warnings;

use Test::More tests => 15;

use_ok('QDepo');
use_ok('QDepo::Utils');
use_ok('QDepo::Config');
use_ok('QDepo::Config::Utils');
use_ok('QDepo::FileIO');
use_ok('QDepo::Db');
use_ok('QDepo::Db::Connection::Firebird');
use_ok('QDepo::Db::Connection::Mysql');
use_ok('QDepo::Db::Connection::Postgresql');
use_ok('QDepo::Db::Connection::Sqlite');
use_ok('QDepo::Db::Connection');
use_ok('QDepo::Controller');
use_ok('QDepo::Observable');
use_ok('QDepo::Model');
# Output
use_ok('QDepo::Output');

#-- done
