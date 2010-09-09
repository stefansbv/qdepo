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

=head2 _new_instance

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

=head2 # db_connect

Connect method, uses I<Qrt::Config> module for configuration.

=cut

=for TODO

Try DBIx::AnyDBD

=cut

sub db_connect {

    my $self = shift;

    my $conninfo = Qrt::Config->instance->conninfo;

    my $driver = $conninfo->{driver};

    # Select DBMS; tried with 'use if', but not shure is better
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

    my $conn;
    if ( $driver =~ /Firebird/i ) {
        $conn = Qrt::Db::Connection::Firebird->new();
    }
    elsif ( $driver =~ /Postgresql/i ) {
        $conn = Qrt::Db::Connection::Postgresql->new();
    }
    # elsif ( $driver =~ /mysql/i ) {
    #     $conn = Qrt::Db::Connection::MySql->new();
    # }
    else {
        die "Database $driver not supported!\n";
    }

    my $dbh = $conn->conectare($conninfo);

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
