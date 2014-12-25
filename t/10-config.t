#
# QDepo::Config test script
#
# Inspired from the Class::Singleton test script by Andy Wardley

use strict;
use warnings;

use Test::More tests => 5;

use lib qw( lib ../lib );

use QDepo::Config;

my $args = {
    mnemonic => 'test',
    user     => undef,
    pass     => undef,
};

#-- Check the one instance functionality

# No instance if instance() not called yet
ok( !QDepo::Config->has_instance(), 'no QDepo::Config instance yet' );

my $c1 = QDepo::Config->instance($args);
ok( $c1->isa('QDepo::Config'), 'created QDepo::Config instance 1' );

my $c2 = QDepo::Config->instance();
ok( $c2->isa('QDepo::Config'), 'created QDepo::Config instance 2' );

is( $c1, $c2, 'both instances are the same object' );

# Check some config key => value pairs ( stollen from Padre ;) )

# Configuration: etc/main.yml

# resource::icons
ok( -d $c1->icons, '"icons" path exists' )
    or diag( '"icons" path defined as "' . $c1->icons . '" not exists' );

# end tests
