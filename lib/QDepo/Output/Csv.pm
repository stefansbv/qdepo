package QDepo::Output::Csv;

# ABSTRACT: Export data in CSV format

use strict;
use warnings;
use Carp;

use Text::CSV;
use QDepo::Utils;

sub new {
    my $class = shift;

    my $self = {};
    bless( $self, $class );
    $self->{csv_file} = shift;
    $self->{csv_fh} = undef;

    $self->{csv} = $self->_create_doc();

    return $self;
}

sub _create_doc {
    my ($self) = @_;

    # Options from config?
    my $csv_o = Text::CSV->new(
        {
            'sep_char'     => ';',
            'always_quote' => 0,
            'binary'       => 1
        }
    );

    open $self->{csv_fh}, '>:encoding(utf8)', $self->{csv_file}
        or croak "Can't open file ", $self->{csv_file}, ": $!";

    return $csv_o;
}

sub create_header_row {
    my ( $self, undef, $col_data ) = @_;
    my $status = $self->{csv}->combine( @{$col_data} );
    my $line = $self->{csv}->string();
    print { $self->{csv_fh} } "$line\n";
    return;
}

sub create_row {
    my ( $self, undef, $col_data ) = @_;
    my @row_data = ();
    foreach my $rec ( @{$col_data} ) {
        my $data = $rec->{contents} // "";
        $data = QDepo::Utils->decode_unless_utf($data) if $data;
        push @row_data, $data;
    }
    my $status = $self->{csv}->combine( @row_data );
    my $line   = $self->{csv}->string();
    print { $self->{csv_fh} } "$line\n";
    return;
}

sub finish {
    my ($self, $count_rows, $percent) = @_;
    close $self->{csv_fh}
        or die "Can not close file: $!\n";
    my $output;
    if ( -f $self->{csv_file} ) {
        $output = $self->{csv_file};
    }
    return ($output, $count_rows, $percent);
}

1;

__END__

=pod

=head2 new

Constructor method.

=head2 _create_doc

Create the CSV text document.

=head2 create_row

Create a row of data.

=head2 finish

Print a message about the status of document creation and return it.

=cut
