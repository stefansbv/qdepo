package TpdaQrt::Db::Connection::Postgresql;

use strict;
use warnings;

use Regexp::Common;

use Ouch;
use Try::Tiny;
use DBI;

=head1 NAME

TpdaQrt::Db::Connection::Postgresql - Connect to a PostgreSQL database.

=head1 VERSION

Version 0.49

=cut

our $VERSION = 0.49;

=head1 SYNOPSIS

    use TpdaQrt::Db::Connection::Postgresql;

    my $db = TpdaQrt::Db::Connection::Postgresql->new();

    $db->db_connect($connection);


=head1 METHODS

=head2 new

Constructor

=cut

sub new {
    my ($class, $model) = @_;

    my $self = {};

    $self->{model} = $model;

    bless $self, $class;

    return $self;
}

=head2 db_connect

Connect to database

=cut

sub db_connect {
    my ( $self, $conf ) = @_;

    try {
        $self->{_dbh} = DBI->connect(
            "dbi:Pg:"
                . "dbname="
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
                LongReadLen      => 524288,
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

    ## Date format
    # set: datestyle = 'iso' in postgresql.conf
    ##
    $self->{_dbh}{pg_enable_utf8} = 1;

    # $log->info("Connected to '$conf->{dbname}'");

    return $self->{_dbh};
}

=head2 parse_db_error

Parse a database error message, and translate it for the user.

TODO check if RDBMS specific and/or maybe version specific.

=cut

sub parse_db_error {
    my ($self, $pg) = @_;

    print "\nPG: $pg\n\n";

    my $message_type =
         $pg eq q{}                                          ? "nomessage"
       : $pg =~ m/database ($RE{quoted}) does not exist/smi  ? "dbnotfound:$1"
       : $pg =~ m/ERROR:  column ($RE{quoted}) of relation ($RE{quoted}) does not exist/smi ? "colnotfound:$2.$1"
       : $pg =~ m/ERROR:  null value in column ($RE{quoted})/smi ? "nullvalue:$1"
       : $pg =~ m/relation ($RE{quoted}) does not exist/smi  ? "relnotfound:$1"
       : $pg =~ m/authentication failed .* ($RE{quoted})/smi ? "password:$1"
       : $pg =~ m/no password supplied/smi                   ? "password"
       : $pg =~ m/role ($RE{quoted}) does not exist/smi      ? "username:$1"
       : $pg =~ m/no route to host/smi                       ? "network"
       : $pg =~ m/DETAIL:  Key ($RE{balanced}{-parens=>'()'})=/smi ? "duplicate:$1"
       :                                                       "unknown";

    # Analize and translate

    my ( $type, $name ) = split /:/, $message_type, 2;
    $name = $name ? $name : '';

    my $translations = {
        nomessage   => "weird#Error without message!",
        dbnotfound  => "fatal#Database $name not found!",
        relnotfound => "fatal#Relation $name not found!",
        password    => "info#Authentication failed for $name",
        password    => "info#Authentication failed, password?",
        username    => "info#User name $name not found!",
        network     => "fatal#Network problem",
        unknown     => "fatal#Database error",
        duplicate   => "error#Duplicate $name",
        colnotfound => "error#Column not found $name",
        nullvalue   => "error#Null value for $name",
    };

    my $message;
    if (exists $translations->{$type} ) {
        $message = $translations->{$type}
    }
    else {
        print "EE: Translation error!\n";
    }

    return $message;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGEMENTS

Information schema queries by Lorenzo Alberton from
http://www.alberton.info/postgresql_meta_info.html

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of TpdaQrt::Db::Connection::Postgresql
