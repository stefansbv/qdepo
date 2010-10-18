package Qrt::Db::Connection::Sqlite;

use warnings;
use strict;

use DBI;


=head1 NAME

Qrt::Db::Connection::Sqlite - The great new Qrt::Db::Connection::Sqlite!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use Qrt::Db::Connection::Sqlite;

    my $db = Qrt::Db::Connection::Sqlite->new();

    $db->conectare($conninfo);


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

=head2 conectare

Connect to database

=cut

sub conectare {
    my ($self, $conf) = @_;

    # $pass = undef; # Uncomment when is no password set

    my $dbname = $conf->{database};
    my $driver = $conf->{driver};

    print "Connect to the $driver server ...\n";
    print " Parameters:\n";
    print "  => Database = $dbname\n";

    eval {
        $self->{dbh} = DBI->connect(
            "dbi:SQLite:"
                . $dbname,
            q{},
            q{},
            { FetchHashKeyName => 'NAME_lc' }
        );
    };

    if ($@) {
        warn "$@";
        return;
    }
    else {
        print "\nConnected to database \'$dbname\'.\n";

        return $self->{dbh};
    }
}


=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1; # End of Qrt::Db::Connection::Sqlite
