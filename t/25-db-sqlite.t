#
# QDepo::Db::Connection test script
#
# From Class::Singleton test script
#   by Andy Wardley <abw@wardley.org>

use strict;
use warnings;

use Test::More tests => 14;

use lib qw( lib ../lib );

use QDepo::Config;

my $args = {
    mnemonic => 'test',
    user     => undef,
    pass     => undef,
};

my $cfg = QDepo::Config->instance( $args );
ok( $cfg->isa('QDepo::Config'), 'created QDepo::Config instance' );

use QDepo::Db;

#-- Check the one instance functionality

ok my $db = QDepo::Db->new($args), 'new Db instance';
ok $db->isa('QDepo::Db'), 'created QDepo::Db instance';
ok $db->dbc->table_exists('orders'), 'table "orders" exists';
ok my $info = $db->dbc->table_info_short('orders'), 'table info for "orders"';
ok my @columns = keys %{$info}, 'get the columns';
foreach my $field (@columns) {
    like $field, qr/^\p{IsAlpha}/, "'$field' starts with an alphabetic char";
}

# end test
