#
# QDepo::Db::Connection test script
#
# From Class::Singleton test script
#   by Andy Wardley <abw@wardley.org>

use strict;
use warnings;

use Test::More tests => 5;

use lib qw( lib ../lib );

use QDepo::Config;

my $args = {
    cfname  => 'test',
    cfgmain => 'etc/main.yml',
    user    => undef,
    pass    => undef,
};

my $c1 = QDepo::Config->instance( $args );
ok( $c1->isa('QDepo::Config'), 'created QDepo::Config instance 1' );

use QDepo::Db;

#-- Check the one instance functionality

# No instance if instance() not called yet
ok( ! QDepo::Db->has_instance(), 'no QDepo::Db instance yet' );

my $d1 = QDepo::Db->instance( $args );
ok( $d1->isa('QDepo::Db'), 'created QDepo::Db instance 1' );

my $d2 = QDepo::Db->instance();
ok( $d2->isa('QDepo::Db'), 'created QDepo::Db instance 2' );

is( $d1, $d2, 'both instances are the same object' );

# end test
