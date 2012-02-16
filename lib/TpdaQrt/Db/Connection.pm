package TpdaQrt::Db::Connection;

use strict;
use warnings;

use DBI;
use TpdaQrt::Config;

=head1 NAME

TpdaQrt::Db::Connection - Connect to various databases.

=head1 VERSION

Version 0.28

=cut

our $VERSION = '0.28';

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

    $self->db_connect();

    return $self;
}

=head2 db_connect

Connect method, uses I<TpdaQrt::Config> module for configuration.

Using separate modules for each RDBMS, because ...

=cut

sub db_connect {

    my $self = shift;

    my $inst = TpdaQrt::Config->instance;
    my $conf = $inst->conninfo;

    $conf->{user} = $inst->user;    # add user and pass to
    $conf->{pass} = $inst->pass;    #  connection options

    my $driver = $conf->{driver};
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

    $self->{dbc} = $db;
    $self->{dbh} = $db->db_connect($conf);

    if ( ref $self->{dbh} ) {

        # Some defaults
        $self->{dbh}->{AutoCommit} = 1; # disable transactions
        $self->{dbh}->{RaiseError} = 0; # non fatal, handled
        $self->{dbh}->{PrintError} = 0;
        $self->{dbh}->{ShowErrorStatement} = 1;
        $self->{dbh}->{LongReadLen} = 524288;    # for BLOBs
        $self->{dbh}->{FetchHashKeyName} = 'NAME_lc';
    }

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

Disconnecting an reconnecting with the toolbar button does not work, the
application reports that the connection is established but is not.

Please report any other bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of TpdaQrt::Db::Connection
