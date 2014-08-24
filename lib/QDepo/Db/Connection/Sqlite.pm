package QDepo::Db::Connection::Sqlite;

# ABSTRACT: Connect to a SQLite database

use strict;
use warnings;

use DBI;
use Try::Tiny;
use Regexp::Common;

use QDepo::Exceptions;

=head1 NAME

QDepo::Db::Connection::Sqlite - Connect to a PostgreSQL database.

=head1 VERSION

Version 0.39

=cut

our $VERSION = '0.39';

=head1 SYNOPSIS

    use QDepo::Db::Connection::Sqlite;

    my $db = QDepo::Db::Connection::Sqlite->new();

    $db->db_connect($connection);

=head1 METHODS

=head2 new

Constructor

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
    my ( $self, $conf ) = @_;

    my ($dbname, $driver) = @{$conf}{qw(dbname driver)};

    unless (-f $dbname) {
        print "DB: $dbname not found\n";
        my $errorstr = "The $dbname database does not exists! Aborting.";
        Exception::Db::Connect->throw(
            logmsg  => $errorstr,
            usermsg => $errorstr,
        );
    }

    my $dsn = qq{dbi:SQLite:dbname=$dbname};

    $self->{_dbh} = DBI->connect(
        $dsn, undef, undef,
        {   FetchHashKeyName => 'NAME_lc',
            AutoCommit       => 1,
            RaiseError       => 1,
            PrintError       => 0,
            LongReadLen      => 524288,
            HandleError      => sub { $self->handle_error() },
            sqlite_unicode   => 1,
        }
    );

    return $self->{_dbh};
}

=head2 handle_error

Log errors.

=cut

sub handle_error {
    my $self = shift;

    if ( defined $self->{_dbh} and $self->{_dbh}->isa('DBI::db') ) {
        my $errorstr = $self->{_dbh}->errstr;
        Exception::Db::SQL->throw(
            logmsg  => $errorstr,
            usermsg => $self->parse_error($errorstr),
        );
    }
    else {
        my $errorstr = DBI->errstr;
        Exception::Db::Connect->throw(
            logmsg  => $errorstr,
            usermsg => $self->parse_error($errorstr),
        );
    }

    return;
}

=head2 parse_error

Parse a database error message, and translate it for the user.

=cut

sub parse_error {
    my ($self, $si) = @_;

    my $log = get_logger();

    $log->error("EE: $si");

    my $message_type =
         $si eq q{}                                        ? "nomessage"
       : $si =~ m/prepare failed: no such table: (\w+)/smi ? "relnotfound:$1"
       : $si =~ m/prepare failed: near ($RE{quoted}):/smi  ? "notsuported:$1"
       : $si =~ m/not connected/smi                        ? "notconn"
       : $si =~ m/(.*) may not be NULL/smi                 ? "errnull:$1"
       :                                                     "unknown";

    # Analize and translate

    my ( $type, $name ) = split /:/, $message_type, 2;
    $name = $name ? $name : '';

    my $translations = {
        nomessage   => "weird#Error without message!",
        notsuported => "fatal#Syntax not supported: $name!",
        relnotfound => "fatal#Relation $name not found",
        unknown     => "fatal#Database error",
        notconn     => "error#Not connected",
        errnull     => "error#$name may not be NULL",
    };

    my $message;
    if (exists $translations->{$type} ) {
        $message = $translations->{$type}
    }
    else {
        $log->error('EE: Translation error for: $si!');
    }

    return $message;
}

=head2 table_info_short

Table info 'short'.

=cut

sub table_info_short {
    my ( $self, $table ) = @_;

    my $h_ref = $self->{_dbh}
        ->selectall_hashref( "PRAGMA table_info($table)", 'cid' );

    my $flds_ref = {};
    foreach my $cid ( sort keys %{$h_ref} ) {
        my $name       = $h_ref->{$cid}{name};
        my $dflt_value = $h_ref->{$cid}{dflt_value};
        my $notnull    = $h_ref->{$cid}{notnull};
        # my $pk       = $h_ref->{$cid}{pk}; is part of PK ? index : undef
        my $data_type  = $h_ref->{$cid}{type};

        # Parse type;
        my ($type, $precision, $scale);
        if ( $data_type =~ m{
               (\w+)                           # data type
               (?:\((\d+)(?:,(\d+))?\))?       # optional (precision[,scale])
             }x
         ) {
            $type      = $1;
            $precision = $2;
            $scale     = $3;
        }

        my $info = {
            pos         => $cid,
            name        => $name,
            type        => $type,
            is_nullable => $notnull ? 0 : 1,
            defa        => $dflt_value,
            length      => $precision,
            prec        => $precision,
            scale       => $scale,
        };
        $flds_ref->{$name} = $info;
    }

    return $flds_ref;
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

1; # End of QDepo::Db::Connection::Sqlite
