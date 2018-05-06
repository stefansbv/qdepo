use 5.010001;
use utf8;
use strict;
use warnings;
use Path::Tiny;
use Test::More;
use Test::Exception;

use QDepo::Config;
use QDepo::Config::Connection;

subtest 'Connection config from test' => sub {
    my $args = {
        mnemonic => 'test',
        user     => undef,
        pass     => undef,
    };
    my $c1 = QDepo::Config->instance($args);
    ok( $c1->isa('QDepo::Config'), 'created QDepo::Config instance 1' );

    ok my $db = QDepo::Config::Connection->new, 'new instance';
    like $db->uri_db, qr/^db:sqlite/, 'the uri built from a connection file';
    is $db->driver,   'sqlite',       'the engine';
    is $db->host,     undef,          'the host';
    is $db->port,     undef,          'the port';
    is $db->dbname, 'classicmodels.db', 'the dbname';
    is $db->user,   undef,              'the user name';
    is $db->role,   undef,              'the role name';
    like $db->uri,  qr/classicmodels/, 'the uri';
};

done_testing;
