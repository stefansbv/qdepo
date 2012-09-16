package QDepo::Db::Connection;

use strict;
use warnings;

use DBI;
use QDepo::Config;

=head1 NAME

QDepo::Db::Connection - Connect to various databases.

=head1 VERSION

Version 0.38

=cut

our $VERSION = '0.38';

=head1 SYNOPSIS

Connect to a database.

    use QDepo::Db::Connection;

    my $dbh = QDepo::Db::Connection->new();

=head1 METHODS

=head2 new

Constructor method, the first and only time a new instance is created.
All parameters passed to the instance() method are forwarded to this
method. (From I<Class::Singleton> docs).

=cut

sub new {
    my ($class, $model) = @_;

    my $self = bless {}, $class;

    $self->_connect($model);

    return $self;
}

=head2 _connect

Connect method, uses I<QDepo::Config> module for configuration.

Using separate modules for each RDBMS, because ...

=cut

sub _connect {
    my ($self, $model) = @_;

    my $inst = QDepo::Config->instance;
    my $conf = $inst->conninfo;

    $conf->{user} = $inst->user;    # add user and pass to
    $conf->{pass} = $inst->pass;    #  connection options

    my $driver = $conf->{driver};
    my $db;

  SWITCH: for ( $driver ) {
        /^$/ && do warn "No driver name?\n";
        /cb|cubrid/i && do {
            require QDepo::Db::Connection::Cubrid;
            $db = QDepo::Db::Connection::Cubrid->new($model);
            last SWITCH;
        };
        /fb|firebird/i && do {
            require QDepo::Db::Connection::Firebird;
            $db = QDepo::Db::Connection::Firebird->new($model);
            last SWITCH;
        };
        /pg|postgresql/i && do {
            require QDepo::Db::Connection::Postgresql;
            $db = QDepo::Db::Connection::Postgresql->new($model);
            last SWITCH;
        };
        /mysql/i && do {
            require QDepo::Db::Connection::Mysql;
            $db = QDepo::Db::Connection::Mysql->new($model);
            last SWITCH;
        };
        /sqlite/i && do {
            require QDepo::Db::Connection::Sqlite;
            $db = QDepo::Db::Connection::Sqlite->new($model);
            last SWITCH;
        };
        # Default
        warn "Database $driver not supported!\n";
        return;
    }

    $self->{dbc} = $db;
    $self->{dbh} = $db->db_connect($conf);

    my $username = defined $self->{dbh}->{Username}
        ? $self->{dbh}->{Username}
        : 'undef?'
        ;
    print "Connected as $username\n";

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>.

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

1; # End of QDepo::Db::Connection
