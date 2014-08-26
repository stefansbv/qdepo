package QDepo::Db::Connection::Mysql;

# ABSTRACT: Connect to a MySQL database

use strict;
use warnings;

use DBI;
use Try::Tiny;
use Regexp::Common;

use QDepo::Exceptions;

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

Connect to the database.

=cut

sub db_connect {
    my ($self, $conf) = @_;

    my ( $dbname, $host, $port ) = @{$conf}{qw(dbname host port)};
    my ( $driver, $user, $pass ) = @{$conf}{qw(driver user pass)};

    my $dsn = qq{dbi:mysql:database=$dbname;host=$host;port=$port};

    $self->{_dbh} = DBI->connect(
        $dsn, $user, $pass, {
            FetchHashKeyName   => 'NAME_lc',
            LongReadLen        => 524288,
            AutoCommit         => 1,
            RaiseError         => 0,
            PrintError         => 0,
            HandleError        => sub { $self->handle_error() },
        }
    );

    return $self->{_dbh};
}

=head2 handle_error

Handle errors.  Makes a distinction between a connection error and
other errors.

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

=head2 parse_db_error

Parse a database error message, and translate it for the user.

=cut

sub parse_db_error {
    my ($self, $mi) = @_;

    #print "\nMY: $mi\n\n";

    my $message_type
        = $mi eq q{}                                         ? "nomessage"
       : $mi =~ m/Access denied for user ($RE{quoted})/smi   ? "password:$1"
       : $mi =~ m/Can't connect to local MySQL server/smi    ? "nolocalconn"
       : $mi =~ m/Can't connect to MySQL server on ($RE{quoted})/smi ? "nethost:$1"
       :                                                       "unknown"
       ;

    # Analize and translate

    my ( $type, $name ) = split /:/, $message_type, 2;
    $name = $name ? $name : '';

    my $translations = {
        nomessage   => "weird#Error without message!",
        dbnotfound  => "fatal#Database $name not found!",
        password    => "info#Authentication failed for $name",
        username    => "info#User name $name not found!",
        network     => "fatal#Network problem",
        nethost     => "fatal#Network problem: host $name",
        nolocalconn => "fatal#Connection problem to local MySQL",
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

1;
