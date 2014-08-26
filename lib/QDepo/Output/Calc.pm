package QDepo::Output::Calc;

# ABSTRACT: Export data in OppenOffice.org format

use strict;
use warnings;
use Carp;

use OpenOffice::OODoc 2.103;

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;

    my $self = {};

    bless( $self, $class );

    $self->{doc_file} = shift;
    my $doc_rows      = shift;  # Number of rows for doc init
    my $doc_cols      = shift;  # Number of cols for doc init

    $self->{doc_fh}  = undef;
    $self->{doc}     = undef;
    $self->{sheet}   = undef;
    $self->{lenghts} = [];      # Array to hold max lenghts for each col
    $self->{max_len} = 30;      # Max column width

    $self->_create_doc('Page1', $doc_rows, $doc_cols);

    return $self;
}

=head2 _create_doc

Create the OpenOffice.org spreadsheet document with a predefined
number of rows and cols.

=cut

sub _create_doc {
    my ( $self, $sheet_name, $rows, $cols ) = @_;

    $self->{doc} = odfDocument(
        file   => $self->{doc_file},
        create => 'spreadsheet',
    );

    $self->{doc}->renameTable(0, $sheet_name);

    # select & size the 1st (and only) sheet in the document
    $self->{sheet} = $self->{doc}->expandTable( 0, $rows, $cols );

    return;
}

sub create_header_row {
    my ( $self, $row, $col_data ) = @_;

    my $col = 0;
    foreach my $rec ( @{$col_data} ) {
        my $data = QDepo::Utils->decode_unless_utf($rec);
        $self->{doc}->cellValue( $self->{sheet}, $row, $col, $data );
        $col++;
    }

    return;
}

=head2 create_row

Create a row of data; format not imlemented yet.

=cut

sub create_row {
    my ( $self, $row, $col_data ) = @_;

    my $col = 0;
    foreach my $rec ( @{$col_data} ) {
        my $data = odfDecodeText( $rec->{contents} );
        my $type = $rec->{type};
        if ( $type and $type =~ /date/ ) {
            # Date/Time is in ISO8601 format: yyyy-mm-ddThh:mm:ss.sss
            # TODO: format date/time
        }
        $self->{doc}->cellValue( $self->{sheet}, $row, $col, $data );
        $self->store_max_len( $col, length $data ) if $data;
        $col++;
    }

    return;
}

=head2 create_done

Print a message about the status of document creation and return it.

=cut

sub create_done {
    my ($self, $count_rows, $percent) = @_;

    # Set columns width
    # $self->set_cols_width();

    $self->{doc}->save
        or die "Can not save document: $!\n";

    my $output;
    if ( -f $self->{doc_file} ) {
        $output = $self->{doc_file};
    }

    return ($output, $count_rows, $percent);
}

=head2 init_lengths

Init lengths record to avoid error when making comparisons.

=cut

sub init_lengths {
    my ($self, $fields) = @_;

    @{$self->{lenghts}} = map { defined $_ ? length($_) : 0 } @{$fields};

    return;
}

=head2 store_max_len

Impose a maximum width and store max length.

=cut

sub store_max_len {
    my ($self, $col, $len) = @_;

    $len = $self->{max_len} if $len > $self->{max_len};
    ${ $self->{lenghts} }[$col] = $len if ${ $self->{lenghts} }[$col] < $len;

    return;
}

=head2 set_cols_width

Set the columns with.

=cut

sub set_cols_width {

    my ($self) = @_;

    my $cols = scalar @{ $self->{lenghts} };

    for ( my $col = 0 ; $col < $cols; $col++ ) {
        $self->{sheet}->set_column( $col, $col, ${ $self->{lenghts} }[$col] );
    }

    return;
}

1;
