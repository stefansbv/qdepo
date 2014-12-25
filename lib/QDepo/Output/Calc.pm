package QDepo::Output::Calc;

# ABSTRACT: Export data in OppenOffice.org format

use strict;
use warnings;
use Carp;

use OpenOffice::OODoc 2.103;

sub new {
    my $class = shift;

    my $self = {};

    bless( $self, $class );

    $self->{doc_file} = shift;
    my $doc_rows = shift;    # Number of rows for doc init
    my $doc_cols = shift;    # Number of cols for doc init

    $self->{doc_fh}  = undef;
    $self->{doc}     = undef;
    $self->{sheet}   = undef;
    $self->{lenghts} = [];      # Array to hold max lenghts for each col
    $self->{max_len} = 30;      # Max column width

    $self->_create_doc( 'Page1', $doc_rows, $doc_cols );

    return $self;
}

sub _create_doc {
    my ( $self, $sheet_name, $rows, $cols ) = @_;
    $self->{doc} = odfDocument(
        file   => $self->{doc_file},
        create => 'spreadsheet',
    );
    $self->{doc}->renameTable( 0, $sheet_name );

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

sub finish {
    my ( $self, $count_rows, $percent ) = @_;

    # Set columns width
    # $self->set_cols_width();
    $self->{doc}->save
        or croak "Can not save document: $!\n";
    my $output;
    if ( -f $self->{doc_file} ) {
        $output = $self->{doc_file};
    }
    return ( $output, $count_rows, $percent );
}

sub init_column_widths {
    my ( $self, $fields ) = @_;
    @{ $self->{lenghts} } = map { defined $_ ? length($_) : 0 } @{$fields};
    return;
}

sub store_max_len {
    my ( $self, $col, $len ) = @_;
    $len = $self->{max_len} if $len > $self->{max_len};
    ${ $self->{lenghts} }[$col] = $len if ${ $self->{lenghts} }[$col] < $len;
    return;
}

sub set_cols_width {
    my ($self) = @_;
    my $cols = scalar @{ $self->{lenghts} };
    for ( my $col = 0; $col < $cols; $col++ ) {
        $self->{sheet}->set_column( $col, $col, ${ $self->{lenghts} }[$col] );
    }
    return;
}

1;

__END__

=pod

=head2 new

Constructor method.

=head2 _create_doc

Create the OpenOffice.org spreadsheet document with a predefined number of rows
and cols.

=head2 create_row

Create a row of data; format not imlemented yet.

=head2 finish

Print a message about the status of document creation and return it.

=head2 init_column_widths

Init lengths record to avoid error when making comparisons.

=head2 store_max_len

Impose a maximum width and store max length.

=head2 set_cols_width

Set the columns with.

=cut
