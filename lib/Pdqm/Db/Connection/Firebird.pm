package Pdqm::Db::Connection::Firebird;

use strict;
use warnings;

use Carp;
use DBI;

use vars qw($VERSION);

$VERSION = '0.80';

sub new {

# +---------------------------------------------------------------------------+
# | Descriere: Rutina de instantiere                                          |
# | Parametri: class, alias                                                   |
# +---------------------------------------------------------------------------+

    my $class = shift;

    my $self = {};

    bless $self, $class;

    return $self;
}

sub conectare {

    # +-----------------------------------------------------------------------+
    # | Descriere: Connect to the database                                    |
    # +-----------------------------------------------------------------------+

    my ($self, $conf, $user, $pass) = @_;

    my $dbname  = $conf->{Database};
    my $server  = $conf->{Server};
    my $fbport  = $conf->{Port};
    my $rdbms   = $conf->{DBMS};
    my $dialect = 3;

    print "Connect to the $rdbms server ...\n";
    print " Parameters:\n";
    print "  => Database = $dbname\n";
    print "  => Server   = $server\n";
    print "  => Dialect  = $dialect\n";
    print "  => User     = $user\n";

    eval {
        $self->{DBH} = DBI->connect(
            "DBI:InterBase:"
                . "dbname="
                . $dbname
                . ";host="
                . $server
                . ";ib_dialect="
                . $dialect,
            $user,
            $pass,
            { RaiseError => 1, FetchHashKeyName => 'NAME_lc' }
        );
    };

    if ($@) {
        warn "Transaction aborted because $@";
        print "Not connected!\n";
    }
    else {
        ## Default format: ISO
        # $self->{DBH}->{ib_timestampformat} = '%y-%m-%d %H:%M';
        # $self->{DBH}->{ib_dateformat}      = '%Y-%m-%d';
        # $self->{DBH}->{ib_timeformat}      = '%H:%M';
        ## Format: German
        $self->{DBH}->{ib_timestampformat} = '%d.%m.%Y %H:%M';
        $self->{DBH}->{ib_dateformat}      = '%d.%m.%Y';
        $self->{DBH}->{ib_timeformat}      = '%H:%M';

        print "\nConnected to database \'$dbname\'.\n"
            if $self->{tpda}->{run_ref}->{verbose} >= 1;
    }

    return $self->{DBH};
}

