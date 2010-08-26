# +---------------------------------------------------------------------------+
# | Name     : Qrt (Perl Database Query Manager)                             |
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
# |                                                     p a c k a g e   C s v |
# +---------------------------------------------------------------------------+
package Qrt::Output::Csv;

use strict;
use warnings;
use Carp;

use Text::CSV_XS;

sub new {

    my $class = shift;

    my $self = {};

    bless( $self, $class );

    $self->{csv_file} = shift;

    $self->{csv_fh} = undef;

    $self->{csv} = $self->_create_csv();

    return $self;
}

sub _create_csv {

    my ($self) = @_;

    # Options from config?
    my $csv_o = Text::CSV_XS->new(
        {
            'sep_char'     => ';',
            'always_quote' => 1,
            'binary'       => 1
        }
    );

    open $self->{csv_fh}, '>', $self->{csv_file}
        or croak "Can't open file ", $self->{csv_file}, ": $!";

    return $csv_o;
}

sub create_row {

    my ($self, $data) = @_;

    my @data = map { defined $_ ? $_ : "" } @{$data};

    chomp(@data);

    # Data
    # Could use $csv->print ($io, $colref) for eficiency
    my $status = $self->{csv}->combine( @data );
    # print " status $status\n";
    my $line   = $self->{csv}->string();
    print { $self->{csv_fh} } "$line\n";

    return;
}

sub create_done {

    my ($self, ) = @_;

    close $self->{csv_fh}
        or die "Can not close file: $!\n";

    my $output;
    if ( -f $self->{csv_file} ) {
        $output = $self->{csv_file};
        print " Output file: ", $self->{csv_file}, " created.\n";
    }
    else {
        $output = '';
        print " ERROR, output file", $self->{csv_file}, " NOT created.\n";
    }

    return $output;
}


1;
