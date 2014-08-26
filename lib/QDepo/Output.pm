package QDepo::Output;

# ABSTRACT: Export from database to various formats

use strict;
use warnings;

use Try::Tiny;
use POSIX qw (floor);

use QDepo::Exceptions;
use QDepo::Config;
use QDepo::Db;

=head2 new

Constructor.

=cut

sub new {
    my ($class, $model) = @_;

    my $self = {
        _model  => $model,
        _cfg    => QDepo::Config->instance(),
        _dbh    => QDepo::Db->instance()->dbh,
        columns => [],
    };

    bless $self, $class;

    return $self;
}

=head2 cfg

Return config instance variable

=cut

sub cfg {
    my $self = shift;
    return $self->{_cfg};
}

sub dbh {
    my $self = shift;
    return $self->{_dbh};
}

sub model {
    my $self = shift;
    return $self->{_model};
}

=head2 db_generate_output

Select the appropriate method to generate output.

=cut

sub db_generate_output {
    my ($self, $option, $sqltext, $bind, $outfile) = @_;

    # Check SQL param
    if ( !defined $sqltext ) {
        $self->model->message_status('No SQL parameter!');
        return;
    }

    try {
        $self->make_columns_record;
    }
    catch {
        $self->catch_db_exceptions($_, 'Columns record');
    };

    my $sub_name = 'generate_output_' . lc($option);
    my $out;
    if ( $self->can($sub_name) ) {
        $out = $self->$sub_name($sqltext, $bind, $outfile);
    }
    else {
        $self->model->message_log("WW $option is not implemented yet!");
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
        $self->model->message_status('No file parameter');
        return;
    }

    $self->model->message_log("II Generating output file '$outfile'");
    try { require QDepo::Output::Excel; }
    catch {
        $self->model->message_log("EE Spreadsheet::WriteExcel not available!");
        return;
    };

    # Rows count used only for user messages
    my $rows_cnt = $self->count_rows($sql, $bind);
    if ($rows_cnt) {
        $self->model->message_log("II Count: $rows_cnt total rows");
    }
    else {
        $self->model->message_log("II Count: No output rows!");
        return;
    }

    #--- Select

    my $doc = QDepo::Output::Excel->new($outfile);

    my @out;
    try {
        my $sth = $self->dbh->prepare($sql);

        foreach my $params ( @{$bind} ) {
            my ($p_num, $data) = @{$params};
            $sth->bind_param($p_num, $data);
        }

        $sth->execute();

        # Initialize lengths record
        $doc->init_lengths( $sth->{NAME} );

        # Header
        $doc->create_header_row( 0, $self->{header} );

        $self->model->progress_update(0);

        my ($row, $pv) = $self->create_contents($doc, $sth, $rows_cnt);

        # Try to close file and check if realy exists
        @out = $doc->create_done($row, $pv);
    }
    catch {
        $self->catch_db_exceptions($_, 'Excel');
    };

    return \@out;
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
        $self->model->message_status("No file parameter!");
        return;
    }

    $self->model->message_log("II Generating output file '$outfile'");

    try { require QDepo::Output::Csv; }
    catch {
        $self->model->message_log("EE Text::CSV_XS not available!");
        return;
    };

    # Rows count used only for user messages
    my $rows_cnt = $self->count_rows($sql, $bind);
    #$self->model->message_log("II SQL: $sql") if $self->cfg->verbose;
    if ($rows_cnt) {
        $self->model->message_log("II Count: $rows_cnt total rows");
    }
    else {
        $self->model->message_log("II Count: No output rows!");
        return;
    }

    my $doc = QDepo::Output::Csv->new($outfile);

    my @out;
    try {
        my $sth = $self->dbh->prepare($sql);

        foreach my $params ( @{$bind} ) {
            my ($p_num, $data) = @{$params};
            $sth->bind_param($p_num, $data);
        }

        $sth->execute();

        # Header
        $doc->create_header_row( 0, $self->{header} );

        my ($row, $pv) = $self->create_contents($doc, $sth, $rows_cnt);

        # Try to close file and check if realy exists
        @out = $doc->create_done($row, $pv);
    }
    catch {
        $self->catch_db_exceptions($_, 'CSV');
    };

    return \@out;
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
        $self->model->message_status('No file parameter');
        return;
    }

    $self->model->message_log("II Generating output file '$outfile'");

    try { require QDepo::Output::Calc; }
    catch {
        $self->model->message_log("EE OpenOffice::OODoc not available!");
        return;
    };

    # Rows count used for user messages and for sheet initialization
    my $rows_cnt = $self->count_rows($sql, $bind);
    if ($rows_cnt) {
        $self->model->message_log("II Count: $rows_cnt total rows");
    }
    else {
        $self->model->message_log("II SQL: No output rows!");
        return;
    }

    #--- Select

    my (@out, $sth);
    try {
        $sth = $self->dbh->prepare($sql);
        foreach my $params ( @{$bind} ) {
            my ($p_num, $data) = @{$params};
            $sth->bind_param($p_num, $data);
        }
        $sth->execute();
    }
    catch {
        $self->catch_db_exceptions($_, 'Calc');
    };

    my $cols = scalar @{ $sth->{NAME} };

    # Create new spreadsheet with predefined dimensions
    my $doc = QDepo::Output::Calc->new($outfile, $rows_cnt, $cols);

    # Initialize lengths record
    $doc->init_lengths( $sth->{NAME} );

    # Header
    $doc->create_header_row( 0, $self->{header} );

    $self->model->message_status("$rows_cnt total rows");

    $self->model->progress_update(0);

    my ($row, $pv) = $self->create_contents($doc, $sth, $rows_cnt);

    # Try to close file and check if realy exists
    @out = $doc->create_done($row, $pv);

    return \@out;
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
        $self->model->message_status('No file parameter');
        return;
    }

    $self->model->message_log("II Generating output file '$outfile'");

    try { require QDepo::Output::ODF; }
    catch {
        $self->model->message_log("EE ODF::lpOD not available!");
        return;
    };

    # Rows count used for user messages and for sheet initialization
    my $rows_cnt = $self->count_rows($sql, $bind);
    if ($rows_cnt) {
        $self->model->message_log("II Count: $rows_cnt total rows");
    }
    else {
        $self->model->message_log("II SQL: No output rows!");
        return;
    }

    #--- Select

    my @out;
    try {
        my $sth = $self->dbh->prepare($sql);

        foreach my $params ( @{$bind} ) {
            my ($p_num, $data) = @{$params};
            $sth->bind_param($p_num, $data);
        }

        $sth->execute();

        my $cols = scalar @{ $sth->{NAME} };

        # Create new spreadsheet
        my $doc = QDepo::Output::ODF->new($outfile, $rows_cnt, $cols);

        # Initialize lengths record
        $doc->init_lengths( $sth->{NAME} );

        # Header
        $doc->create_header_row( 0, $self->{header} );

        $self->model->message_status("$rows_cnt total rows");

        $self->model->progress_update(0);

        my ($row, $pv) = $self->create_contents($doc, $sth, $rows_cnt);

        # Try to close file and check if realy exists
        @out = $doc->create_done($row, $pv);
    }
    catch {
        $self->catch_db_exceptions($_, 'ODF');
    };

    return \@out;
}

