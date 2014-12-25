package QDepo::Output::ODF;

# ABSTRACT: Export data in ODF format

use 5.010001;    # minimum version nedeed by ODF::lpOD
use strict;
use warnings;
use Carp;

use ODF::lpOD;
use QDepo::Utils;

sub new {
    my $class = shift;

    my $self = {};
    bless( $self, $class );
    $self->{doc_file} = shift;
    $self->{doc_rows} = shift;
    $self->{doc_cols} = shift;
    $self->{doc}      = undef;
    $self->{lenghts}  = [];      # Array to hold max lenghts for each col
    $self->{max_len}  = 30;      # Max column width

    $self->_create_doc('Sheet');

    return $self;
}

sub _create_doc {
    my ( $self, $sheet_name ) = @_;

    # lpod->set_input_charset('utf-8');
    # lpod->debug(1);

    $self->{doc} = odf_document->create('spreadsheet');

    my $contexte = $self->{doc}->get_body();

    $contexte->clear;

    $self->{sheet} = odf_table->create(
        $sheet_name,
        height => $self->{doc_rows},
        width  => $self->{doc_cols},
    );

    $contexte->insert_element( $self->{sheet} );

    return;
}

sub create_header_row {
    my ( $self, $row, $col_data ) = @_;
    my $col = 0;
    foreach my $rec ( @{$col_data} ) {
        my $data = QDepo::Utils->decode_unless_utf($rec);
        $self->{sheet}->get_cell( $row, $col )->set_value($data);
        $col++;
    }
    return;
}

sub create_row {
    my ( $self, $row, $col_data ) = @_;
    my $col = 0;
    foreach my $rec ( @{$col_data} ) {
        my $data = $rec->{contents};
        my $type = $rec->{type};
        if ( $type and $type =~ /date/ ) {

            # Date/Time is in ISO8601 format: yyyy-mm-ddThh:mm:ss.sss
            # TODO: format date/time
        }
        $self->{sheet}->get_cell( $row, $col )->set_value($data);
        $self->store_max_len( $col, length $data ) if $data;
        $col++;
    }
    return;
}

sub finish {
    my ( $self, $count_rows, $percent ) = @_;

    # Set column widths
    $self->set_cols_width();
    $self->{doc}->save( target => $self->{doc_file} );
    my $output;
    if ( -f $self->{doc_file} ) {
        $output = $self->{doc_file};
    }
    return ( $output, $count_rows, $percent );
}

sub init_column_widths {
    my ( $self, $fields ) = @_;
    @{ $self->{lenghts} } = map { defined $_ ? length($_) : 0 } @{$fields};
    return scalar @{ $self->{lenghts} };    # for test
}

sub store_max_len {
    my ( $self, $col, $len ) = @_;

    # Impose a maximum width
    $len = $self->{max_len} if $len > $self->{max_len};

    # Store max
    ${ $self->{lenghts} }[$col] = $len if ${ $self->{lenghts} }[$col] < $len;

    return;
}

sub set_cols_width {
    my ($self) = @_;
    my $cols = scalar @{ $self->{lenghts} };
    for ( my $col = 0; $col < $cols; $col++ ) {

        #$self->{sheet}->set_column( $col, $col, ${ $self->{lenghts} }[$col] );
        $self->set_col_style( $col, ${ $self->{lenghts} }[$col] );
    }
    return;
}

sub set_col_style {
    my ( $self, $col, $width ) = @_;
    $self->{doc}->insert_style(
        odf_style->create(
            'table column',
            name  => "StylePour$col",
            width => "${width}cm",
        )
    );
    $self->{sheet}->get_column($col)->set_style("StylePour$col");
    return;
}

1;

__END__

=pod

=head2 new

Constructor method.

=head2 _create_doc

Create the ODF spreadsheet document.

=head2 create_row

Create a row of data; format not implemented yet.

=head2 finish

Print a message about the status of document creation and return it.

=head2 init_column_widths

Init lengths record to avoid error when making comparisons.

=head2 store_max_len

Impose a maximum width and store max length.

=head2 set_cols_width

Set the columns with.

=head2 set_col_style

Set column width.

TODO: compute optimum width. Add other style attributes.

=cut
