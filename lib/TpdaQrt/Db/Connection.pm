package TpdaQrt::Db::Connection;

use strict;
use warnings;

use TpdaQrt::Config;

=head1 NAME

TpdaQrt::Db::Connection - Connect to various databases.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Connect to a database.

    use TpdaQrt::Db::Connection;

    my $dbh = TpdaQrt::Db::Connection->new();

=head1 METHODS

=head2 new

Constructor method, the first and only time a new instance is created.
All parameters passed to the instance() method are forwarded to this
method. (From I<Class::Singleton> docs).

=cut

sub new {
    my $class = shift;

    my $self = bless {}, $class;

    $self->{dbh} = $self->db_connect();

    return $self->{dbh};
}

=head2 db_connect

Connect method, uses I<TpdaQrt::Config> module for configuration.

=cut

sub db_connect {

    my $self = shift;

    my $conninfo = TpdaQrt::Config->instance->conninfo;

    my $driver = $conninfo->{driver};
    my $db;

  SWITCH: for ( $driver ) {
        /^$/ && do warn "No driver name?\n";
        /firebird/i && do {
            require TpdaQrt::Db::Connection::Firebird;
            $db = TpdaQrt::Db::Connection::Firebird->new();
            last SWITCH;
        };
        /postgresql/i && do {
            require TpdaQrt::Db::Connection::Postgresql;
            $db = TpdaQrt::Db::Connection::Postgresql->new();
            last SWITCH;
        };
        /mysql/i && do {
            require TpdaQrt::Db::Connection::Mysql;
            $db = TpdaQrt::Db::Connection::Mysql->new();
            last SWITCH;
        };
        /sqlite/i && do {
            require TpdaQrt::Db::Connection::Sqlite;
            $db = TpdaQrt::Db::Connection::Sqlite->new();
            last SWITCH;
        };
        # Default
        warn "Database $driver not supported!\n";
        return;
    }

    my $dbh = $db->db_connect($conninfo);

    if (ref $dbh) {

        # Some defaults
        $dbh->{AutoCommit}  = 1;          # disable transactions
        $dbh->{RaiseError}  = 0;
        $dbh->{PrintError}  = 0;
        $dbh->{LongReadLen} = 512 * 1024; # for BLOBs
        $dbh->{FetchHashKeyName} = 'NAME_lc';
    }

    return $dbh;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

Disconnecting an reconnecting with the toolbar button does not work, the
application reports that the connection is established but is not.

Please report any other bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of TpdaQrt::Db::Connection