=head2 count_rows

Count rows. Build the I<COUNT> SQL query using the I<FROM> clause from
the query.

=cut

sub count_rows {
    my ($self, $sql, $bind) = @_;

    # Capture everything after the first "FROM"
    my ($from) = $sql =~ m/\bFROM\b(.*?)\Z/ims; # incomplete
    unless ($from) {
        $self->model->message_log("EE Failed to extract FROM clause!");
        return;
    }

    #--- Count

    my $cnt_sql = q{SELECT COUNT(*) FROM } . $from;

    #$self->model->message_log("II SQL: $cnt_sql") if $self->cfg->verbose;

    my $rows_cnt;
    try {
        my $sth = $self->dbh->prepare($cnt_sql);

        foreach my $params ( @{$bind} ) {
            my ($p_num, $data) = @{$params};
            $sth->bind_param($p_num, $data);
        }

        my @cols = $self->dbh->selectrow_array( $sth );
        if (@cols) {
            $rows_cnt = $cols[0] + 1;         # One more for the header
        }
    }
    catch {
        $self->catch_db_exceptions($_, 'Count rows');
    };

    return $rows_cnt;
}

=head2 create_contents

Create document contents and show progress.

The row data passed to create_row is a AoH:
    [0] {
        contents   "Joe Doe",
        field      "name",
        recno      1,
        type       "varchar"
    },

=cut

sub create_contents {
    my ( $self, $doc, $sth, $rows_cnt ) = @_;

    my ($row_num, $pv) = (1, 0);

    while ( my $row_data = $sth->fetchrow_hashref ) {
        my $col_data = [];
        foreach my $col ( @{ $self->{columns} } ) {
            $col->{contents} = $row_data->{ $col->{field} };
            push @{$col_data}, $col;
        }
        $doc->create_row( $row_num, $col_data );
        $row_num++;

        #-- Progress bar

        my $p = floor( $row_num * 100 / $rows_cnt );
        next if $pv == $p;
        $self->model->progress_update($p);
        unless ( $self->model->get_continue_observable->get ) {
            $self->model->message_log("II Stopped at user request!");
            $sth->finish;
            last;
        }
        $pv = $p;
    }

    $self->model->progress_update(100); # finish
    $self->model->progress_update();

    return ($row_num, $pv);
}

=head2 function_name

Columns meta data.  Have to call it early before the main transaction.

=cut

sub make_columns_record {
    my $self = shift;
    ( $self->{columns}, $self->{header} ) = $self->model->get_columns_list;
    return;
}

sub catch_db_exceptions {
    my ($self, $exc, $context) = @_;

    print "Context $context\n";
    my ($message, $details);
    if ( my $e = Exception::Base->catch($exc) ) {
        if ( $e->isa('Exception::Db::SQL') ) {
            $message = $e->usermsg;
            $details = $e->logmsg;
            $self->model->message_log("EE $message: $details");
        }
        elsif ( $e->isa('Exception::Db::Connect') ) {
            $message = $e->usermsg;
            $details = $e->logmsg;
            $self->model->message_log("EE $message: $details");
        }
        else {
            # Exception isa Unknown
            $self->model->message_log("EE ", $e->message);
            $e->throw;                       # rethrow the exception
            return;
        }
    }

    return;
}

1;
