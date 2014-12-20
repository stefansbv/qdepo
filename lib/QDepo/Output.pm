package QDepo::Output;

# ABSTRACT: Export from database to various formats

use strict;
use warnings;

use Try::Tiny;
use POSIX qw (floor);
use Locale::TextDomain 1.20 qw(QDepo);
use QDepo::Exceptions;
use QDepo::Config;

sub new {
    my ($class, $model) = @_;
    my $self = {
        _model  => $model,
        _cfg    => QDepo::Config->instance(),
        _dbh    => $model->dbh,
        columns => [],
    };
    bless $self, $class;
    return $self;
}

sub module_name {
    return {
        excel => {
            depend => 'Spreadsheet::WriteExcel',
            module => 'QDepo::Output::Excel',
            ext    => 'xls',
        },
        csv => {
            depend => 'Text::CSV_XS',
            module => 'QDepo::Output::Csv',
            ext    => 'csv',
        },
        calc => {
            depend => 'OpenOffice::OODoc',
            module => 'QDepo::Output::Calc',
            ext    => 'ods',
        },
        odf => {
            depend => 'ODF::lpOD',
            module => 'QDepo::Output::ODF',
            ext    => 'ods',
        },
    };
}

sub module_name_parameter {
    my ($self, $option, $param) = @_;
    $option = lc $option;
    my $names = $self->module_name;
    if ( exists $names->{$option}{$param} ) {
        return $names->{$option}{$param};
    }
    else {
        die "Unknown module for $option";
    }
}

sub load_module {
    my ($self, $option) = @_;

    # Check dependency
    my $depend = $self->module_name_parameter($option, 'depend');
    try { eval "require $depend" or die $@; }
    catch {
        $self->model->message_log(
            __x('{ert} {module} is not available',
                ert    => 'EE',
                module => $depend,
            )
        );
    };

    my $module = $self->module_name_parameter($option, 'module');
    try { eval "require $module" or die $@; }
    catch {
        $self->model->message_log(
            __x('{ert} {module} is not available',
                ert    => 'EE',
                module => $module,
            )
        );
    };
}

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

sub db_generate_output {
    my ($self, $option, $sql, $bind, $outfile) = @_;

    $self->load_module($option);

    my $ext = $self->module_name_parameter($option, 'ext');
    if ( defined $outfile ) {
        $outfile .= ".$ext" unless $outfile =~ m{\.${ext}$}i;
    }
    else {
        $self->model->message_status(__ 'No output file parameter');
        return;
    }

    # Check SQL param
    unless ( defined $sql ) {
        $self->model->message_status(__ 'No SQL parameter!');
        return;
    }

    # Rows count for user messages and spreadsheet dimensions initialization
    my $rows_cnt = $self->check_rows($sql, $bind);

    # Execute Select
    my $sth;
    my $success = try {
        $sth = $self->dbh->prepare($sql);
        foreach my $params ( @{$bind} ) {
            my ($p_num, $data) = @{$params};
            $sth->bind_param($p_num, $data);
        }
        $sth->execute();
        1;
    }
    catch {
        $self->catch_db_exceptions($_, 'Execute select');
        return undef;           # required!
    };
    return unless $success;

    # Set header and columns matadata
    $self->make_columns_record($sth);

    $self->model->message_log(
        __x('{ert} Generating output file "{outfile}"',
            ert     => 'II',
            outfile => $outfile,
        )
    );

    return unless $sth;

    # Create output document
    my $sub_name = 'generate_output_' . lc($option);
    my $out;
    if ( $self->can($sub_name) ) {
        $out = $self->$sub_name($sth, $outfile, $rows_cnt);
    }
    else {
        $self->model->message_log(
            __x('{ert} {option} is not implemented',
                ert    => 'WW',
                option => $option,
            )
        );
    }

    return $out;
}

sub check_rows {
    my ($self, $sql, $bind) = @_;
    my $rows_cnt = $self->count_rows($sql, $bind);
    if (defined $rows_cnt and $rows_cnt >= 0 ) {
        $self->model->message_log(
            __x('{ert} Count: {rows_cnt} total rows',
                ert      => 'II',
                rows_cnt => $rows_cnt,
            )
        );
    }
    else {
        $self->model->message_log(
            __x('{ert} Could not count rows!', ert => 'WW') );
    }
    return $rows_cnt;
}

sub generate_output_excel {
    my ($self, $sth, $outfile, $rows_cnt) = @_;

    my $doc = QDepo::Output::Excel->new($outfile);
    $doc->init_column_widths( $sth->{NAME} );
    $doc->create_header_row( 0, $self->{header} );
    $self->model->progress_update(0);
    my ($row, $pv) = $self->create_contents($doc, $sth, $rows_cnt);

    return $doc->finish($row, $pv);
}

sub generate_output_csv {
    my ($self, $sth, $outfile, $rows_cnt) = @_;

    my $doc = QDepo::Output::Csv->new($outfile);
    $doc->create_header_row( 0, $self->{header} );
    my ($row, $pv) = $self->create_contents($doc, $sth, $rows_cnt);

    return $doc->finish($row, $pv);
}

