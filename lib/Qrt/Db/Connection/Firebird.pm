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
# |                                           p a c k a g e   F i r e b i r d |
# +---------------------------------------------------------------------------+
package Qrt::Db::Connection::Firebird;

use strict;
use warnings;
use Carp;

use DBI;

our $VERSION = '0.10';

sub new {

# +---------------------------------------------------------------------------+
# | Descriere: Rutina de instantiere                                          |
# | Parametri: class, alias                                                   |
# +---------------------------------------------------------------------------+

    my $class = shift;

    my $self = {};

    bless $self, $class;

    return $self;
}

sub conectare {

    # +-----------------------------------------------------------------------+
    # | Descriere: Connect to the database                                    |
    # +-----------------------------------------------------------------------+

    my ( $self, $conf ) = @_;

    my $dbname  = $conf->{database};
    my $server  = $conf->{server};
    my $port    = $conf->{port};
    my $driver  = $conf->{driver};
    my $user    = $conf->{user};
    my $pass    = $conf->{pass};

    print "Connect to the $driver server ...\n";
    print " Parameters:\n";
    print "  => Database = $dbname\n";
    print "  => Server   = $server\n";
    print "  => User     = $user\n";

    eval {
        $self->{dbh} = DBI->connect(
            "DBI:InterBase:"
                . "dbname="
                . $dbname
                . ";host="
                . $server
                . ";port="
                . $port
                . ";ib_dialect=3",
            $user,
            $pass,
            { RaiseError => 1, FetchHashKeyName => 'NAME_lc' }
        );
    };

    if ($@) {
        warn "Transaction aborted because $@";
        print "Not connected!\n";
    }
    else {
        ## Default format: ISO
        $self->{dbh}->{ib_timestampformat} = '%y-%m-%d %H:%M';
        $self->{dbh}->{ib_dateformat}      = '%Y-%m-%d';
        $self->{dbh}->{ib_timeformat}      = '%H:%M';
        ## Format: German
        # $self->{dbh}->{ib_timestampformat} = '%d.%m.%Y %H:%M';
        # $self->{dbh}->{ib_dateformat}      = '%d.%m.%Y';
        # $self->{dbh}->{ib_timeformat}      = '%H:%M';

        print "\nConnected to database \'$dbname\'.\n";

        return $self->{dbh};
    }
}

# --* End file

1;

__END__
