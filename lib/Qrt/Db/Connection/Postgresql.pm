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

use Carp;
use DBI;

# use Postgresql >= 8.3.5 !!! :)

our $VERSION = 0.30;

sub new {

    my $class = shift;

    my $self = {};

    bless $self, $class;

    return $self;
}

sub conectare {

    # +-----------------------------------------------------------------------+
    # | Descriere: Connect to the database                                    |
    # +-----------------------------------------------------------------------+

    my ($self, $conf, $user, $pass) = @_;

    # $pass = undef; # Uncomment when is no password set

    my $dbname = $conf->{database};
    my $server = $conf->{server};
    my $port   = $conf->{port};
    my $driver = $conf->{driver};

    print "Connect to the $driver server ...\n";
    print " Parameters:\n";
    print "  => Database = $dbname\n";
    print "  => Server   = $server\n";
    print "  => Port     = $port\n";
    print "  => User     = $user\n";

    eval {
        $self->{_dbh} = DBI->connect(
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
        return $self->{_dbh};
    }
}

# --* End file

1;

__END__
