package TpdaQrt::Utils;

use strict;
use warnings;

=head1 NAME

TpdaQrt::Utils - Various utility functions

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Various utility functions used by all other modules.

    use TpdaQrt::Utils;

    my $foo = TpdaQrt::Utils->function_name();

=head1 METHODS

=head2 trim

Trim strings or arrays.

=cut

sub trim {
    my ($self, @text) = @_;

    for (@text) {
        s/^\s+//;
        s/\s+$//;
        s/\n$//mg; # m=multiline
    }

    return wantarray ? @text : "@text";
}

=head2 sort_hash_by_id

Use ST to sort hash by value (Id), returns an array ref of the sorted
items.

=cut

sub sort_hash_by_id {
    my ( $self, $attribs ) = @_;

    #-- Sort by id
    #- Keep only key and id for sorting
    my %temp = map { $_ => $attribs->{$_}{id} } keys %{$attribs};

    #- Sort with  ST
    my @attribs = map { $_->[0] }
        sort { $a->[1] <=> $b->[1] }
        map { [ $_ => $temp{$_} ] }
        keys %temp;

    return \@attribs;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at users.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc TpdaQrt::Utils

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2010 - 2011 Stefan Suciu.

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

1; # End of TpdaQrt::Utils
