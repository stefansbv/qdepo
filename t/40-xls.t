#
# QDepo::Output::Excel test script
#

use strict;
use warnings;

use Test::More;

use lib qw( lib ../lib );

BEGIN {
    eval { require QDepo::Output::Excel; };
    if ($@) {
        plan(
            skip_all => 'Spreadsheet::WriteExcel is required for this test' );
    }
    else {
        plan tests => 5;
    }
}

my $test_data_header = [qw(id firstname lastname)];
my $test_data_row    = [
    {   contents => 1,
        field    => "id",
        recno    => 1,
        type     => "integer"
    },
    {   contents => "Joe",
        field    => "firstname",
        recno    => 1,
        type     => "varchar"
    },
    {   contents => "Doe",
        field    => "lastname",
        recno    => 1,
        type     => "varchar"
    },
];

# Create new spreadsheet
ok my $doc = QDepo::Output::Excel->new( 'test.xls', 1, 3 ), 'new';

ok $doc->init_column_widths( [qw{id firstname lastname}] ), 'init lengths';

# Fill
is $doc->create_header_row( 0, $test_data_header ), undef, "header row";
is $doc->create_row( 1, $test_data_row ), undef, 'Create 1 row of data';

# Close
ok my ($out) = $doc->finish, 'done';

# end test
