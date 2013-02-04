package QDepo::Db::Connection::Cubrid;

use strict;
use warnings;

use QDepo::Exceptions;
use Try::Tiny;
use DBI;

=head1 NAME

QDepo::Db::Connection::Cubrid - Connect to a CUBRID database.

=head1 VERSION

Version 0.39

=cut

our $VERSION = 0.39;

=head1 SYNOPSIS

    use QDepo::Db::Connection::Cubrid;

    my $db = QDepo::Db::Connection::Cubrid->new($model);

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

    my ($dbname, $host, $port) = @{$conf}{qw(dbname host port)};
    my ($driver, $user, $pass) = @{$conf}{qw(driver user pass)};

    my $dsn = qq{dbi:cubrid:database=$dbname;host=$host;port=$port};

    $self->{_dbh} = DBI->connect(
        $dsn, $user, $pass,
        {   FetchHashKeyName => 'NAME_lc',
            AutoCommit       => 1,
            RaiseError       => 1,
            PrintError       => 0,
            LongReadLen      => 524288,
            HandleError      => sub { $self->handle_error() },
        }
    );

    ## Date format ISO ???
    ## UTF-8 ???

    return $self->{_dbh};
}

=head2 handle_error

Log errors.

=cut

sub handle_error {
    my $self = shift;

    if ( defined $self->{_dbh} and $self->{_dbh}->isa('DBI::db') ) {
        QDepo::Exception::Db::SQL->throw(
            logmsg  => $self->{_dbh}->errstr,
            usermsg => 'SQL error',
        );
    }
    else {
        QDepo::Exception::Db::Connect->throw(
            logmsg  => DBI->errstr,
            usermsg => 'Connection error!',
        );
    }

    return;
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

1;    # End of QDepo::Db::Connection::Cubrid
