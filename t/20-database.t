#
# QDepo::Db::Connection test script
#
use strict;
use warnings;

use Test::More tests => 4;

use lib qw( lib ../lib );

use QDepo::Config;

my $args = {
    mnemonic => 'test',
    user     => undef,
    pass     => undef,
};

my $c1 = QDepo::Config->instance( $args );
ok( $c1->isa('QDepo::Config'), 'created QDepo::Config instance 1' );

use QDepo::Db;

#-- Check the one instance functionality

my $d1 = QDepo::Db->new($args);
isa_ok $d1, 'QDepo::Db';
isa_ok $d1->dbh, 'DBI::db';
isa_ok $d1->dbc, 'QDepo::Db::Connection::Sqlite';

# end test
