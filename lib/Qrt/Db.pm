# +---------------------------------------------------------------------------+
# | Name     : tpda-qrt (TPDA - Query Repository Tool)                        |
# | Author   : Stefan Suciu  [ stefansbv 'at' users . sourceforge . net ]     |
# | Website  : http://tpda-qrt.sourceforge.net                                |
# |                                                                           |
# | Copyright (C) 2004-2010  Stefan Suciu                                     |
# |                                                                           |
# | This program is free software; you can redistribute it and/or modify      |
# | it under the terms of the GNU General Public License as published by      |
# | the Free Software Foundation; either version 2 of the License, or         |
# | (at your option) any later version.                                       |
# |                                                                           |
# | This program is distributed in the hope that it will be useful,           |
# | but WITHOUT ANY WARRANTY; without even the implied warranty of            |
# | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             |
# | GNU General Public License for more details.                              |
# |                                                                           |
# | You should have received a copy of the GNU General Public License         |
# | along with this program; if not, write to the Free Software               |
# | Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA |
# +---------------------------------------------------------------------------+
# |
# +---------------------------------------------------------------------------+
# |                                                       p a c k a g e   D b |
# +---------------------------------------------------------------------------+
package Qrt::Db;

use strict;
use warnings;

use Data::Dumper;
use Carp;

use Qrt::Db::Instance;

sub new {

    my ( $class, $args ) = @_;

    my $self = bless {}, $class;

    $self->{db} = Qrt::Db::Instance->instance( $args );

    return $self;
}

sub DESTROY {
    my $self = shift;

    $self->{db} = undef;
}

sub dbh {
    my $self = shift;

    my $db = $self->{db};

    die ref($self) . " not properly initialized"
        unless defined $db and $db->isa('Qrt::Db::Instance');

    return $db->{dbh};
}

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

=pod

A plug-in mechanism would be nice here to detect and extend the output
formats and maybe update the toolbar Wx::Choice options accordingly.

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

        # Bind parameters
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

        # Bind parameters
        foreach my $params ( @{$bind} ) {
            my ($p_num, $data) = @{$params};
            $sth->bind_param($p_num, $data);
        }

        $sth->execute();

        my $row = 0;

        # Create new spreadsheet with predefined dimensions
        my $cols = scalar @{ $sth->{NAME} };

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

1;
