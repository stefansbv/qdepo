package TpdaQrt::Output;

use warnings;
use strict;

use TpdaQrt::Db;

=head1 NAME

TpdaQrt::Output - Export from database to various formats

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use TpdaQrt::Output;

    my $out = TpdaQrt::Output->new();


=head1 METHODS

=head2 new

Constructor

=cut

sub new {
    my $class = shift;

    return bless { dbh => TpdaQrt::Db->instance()->dbh, }, $class;
}

=head2 db_generate_output

Select the appropriate method to generate output

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

Generate output in Microsoft Excel format

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
        require TpdaQrt::Output::Excel;
    };
    if ($@) {
        print "Spreadsheet::WriteExcel not available!\n";
        return;
    }

    my $xls = TpdaQrt::Output::Excel->new($outfile);

    my $error = 0; # Error flag
    eval {
        my $sth = $self->{dbh}->prepare($sql);

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

Generate output in CSV format

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
        require TpdaQrt::Output::Csv;
    };
    if ($@) {
        print "Text::CSV_XS not available!\n";
        return;
    }

    my $csv = TpdaQrt::Output::Csv->new($outfile);

    my $error = 0; # Error flag
    eval {
        my $sth = $self->{dbh}->prepare($sql);

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

Generate output in OpenOffice.org - Calc format

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
        require TpdaQrt::Output::Calc;
    };
    if ($@) {
        print "OpenOffice::OODoc 2.103 not available!\n";
        return;
    }

    my $doc;
    # Need the last part of the query to build a counting select
    # first to create new spreadsheet with predefined dimensions
    my ($from) = $sql =~ m/\bFROM\b(.*?)\Z/ims; # Needs more testing!!!

    #--- Count

    my $cnt_sql = 'SELECT COUNT(*) FROM ' . $from;
    # print "\nsql=",$cnt_sql,"\n\n";

    my $rows_cnt;
    eval {
        my $sth = $self->{dbh}->prepare($cnt_sql);

        foreach my $params ( @{$bind} ) {
            my ($p_num, $data) = @{$params};
            $sth->bind_param($p_num, $data);
        }

        my @cols = $self->{dbh}->selectrow_array( $sth );
        $rows_cnt = $cols[0] + 1;         # One more for the header
    };
    if ($@) {
        warn "Transaction aborted because $@";
        return 1;
    }

    #--- Select

    my $error = 0; # Error flag
    eval {
        my $sth = $self->{dbh}->prepare($sql);

        foreach my $params ( @{$bind} ) {
            my ($p_num, $data) = @{$params};
            $sth->bind_param($p_num, $data);
        }

        $sth->execute();

        my $row = 0;
        my $cols = scalar @{ $sth->{NAME} };

        # Create new spreadsheet with predefined dimensions
        $doc = TpdaQrt::Output::Calc->new($outfile, $rows_cnt, $cols);

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

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of TpdaQrt::Output
