package Qrt::Db::Connection;

use strict;
use warnings;

use Qrt::Config;

=head1 NAME

Qrt::Db::Connection - The great new Qrt::Db::Connection!

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

Constructor method.

The arguments are user and password.

=cut

sub new {

    my ($class, $args) = @_;

    my $self = bless( {}, $class);

    $self->{args} = $args;

    return $self;
}

=head2 # db_connect

Connect method, uses I<Qrt::Config> module for configuration.

=cut

=for TODO

Try DBIx::AnyDBD

=cut

sub db_connect {

    my ($self, $user, $pass) = @_;

    my $cfg = Qrt::Config->instance();
    my $conninfo = $cfg->conninfo;

    my $driver = $conninfo->{driver};

    # Select DBMS; tryed with 'use if', but not shure is better
    # 'use' would do but don't want to load modules if not necessary
    if ( $driver =~ /Firebird/i ) {
        require Qrt::Db::Connection::Firebird;
    }
    elsif ( $driver =~ /Postgresql/i ) {
        require Qrt::Db::Connection::Postgresql;
    }
    # elsif ( $driver =~ /MySQL/i ) {
    #     require Qrt::Db::Connection::MySql;
    # }
    else {
        die "Database $driver not supported!\n";
    }

    # Connect to Database, Select RDBMS

    if ( $driver =~ /Firebird/i ) {
        $self->{conn} = Qrt::Db::Connection::Firebird->new();
    }
    elsif ( $driver =~ /Postgresql/i ) {
        $self->{conn} = Qrt::Db::Connection::Postgresql->new();
    }
    # elsif ( $driver =~ /mysql/i ) {
    #     $self->{conn} = Qrt::Db::Connection::MySql->new();
    # }
    else {
        die "Database $driver not supported!\n";
    }

    $self->{dbh} = $self->{conn}->conectare(
        $conninfo,
        $user,
        $pass,
    );

    return $self->{dbh};
}



=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>


=head1 BUGS

None known.

Please report any bugs or feature requests to the author.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Qrt::Db


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Qrt::Db::Connection
