#
# TpdaQrt::Config test script
#
# From Class::Singleton test script
#   by Andy Wardley <abw@wardley.org>

use strict;
use warnings;

use Test::More tests => 5;

use lib qw( lib ../lib );

use TpdaQrt::Config;

my $args = {
    cfgname => 'test',
    user    => undef,
    pass    => undef,
};

#-- Check the one instance functionality

# No instance if instance() not called yet
ok( ! TpdaQrt::Config->has_instance(), 'no TpdaQrt::Config instance yet' );

my $c1 = TpdaQrt::Config->instance( $args );
ok( $c1->isa('TpdaQrt::Config'), 'created TpdaQrt::Config instance 1' );

my $c2 = TpdaQrt::Config->instance();
ok( $c2->isa('TpdaQrt::Config'), 'created TpdaQrt::Config instance 2' );

is( $c1, $c2, 'both instances are the same object' );

#-- Check accessors

# Check some config key => value pairs ( stollen from Padre ;) )

ok( $c1->conninfo->{dbname} =~ m{tpdaqrt-test.db},
    'conninfo has expected config value for "dbname"' )
  or diag( '"dbname" defined as "'
      . $c1->conninfo->{dbname}
      . '" and not "tpdaqrt-test.db" in config' );

# end test
