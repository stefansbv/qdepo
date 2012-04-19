package TpdaQrt::Db::Connection::Firebird;

use strict;
use warnings;

use Regexp::Common;
use DBI;
use Ouch;
use Try::Tiny;

=head1 NAME

TpdaQrt::Db::Connection::Firebird - Connect to a Firebird database.

=head1 VERSION

Version 0.34

=cut

our $VERSION = '0.34';

=head1 SYNOPSIS

    use TpdaQrt::Db::Connection::Firebird;

    my $db = TpdaQrt::Db::Connection::Firebird->new();

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
    ## Default format: ISO
    $self->{_dbh}->{ib_timestampformat} = '%y-%m-%d %H:%M';
    $self->{_dbh}->{ib_dateformat}      = '%Y-%m-%d';
    $self->{_dbh}->{ib_timeformat}      = '%H:%M';

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

1; # End of TpdaQrt::Db::Connection::Firebird
