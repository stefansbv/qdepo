package Pdqm::Db::Connection;

use strict;
use warnings;

use Data::Dumper;
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
