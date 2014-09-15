package QDepo::Output;

# ABSTRACT: Export from database to various formats

use strict;
use warnings;

use Try::Tiny;
use POSIX qw (floor);
use Locale::TextDomain 1.20 qw(QDepo);
use QDepo::Exceptions;
use QDepo::Config;
use QDepo::Db;

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
        return;
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
        return;
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
    my ($self, $option, $sqltext, $bind, $outfile) = @_;

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
    unless ( defined $sqltext ) {
        $self->model->message_status(__ 'No SQL parameter!');
        return;
    }

    try {
        $self->make_columns_record;
    }
    catch {
        $self->catch_db_exceptions($_, __ 'Columns record');
    };

    my $sub_name = 'generate_output_' . lc($option);
    my $out;
    if ( $self->can($sub_name) ) {
        $out = $self->$sub_name($sqltext, $bind, $outfile);
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
    if ($rows_cnt) {
        $self->model->message_log(
            __x('{ert} Count: {rows_cnt} total rows',
                ert      => 'II',
                rows_cnt => $rows_cnt,
            )
        );
    }
    else {
        $self->model->message_log(
            __x('{ert} No output rows!',
                ert      => 'II',
                rows_cnt => $rows_cnt,
            )
        );
        return;
    }
    return $rows_cnt;
}

sub generate_output_excel {
    my ($self, $sql, $bind, $outfile) = @_;

    $self->model->message_log(
        __x('{ert} Generating output file "{outfile}"',
            ert     => 'II',
            outfile => $outfile,
        )
    );

    # Rows count used only for user messages
    my $rows_cnt = $self->check_rows($sql, $bind);
    return unless $rows_cnt;

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

sub generate_output_csv {
    my ($self, $sql, $bind, $outfile) = @_;

    $self->model->message_log(
        __x('{ert} Generating output file "{outfile}"',
            ert     => 'II',
            outfile => $outfile,
        )
    );

    # Rows count used only for user messages
    my $rows_cnt = $self->check_rows($sql, $bind);
    return unless $rows_cnt;

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

sub generate_output_calc {
    my ($self, $sql, $bind, $outfile) = @_;

    $self->model->message_log(
        __x('{ert} Generating output file "{outfile}"',
            ert     => 'II',
            outfile => $outfile,
        )
    );

    # Rows count used for user messages and for sheet initialization
    my $rows_cnt = $self->check_rows($sql, $bind);
    return unless $rows_cnt;

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

sub generate_output_odf {
    my ($self, $sql, $bind, $outfile) = @_;

    $self->model->message_log(
        __x('{ert} Generating output file "{outfile}"',
            ert     => 'II',
            outfile => $outfile,
        )
    );

    # Rows count used for user messages and for sheet initialization
    my $rows_cnt = $self->check_rows($sql, $bind);
    return unless $rows_cnt;

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

sub count_rows {
    my ($self, $sql, $bind) = @_;

    # Capture everything after the first "FROM"
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
    my $self = shift;
    ( $self->{columns}, $self->{header} ) = $self->model->get_columns_list;
    return;
}

sub catch_db_exceptions {
    my ($self, $exc, $context) = @_;

    my ($message, $details);
    if ( my $e = Exception::Base->catch($exc) ) {
        if ( $e->isa('Exception::Db::SQL') ) {
            $message = $e->usermsg;
            $details = $e->logmsg;
            $self->model->message_log(
                __x('{ert} {message}: {$details}',
                    ert     => 'EE',
                    message => $message,
                    details => $details,
                )
            );

        }
        elsif ( $e->isa('Exception::Db::Connect') ) {
            $message = $e->usermsg;
            $details = $e->logmsg;
            $self->model->message_log(
                __x('{ert} {message}: {$details}',
                    ert     => 'EE',
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
            $e->throw;                       # rethrow the exception
            return;
        }
    }

    return;
}

1;

=head2 count_rows

Count rows. Build the I<COUNT> SQL query using the I<FROM> clause from
the query.

=head2 create_contents

Create document contents and show progress.

The row data passed to create_row is a AoH:
    [0] {
        contents   "Joe Doe",
        field      "name",
        recno      1,
        type       "varchar"
    },

=head2 make_columns_record

Columns meta data.  Have to call it early before the main transaction.

=cut
