# +---------------------------------------------------------------------------+
# | Name     : tpda-qrt (TPDA - Query Repository Tool)                        |
# | Author   : Stefan Suciu  [ stefansbv 'at' users . sourceforge . net ]     |
# | Website  : http://tpda-qrt.sourceforge.net                                |
# |                                                                           |
# | Copyright (C) 2004-2010  Stefan Suciu                                     |
# |                                                                           |
# | This program is free software; you can redistribute it and/or modify      |
# | it under the terms of the GNU General Public License as published by      |
# | the Free Software Foundation; either version 2 of the License, or         |
# | (at your option) any later version.                                       |
# |                                                                           |
# | This program is distributed in the hope that it will be useful,           |
# | but WITHOUT ANY WARRANTY; without even the implied warranty of            |
# | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             |
# | GNU General Public License for more details.                              |
# |                                                                           |
# | You should have received a copy of the GNU General Public License         |
# | along with this program; if not, write to the Free Software               |
# | Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA |
# +---------------------------------------------------------------------------+
# |
# +---------------------------------------------------------------------------+
# |                                       p a c k a g e   C o n n e c t i o n |
# +---------------------------------------------------------------------------+
package Qrt::Db::Connection;

use strict;
use warnings;

use Qrt::Config;

=head1 NAME

Qrt::Db::Connection - Connect to different databases.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Connect to a database.

    use Qrt::Db::Connection;

    my $dbh = Qrt::Db::Connection->new();


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

Connect method, uses I<Qrt::Config> module for configuration.

=cut

sub db_connect {

    my $self = shift;

    my $conninfo = Qrt::Config->instance->conninfo;

    my $driver = $conninfo->{driver};
    my $db;

  SWITCH: for ( $driver ) {
        /^$/ && do warn "No driver name?\n";
        /firebird/i && do {
            require Qrt::Db::Connection::Firebird;
            $db = Qrt::Db::Connection::Firebird->new();
            last SWITCH;
        };
        /postgresql/i && do {
            require Qrt::Db::Connection::Postgresql;
            $db = Qrt::Db::Connection::Postgresql->new();
            last SWITCH;
        };
        /mysql/i && do {
            require Qrt::Db::Connection::Mysql;
            $db = Qrt::Db::Connection::MySql->new();
            last SWITCH;
        };
        /sqlite/i && do {
            require Qrt::Db::Connection::Sqlite;
            $db = Qrt::Db::Connection::Sqlite->new();
            last SWITCH;
        };
        # Default
        warn "Database $driver not supported!\n";
        return;
    }

    my $dbh = $db->conectare($conninfo);

    if (ref $self->{_dbh}) {

        # Some defaults
        $self->{_dbh}->{AutoCommit}  = 1;          # disable transactions
        $self->{_dbh}->{RaiseError}  = 1;
        $self->{_dbh}->{LongReadLen} = 512 * 1024; # for Firebird with BLOBs
    }

    return $dbh;
}


=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>


=head1 BUGS

None known.

Please report any bugs or feature requests to the author.


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1; # End of Qrt::Db::Connection
