#
# TpdaQrt::Output::ODF test script
#

use strict;
use warnings;

use Test::More tests => 5;

use lib qw( lib ../lib );

use TpdaQrt::Output::ODF;

my @test_data = (
    [ 'id', 'firstname', 'lastname' ],
    [ 1,    'John',      'Doe' ],
    [ 2,    'Silvester', 'Stalone' ],
);

my $rows = scalar @test_data;
my $cols = scalar @{$test_data[0]};

# diag("rows = $rows");
# diag("cols = $cols");

# Create new spreadsheet
ok( my $doc = TpdaQrt::Output::ODF->new( 'test.odf', $rows, $cols ), 'new' );

# Fill
for ( my $row = 0 ; $row < $rows ; $row++ ) {
    is($doc->create_row( $row, $test_data[$row]), undef, "row $row");
}

# Close
ok( my $out = $doc->create_done(), 'done' );

# end test
