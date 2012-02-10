package TpdaQrt::Output::ODF;

use strict;
use warnings;
use 5.010_000;
use Carp;

use ODF::lpOD;
use Encode qw(encode);

=head1 NAME

TpdaQrt::Output::ODF - Export data in ODF format

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use TpdaQrt::Output::ODF;

    my $app = TpdaQrt::Output::ODF->new();

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;

    my $self = {};

    bless( $self, $class );

    $self->{doc_file} = shift;
    $self->{doc_rows} = shift;
    $self->{doc_cols} = shift;

    $self->{doc} = undef;

    $self->_create_doc('Sheet');

    return $self;
}

=head2 _create_doc

Create the ODF spreadsheet document.

=cut

sub _create_doc {
    my ( $self, $sheet_name ) = @_;

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

=head2 create_row

Create a row of data; format not imlemented yet.

=cut

sub create_row {
    my ($self, $row, $data, $fmt_name) = @_;

    for ( my $col = 0 ; $col < $self->{doc_cols} ; $col++ ) {
        my $data = encode('utf-8', $data->[$col]);
        $self->{sheet}->get_cell($row,$col)->set_value($data);
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

    $self->{doc}->save(target => $self->{doc_file});

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

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of TpdaQrt::Output::ODF
