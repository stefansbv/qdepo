package TpdaQrt::Output::Excel;

use strict;
use warnings;
use Carp;

use Spreadsheet::WriteExcel;

=head1 NAME

TpdaQrt::Output::Excel - Export data in CSV format

=head1 VERSION

Version 0.33

=cut

our $VERSION = '0.33';

=head1 SYNOPSIS

    use TpdaQrt::Output::Excel;

    my $app = TpdaQrt::Output::Excel->new();

=head1 METHODS

=head2 new

Constructor method.

=cut

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

=pod

Create the create the Excel spreadsheet document.

TODO: Formats better defined outside the module, maybe in a YAML
configuration file?

=cut

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
    $fmt{'h_fmt'} = $self->{workbook}->addformat(
        size   => 8,
        color  => 'black',
        align  => 'center',
        bold   => 1,
        border => 1,
    );

    # String format
    $fmt{'s_fmt'} = $self->{workbook}->addformat(
        size   => 8,
        color  => 'black',
        align  => 'left',
        border => 1,
    );

    # String wrap format
    $fmt{'sw_fmt'} = $self->{workbook}->addformat(
        size      => 8,
        color     => 'black',
        align     => 'left',
        border    => 1,
        text_wrap => 1,
        border    => 1,
    );

    # Numeric format
    $fmt{'n_fmt'} = $self->{workbook}->addformat(
        size       => 8,
        color      => 'black',
        num_format => '#,##0.00',
        border     => 1,
    );

    # Numeric format INTEGER
    $fmt{'nint_fmt'} = $self->{workbook}->addformat(
        size       => 8,
        color      => 'black',
        num_format => '#,##0',
        border     => 1,
    );

    # Char format CNP (numeric)
    $fmt{'cnp_fmt'} = $self->{workbook}->addformat(
        size       => 8,
        color      => 'black',
        num_format => 0x01,
        border     => 1,
    );

    $self->{fmt} = \%fmt;

    return;
}

=head2 create_row

Create a row of data; format not imlemented yet.

=cut

sub create_row {
    my ($self, $row, $fields, $fmt_name) = @_;

    my $cols = scalar @{$fields};

    for ( my $col = 0 ; $col < $cols; $col++ ) {
        my $data = $fields->[$col];
        $self->{sheet}->write( $row, $col, $data, $self->{fmt}->{$fmt_name} );
        if (defined $data) {
            $self->store_max_len($col, length $data);
        }
    }

    return;
}

=head2 create_done

Print a message about the status of document creation and return it.

=cut

sub create_done {

    my ($self, ) = @_;

    # Set columns width
    $self->set_cols_width();

    $self->{workbook}->close
        or die "Can not close WorkBook: $!\n";

    my $output;
    if ( -f $self->{xls_file} ) {
        $output = $self->{xls_file};
    }

    return $output;
}

=head2 init_lengths

Init lengths record to avoid error when making comparisons.

=cut

sub init_lengths {
    my ( $self, $fields ) = @_;

    @{ $self->{lenghts} } = map { defined $_ ? length($_) : 0 } @{$fields};

    return scalar @{$self->{lenghts}};       # for test
}

=head2 store_max_len

Impose a maximum width and store max length.

=cut

sub store_max_len {
    my ($self, $col, $len) = @_;

    # Impose a maximum width
    $len = $self->{max_len} if $len > $self->{max_len};

    # Store max
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

1; # End of TpdaQrt::Output::Excel
