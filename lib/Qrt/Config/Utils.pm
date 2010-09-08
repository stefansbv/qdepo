package Qrt::Config::Utils;

use warnings;
use strict;

use YAML::Tiny;

=head1 NAME

Qrt::Config::Utils - Utility functions for config paths and files

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Qrt::Config::Utils;

    my $foo = Qrt::Config::Utils->new();


=head1 METHODS

=head2 load

Use YAML::Tiny to load a YAML file and return as a Perl hash data
structure.

=cut

sub load {
    my ( $self, $yaml_file ) = @_;

    return YAML::Tiny::LoadFile( $yaml_file );
}

=head2 merge_data

Merge two HoH and return the result.

=cut

sub data_merge {
    my ($self, $cfg, $cfg_data) = @_;

    foreach my $item ( keys %{$cfg_data} ) {
        $cfg->{_cfg}{$item} = $cfg_data->{$item};
    }

    return $cfg;
}


=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-qrt-config-utils at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Qrt-Config-Utils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Qrt::Config::Utils


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Qrt::Config::Utils
