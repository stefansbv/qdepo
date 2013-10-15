package QDepo::Db;

use strict;
use warnings;

# use Log::Log4perl qw(get_logger);

use QDepo::Db::Connection;

use base qw(Class::Singleton);

=head1 NAME

QDepo::Db - Database operations module

=head1 VERSION

Version 0.39

=cut

our $VERSION = '0.39';

=head1 SYNOPSIS

Create a new connection instance only once and use it many times.

    use QDepo::Db;

    my $dbi = QDepo::Db->instance($args); # first time init

    my $dbi = QDepo::Db->instance();      # later, in other modules

    my $dbh = $dbi->dbh;

=head1 METHODS

=head2 _new_instance

Constructor method, the first and only time a new instance is created.
All parameters passed to the instance() method are forwarded to this
method. (From I<Class::Singleton> docs).

=cut

sub _new_instance {
    my ($class, $model) = @_;

    my $conn = QDepo::Db::Connection->new($model);

    return bless { conn => $conn }, $class;
}

=head2 db_connect

Connect when there already is an instance.

=cut

sub db_connect {
    my ($self, $model) = @_;

    my $conn = QDepo::Db::Connection->new($model);

    $self->{conn} = $conn;

    return $self;
}

=head2 dbh

Return database handle.

=cut

sub dbh {
    my $self = shift;

    return $self->{conn}{dbh};
}

=head2 dbc

Module instance

=cut

sub dbc {
    my $self = shift;

    return $self->{conn}{dbc};
}

=head2 DESTROY

Destroy method.

=cut

sub DESTROY {
    my $self = shift;

    if ( defined $self->{conn}{dbh} ) {
        $self->{conn}{dbh}->disconnect;
        print "Disconnected\n";
    }

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGEMENTS

Inspired from PerlMonks node [id://609543] by GrandFather.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut

1;    # End of QDepo::Db