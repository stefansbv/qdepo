package Pdqm::Output::Csv;

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
