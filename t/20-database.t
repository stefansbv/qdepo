#
# TpdaQrt::Db::Connection test script
#
# From Class::Singleton test script
#   by Andy Wardley <abw@wardley.org>

use strict;
use warnings;

use Test::More tests => 5;

use lib qw( lib ../lib );

use TpdaQrt::Config;

my $args = {
    cfname  => 'test',
    cfgmain => 'etc/main.yml',
    user    => undef,
    pass    => undef,
};

my $c1 = TpdaQrt::Config->instance( $args );
ok( $c1->isa('TpdaQrt::Config'), 'created TpdaQrt::Config instance 1' );

use TpdaQrt::Db;

#-- Check the one instance functionality

# No instance if instance() not called yet
ok( ! TpdaQrt::Db->has_instance(), 'no TpdaQrt::Db instance yet' );

my $d1 = TpdaQrt::Db->instance( $args );
ok( $d1->isa('TpdaQrt::Db'), 'created TpdaQrt::Db instance 1' );

my $d2 = TpdaQrt::Db->instance();
ok( $d2->isa('TpdaQrt::Db'), 'created TpdaQrt::Db instance 2' );

is( $d1, $d2, 'both instances are the same object' );

# end test
