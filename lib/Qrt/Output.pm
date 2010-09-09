package Qrt::Output;

use warnings;
use strict;

=head1 NAME

Qrt::Output - The great new Qrt::Output!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Qrt::Output;

    my $foo = Qrt::Output->new();

    ...


=head1 METHODS

=head2 db_generate_output

=cut

sub db_generate_output {

    my ($self, $option, $sqltext, $bind, $outfile) = @_;

    # Check SQL param
    if (! defined $sqltext ) {
        warn "SQL parameter?\n";
        return;
    }

    my $sub_name = 'generate_output_' . lc($option);
    my ($err, $out);
    if ( $self->can($sub_name) ) {
        ($err, $out) = $self->$sub_name($sqltext, $bind, $outfile);
    }
    else {
        print " $option generation is not implemented yet...\n";
    }

    return ($err, $out);
}

=head2 generate_output_excel

=cut

sub generate_output_excel {

    my ($self, $sql, $bind, $outfile) = @_;

    # File name
    if ( defined $outfile ) {
        $outfile .= '.xls';
    }
    else {
        warn "File parameter?\n";
        return;
    }

    eval {
        require Qrt::Output::Excel;
    };
    if ($@) {
        print "Spreadsheet::WriteExcel not available!\n";
        return;
    }

    my $xls = Qrt::Output::Excel->new($outfile);

    my $dbh = $self->dbh();

    my $error = 0; # Error flag
    eval {
        my $sth = $dbh->prepare($sql);

        foreach my $params ( @{$bind} ) {
            my ($p_num, $data) = @{$params};
            $sth->bind_param($p_num, $data);
        }

        $sth->execute();

        my $row = 0;

        # Initialize lengths record
        $xls->init_lengths( $sth->{NAME} );

        # Header
        $xls->create_row( $row, $sth->{NAME}, 'h_fmt');

        $row++;

        while ( my @rezultat = $sth->fetchrow_array() ) {
            my $fmt_name = 's_format'; # Default to string format
                                       # other formats support TODO
            $xls->create_row($row, \@rezultat, $fmt_name);

            $row++;
        }
    };
    if ($@) {
        warn "Transaction aborted because $@";
        $error++;
    }

    # Try to close file and check if realy exists
    my $out = $xls->create_done();

    return ($error, $out);
}

=head2 generate_output_csv

=cut

sub generate_output_csv {

    my ($self, $sql, $bind, $outfile) = @_;

    # File name
    if ( defined $outfile ) {
        $outfile .= '.csv';
    }
    else {
        warn "File parameter?\n";
        return;
    }

    eval {
        require Qrt::Output::Csv;
    };
    if ($@) {
        print "Text::CSV_XS not available!\n";
        return;
    }

    my $csv = Qrt::Output::Csv->new($outfile);

    my $dbh = $self->dbh();

    my $error = 0; # Error flag
    eval {
        my $sth = $dbh->prepare($sql);

        foreach my $params ( @{$bind} ) {
            my ($p_num, $data) = @{$params};
            $sth->bind_param($p_num, $data);
        }

        $sth->execute();

        # Header
        $csv->create_row( $sth->{NAME} );

        while ( my @rezultat = $sth->fetchrow_array() ) {
            $csv->create_row(\@rezultat);
        }
    };
    if ($@) {
        warn "Transaction aborted because $@";
        $error++;
    }

    # Try to close file and check if realy exists
    my $out = $csv->create_done();

    return ($error, $out);
}

=head2 generate_output_calc

=cut

sub generate_output_calc {

    my ($self, $sql, $bind, $outfile) = @_;

    # File name
    if ( defined $outfile ) {
        $outfile .= '.ods';
    }
    else {
        warn "File parameter?\n";
        return;
    }

    print " generating $outfile\n";

    eval {
        require Qrt::Output::Calc;
    };
    if ($@) {
        print "OpenOffice::OODoc 2.103 not available!\n";
        return;
    }

    my $dbh = $self->dbh();

    my $doc;
    # Need the last part of the query to build a counting select
    # first to create new spreadsheet with predefined dimensions
    my ($from) = $sql =~ m/\bFROM\b(.*?)\Z/ims; # Needs more testing!!!

    #--- Count

    my $cnt_sql = 'SELECT COUNT(*) FROM ' . $from;
    # print "\nsql=",$cnt_sql,"\n\n";

    my $rows_cnt;
    eval {
        my $sth = $dbh->prepare($cnt_sql);

        foreach my $params ( @{$bind} ) {
            my ($p_num, $data) = @{$params};
            $sth->bind_param($p_num, $data);
        }

        my @cols = $dbh->selectrow_array( $sth );
        $rows_cnt = $cols[0] + 1;         # One more for the header
    };
    if ($@) {
        warn "Transaction aborted because $@";
        return 1;
    }

    #--- Select

    my $error = 0; # Error flag
    eval {
        my $sth = $dbh->prepare($sql);

        foreach my $params ( @{$bind} ) {
            my ($p_num, $data) = @{$params};
            $sth->bind_param($p_num, $data);
        }

        $sth->execute();

        my $row = 0;
        my $cols = scalar @{ $sth->{NAME} };

        # Create new spreadsheet with predefined dimensions
        $doc = Qrt::Output::Calc->new($outfile, $rows_cnt, $cols);

        # Initialize lengths record
        $doc->init_lengths( $sth->{NAME} );

        # Header
        $doc->create_row( $row, $sth->{NAME}, 'h_fmt');

        $row++;

        while ( my @rezultat = $sth->fetchrow_array() ) {
            my $fmt_name = 's_format'; # Default to string format
                                       # other formats support TODO
            $doc->create_row($row, \@rezultat, $fmt_name);

            $row++;
        }
    };
    if ($@) {
        warn "Transaction aborted because $@";
        $error++;
    }

    # Try to close file and check if realy exists
    my $out = $doc->create_done();

    return ($error, $out);
}


=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-qrt-output at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Qrt-Output>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Qrt::Output


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Qrt-Output>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Qrt-Output>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Qrt-Output>

=item * Search CPAN

L<http://search.cpan.org/dist/Qrt-Output/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Qrt::Output
