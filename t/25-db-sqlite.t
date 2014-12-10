#
# QDepo::Db::Connection test script
#
use 5.010;
use strict;
use warnings;

use Test::More tests => 24;

use lib qw( lib ../lib );

use QDepo::Config;
use QDepo::Model;

my $args = {
    mnemonic => 'test',
    user     => undef,
    pass     => undef,
};

my $cfg = QDepo::Config->instance( $args );
ok( $cfg->isa('QDepo::Config'), 'created QDepo::Config instance' );

ok my $model = QDepo::Model->new, 'new Model instance';
is $model->is_connected, undef, 'is not connected';
ok $model->db_connect, 'connect';
ok $model->is_connected, 'is connected';
ok $model->disconnect, 'disconnect';
is $model->is_connected, 0, 'is not connected';
ok $model->db_connect, 'connect again';
ok $model->is_connected, 'is connected again';
ok my $conn  = $model->conn, 'get the connection';
isa_ok $conn, 'QDepo::Db';
isa_ok $conn->dbh, 'DBI::db';
isa_ok $conn->dbc, 'QDepo::Db::Connection::Sqlite';
ok $conn->dbc->table_exists('orders'), 'table "orders" exists';
ok my $info = $conn->dbc->table_info_short('orders'), 'table info for "orders"';
ok my @columns = keys %{$info}, 'get the columns';
foreach my $field (@columns) {
    like $field, qr/^\p{IsAlpha}/,
        "'$field' starts with an alphabetic char";
}

# end test
