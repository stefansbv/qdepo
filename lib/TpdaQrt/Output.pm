package TpdaQrt::Output;

use strict;
use warnings;

use POSIX qw (floor);

use Try::Tiny;

use TpdaQrt::Db;

=head1 NAME

TpdaQrt::Output - Export from database to various formats.

=head1 VERSION

Version 0.16

=cut

our $VERSION = '0.16';

=head1 SYNOPSIS

    use TpdaQrt::Output;

    my $out = TpdaQrt::Output->new();


=head1 METHODS

=head2 new

Constructor.

=cut

sub new {
    my ($class, $model) = @_;

    my $self = {};

    $self->{model} = $model;
    $self->{dbh}   = TpdaQrt::Db->instance()->dbh;

    bless $self, $class;

    return $self;
}

=head2 db_generate_output

Select the appropriate method to generate output.

=cut

sub db_generate_output {
    my ($self, $option, $sqltext, $bind, $outfile) = @_;

    # Check SQL param
    if ( !defined $sqltext ) {
        $self->{model}->message('No SQL parameter!');
        return;
    }

    my $sub_name = 'generate_output_' . lc($option);
    my $out;
    if ( $self->can($sub_name) ) {
        $out = $self->$sub_name($sqltext, $bind, $outfile);
    }
    else {
        $self->{model}->message_log("WW $option is not implemented yet!");
    }

    return $out;
}

=head2 generate_output_excel

Generate output in Microsoft Excel format.

=cut

sub generate_output_excel {
    my ($self, $sql, $bind, $outfile) = @_;

    # File name
    if ( defined $outfile ) {
        $outfile .= '.xls';
    }
    else {
        $self->{model}->message('No file parameter');
        return;
    }

    try {
        require TpdaQrt::Output::Excel;
    }
    catch {
        $self->{model}->message_log("EE Spreadsheet::WriteExcel not available!");
        return;
    };

    my $xls = TpdaQrt::Output::Excel->new($outfile);

    try {
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
    }
    catch {
        $self->{model}->message_log("II SQL: $sql");
        $self->{model}->message_log('EE ' . $_);
    };

    # Try to close file and check if realy exists
    my $out = $xls->create_done();

    return $out;
}

=head2 generate_output_csv

Generate output in CSV format.

=cut

sub generate_output_csv {

    my ($self, $sql, $bind, $outfile) = @_;

    # File name
    if ( defined $outfile ) {
        $outfile .= '.csv';
    }
    else {
        $self->{model}->message("No file parameter!");
        return;
    }

    try {
        require TpdaQrt::Output::Csv;
    }
    catch {
        $self->{model}->message_log("EE Text::CSV_XS not available!");
        return;
    };

    my $csv = TpdaQrt::Output::Csv->new($outfile);

    try {
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
    }
    catch {
        $self->{model}->message_log("II SQL: $sql");
        $self->{model}->message_log('EE ' . $_);
    };

    # Try to close file and check if realy exists
    my $out = $csv->create_done();

    return $out;
}

=head2 generate_output_calc

Generate output in OpenOffice.org - Calc format.

=cut

sub generate_output_calc {
    my ($self, $sql, $bind, $outfile) = @_;

    # File name
    if ( defined $outfile ) {
        $outfile .= '.ods';
    }
    else {
        $self->{model}->message('No file parameter');
        return;
    }

    $self->{model}->message_log("II Generating output file '$outfile'");

    try { require TpdaQrt::Output::Calc; }
    catch {
        $self->{model}->message_log("EE OpenOffice::OODoc not available!");
        return;
    };

    my $rows_cnt = $self->count_rows($sql, $bind);

    #--- Select

    my $out;
    try {
        my $sth = $self->{dbh}->prepare($sql);

        foreach my $params ( @{$bind} ) {
            my ($p_num, $data) = @{$params};
            $sth->bind_param($p_num, $data);
        }

        $sth->execute();

        my $cols = scalar @{ $sth->{NAME} };

        # Create new spreadsheet with predefined dimensions
        my $doc = TpdaQrt::Output::Calc->new($outfile, $rows_cnt, $cols);

        # Initialize lengths record
        $doc->init_lengths( $sth->{NAME} );

        my $row = 0;

        # Header
        $doc->create_row( $row, $sth->{NAME}, 'h_fmt');

        $row++;

        $self->{model}->message("$rows_cnt total rows");

        $self->{model}->progress_update(0);
        my $pv = 0;

        while ( my @rezultat = $sth->fetchrow_array() ) {
            my $fmt_name = 's_format'; # Default to string format
                                       # other formats support TODO
            $doc->create_row($row, \@rezultat, $fmt_name);

            $row++;

            # Progress bar
            my $p = floor ($row * 100 / $rows_cnt);
            next if $pv == $p;

            $self->{model}->progress_update($p);
            $pv = $p;
        }

        $self->{model}->progress_update(100); # finish

        # Try to close file and check if realy exists
        $out = $doc->create_done();
    }
    catch {
        $self->{model}->message_log("II SQL: $sql");
        $self->{model}->message_log('EE ' . $_);
    };

    return $out;
}

