#
# Qrt::Config test script
#
# From Class::Singleton test script
#   by Andy Wardley <abw@wardley.org>

use strict;
use warnings;

use Test::More tests => 5;

use lib qw( lib ../lib );

use Qrt::Config;

my $args = {
    cfgname => 'test',
    cfgmain => 'etc/main.yml',
    user    => undef,
    pass    => undef,
};

#-- Check the one instance functionality

# No instance if instance() not called yet
ok( ! Qrt::Config->has_instance(), 'no Qrt::Config instance yet' );

my $c1 = Qrt::Config->instance( $args );
ok( $c1->isa('Qrt::Config'), 'created Qrt::Config instance 1' );

my $c2 = Qrt::Config->instance();
ok( $c2->isa('Qrt::Config'), 'created Qrt::Config instance 2' );

is( $c1, $c2, 'both instances are the same object' );

#-- Check accessors

# Check some config key => value pairs ( stollen from Padre ;) )

ok( $c1->conninfo->{database} eq 'testdb',
    'conninfo has expected config value for "database"' )
  or diag( '"database" defined as "'
      . $c1->conninfo->{database}
      . '" and not "testdb" in config' );

# end test
