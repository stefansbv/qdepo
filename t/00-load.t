#!/usr/bin/perl
#
use strict;
use warnings;

use Test::More tests => 15;

use_ok('TpdaQrt');
use_ok('TpdaQrt::Utils');
use_ok('TpdaQrt::Config');
use_ok('TpdaQrt::Config::Utils');
use_ok('TpdaQrt::FileIO');
use_ok('TpdaQrt::Db');
use_ok('TpdaQrt::Db::Connection::Firebird');
use_ok('TpdaQrt::Db::Connection::Mysql');
use_ok('TpdaQrt::Db::Connection::Postgresql');
use_ok('TpdaQrt::Db::Connection::Sqlite');
use_ok('TpdaQrt::Db::Connection');
use_ok('TpdaQrt::Controller');
use_ok('TpdaQrt::Observable');
use_ok('TpdaQrt::Model');
# Output
use_ok('TpdaQrt::Output');

#-- done