=head2 generate_output_odf

Generate output in ODF format.

=cut

sub generate_output_odf {
    my ($self, $sql, $bind, $outfile) = @_;

    # File name
    if ( defined $outfile ) {
        $outfile .= '.ods';
    }
    else {
        $self->{model}->message('No file parameter');
        return;
    }

    $self->{model}->message_log("II Generating output file '$outfile'");

    try { require TpdaQrt::Output::ODF; }
    catch {
        $self->{model}->message_log("EE ODF::lpOD not available!");
        return;
    };

    my $rows_cnt = $self->count_rows($sql, $bind);

    #--- Select

    my $out;
    try {
        my $sth = $self->{dbh}->prepare($sql);

        foreach my $params ( @{$bind} ) {
            my ($p_num, $data) = @{$params};
            $sth->bind_param($p_num, $data);
        }

        $sth->execute();

        my $cols = scalar @{ $sth->{NAME} };

        # Create new spreadsheet
        my $doc = TpdaQrt::Output::ODF->new($outfile, $rows_cnt, $cols);

        # Initialize lengths record
        $doc->init_lengths( $sth->{NAME} );

        my $row = 0;

        # Header
        $doc->create_row( $row, $sth->{NAME}, 'h_fmt');

        $row++;

        $self->{model}->message("$rows_cnt total rows");

        $self->{model}->progress_update(0);
        my $pv = 0;

        while ( my @rezultat = $sth->fetchrow_array() ) {
            my $fmt_name = 's_format'; # Default to string format
                                       # other formats support TODO
            $doc->create_row($row, \@rezultat, $fmt_name);

            $row++;

            # Progress bar
            my $p = floor ($row * 100 / $rows_cnt);
            next if $pv == $p;

            $self->{model}->progress_update($p);
            $pv = $p;
        }

        $self->{model}->progress_update(100); # finish

        # Try to close file and check if realy exists
        $out = $doc->create_done();
    }
    catch {
        $self->{model}->message_log("II SQL: $sql");
        $self->{model}->message_log('EE ' . $_);
    };

    return $out;
}

=head2 count_rows

Count rows. Build the count SQL query using the from clause from the
query from the qdf file.

TODO: Improve to support GROUP BY | ORDER and so ...

=cut

sub count_rows {
    my ($self, $sql, $bind) = @_;

    my ($from) = $sql =~ m/\bFROM\b(.*?)\Z/ims; # incomplete

    #--- Count

    my $cnt_sql = q{SELECT COUNT(*) FROM } . $from;

    $self->{model}->message_log("II SQL: $cnt_sql");

    my $rows_cnt;
    try {
        my $sth = $self->{dbh}->prepare($cnt_sql);

        foreach my $params ( @{$bind} ) {
            my ($p_num, $data) = @{$params};
            $sth->bind_param($p_num, $data);
        }

        my @cols = $self->{dbh}->selectrow_array( $sth );
        $rows_cnt = $cols[0] + 1;         # One more for the header
    }
    catch {
        $self->{model}->message_log("II SQL: $sql");
        $self->{model}->message_log('EE ' . $_);
    };

    return $rows_cnt;
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

1; # End of TpdaQrt::Output
