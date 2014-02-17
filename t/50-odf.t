#
# QDepo::Output::ODF test script
#

use strict;
use warnings;

use Test::More;

use lib qw( lib ../lib );

BEGIN {
    eval { require QDepo::Output::ODF; };
    if ($@) {
        plan( skip_all => 'ODF::lpOD is required for this test' );
    }
    else {
        plan tests => 7;
    }
}

my @test_data = (
    [ 'id', 'firstname', 'lastname' ],
    [ 1,    'John',       'Doe' ],
    [ 2,    'Jane ',      'Doe' ],
    [ 3,    'Jane – Eve', 'Doe' ], # use a dash: \x{2013}
);

my $rows = scalar @test_data;
my $cols = scalar @{$test_data[0]};

# diag("rows = $rows");
# diag("cols = $cols");

# Create new spreadsheet
ok( my $doc = QDepo::Output::ODF->new( 'test.ods', $rows, $cols ), 'new' );

ok($doc->init_lengths( [qw{id firstname lastname}] ), 'init lengths');

# Fill
for ( my $row = 0 ; $row < $rows ; $row++ ) {
    is $doc->create_row( $row, $test_data[$row]), undef, "row $row";
}

# Close
ok( my ($out) = $doc->create_done(), 'done' );

# end test
