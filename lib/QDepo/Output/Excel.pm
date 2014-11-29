package QDepo::Output::Excel;

# ABSTRACT: Export data in Excel format

use strict;
use warnings;
use Carp;

use Spreadsheet::WriteExcel;
use QDepo::Utils;

sub new {
    my $class = shift;

    my $self = {};
    bless( $self, $class );
    $self->{xls_file} = shift;
    $self->{xls_fh}   = undef;
    $self->{workbook} = undef;
    $self->{sheet}    = undef;
    $self->{lenghts}  = [];     # Array to hold max lenghts for each col
    $self->{max_len}  = 30;     # Max column width

    $self->_create_doc();

    return $self;
}

sub _create_doc {
    my ( $self, $sheet_name ) = @_;

    # Create a new Excel workbook
    eval { $self->{workbook}
               = Spreadsheet::WriteExcel->new( $self->{xls_file} ) };
    if ($@) {
        print "Spreadsheet::WriteExcel not installed?";
        return;
    }

    # Get a new sheet
    $self->{sheet} = $self->{workbook}->addworksheet($sheet_name);

    # Define formats
    my %fmt;

    # Header format
    $fmt{h_fmt} = $self->{workbook}->addformat(
        size   => 8,
        color  => 'black',
        align  => 'center',
        bold   => 1,
        border => 1,
    );

    # String format
    $fmt{char_fmt} = $self->{workbook}->addformat(
        size   => 8,
        color  => 'black',
        align  => 'left',
        border => 1,
    );

    # String wrap format
    $fmt{varchar_fmt} = $self->{workbook}->addformat(
        size      => 8,
        color     => 'black',
        align     => 'left',
        border    => 1,
        #text_wrap => 1,
        border    => 1,
    );

    # Numeric format
    $fmt{numeric_fmt} = $self->{workbook}->addformat(
        size       => 8,
        color      => 'black',
        num_format => '#,##0.00',
        border     => 1,
    );

    # Numeric format INTEGER
    $fmt{integer_fmt} = $self->{workbook}->addformat(
        size       => 8,
        color      => 'black',
        num_format => '#,##0',
        border     => 1,
    );

    # Numeric format INTEGER
    $fmt{smallint_fmt} = $self->{workbook}->addformat(
        size       => 8,
        color      => 'black',
        num_format => '#,##0',
        border     => 1,
    );

    # Date format DMY
    $fmt{date_fmt} = $self->{workbook}->addformat(
        color      => 'black',
        num_format => 'dd.mm.yyyy',
        border     => 1,
        align      => 'center',
    );

    # Char format CNP (numeric)
    $fmt{cnp_fmt} = $self->{workbook}->addformat(
        size       => 8,
        color      => 'black',
        num_format => 0x01,
        border     => 1,
    );

    $self->{fmt} = \%fmt;

    return;
}

sub create_header_row {
    my ( $self, $row, $col_data ) = @_;

    my $col = 0;
    foreach my $rec ( @{$col_data} ) {
        my $data = QDepo::Utils->decode_unless_utf($rec);
        $self->{sheet}->write( $row, $col, $data, $self->{fmt}{h_fmt} );
        $col++;
    }

    return;
}

sub create_row {
    my ( $self, $row, $col_data ) = @_;
    my $col = 0;
    foreach my $rec ( @{$col_data} ) {
        my $data = QDepo::Utils->decode_unless_utf( $rec->{contents} );
        my $type = $rec->{type};
        my $cfmt = defined $type ? "${type}_fmt" : 'varchar_fmt';
        if ( $type and $type =~ /date/ ) {
            # Date/Time must be in ISO8601 format: yyyy-mm-ddThh:mm:ss.sss
            $self->{sheet}->write_date_time( $row, $col, $data,
                                             $self->{fmt}{$cfmt} );
        }
        else {
            $self->{sheet}
                ->write( $row, $col, $data, $self->{fmt}{$cfmt} );
        }
        $self->store_max_len( $col, length $data ) if $data;
        $col++;
    }
    return;
}

sub finish {
    my ($self, $count_rows, $percent) = @_;

    # Set columns width
    $self->set_cols_width();
    $self->{workbook}->close
        or die "Can not close WorkBook: $!\n";
    my $output;
    if ( -f $self->{xls_file} ) {
        $output = $self->{xls_file};
    }
    return ($output, $count_rows, $percent);
}

sub init_column_widths {
    my ( $self, $fields ) = @_;
    @{ $self->{lenghts} } = map { defined $_ ? length($_) : 0 } @{$fields};
    return scalar @{$self->{lenghts}};       # for test
}

sub store_max_len {
    my ($self, $col, $len) = @_;

    # Impose a maximum width
    $len = $self->{max_len} if $len > $self->{max_len};

    # Store max
    ${ $self->{lenghts} }[$col] = $len if ${ $self->{lenghts} }[$col] < $len;

    return;
}

sub set_cols_width {
    my ($self) = @_;
    my $cols = scalar @{ $self->{lenghts} };
    for ( my $col = 0 ; $col < $cols; $col++ ) {
        $self->{sheet}->set_column( $col, $col, ${ $self->{lenghts} }[$col] );
    }
    return;
}

1;

__END__

=pod

=head2 new

Constructor method.

Create the create the Excel spreadsheet document.

TODO: Formats better defined outside the module, maybe in a YAML
configuration file?

=head2 create_row

Create a row of data; format not implemented yet.

=head2 finish

Print a message about the status of document creation and return it.

=head2 init_column_widths

Init column widths record to avoid error when making comparisons.

=head2 store_max_len

Impose a maximum width and store max length.

=head2 set_cols_width

Set the columns with.

=cut
