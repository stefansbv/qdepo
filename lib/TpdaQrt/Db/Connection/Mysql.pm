package TpdaQrt::Db::Connection::Mysql;

use strict;
use warnings;

use Regexp::Common;
use DBI;
use Ouch;
use Try::Tiny;

=head1 NAME

TpdaQrt::Db::Connection::Mysql - Connect to a MySQL database

=head1 VERSION

Version 0.36

=cut

our $VERSION = '0.36';

=head1 SYNOPSIS

    use TpdaQrt::Db::Connection::Mysql;

    my $db = TpdaQrt::Db::Connection::Mysql->new($model);

    $db->db_connect($conninfo);


=head1 METHODS

=head2 new

Constructor.

=cut

sub new {
    my ($class, $model) = @_;

    my $self = {};

    $self->{model} = $model;

    bless $self, $class;

    return $self;
}

=head2 db_connect

Connect to the database.

=cut

sub db_connect {
    my ($self, $conf) = @_;

    try {
        $self->{_dbh} = DBI->connect(
            "dbi:mysql:"
                . "database="
                . $conf->{dbname}
                . ";host="
                . $conf->{host}
                . ";port="
                . $conf->{port},
            $conf->{user},
            $conf->{pass},
            {   FetchHashKeyName => 'NAME_lc',
                AutoCommit       => 1,
                RaiseError       => 1,
                PrintError       => 0,
                #LongReadLen      => 524288,
            }
        );
    }
    catch {
        my $user_message = $self->parse_db_error($_);
        if ( $self->{model} and $self->{model}->can('exception_log') ) {
            $self->{model}->exception_log($user_message);
        }
        else {
            ouch 'ConnError','Connection failed!';
        }
    };

    #$self->{_dbh}{pg_enable_utf8} = 1;

    return $self->{_dbh};
}

=head2 parse_db_error

Parse a database error message, and translate it for the user.

TODO check if RDBMS specific and/or maybe version specific.

=cut

sub parse_db_error {
    my ($self, $mi) = @_;

    print "\nMY: $mi\n\n";

    my $message_type =
         $mi eq q{}                                          ? "nomessage"
       : $mi =~ m/Access denied for user ($RE{quoted})/smi   ? "password:$1"
       : $mi =~ m/Can't connect to local MySQL server/smi    ? "nolocalconn"
       : $mi =~ m/Can't connect to MySQL server on ($RE{quoted})/smi ? "nethost:$1"
       :                                                       "unknown"
       ;

    # Analize and translate

    my ( $type, $name ) = split /:/, $message_type, 2;
    $name = $name ? $name : '';

    my $translations = {
        nomessage   => "weird#Error without message!",
        dbnotfound  => "fatal#Database $name not found!",
        password    => "info#Authentication failed for $name",
        username    => "info#User name $name not found!",
        network     => "fatal#Network problem",
        nethost     => "fatal#Network problem: host $name",
        nolocalconn => "fatal#Connection problem to local MySQL",
        unknown     => "fatal#Database error",
    };

    my $message;
    if (exists $translations->{$type} ) {
        $message = $translations->{$type};
    }
    else {
        print "EE: Translation error!\n";
    }

    return $message;
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

1; # End of TpdaQrt::Db::Connection::Mysql
