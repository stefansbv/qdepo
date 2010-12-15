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
# |                                       p a c k a g e   P o s t g r e s q l |
# +---------------------------------------------------------------------------+
package Qrt::Db::Connection::Postgresql;

use strict;
use warnings;

use DBI;
use Try::Tiny;

=head1 NAME

Tpda3::Db::Connection::Postgresql - Connect to a PostgreSQL database.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use Tpda3::Db::Connection::Postgresql;

    my $db = Tpda3::Db::Connection::Postgresql->new();

    $db->db_connect($connection);

=head1 METHODS

=head2 new

Constructor

=cut

sub new {
    my $class = shift;

    my $self = {};

    bless $self, $class;

    return $self;
}

=head2 db_connect

Connect to database

=cut

sub db_connect {
    my ($self, $conf) = @_;

    print "Connecting to the $conf->{driver} server\n";
    print "Parameters:\n";
    print "  => Database = $conf->{dbname}\n";
    print "  => Host   = $conf->{host}\n";
    print "  => User     = $conf->{user}\n";

    try {
        $self->{_dbh} = DBI->connect(
            "dbi:Pg:"
              . "dbname="
              . $conf->{dbname}
              . ";host="
              . $conf->{host}
              . ";port="
              . $conf->{port},
            $conf->{user}, $conf->{pass},
        );
    }
    catch {
        print "Transaction aborted: $_"
            or print STDERR "$_\n";

          # exit 1;
    };

    ## Date format
    # set: datestyle = 'iso' in postgresql.conf
    ##
    $self->{_dbh}{pg_enable_utf8} = 1;

    print "Connected to database $conf->{dbname}\n";

    return $self->{_dbh};
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

1; # End of Qrt::Db::Connection::Postgresql
