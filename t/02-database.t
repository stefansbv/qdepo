#
# Qrt::Db::Connection test script
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

my $c1 = Qrt::Config->instance( $args );
ok( $c1->isa('Qrt::Config'), 'created Qrt::Config instance 1' );

use Qrt::Db;

#-- Check the one instance functionality

# No instance if instance() not called yet
ok( ! Qrt::Db->has_instance(), 'no Qrt::Db instance yet' );

my $d1 = Qrt::Db->instance( $args );
ok( $d1->isa('Qrt::Db'), 'created Qrt::Db instance 1' );

my $d2 = Qrt::Db->instance();
ok( $d2->isa('Qrt::Db'), 'created Qrt::Db instance 2' );

is( $d1, $d2, 'both instances are the same object' );

#-- Check accessors

# # Check some config key => value pairs ( stollen from Padre ;) )

# ok( $c1->conninfo->{database} eq 'testdb',
#     'conninfo has expected config value for "database"' )
#   or diag( '"database" defined as "'
#       . $c1->conninfo->{database}
#       . '" and not "testdb" in config' );

# end test
