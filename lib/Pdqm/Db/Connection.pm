# +---------------------------------------------------------------------------+
# | Name     : Pdqm (Perl Database Query Manager)                             |
# | Author   : Stefan Suciu  [ stefansbv 'at' users . sourceforge . net ]     |
# | Website  :                                                                |
# |                                                                           |
# | Copyright (C) 2010  Stefan Suciu                                          |
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
package Pdqm::Db::Connection;

use strict;
use warnings;

use Pdqm::Config;

our $VERSION = 0.03;

sub new {

    my ($class, $args) = @_;

    my $self = bless( {}, $class);

    $self->{args} = $args;

    return $self;
}

sub db_connect {

# +---------------------------------------------------------------------------+
# | Descriere: Conect to database                                             |
# | Parametri: class, alias                                                   |
# +---------------------------------------------------------------------------+

    my ($self, $user, $pass) = @_;

    # Connection information from config ??? needs rewrite !!!
    my $cnf = Pdqm::Config->new();
    my $conninfo = $cnf->cfg->conninfo;

    my $rdbms = $conninfo->{DBMS};

    # Select RDBMS; tryed with 'use if', but not shure is better
    # 'use' would do but don't want to load modules if not necessary
    if ( $rdbms =~ /Firebird/i ) {
        require Pdqm::Db::Connection::Firebird;
    }
    elsif ( $rdbms =~ /Postgresql/i ) {
        require Pdqm::Db::Connection::Postgresql;
    }
    elsif ( $rdbms =~ /mysql/i ) {
        require Pdqm::Db::Connection::MySql;
    }
    else {
        die "Database $rdbms not supported!\n";
    }

    # Connect to Database, Select RDBMS

    if ( $rdbms =~ /Firebird/i ) {
        $self->{conn} = Pdqm::Db::Connection::Firebird->new();
    }
    elsif ( $rdbms =~ /Postgresql/i ) {
        $self->{conn} = Pdqm::Db::Connection::Postgresql->new();
    }
    elsif ( $rdbms =~ /mysql/i ) {
        $self->{conn} = Pdqm::Db::Connection::MySql->new();
    }
    else {
        die "Database $rdbms not supported!\n";
    }

    $self->{dbh} = $self->{conn}->conectare(
        $conninfo,
        $user,
        $pass,
    );

    return $self->{dbh};
}

1;
