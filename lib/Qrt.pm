# +---------------------------------------------------------------------------+
# | Name     : Qrt (Perl Database Query Manager)                             |
# | Author   : Stefan Suciu  [ stefansbv 'at' users . sourceforge . net ]     |
# | Website  :                                                                |
# |                                                                           |
# | Copyright (C) 2010  Stefan Suciu                                          |
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
# |                                                   p a c k a g e   P d q m |
# +---------------------------------------------------------------------------+
package Qrt;

use strict;
use warnings;
use 5.010;

use Qrt::Config;
use Qrt::Wx::App;

our $VERSION = 0.10;

sub new {
    my ($class, $args) = @_;

    my $self = {};

    bless $self, $class;

    $self->_init($args);

    return $self;
}

sub _init {
    my ( $self, $args ) = @_;

    # Initialize config for the first time
    my $cnf = Qrt::Config->new($args);

    # Create Wx application
    $self->{gui} = Qrt::Wx::App->create();
}

sub run {
    my $self = shift;
    $self->{gui}->MainLoop;
}

1;

__END__

=head1 NAME

Qrt - Is the main module in a wxPerl application for ...

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONFIGURATION AND ENVIRONMENT

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

This screen module in general does not check the input ...

Please report problems to the author(s)

Patches are welcome.

=head1 AUTHOR

Stefan Suciu  [ stefansbv 'at' users . sourceforge . net ]

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010 Stefan Suciu.

All rights reserved.

GNU General Public License
