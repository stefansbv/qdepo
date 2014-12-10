#
# QDepo::Db::Connection test script
#
use strict;
use warnings;

use Test::More tests => 6;

use lib qw( lib ../lib );

use QDepo::Config;
use QDepo::Model;

my $args = {
    mnemonic => 'test',
    user     => undef,
    pass     => undef,
};

my $c1 = QDepo::Config->instance( $args );
ok( $c1->isa('QDepo::Config'), 'created QDepo::Config instance' );

ok my $model = QDepo::Model->new, 'new Model instance';
ok my $conn  = $model->conn, 'get the collection';
isa_ok $conn, 'QDepo::Db';
isa_ok $conn->dbh, 'DBI::db';
isa_ok $conn->dbc, 'QDepo::Db::Connection::Sqlite';

# end test