sub table_exists {

# +---------------------------------------------------------------------------+
# | Descriere: Returneaza 1 daca tabelul exista                               |
# | Parametri: nume_tabel                                                     |
# +---------------------------------------------------------------------------+
    my $self  = $_[0];
    my $tabel = $_[1];

    my ( $sql, $val_ret );

    $tabel = uc($tabel);

    $sql = qq( SELECT COUNT(RDB\$RELATION_NAME)
                  FROM RDB\$RELATIONS
                  WHERE (RDB\$RELATION_NAME = '$tabel')
                    AND  RDB\$VIEW_SOURCE IS NULL;
    );

    # print "sql=",$sql,"\n";

    eval {
        ##Assuming a valid $dbh exists...
        ($val_ret) = $self->{DBH}->selectrow_array($sql);
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

    # RDB\$RELATION_NAME must be Upper Character
    $tabel = uc($tabel);

    my ( $sql, $pkf );

    $sql = qq( SELECT c.RDB\$FIELD_NAME
                 FROM RDB\$RELATION_CONSTRAINTS a, RDB\$INDICES b, RDB\$INDEX_SEGMENTS c
                 WHERE ( a.RDB\$CONSTRAINT_TYPE = 'PRIMARY KEY'
                         OR a.RDB\$CONSTRAINT_TYPE = 'UNIQUE')
                       AND a.RDB\$RELATION_NAME = '$tabel'
                       AND a.RDB\$INDEX_NAME = b.RDB\$INDEX_NAME
                       AND b.RDB\$INDEX_NAME = c.RDB\$INDEX_NAME;
  );

    # print "sql=",$sql,"\n";

    $self->{DBH}->{AutoCommit} = 1;    # disable transactions
    $self->{DBH}->{RaiseError} = 0;

    eval {

        # Fetch max 1 rows
        $pkf = $self->{DBH}->selectcol_arrayref( $sql, { MaxRows => 1 } );
    };
    if ($@) {
        warn "Transaction aborted because $@";
    }

    return $pkf->[0];
}

sub generator_value {

# +---------------------------------------------------------------------------+
# | Descriere: Return generator value                                         |
# | Parametri: nume_generator                                                 |
# +---------------------------------------------------------------------------+

    my $self     = $_[0];
    my $gen_name = $_[1];

    $gen_name = uc($gen_name);

    my ( $sql, $genval );

    $sql = qq( SELECT GEN_ID($gen_name, 0) AS genval
                FROM RDB\$DATABASE;
  );

    # print "sql=",$sql,"\n";

    $self->{DBH}->{AutoCommit} = 1;    # disable transactions
    $self->{DBH}->{RaiseError} = 0;

    eval {

        # Fetch max 1 rows
        $genval = $self->{DBH}->selectcol_arrayref( $sql, { MaxRows => 1 } );
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

    $gen_name = uc($gen_name);

    my ( $sql, $genval );

    $sql = qq( SELECT GEN_ID($gen_name, 1) AS genval
                FROM RDB\$DATABASE;
  );

    # print "sql=",$sql,"\n";

    eval {

        # Fetch max 1 rows
        $genval = $self->{DBH}->selectcol_arrayref( $sql, { MaxRows => 1 } );
    };
    if ($@) {
        warn "Transaction aborted because $@";
    }
    return $genval->[0];
}

sub table_deps {

# +---------------------------------------------------------------------------+
# | Descriere: Returneaza tabelele dependente si campul id                    |
# | Parametri: nume_tabel                                                     |
# +---------------------------------------------------------------------------+

    my $self  = $_[0];
    my $tabel = $_[1];

    # RDB\$RELATION_NAME must be Upper Character
    $tabel = uc($tabel);

    my ( $sql, $report_lol );

    $sql = qq( SELECT r1.RDB\$RELATION_NAME, i.RDB\$FIELD_NAME
                  FROM RDB\$RELATION_CONSTRAINTS r1
                      JOIN RDB\$REF_CONSTRAINTS c
                         ON R1.RDB\$CONSTRAINT_NAME = c.RDB\$CONSTRAINT_NAME
                      JOIN RDB\$RELATION_CONSTRAINTS r2
                         ON c.RDB\$CONST_NAME_UQ = r2.RDB\$CONSTRAINT_NAME
                      JOIN RDB\$INDEX_SEGMENTS i
                         ON r1.RDB\$INDEX_NAME = i.RDB\$INDEX_NAME
                  WHERE (r2.RDB\$RELATION_NAME = '$tabel')
                         AND r1.RDB\$CONSTRAINT_TYPE = 'FOREIGN KEY';
  );

    # print "sql=",$sql,"\n";

    $self->{DBH}->{AutoCommit} = 1;    # disable transactions
    $self->{DBH}->{RaiseError} = 0;

    eval {

        # List of lists
        $report_lol = $self->{DBH}->selectall_arrayref($sql);
    };
    if ($@) {
        warn "Transaction aborted because $@";
    }

    return $report_lol;
}

sub db_specific_like {

# +-------------------------------------------------------------------------+
# | Description:                                                            |
# | Parameters :                                                            |
# +-------------------------------------------------------------------------+

    my $self  = $_[0];
    my $field = $_[1];

    my $operator = {};

    $operator->{cmd} = 'LIKE';
    $operator->{fld} = $field;

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

    $operator->{cmd} = 'CONTAINING';
    $operator->{fld} = $field;
    $operator->{val} = $value;

    return $operator;
}

sub table_info_short {

# +---------------------------------------------------------------------------+
# | Descriere: Returneaza: table info, varianta scurta                        |
# | Parametri: nume_tabel                                                     |
# +---------------------------------------------------------------------------+

    my $self  = $_[0];
    my $tabel = $_[1];

    # print "table_info ($tabel)\n";

    # RDB$RELATION_NAME must be Upper Character
    $tabel = uc($tabel);

    my ( $sql, $hash_ref );

    # COALESCE(F_BlobAsPChar(r.RDB\$DEFAULT_VALUE),'') AS fld_default
    $sql = qq( SELECT r.RDB\$FIELD_NAME AS fld_name
                  , r.RDB\$FIELD_POSITION AS fld_pos
                  , f.RDB\$FIELD_LENGTH AS fld_length
                  , f.RDB\$FIELD_PRECISION AS fld_prec
                  , f.RDB\$FIELD_SCALE AS fld_scale
                  , CASE
                      WHEN (f.RDB\$FIELD_TYPE = 261) THEN 'BLOB'
                      WHEN (f.RDB\$FIELD_TYPE = 14) THEN 'CHAR'
                      WHEN (f.RDB\$FIELD_TYPE = 40) THEN 'CSTRING'
                      WHEN (f.RDB\$FIELD_TYPE = 11) THEN 'D_FLOAT'
                      WHEN (f.RDB\$FIELD_TYPE = 27) THEN 'DOUBLE'
                      WHEN (f.RDB\$FIELD_TYPE = 10) THEN 'FLOAT'
                      WHEN (f.RDB\$FIELD_TYPE = 16
                            AND f.RDB\$FIELD_SUB_TYPE = 0) THEN 'INT64'
                      WHEN (f.RDB\$FIELD_TYPE = 16
                            AND f.RDB\$FIELD_SUB_TYPE = 1) THEN 'NUMERIC'
                      WHEN (f.RDB\$FIELD_TYPE = 16
                            AND f.RDB\$FIELD_SUB_TYPE = 2) THEN 'DECIMAL'
                      WHEN (f.RDB\$FIELD_TYPE = 8
                            AND f.RDB\$FIELD_SUB_TYPE = 0) THEN 'INTEGER'
                      WHEN (f.RDB\$FIELD_TYPE = 8
                            AND f.RDB\$FIELD_SUB_TYPE = 1) THEN 'NUMERIC'
                      WHEN (f.RDB\$FIELD_TYPE = 8
                            AND f.RDB\$FIELD_SUB_TYPE = 2) THEN 'DECIMAL'
                      WHEN (f.RDB\$FIELD_TYPE = 9)  THEN 'QUAD'
                      WHEN (f.RDB\$FIELD_TYPE = 7
                            AND f.RDB\$FIELD_SUB_TYPE = 0) THEN 'SMALLINT'
                      WHEN (f.RDB\$FIELD_TYPE = 7
                            AND f.RDB\$FIELD_SUB_TYPE = 1) THEN 'NUMERIC'
                      WHEN (f.RDB\$FIELD_TYPE = 7
                            AND f.RDB\$FIELD_SUB_TYPE = 2) THEN 'DECIMAL'
                      WHEN (f.RDB\$FIELD_TYPE = 12) THEN 'DATE'
                      WHEN (f.RDB\$FIELD_TYPE = 13) THEN 'TIME'
                      WHEN (f.RDB\$FIELD_TYPE = 35) THEN 'TIMESTAMP'
                      WHEN (f.RDB\$FIELD_TYPE = 37) THEN 'VARCHAR'
                     ELSE 'UNKNOWN'
                    END AS fld_type
                FROM RDB\$RELATION_FIELDS r
                     LEFT JOIN RDB\$FIELDS f
                       ON r.RDB\$FIELD_SOURCE = f.RDB\$FIELD_NAME
                     LEFT JOIN RDB\$COLLATIONS coll
                       ON f.RDB\$COLLATION_ID = coll.RDB\$COLLATION_ID
                     LEFT JOIN RDB\$CHARACTER_SETS cset
                       ON f.RDB\$CHARACTER_SET_ID = cset.RDB\$CHARACTER_SET_ID
                WHERE r.RDB\$RELATION_NAME = '$tabel'
                ORDER BY r.RDB\$FIELD_POSITION;
  );

    $self->{DBH}->{AutoCommit}       = 1;           # disable transactions
    $self->{DBH}->{RaiseError}       = 1;
    $self->{DBH}->{ChopBlanks}       = 1;           # trim CHAR fields
    $self->{DBH}->{FetchHashKeyName} = 'NAME_lc';

    eval {

        # List of lists
        $self->{STH} = $self->{DBH}->prepare($sql);
        $self->{STH}->execute;
        $hash_ref = $self->{STH}->fetchall_hashref('fld_pos');
    };
    if ($@) {
        warn "Transaction aborted because $@";
    }

    my $nr_campuri = scalar keys %{$hash_ref};

    # print "\nNumar campuri = $nr_campuri\n";

    return $hash_ref;
}

sub get_tbl_find_records_sql {

# +-------------------------------------------------------------------------+
# | Description:                                                            |
# | Parameters :                                                            |
# +-------------------------------------------------------------------------+

    my $self   = $_[0];
    my $cols   = $_[1];
    my $table  = $_[2];
    my $where  = $_[3];
    my $ordcol = $_[4];
    my $limit  = $_[5];

    my $sql = qq{ SELECT FIRST $limit $cols
               FROM  $table
                   WHERE $where
           ORDER BY $ordcol;
          };

    return $sql;
}

# --* End file

1;

__END__
