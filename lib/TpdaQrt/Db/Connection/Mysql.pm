package TpdaQrt::Db::Connection::Mysql;

use warnings;
use strict;

use DBI;
use Try::Tiny;

=head1 NAME

TpdaQrt::Db::Connection::Mysql - Connect to a MySQL database

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

=head1 SYNOPSIS

    use TpdaQrt::Db::Connection::Mysql;

    my $db = TpdaQrt::Db::Connection::Mysql->new();

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

=head2 db_connect

Connect to database

=cut

sub db_connect {
    my ($self, $conf) = @_;

    print "Connecting to the $conf->{driver} server\n";
    print "Parameters:\n";
    print "  => Database = $conf->{dbname}\n";
    print "  => Host     = $conf->{host}\n";
    print "  => User     = $conf->{user}\n";

    try {
        $self->{_dbh} = DBI->connect(
            "dbi:mysql:"
                . "dbname="
                . $conf->{dbname}
                . ";host="
                . $conf->{host}
                . ";port="
                . $conf->{port},
            $conf->{user}, $conf->{pass},
            { FetchHashKeyName => 'NAME_lc' }
        );
    };
    catch {
        print "Transaction aborted: $_"
            or print STDERR "$_\n";

          # exit 1;
    };

    print "Connected to database $conf->{dbname}\n";

    return $self->{_dbh};
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of TpdaQrt::Db::Connection::Mysql
