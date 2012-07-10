package TpdaQrt::Db::Connection::Cubrid;

use strict;
use warnings;

use Regexp::Common;
use DBI;
use Ouch;
use Try::Tiny;

=head1 NAME

TpdaQrt::Db::Connection::Cubrid - Connect to a CUBRID database.

=head1 VERSION

Version 0.37

=cut

our $VERSION = 0.37;

=head1 SYNOPSIS

    use TpdaQrt::Db::Connection::Cubrid;

    my $db = TpdaQrt::Db::Connection::Cubrid->new($model);

    $db->db_connect($connection);


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
    my ( $self, $conf ) = @_;

    try {
        $self->{_dbh} = DBI->connect(
            "dbi:cubrid:"
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
                LongReadLen      => 524288,
            }
        );
    }
    catch {
        my $error_msg = $_;
        my $user_message = $self->parse_db_error($error_msg);
        if ( $self->{model} and $self->{model}->can('exception_log') ) {
            $self->{model}->exception_log($user_message);
        }
        else {
            ouch 'ConnError','Connection failed!';
        }
    };

    ## Date format ISO ???
    ## UTF-8 ???

    return $self->{_dbh};
}

=head2 parse_db_error

Parse a database connection error message, and translate it for the
user.

TODO: Extend with specific errors like authentication error...

=cut

sub parse_db_error {
    my ($self, $cb) = @_;

    print "\nCB: $cb\n\n";

    my $message_type =
         $cb eq q{}                                          ? "nomessage"
       : $cb =~ m/Unknown host name/smi                      ? "unknownhost"
       : $cb =~ m/Cannot communicate with server/smi         ? "unknownport"
       : $cb =~ m/CUBRID DBMS Error/smi                      ? "dbmserror"
       :                                                       "unknown";

    # Analize and translate

    my ( $type, $name ) = split /:/, $message_type, 2;
    $name = $name ? $name : '';

    my $translations = {
        dbmserror   => "fatal#Database error",
        nomessage   => "weird#Error without message!",
        unknownhost => "fatal#Network problem, unknown host name",
        unknownport => "fatal#Network problem, check server port",
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

1;    # End of TpdaQrt::Db::Connection::Cubrid
