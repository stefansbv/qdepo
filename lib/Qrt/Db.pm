package Qrt::Db;

use strict;
use warnings;
use Carp;

use Qrt::Db::Connection;

use base qw(Class::Singleton);

=head1 NAME

Qrt::Db - Tpda Qrt database access module

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Connect to a database.

    use Qrt::Db;

    my $dbh = Qrt::Db->instance($args);

    ...

=head1 METHODS

=head2 _new_instance

Constructor method, the first and only time a new instance is created.
All parameters passed to the instance() method are forwarded to this
method. (From I<Class::Singleton> docs).

=cut

sub _new_instance {
    my ($class, $args) = @_;

    my $self = bless {}, $class;

    my $conn = Qrt::Db::Connection->new( $args );
    $self->{_dbh} = $conn->db_connect(
        $args->{user},
        $args->{pass},
    );

    if (ref $self->{_dbh}) {

        # Some defaults
        $self->{_dbh}->{AutoCommit}  = 1;          # disable transactions
        $self->{_dbh}->{RaiseError}  = 1;
        $self->{_dbh}->{LongReadLen} = 512 * 1024; # for Firebird with BLOBs
    }

    return $self;
}

=head2 function2

Return database handle.

=cut

sub dbh {
    my $self = shift;

    return $self->{_dbh};
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

1; # End of Qrt::Db
