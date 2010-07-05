# +---------------------------------------------------------------------------+
# | Name     : Pdqm (Perl Database Query Manager)                             |
# | Author   : Stefan Suciu  [ stefansbv 'at' users . sourceforge . net ]     |
# | Website  :                                                                |
# |                                                                           |
# | Copyright (C) 2010  Stefan Suciu                                          |
# |                                                                           |
# | This program is free software; you can redistribute it and/or modify      |
# | it under the terms of the GNU General Public License as published by      |
# | the Free Software Foundation; either version 2 of the License, or         |
# | (at your option) any later version.                                       |
# |                                                                           |
# | This program is distributed in the hope that it will be useful,           |
# | but WITHOUT ANY WARRANTY; without even the implied warranty of            |
# | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             |
# | GNU General Public License for more details.                              |
# |                                                                           |
# | You should have received a copy of the GNU General Public License         |
# | along with this program; if not, write to the Free Software               |
# | Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA |
# +---------------------------------------------------------------------------+
# |
# +---------------------------------------------------------------------------+
# |                                                   p a c k a g e   C a l c |
# +---------------------------------------------------------------------------+
package Pdqm::Output::Calc;

use strict;
use warnings;
use Carp;

use OpenOffice::OODoc 2.103;

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

    $self->_create_doc('Test', $doc_rows, $doc_cols);

    return $self;
}

sub _create_doc {

    my ( $self, $sheet_name, $rows, $cols ) = @_;

    # create the OOo spreadsheet
    $self->{doc} = odfDocument(
        file => $self->{doc_file},
        create => 'spreadsheet',
    );

    # select & size the 1st (and only) sheet in the document
    $self->{sheet} = $self->{doc}->expandTable(0, $rows, $cols);

    return;
}

sub create_row {

    my ($self, $row, $data, $fmt_name) = @_;

    my $cols = scalar @{$data};

    for ( my $col = 0 ; $col < $cols ; $col++ ) {
        my $data = $data->[$col];
        $self->{doc}->cellValue( $self->{sheet}, $row, $col, $data );
        if (defined $data) {
            $self->store_max_len( $col, length $data );
        }
    }

    return;
}

sub create_done {

    my ($self, ) = @_;

    # Set columns width
    # $self->set_cols_width(); Nu mere in OODoc !!!

    $self->{doc}->save
        or die "Can not save document: $!\n";

    my $output;
    if ( -f $self->{doc_file} ) {
        $output = $self->{doc_file};
        print " Output file: ", $self->{doc_file}, " created.\n";
    }
    else {
        $output = '';
        print " ERROR, output file", $self->{doc_file}, " NOT created.\n";
    }

    return $output;
}

sub init_lengths {

    # Init lengths record to avoid error when making comparisons

    my ($self, $fields) = @_;

    @{$self->{lenghts}} = map { defined $_ ? length($_) : 0 } @{$fields};

    return;
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
