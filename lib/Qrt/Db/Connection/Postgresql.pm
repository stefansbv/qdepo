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

use warnings;
use strict;

use DBI;


=head1 NAME

Qrt::Db::Connection::Postgresql - Connect to a PostgreSQL database.


=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

    use Qrt::Db::Connection::Postgresql;

    my $db = Qrt::Db::Connection::Postgresql->new();

    $db->conectare($conninfo);


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

=head2 conectare

Connect to database

=cut

sub conectare {
    my ($self, $conf) = @_;

    # $pass = undef; # Uncomment when is no password set

    my $dbname = $conf->{database};
    my $server = $conf->{server};
    my $port   = $conf->{port};
    my $driver = $conf->{driver};
    my $user    = $conf->{user};
    my $pass    = $conf->{pass};

    print "Connect to the $driver server ...\n";
    print " Parameters:\n";
    print "  => Database = $dbname\n";
    print "  => Server   = $server\n";
    print "  => User     = $user\n";

    eval {
        $self->{dbh} = DBI->connect(
            "dbi:Pg:"
                . "dbname="
                . $dbname
                . ";host="
                . $server
                . ";port="
                . $port,
            $user,
            $pass,
            { RaiseError => 1, FetchHashKeyName => 'NAME_lc' }
        );
    };
    ## Date format
    # set: datestyle = 'iso' in postgresql.conf
    ##

    if ($@) {
        warn "$@";
        return;
    }
    else {
        print "\nConnected to database \'$dbname\'.\n";

        return $self->{dbh};
    }
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
