package Qrt::Db;

use strict;
use warnings;

use Qrt::Db::Connection;

use base qw(Class::Singleton);

=head1 NAME

Qrt::Db - Tpda Qrt database operations module

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

Connect to a database.

    use Qrt::Db;

    my $dbh = Qrt::Db->new($args);

=head1 METHODS

=head2 new

Constructor method.

=cut

sub _new_instance {
    my $class = shift;

    my $dbh = Qrt::Db::Connection->new;

    return bless { dbh => $dbh }, $class;
}

=head2 dbh

Return database handle.

=cut

sub dbh {
    my $self = shift;

    return $self->{dbh};
}

sub DESTROY {
    my $self = shift;

    $self->{dbh}->disconnect () if defined $self->{dbh};
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