sub generate_output_calc {
    my ($self, $sth, $outfile, $rows_cnt) = @_;
    if ( $rows_cnt <= 0 ) {
        $self->model->message_log(
            __x('{ert} Can not count the output rows or rows_no <= 0',
                ert => 'WW',
            )
        );
        return;
    }
    my $cols = scalar @{ $sth->{NAME} };
    my $doc = QDepo::Output::Calc->new($outfile, $rows_cnt, $cols);
    $doc->init_column_widths( $sth->{NAME} );
    $doc->create_header_row( 0, $self->{header} );
    $self->model->message_status(
        __nx ("one row", "{num} rows", $rows_cnt, num => $rows_cnt)
    );
    $self->model->progress_update(0);

    my ($row, $pv) = $self->create_contents($doc, $sth, $rows_cnt);

    return $doc->finish($row, $pv);
}

sub generate_output_odf {
    my ($self, $sth, $outfile, $rows_cnt) = @_;
    if ( $rows_cnt <= 0 ) {
        $self->model->message_log(
            __x('{ert} Can not count the output rows or rows_no <= 0',
                ert => 'WW',
            )
        );
        return;
    }
    my $cols = scalar @{ $sth->{NAME} };
    my $doc = QDepo::Output::ODF->new($outfile, $rows_cnt, $cols);
    $doc->init_column_widths( $sth->{NAME} );
    $doc->create_header_row( 0, $self->{header} );
    $self->model->message_status(
        __nx ("one row", "{num} rows", $rows_cnt, num => $rows_cnt)
    );
    $self->model->progress_update(0);
    my ($row, $pv) = $self->create_contents($doc, $sth, $rows_cnt);

    return $doc->finish($row, $pv);
}

sub count_rows {
    my ($self, $sql, $bind) = @_;

    # Capture everything after the first "FROM"

    # !!! This does not work for complex SQL statements !!!

    return -1 if $sql =~ m/\bUNION\s+SELECT/ims;

    my ($from) = $sql =~ m/\bFROM\b(.*?)\Z/ims; # incomplete
    unless ($from) {
        $self->model->message_log(
            __x('{ert} Failed to extract FROM clause',
                ert      => 'EE',
            )
        );

        return;
    }

    #--- Count

    my $cnt_sql = q{SELECT COUNT(*) FROM } . $from;
    $self->model->message_log(
        __x('{ert} SQL: {cnt_sql}',
            ert     => 'II',
            cnt_sql => $cnt_sql,
        )
    ) if $self->cfg->verbose;

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

        next if $rows_cnt < 0;  # no progress bar

        my $p = floor( $row_num * 100 / $rows_cnt );
        next if $pv == $p;
        $self->model->progress_update($p);
        unless ( $self->model->get_continue_observable->get ) {
            $self->model->message_log(
                __x( '{ert} Stopped at user request', ert => 'II', ) );
            $sth->finish;
            last;
        }
        $pv = $p;
    }

    $self->model->progress_update(100); # finish
    $self->model->progress_update();

    return ($row_num, $pv);
}

sub make_columns_record {
    my ($self, $sth) = @_;

    my ( $columns, $header );
    my $success = try {
        ( $columns, $header ) = $self->model->parse_sql_text;
        1;
    }
    catch {
        $self->catch_db_exceptions($_, __ 'Columns record');
        return undef;           # required!
    };
    if ($success) {
        ( $self->{columns}, $self->{header} ) = ( $columns, $header );
        return;
    }

    # Fallback to get info DBI statement

    @{ $self->{header} } = map {lc} @{ $sth->{NAME} };
    my $row = 1;
    foreach my $field ( @{ $self->{header} } ) {
        push @{ $self->{columns} },
            { field => $field, type => 'varchar', recno => $row };
        $row++;
    }
    return;
}

sub catch_db_exceptions {
    my ($self, $exc, $context) = @_;
    print "Context is $context\n";
    my ($message, $details);
    if ( my $e = Exception::Base->catch($exc) ) {
        if ( $e->isa('Exception::Db::Connect') ) {
            $message = $e->usermsg;
            $details = $e->logmsg;
            $self->model->message_log(
                __x('{ert} {message}: {details}',
                    ert     => 'EE',
                    message => $message,
                    details => $details,
                )
            );
        }
        elsif ( $e->isa('Exception::Db::SQL::Parser') ) {
            $message = $e->usermsg;
            $details = $e->logmsg;
            $self->model->message_log(
                __x('{ert} {message}: {details}',
                    ert     => 'WW',
                    message => $message,
                    details => $details,
                )
            );
        }
        elsif ( $e->isa('Exception::Db::SQL') ) {
            $message = $e->usermsg;
            $details = $e->logmsg;
            my $sep  = $details ? ':' : '';
            $self->model->message_log(
                __x('{ert} {message}{sep} {details}',
                    ert     => 'EE',
                    sep     => $sep,
                    message => $message,
                    details => $details,
                )
            );
        }
        else {
            # Exception isa Unknown
            $self->model->message_log(
                __x('{ert} {message}',
                    ert     => 'EE',
                    message => $e->message,
                )
            );
        }
    }
    return;
}

1;

__END__

=head2 count_rows

Count rows. Build the I<COUNT> SQL query using the I<FROM> clause from
the query.

=head2 create_contents

Create document contents and show progress.

The row data passed to create_row is a AoH:
    [
      {
        recno    =>  1,
        field    =>  'name',
        type     =>  'varchar',
        contents =>  'John Doe',
      },
    ],

=head2 make_columns_record

Columns meta data.  Have to call it early before the main transaction.

Example:

    [
      {
        recno => 0,
        field => 'name',
        type  => 'varchar'
      },
    ],

=cut
