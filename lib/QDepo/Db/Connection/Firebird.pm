package QDepo::Db::Connection::Firebird;

use strict;
use warnings;

use Regexp::Common;
use DBI;
use Ouch;
use Try::Tiny;

=head1 NAME

QDepo::Db::Connection::Firebird - Connect to a Firebird database.

=head1 VERSION

Version 0.39

=cut

our $VERSION = '0.39';

=head1 SYNOPSIS

    use QDepo::Db::Connection::Firebird;

    my $db = QDepo::Db::Connection::Firebird->new();

    $db->db_connect($connection);

=head1 METHODS

=head2 new

Constructor.

=cut

sub new {
    my ($class, $model) = @_;

    my $self = {};

    $self->{model} = $model;

    bless $self, $class;

    return $self;
}

=head2 db_connect

Connect to database

=cut

sub db_connect {
    my ($self, $conf) = @_;

    try {
        $self->{_dbh} = DBI->connect(
            "dbi:Firebird:"
                . "dbname="
                . $conf->{dbname}
                . ";host="
                . $conf->{host}
                . ";port="
                . $conf->{port}
                . ";ib_dialect=3"
                . ";ib_charset=UTF8",
            $conf->{user},
            $conf->{pass},
            {   FetchHashKeyName => 'NAME_lc',
                AutoCommit       => 1,
                RaiseError       => 1,
                PrintError       => 0,
                LongReadLen      => 524288,
            }
        );
    }
    catch {
        my $user_message = $self->parse_db_error($_);
        if ( $self->{model} and $self->{model}->can('exception_log') ) {
             $self->{model}->exception_log($user_message);
        }
        else {
            ouch 'ConnError','Connection failed!';
        }
    };

    ## Date format
    ## Default format: ISO8601
    $self->{_dbh}->{ib_timestampformat} = '%Y-%m-%dT%H:%M';
    $self->{_dbh}->{ib_dateformat}      = '%Y-%m-%dT';
    $self->{_dbh}->{ib_timeformat}      = 'T%H:%M';

    $self->{_dbh}{ib_enable_utf8} = 1;

    return $self->{_dbh};
}

=head2 parse_db_error

Parse a database error message, and translate it for the user.

RDBMS specific (and maybe version specific?).

=cut

sub parse_db_error {
    my ($self, $fb) = @_;

    print "\nFB: $fb\n\n";

    my $message_type =
         $fb eq q{}                                          ? "nomessage"
       : $fb =~ m/operation for file ($RE{quoted})/smi       ? "dbnotfound:$1"
       : $fb =~ m/user name and password/smi                 ? "userpass"
       : $fb =~ m/no route to host/smi                       ? "network"
       : $fb =~ m/network request to host ($RE{quoted})/smi  ? "nethost:$1"
       : $fb =~ m/install_driver($RE{balanced}{-parens=>'()'})/smi ? "driver:$1"
       :                                                       "unknown";

    # Analize and translate

    my ( $type, $name ) = split /:/, $message_type, 2;
    $name = $name ? $name : '';

    my $translations = {
        nomessage   => "weird#Error without message",
        driver      => "fatal#Database driver $name not found",
        dbnotfound  => "fatal#Database $name not found",
        userpass    => "info#Authentication failed, password?",
        nethost     => "fatal#Network problem: host $name",
        network     => "fatal#Network problem",
        unknown     => "fatal#Database error",
    };

    my $message;
    if (exists $translations->{$type} ) {
        $message = $translations->{$type};
    }
    else {
        print "EE: Translation error!\n";
    }

    return $message;
}

=head2 table_info_short

Table info 'short'.  The 'table_info' method from the Firebird driver
doesn't seem to be reliable.

=cut

