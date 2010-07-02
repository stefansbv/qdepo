package Pdqm::Db::Connection::Postgresql;

use strict;
use warnings;

use Carp;
use DBI;

# use Postgresql >= 8.3.5 !!! :)

use vars qw($VERSION);
$VERSION = 0.30;

sub new {

    my $class = shift;

    my $self = {};

    $self->{FLD} = {};

    bless $self, $class;

    return $self;
}

sub conectare {

    # +-----------------------------------------------------------------------+
    # | Descriere: Connect to the database                                    |
    # +-----------------------------------------------------------------------+

    my ($self, $conf, $user, $pass) = @_;

    # $pass = undef; # Uncomment when is no password set

    my $dbname = $conf->{Database};
    my $server = $conf->{Server};
    my $port   = $conf->{Port};
    my $rdbms  = $conf->{DBMS};

    print "Connect to the $rdbms server ...\n";
    print " Parameters:\n";
    print "  => Database = $dbname\n";
    print "  => Server   = $server\n";
    print "  => Port     = $port\n";
    print "  => User     = $user\n";

    eval {
        $self->{_dbh} = DBI->connect(
            "dbi:Pg:"
                . "dbname="
                . $dbname
                . ";host="
                . $server
                . ";port="
                . $port,
            $user,
            $pass,
            { RaiseError => 1, FetchHashKeyName => 'NAME_lc' }
        );
    };
    ## Date format
    # set: datestyle = 'german' in postgresql.conf
    ##

    if ($@) {
        warn "$@";
        return undef;
    }
    else {
        print "\nConnected to database \'$dbname\'.\n";
        return $self->{_dbh};
    }
}

sub table_exists {

# +---------------------------------------------------------------------------+
# | Descriere: Returneaza 1 daca tabelul exista                               |
# | Parametri: nume_tabel                                                     |
# +---------------------------------------------------------------------------+

    my $self  = $_[0];
    my $tabel = $_[1];

    my ( $sql, $val_ret );

    $sql = qq( SELECT COUNT(table_name)
                FROM information_schema.tables
                WHERE table_type = 'BASE TABLE'
                    AND table_schema NOT IN
                    ('pg_catalog', 'information_schema')
                    AND table_name = '$tabel';
    );

    # print "sql=",$sql,"\n";

    eval {
        ##Assuming a valid $dbh exists...
        ($val_ret) = $self->{_dbh}->selectrow_array($sql);
    };
    if ($@) {
        warn "Transaction aborted because $@";
    }

    return $val_ret;
}

sub table_primary_key {

# +---------------------------------------------------------------------------+
# | Descriere: Return primary key field name                                  |
# | Parametri: nume_tabel                                                     |
# +---------------------------------------------------------------------------+

    my $self  = $_[0];
    my $tabel = $_[1];

    # $tabel = uc($tabel);

    my ( $sql, $pkf );

    #  From http://www.alberton.info/postgresql_meta_info.html
    $sql = qq( SELECT kcu.column_name
                   FROM information_schema.table_constraints tc
                     LEFT JOIN information_schema.key_column_usage kcu
                          ON tc.constraint_catalog = kcu.constraint_catalog
                            AND tc.constraint_schema = kcu.constraint_schema
                            AND tc.constraint_name = kcu.constraint_name
                   WHERE tc.table_name = '$tabel'
                     AND tc.constraint_type = 'PRIMARY KEY';
    );

    # print "sql=",$sql,"\n";

    $self->{_dbh}->{AutoCommit} = 1;    # disable transactions
    $self->{_dbh}->{RaiseError} = 0;

    eval {
        # List of lists
        $pkf = $self->{_dbh}->selectcol_arrayref( $sql, { MaxRows => 1 } );
    };
    if ($@) {
        warn "Transaction aborted because $@";
    }

    print 'Pk = ',$pkf->[0],"\n";
    return $pkf->[0];
}

sub generator_value {

# +---------------------------------------------------------------------------+
# | Descriere: Return generator value                                         |
# | Parametri: nume_generator                                                 |
# +---------------------------------------------------------------------------+

    my $self     = $_[0];
    my $gen_name = $_[1];

    # $gen_name = uc($gen_name);

    my ( $sql, $genval );

    # get name of the sequence that a serial or bigserial column uses
    # pg_get_serial_sequence(table_name, column_name)

    $sql = qq( SELECT lastval('$gen_name'); );

    # print "sql=",$sql,"\n";

    $self->{_dbh}->{AutoCommit} = 1;    # disable transactions
    $self->{_dbh}->{RaiseError} = 0;

    eval {

        # Fetch max 1 rows
        $genval = $self->{_dbh}->selectcol_arrayref( $sql, { MaxRows => 1 } );
    };

    if ($@) {
        warn "Transaction aborted because $@";
    }
    return $genval->[0];
}

