#
# Qrt::Config test script
#
# Inspired by Class::Singleton test script
#   by Andy Wardley <abw@wardley.org>

use strict;
use warnings;

#use Test::More; tests => 6;
use Test::More qw(no_plan);

use lib qw( lib ../lib );

use_ok('Qrt::Config');

ok( ! Qrt::Config::Instance->has_instance(), 'no Qrt::Config instance yet' );

my $opts = {
    'verbose'  => 1,
    'pass'     => undef,
    'cfg_gen'  => '/home/user/.tpda-qrt/etc/general.yml',
    'cfg_path' => '/home/user/.tpda-qrt',
    'conn'     => 'conn_name',
    'user'     => undef
};

my $s1 = Qrt::Config->new( $opts );
ok( $s1, 'created Qrt::Config instance 1' );

my $s2 = Qrt::Config->new();
ok( $s2, 'created Qrt::Config instance 2' );

is( $s1, $s2, 'both instances are the same object' );

is( Qrt::Config::Instance->has_instance(), $s1, 'Qrt::Config has instance' );

done_testing();
