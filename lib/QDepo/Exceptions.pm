package QDepo::Exceptions;

use strict;
use warnings;

use Exception::Base
    'Exception::Db',
    'Exception::Db::Connect' => {
        isa               => 'Exception::Db',
        has               => [qw( usermsg logmsg )],
        string_attributes => [qw( usermsg logmsg )],
    },
    'Exception::Db::Connect::Auth' => {
        isa               => 'Exception::Db::Connect',
    },
    'Exception::Db::SQL' => {
        isa               => 'Exception::Db',
        has               => [qw( usermsg logmsg )],
        string_attributes => [qw( usermsg logmsg )],
    };

=head1 NAME

QDepo::Exceptions - QDepo exceptions

=head1 VERSION

Version 0.39

=cut

our $VERSION = 0.39;

=head1 SYNOPSIS

    use QDepo::Exceptions;

    ...

=head1 METHODS

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGEMENTS

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

1;    # End of QDepo::Exceptions