sub table_info_short {
    my ( $self, $table ) = @_;

    $table = uc $table;

    my $sql = qq(SELECT RDB\$FIELD_POSITION AS pos
                    , LOWER(r.RDB\$FIELD_NAME) AS name
                    , r.RDB\$DEFAULT_VALUE AS defa
                    , r.RDB\$NULL_FLAG AS is_nullable
                    , f.RDB\$FIELD_LENGTH AS length
                    , f.RDB\$FIELD_PRECISION AS prec
                    , CASE
                        WHEN f.RDB\$FIELD_SCALE > 0 THEN (f.RDB\$FIELD_SCALE)
                        WHEN f.RDB\$FIELD_SCALE < 0 THEN (f.RDB\$FIELD_SCALE * -1)
                        ELSE 0
                      END AS scale
                    , CASE f.RDB\$FIELD_TYPE
                        WHEN 261 THEN 'blob'
                        WHEN 14  THEN 'char'
                        WHEN 40  THEN 'cstring'
                        WHEN 11  THEN 'd_float'
                        WHEN 27  THEN 'double'
                        WHEN 10  THEN 'float'
                        WHEN 16  THEN
                          CASE f.RDB\$FIELD_SCALE
                            WHEN 0 THEN 'int64'
                            ELSE 'numeric'
                          END
                        WHEN 8   THEN
                          CASE f.RDB\$FIELD_SCALE
                            WHEN 0 THEN 'integer'
                            ELSE 'numeric'
                          END
                        WHEN 9   THEN 'quad'
                        WHEN 7   THEN
                          CASE f.RDB\$FIELD_SCALE
                            WHEN 0 THEN 'smallint'
                            ELSE 'numeric'
                          END
                        WHEN 12  THEN 'date'
                        WHEN 13  THEN 'time'
                        WHEN 35  THEN 'timestamp'
                        WHEN 37  THEN 'varchar'
                      ELSE 'UNKNOWN'
                      END AS type
                    FROM RDB\$RELATION_FIELDS r
                       LEFT JOIN RDB\$FIELDS f
                            ON r.RDB\$FIELD_SOURCE = f.RDB\$FIELD_NAME
                    WHERE r.RDB\$RELATION_NAME = '$table'
                    ORDER BY r.RDB\$FIELD_POSITION;
    );

    $self->{_dbh}{ChopBlanks} = 1;    # trim CHAR fields

    my $flds_ref;
    try {
        my $sth = $self->{_dbh}->prepare($sql);
        $sth->execute;
        $flds_ref = $sth->fetchall_hashref('name');
    }
    catch {
        $self->{model}->exception_log("Transaction aborted because $_");
    };

    return $flds_ref;
}

=head2 table_keys

Get the primary key field name of the table.

=cut

sub table_keys {
    my ( $self, $table, $foreign ) = @_;

    my $type = 'PRIMARY KEY';
    $type = 'FOREIGN KEY' if $foreign;

    $table = uc $table;

    my $sql = qq( SELECT LOWER(s.RDB\$FIELD_NAME) AS column_name
                     FROM RDB\$INDEX_SEGMENTS s
                        LEFT JOIN RDB\$INDICES i
                          ON i.RDB\$INDEX_NAME = s.RDB\$INDEX_NAME
                        LEFT JOIN RDB\$RELATION_CONSTRAINTS rc
                          ON rc.RDB\$INDEX_NAME = s.RDB\$INDEX_NAME
                        LEFT JOIN RDB\$REF_CONSTRAINTS refc
                          ON rc.RDB\$CONSTRAINT_NAME = refc.RDB\$CONSTRAINT_NAME
                        LEFT JOIN RDB\$RELATION_CONSTRAINTS rc2
                          ON rc2.RDB\$CONSTRAINT_NAME = refc.RDB\$CONST_NAME_UQ
                        LEFT JOIN RDB\$INDICES i2
                          ON i2.RDB\$INDEX_NAME = rc2.RDB\$INDEX_NAME
                        LEFT JOIN RDB\$INDEX_SEGMENTS s2
                          ON i2.RDB\$INDEX_NAME = s2.RDB\$INDEX_NAME
                      WHERE i.RDB\$RELATION_NAME = '$table'
                        AND rc.RDB\$CONSTRAINT_TYPE = '$type'
    );

    $self->{_dbh}{AutoCommit} = 1;    # disable transactions
    $self->{_dbh}{RaiseError} = 0;

    my $pkf;
    try {
        $pkf = $self->{_dbh}->selectcol_arrayref($sql);
    }
    catch {
        $self->{model}->exception_log("Transaction aborted because $_");
    };

    return $pkf;
}

=head2 table_exists

Check if table exists in the database.

=cut

sub table_exists {
    my ( $self, $table ) = @_;

    $table = uc $table;

    my $sql = qq(SELECT COUNT(RDB\$RELATION_NAME)
                     FROM RDB\$RELATIONS
                     WHERE RDB\$SYSTEM_FLAG=0
                         AND RDB\$VIEW_BLR IS NULL
                         AND RDB\$RELATION_NAME = '$table';
    );

    my $val_ret;
    try {
        ($val_ret) = $self->{_dbh}->selectrow_array($sql);
    }
    catch {
        $self->{model}->exception_log("Transaction aborted because $_");
    };

    return $val_ret;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>.

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of QDepo::Db::Connection::Firebird
