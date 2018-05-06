#!perl -w
##
use strict;
use warnings;
use 5.010;
use Test::More;
use Path::Tiny;
use File::Temp 'tempdir';
use Try::Tiny;
use Test::Exception;
use Locale::TextDomain 1.20 qw(QDepo);
use QDepo::Target;
use lib 't/lib';
use DBIEngineTest;

my $CLASS;
my $have_sqlite_driver = 1; # assume DBD::SQLite is installed and so is SQLite
my $live_testing       = 0;

# Is DBD::SQLite realy installed?
try { require DBD::SQLite; } catch { $have_sqlite_driver = 0; };

BEGIN {
    $CLASS = 'QDepo::Engine::sqlite';
    require_ok $CLASS or die;
    $ENV{QDEPO_CONFIG}        = 'nonexistent.conf';
    $ENV{QDEPO_SYSTEM_CONFIG} = 'nonexistent.user';
    $ENV{QDEPO_USER_CONFIG}   = 'nonexistent.sys';
}

my $target = QDepo::Target->new(
    uri => 'db:sqlite:foo.db',
);
isa_ok my $sqlite = $CLASS->new( target => $target ),
    $CLASS;

is $sqlite->uri->dbname, path('foo.db'), 'dbname should be filled in';

##############################################################################
# Can we do live tests?

END {
    my %drivers = DBI->installed_drivers;
    for my $driver (values %drivers) {
        $driver->visit_child_handles(sub {
            my $h = shift;
            $h->disconnect if $h->{Type} eq 'db' && $h->{Active};
        });
    }
}

my $tmp_dir = path( tempdir CLEANUP => 1 );
my $db_path = path( $tmp_dir, 'qdepotest.db' );
my $uri = "db:sqlite:$db_path";
DBIEngineTest->run(
    class         => $CLASS,
    target_params => [ uri => $uri ],
    skip_unless   => sub {
        my $self = shift;

        # Should have the database handle
        $self->dbh;
    },
    engine_err_regex  => qr/^near "blah": syntax error/,
    test_dbh => sub {
        my $dbh = shift;
        # Make sure foreign key constraints are enforced.
        ok $dbh->selectcol_arrayref('PRAGMA foreign_keys')->[0],
            'The foreign_keys pragma should be enabled';
    },
);

done_testing;
