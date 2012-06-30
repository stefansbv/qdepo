package TpdaQrt::Output::Calc;

use strict;
use warnings;
use Carp;

use OpenOffice::OODoc 2.103;
use Encode qw(encode);

=head1 NAME

TpdaQrt::Output::Calc - Export data in OppenOffice.org format

=head1 VERSION

Version 0.36

=cut

our $VERSION = '0.36';

=head1 SYNOPSIS

    use TpdaQrt::Output::Calc;

    my $app = TpdaQrt::Output::Calc->new();

=head1 METHODS

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

    $self->_create_doc('TesT', $doc_rows, $doc_cols);

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

=head2 create_row

Create a row of data; format not imlemented yet.

=cut

sub create_row {
    my ($self, $row, $data, $fmt_name) = @_;

    my $cols = scalar @{$data};

    for ( my $col = 0 ; $col < $cols ; $col++ ) {
        my $data = encode('utf-8', $data->[$col]);
        $self->{doc}->cellValue( $self->{sheet}, $row, $col, $data );
        # if (defined $data) {
        #     $self->store_max_len( $col, length $data );
        # }
    }

    return;
}

=head2 create_done

Print a message about the status of document creation and return it.

=cut

sub create_done {
    my ($self, ) = @_;

    # Set columns width
    # $self->set_cols_width();

    $self->{doc}->save
        or die "Can not save document: $!\n";

    my $output;
    if ( -f $self->{doc_file} ) {
        $output = $self->{doc_file};
    }

    return $output;
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

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of TpdaQrt::Output::Calc
