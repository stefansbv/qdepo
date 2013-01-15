#
# QDepo::Config test script
#
# Inspired from the Class::Singleton test script by Andy Wardley

use strict;
use warnings;

use Test::More tests => 7;

use lib qw( lib ../lib );

use QDepo::Config;

my $args = {
    cfname => 'test',
    user   => undef,
    pass   => undef,
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

# interface::widgetset: Tk
ok( $c1->widgetset =~ m{Tk|Wx}i,
    'interface has expected config value for "widgetset"'
    )
    or diag( '"widgetset" defined as "'
        . $c1->widgetset
        . '" and not "Wx or Tk" in config' );

# resource::icons
ok( -d $c1->icons, '"icons" path exists' )
    or diag( '"icons" path defined as "'
        . $c1->icons
        . '" not exists' );

ok( -f $c1->connfile, '"connfile" file exists' )
    or diag( '"connfile" file defined as "'
        . $c1->connfile
        . '" not exists' );

# end tests
