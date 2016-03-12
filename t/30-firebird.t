#
# QDepo::Db::Connection test script
#
# Acknowledgment:
#  Helper subs borrowed from the Sqitch application.
#
use 5.010;
use strict;
use warnings;

use Test::More;

use lib qw( lib ../lib );

use File::ShareDir qw(dist_dir);
use File::Slurp qw(read_file);
use File::Spec::Functions;
use Try::Tiny;
use SQL::SplitStatement;

use QDepo::Config;
use QDepo::Model;

my $CLASS;
my $have_fb_driver = 1; # assume DBD::Firebird is installed and so is Firebird
my $live_testing   = 1;
my $user;
my $pass;
my $tmpdir;

# Is DBD::Firebird realy installed?
try { require DBD::Firebird; } catch { $have_fb_driver = 0; };

BEGIN {
    $CLASS = 'QDepo::Db::Connection::Firebird';
    require_ok $CLASS or die;
    $user = $ENV{ISC_USER}     || $ENV{DBI_USER} || 'SYSDBA';
    $pass = $ENV{ISC_PASSWORD} || $ENV{DBI_PASS} || 'masterkey';
    $tmpdir = File::Spec->tmpdir();
}

my $args = {
    mnemonic => 'test-fb',
    user     => $user,
    pass     => $pass,
};

my $dbname = 'classicmodels.fdb'; # XXX Fullpath is required in connections.yml
my $dbpath = catfile( $tmpdir, $dbname );

my $cfg = QDepo::Config->instance($args);
ok( $cfg->isa('QDepo::Config'), 'created QDepo::Config instance' );

# Make a test database for Firebird
if ( $cfg->connection->driver =~ m{firebird}xi ) {
    my $rv = make_fb_database();
    if ( $rv != 1 ) {
        BAIL_OUT("Dubious return value from 'make_fb_database': $rv");
    }
    create_classicmodels_schema();
}
else {
    die "Expecting to test the Firebird engine, not ",
        $cfg->connection->driver;
}

ok my $model = QDepo::Model->new, 'new Model instance';
is $model->is_connected, undef, 'is not connected';
ok $model->db_connect, 'connect';
ok $model->is_connected, 'is connected';
#ok $model->disconnect,   'disconnect'; # user and pass are reset
#is $model->is_connected, 0,     'is not connected';
#ok $model->db_connect,   'connect again';
# ok $model->is_connected, 'is connected again';
ok my $conn = $model->conn, 'get the connection';
isa_ok $conn, 'QDepo::Db';
isa_ok $conn->dbh, 'DBI::db';
isa_ok $conn->dbc, 'QDepo::Db::Connection::Firebird';
ok $conn->dbc->table_exists('orders'), 'table "orders" exists';
ok my $info = $conn->dbc->table_info_short('orders'),
    'table info for "orders"';
ok my @columns = keys %{$info}, 'get the columns';
# If column name starts with an alphabetic char is OK
foreach my $field (@columns) {
    like $field, qr/^\p{IsAlpha}/, "has '$field' column";
}

done_testing;

# end test

sub make_fb_database {
    try {
        require DBD::Firebird;
        DBD::Firebird->create_database(
            {   db_path       => $dbpath,
                user          => $user,
                password      => $pass,
                character_set => 'UTF8',
                page_size     => 16384,
            }
        );
        undef;
    }
    catch {
        die "Error creating database: $_";
    };
    return 1;
}

sub connect_to_db {
    my $dbfile = shift;
    my $attr   = { @_ };
    my @params = ( "dbi:Firebird:dbname=$dbpath", $user, $pass );
    if ( %{$attr} ) {
        push @params, $attr;
    }
    my $dbh = DBI->connect( @params );
    return $dbh;
}

sub create_classicmodels_schema {
    my $dbh = connect_to_db();
    my $sql_file = get_sql_filename();
    my $sql_text;
    if (-f $sql_file) {
        $sql_text = read_file($sql_file);
    }
    else {
        die " SQL test database schema $sql_file not found!\n";
    }
    my $sql_splitter = SQL::SplitStatement->new;
    my @statements = $sql_splitter->split($sql_text);
    foreach my $sql (@statements) {
        # print "\nSQL: >>$sql<<\n";
        $dbh->do($sql) or die $dbh->errstr;
    }
    $dbh->disconnect;
    return;
}

sub get_sql_filename {
    return catfile( dist_dir('QDepo'), 'cm', 'sql', 'classicmodels-fb.sql' );
}

END {
    return unless $live_testing;
    return unless $have_fb_driver;

    return unless -f $dbpath;
    my $dsn = qq{dbi:Firebird:dbname=$dbpath;host=localhost;port=3050};
    $dsn .= q{;ib_dialect=3;ib_charset=UTF8};

    my $dbh = DBI->connect(
        $dsn, $user, $pass,
        {   FetchHashKeyName => 'NAME_lc',
            AutoCommit       => 1,
            RaiseError       => 0,
            PrintError       => 0,
        }
    ) or die $DBI::errstr;

    $dbh->{Driver}->visit_child_handles(
        sub {
            my $h = shift;
            $h->disconnect
                if $h->{Type} eq 'db' && $h->{Active} && $h ne $dbh;
        }
    );

    my $res
        = $dbh->selectall_arrayref(q{ SELECT MON$USER FROM MON$ATTACHMENTS });
    if ( @{$res} > 1 ) {

        # Do we have more than 1 active connections?
        warn "    Another active connection detected, can't DROP DATABASE!\n";
    }
    else {
        $dbh->func('ib_drop_database')
            or warn "Error dropping test database '$dbname': $DBI::errstr";
    }
}
