package TpdaQrt::Output::Csv;

use strict;
use warnings;
use Carp;

use Text::CSV_XS;

=head1 NAME

TpdaQrt::Output::Csv - Export data in CSV format

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use TpdaQrt::Output::Csv;

    my $app = TpdaQrt::Output::Csv->new();

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;

    my $self = {};

    bless( $self, $class );

    $self->{csv_file} = shift;

    $self->{csv_fh} = undef;

    $self->{csv} = $self->_create_doc();

    return $self;
}

=head2 _create_doc

Create the CSV text document.

=cut

sub _create_doc {
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

=head2 create_row

Create a row of data.

=cut

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

=head2 create_done

Print a message about the status of document creation and return it.

=cut

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

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of TpdaQrt::Output::Csv
