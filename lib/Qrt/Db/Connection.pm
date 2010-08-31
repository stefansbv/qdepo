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
    my $cnf = Qrt::Config->new();
    my $conninfo = $cnf->cfg->connection;

    my $dbms = $conninfo->{dbms};

    # Select DBMS; tryed with 'use if', but not shure is better
    # 'use' would do but don't want to load modules if not necessary
    if ( $dbms =~ /Firebird/i ) {
        require Qrt::Db::Connection::Firebird;
    }
    elsif ( $dbms =~ /Postgresql/i ) {
        require Qrt::Db::Connection::Postgresql;
    }
    elsif ( $dbms =~ /MySQL/i ) {
        require Qrt::Db::Connection::MySql;
    }
    else {
        die "Database $dbms not supported!\n";
    }

    # Connect to Database, Select RDBMS

    if ( $dbms =~ /Firebird/i ) {
        $self->{conn} = Qrt::Db::Connection::Firebird->new();
    }
    elsif ( $dbms =~ /Postgresql/i ) {
        $self->{conn} = Qrt::Db::Connection::Postgresql->new();
    }
    elsif ( $dbms =~ /mysql/i ) {
        $self->{conn} = Qrt::Db::Connection::MySql->new();
    }
    else {
        die "Database $dbms not supported!\n";
    }

    $self->{dbh} = $self->{conn}->conectare(
        $conninfo,
        $user,
        $pass,
    );

    return $self->{dbh};
}

1;