sub generator_value_next {

# +---------------------------------------------------------------------------+
# | Descriere: Return generator value                                         |
# | Parametri: nume_generator                                                 |
# +---------------------------------------------------------------------------+

    my $self     = $_[0];
    my $gen_name = $_[1];

    # $gen_name = uc($gen_name);

    my ( $sql, $genval );

    # get name of the sequence that a serial or bigserial column uses
    # pg_get_serial_sequence(table_name, column_name)

    $sql = qq( SELECT nextval('$gen_name'); );

    # print "sql=",$sql,"\n";

    eval {

        # Fetch max 1 rows
        $genval = $self->{_dbh}->selectcol_arrayref( $sql, { MaxRows => 1 } );
    };

    if ($@) {
        warn "Transaction aborted because $@";
    }
    return $genval->[0];
}

sub db_specific_like {

# +-------------------------------------------------------------------------+
# | Description:                                                            |
# | Parameters :                                                            |
# +-------------------------------------------------------------------------+

    my $self  = $_[0];
    my $field = $_[1];

    my $operator = {};

    $operator->{cmd} = "CAST ($field AS TEXT) ILIKE";
    $operator->{fld} = '';

    return $operator;
}

sub db_specific_contains {

# +-------------------------------------------------------------------------+
# | Description:                                                            |
# | Parameters :                                                            |
# +-------------------------------------------------------------------------+

    my $self  = $_[0];
    my $field = $_[1];
    my $value = $_[2];

    my $operator = {};

    $operator->{cmd} = "CAST ($field AS TEXT) ILIKE";
    $operator->{fld} = '';
    $operator->{val} = '%'.$value.'%';

    return $operator;
}

sub table_info_short {

# +---------------------------------------------------------------------------+
# | Descriere: Returneaza: table info, varianta scurta                        |
# | Parametri: nume_tabel                                                     |
# +---------------------------------------------------------------------------+
    my $self  = $_[0];
    my $tabel = $_[1];

    my ( $sql, $hash_ref );

    $sql = qq( SELECT ordinal_position  AS fld_pos
                    , column_name       AS fld_name
                    , data_type         AS fld_type
                    , column_default    AS fld_defa
                    , is_nullable
                    , character_maximum_length AS fld_length
                    , numeric_precision AS fld_prec
                    , numeric_scale     AS fld_scale
               FROM information_schema.columns
               WHERE table_name = '$tabel'
               ORDER BY ordinal_position;
    );

    $self->{_dbh}->{AutoCommit}       = 1; # disable transactions
    $self->{_dbh}->{RaiseError}       = 1;
    $self->{_dbh}->{ChopBlanks}       = 1; # trim CHAR fields
    $self->{_dbh}->{FetchHashKeyName} = 'NAME_lc';

    eval {

        # List of lists
        $self->{STH} = $self->{_dbh}->prepare($sql);
        $self->{STH}->execute;
        $hash_ref = $self->{STH}->fetchall_hashref('fld_pos');
    };
    if ($@) {
        warn "Transaction aborted because $@";
    }

    my $nr_campuri = scalar keys %{$hash_ref};
    # print "\nNumar campuri = $nr_campuri\n";

    # Initializare
    $self->{FLD}{$tabel} = {};
    $tabel = lc $tabel;

    # Creez lista campuri
    while ( my ( $name, $row ) = each( %{$hash_ref} ) ) {
        $name =~ s/^\s+//;
        $name =~ s/\s+$//;
        $self->{FLD}{$tabel}->{ $row->{fld_pos} } = $name;
    }

    return $hash_ref;
}

sub get_tbl_find_records_sql {

# +-------------------------------------------------------------------------+
# | Description: Ugly code :)                                               |
# | Parameters :                                                            |
# +-------------------------------------------------------------------------+

    my $self   = $_[0];
    my $cols   = $_[1];
    my $table  = $_[2];
    my $where  = $_[3];
    my $ordcol = $_[4];
    my $limit  = $_[5];

    my $sql = qq{ SELECT $cols
               FROM  $table
                   WHERE $where
           ORDER BY $ordcol
                   LIMIT $limit;
          };

    return $sql;
}

# --* End file

1;

__END__
