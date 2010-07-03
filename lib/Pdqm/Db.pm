package Pdqm::Db;

use strict;
use warnings;
use Carp;

use Pdqm::Db::Instance;

sub new {

    my ( $class, $args ) = @_;

    my $self = bless {}, $class;

    $self->_init($args);

    return $self;
}

sub _init {
    my ($self, $args) = @_;

    $self->{db} = Pdqm::Db::Instance->instance( $args );
}

sub DESTROY {
    my $self = shift;

    $self->{db} = undef;
}

sub dbh {
    my $self = shift;

    my $db = $self->{db};

    die ref($self) . " requires a database handle to complete an action"
        unless defined $db and $db->isa('Pdqm::Db::Instance');

    return $db->{dbh};
}

sub db_generate_output {

    my ($self, $choice, $option, $sqltext, $bind, $outfile) = @_;

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
        require Pdqm::Output::Excel;
    };
    if ($@) {
        print "Spreadsheet::WriteExcel not available!\n";
        return;
    }

    my $xls = Pdqm::Output::Excel->new($outfile);

    my $dbh = $self->dbh();

    my $error = 0; # Error flag
    eval {
        my $sth = $dbh->prepare($sql);

        # Bind parameters
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
        require Pdqm::Output::Csv;
    };
    if ($@) {
        print "Text::CSV_XS not available!\n";
        return;
    }

    my $csv = Pdqm::Output::Csv->new($outfile);

    my $dbh = $self->dbh();

    my $error = 0; # Error flag
    eval {
        my $sth = $dbh->prepare($sql);

        # Bind parameters
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
        require Pdqm::Output::Calc;
    };
    if ($@) {
        print "OpenOffice::OODoc 2.103 not available!\n";
        return;
    }

    my $dbh = $self->dbh();

    my $doc;
    my ($from) = $sql =~ m/FROM.+?$/ixmg; # Needs more testing?
    # print "From: $from\n";

    #--- Count

    my $cnt_sql = 'SELECT COUNT(*) ' . $from;

    print "sql=",$cnt_sql,"\n";

    my $rows;
    my $error = 0; # Error flag
    eval {
        my $sth = $dbh->prepare($sql);

        # Bind parameters
        foreach my $params ( @{$bind} ) {
            my ($p_num, $data) = @{$params};
            $sth->bind_param($p_num, $data);
        }

        ($rows) = $dbh->selectrow_array( $cnt_sql );
    };
    if ($@) {
        warn "Transaction aborted because $@";
        $error++;

        # Return error early
        return $error;
    }

    #--- Select

    eval {
        my $sth = $dbh->prepare($sql);

        # Bind parameters
        foreach my $params ( @{$bind} ) {
            my ($p_num, $data) = @{$params};
            $sth->bind_param($p_num, $data);
        }

        $sth->execute();

        my $row = 0;

        # Create new spreadsheet with predefined dimensions
        my $cols = scalar @{ $sth->{NAME} };

        $doc = Pdqm::Output::Calc->new($outfile, $rows, $cols);

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


1;
