#
# QDepo::Output::Csv test script
#

use strict;
use warnings;
use utf8;

use Test::More;

use lib qw( lib ../lib );

BEGIN {
    eval { require QDepo::Output::Csv; };
    if ($@) {
        plan( skip_all => 'Text::CSV is required for this test' );
    }
    else {
        plan tests => 5;
    }
}

my $test_data_header = [qw(id firstname lastname)];
my $test_data_row = [
    {   contents => 1,
        field    => "id",
        recno    => 1,
        type     => "integer"
    },
    {   contents => "Ștefan",
        field    => "firstname",
        recno    => 1,
        type     => "varchar"
    },
    {   contents => "Țarălungă",
        field    => "lastname",
        recno    => 1,
        type     => "varchar"
    },
];

my @test_data;
foreach my $key ( qw(field contents) ) {
    push @test_data, map { $_->{$key} } @{$test_data_row};
}

# Create new spreadsheet
ok my $doc = QDepo::Output::Csv->new( 'test.csv', 1, 3 ), 'new';

# Fill
is $doc->create_header_row( 0, $test_data_header), undef, "header row";
is $doc->create_row( 1, $test_data_row ), undef, 'Create 1 row of data';

# Close
ok my ($test_csv) = $doc->finish, 'done';

# Check result
my $csv = Text::CSV->new( { binary => 1, sep_char => ';' } );
open my $fh, "<", $test_csv or die "$test_csv: $!";
my @test_res;
while ( my $row = $csv->getline ($fh) ) {
    push @test_res, @{$row};
}
$csv->eof or $csv->error_diag;
close $fh or die "$test_csv: $!";
is_deeply \@test_data, \@test_res, 'CSV data ok';

# end test
