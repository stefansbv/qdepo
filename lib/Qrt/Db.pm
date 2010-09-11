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
# |                                                       p a c k a g e   D b |
# +---------------------------------------------------------------------------+
package Qrt::Db;

use strict;
use warnings;

use Qrt::Db::Connection;

use base qw(Class::Singleton);

=head1 NAME

Qrt::Db - Tpda Qrt database operations module


=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

Connect to a database.

    use Qrt::Db;

    my $db = Qrt::Db->_new_instance();

    my $dbh = $db->dbh;


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

PostgreSQL: Transaction aborted because execute on disconnected handle
at lib/Qrt/Db.pm line 125.

Similar for sqlite: Transaction aborted because DBD::SQLite::db
prepare failed: attempt to prepare on inactive database handle at
lib/Qrt/Output.pm line 238.

Appears at disconnect - reconect.

Please report any bugs or feature requests to the author.


=head1 ACKNOWLEDGEMENTS

Inspired from PerlMonks node [id://609543] by GrandFather.


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1; # End of Qrt::Db
