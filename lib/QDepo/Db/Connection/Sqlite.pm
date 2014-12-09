package QDepo::Db::Connection::Sqlite;

# ABSTRACT: Connect to a SQLite database

use strict;
use warnings;

use DBI;
use Try::Tiny;
use Regexp::Common;

use QDepo::Exceptions;

sub new {
    my ($class, $p) = @_;
    my $model = delete $p->{model}
        or die 'Missing "model" parameter to new()';
    my $self = {};
    $self->{model} = $model;
    bless $self, $class;
    return $self;
}

sub db_connect {
    my ( $self, $args ) = @_;

    my $dbpath = $args->dbname;

    unless (-f $dbpath) {
        print "DB: $dbpath not found\n";
        Exception::Db::Connect->throw(
            logmsg  => "The $dbpath database does not exists!",
            usermsg => 'Not connected',
        );
    }

    my $dsn = qq{dbi:SQLite:dbname=$dbpath};

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

sub parse_error {
    my ($self, $err) = @_;

    my $message_type =
         $err eq q{}                                        ? "nomessage"
       : $err =~ m/prepare failed: no such table: (\w+)/smi ? "relnotfound:$1"
       : $err =~ m/prepare failed: near ($RE{quoted}):/smi  ? "notsuported:$1"
       : $err =~ m/not connected/smi                        ? "notconn"
       : $err =~ m/(.*) may not be NULL/smi                 ? "errnull:$1"
       :                                                     "unknown";

    # Analize and translate

    my ( $type, $name ) = split /:/, $message_type, 2;
    $name = $name ? $name : '';

    my $translations = {
        nomessage   => "Error without message!",
        notsuported => "Syntax not supported: $name!",
        relnotfound => "Relation $name not found",
        unknown     => "Database error",
        notconn     => "Not connected",
        errnull     => "$name may not be NULL",
    };

    my $message;
    if ( exists $translations->{$type} ) {
        $message = $translations->{$type};
    }
    else {
        $message = $err;
        print "EE: Translation error for: $message!\n";
    }

    return $message;
}

sub table_exists {
    my ( $self, $table ) = @_;

    die "'table_exists' requires a 'table' parameter!" unless $table;

    my $sql = qq( SELECT COUNT(name)
                FROM sqlite_master
                WHERE type = 'table'
                    AND name = '$table';
    );

    my $val_ret;
    try {
        ($val_ret) = $self->{_dbh}->selectrow_array($sql);
    }
    catch {
        Exception::Db::Connect->throw(
            logmsg  => "error#Transaction aborted because $_",
            usermsg => 'error#Database error',
        );
    };

    return $val_ret;
}

sub table_info_short {
    my ( $self, $table ) = @_;

    die "'table_info_short' requires a 'table' parameter!" unless $table;

    my $h_ref;
    try {
        $h_ref = $self->{_dbh}
            ->selectall_hashref( "PRAGMA table_info($table)", 'cid' );
    }
    catch {
        Exception::Db::Connect->throw(
            logmsg  => "error#Transaction aborted because $_",
            usermsg => 'error#Database error',
        );
    };

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

1;

=head2 parse_error

Parse a database error message, and translate it for the user.

=cut
