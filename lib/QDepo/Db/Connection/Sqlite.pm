package QDepo::Db::Connection::Sqlite;

use strict;
use warnings;

use DBI;
use Try::Tiny;

=head1 NAME

QDepo::Db::Connection::Sqlite - Connect to a PostgreSQL database.

=head1 VERSION

Version 0.39

=cut

our $VERSION = '0.39';

=head1 SYNOPSIS

    use QDepo::Db::Connection::Sqlite;

    my $db = QDepo::Db::Connection::Sqlite->new();

    $db->db_connect($connection);

=head1 METHODS

=head2 new

Constructor

=cut

sub new {
    my $class = shift;

    my $self = {};

    bless $self, $class;

    return $self;
}

=head2 db_connect

Connect to database

=cut

sub db_connect {
    my ($self, $conf) = @_;

    try {
        $self->{_dbh} = DBI->connect(
            "dbi:SQLite:"
              . $conf->{dbname},
            q{},
            q{},
        );
    }
    catch {
        print "Transaction aborted: $_"
            or print STDERR "$_\n";

        # exit 1;
    };

    ## Date format ISO ???

    print "Connected to database $conf->{dbname}\n";

    return $self->{_dbh};
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>.

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of QDepo::Db::Connection::Sqlite