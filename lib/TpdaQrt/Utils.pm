package TpdaQrt::Utils;

use strict;
use warnings;

=head1 NAME

TpdaQrt::Utils - Various utility functions

=head1 VERSION

Version 0.37

=cut

our $VERSION = '0.37';

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

=head2 params_to_hash

Transform data in simple hash reference format

TODO: Move this to model?

=cut

sub params_to_hash {
    my ($self, $params) = @_;

    my $parameters;
    foreach my $parameter ( @{ $params->{parameter} } ) {
        my $id = $parameter->{id};
        if ($id) {
            $parameters->{"value$id"} = $parameter->{value};
            $parameters->{"descr$id"} = $parameter->{descr};
        }
    }

    return $parameters;
}

=head2 transform_data

Transform data to be suitable to save in XML format

=cut

sub transform_data {
    my ($self, $record) = @_;

    my $rec;

    foreach my $item ( @{$record} ) {
        while (my ($key, $value) = each ( %{$item} ) ) {
            $rec->{$key} = $value;
        }
    }

    return $rec;
}

=head2 transform_para

Transform parameters data to AoH, to be suitable to save in XML format.

From:
      {
         'descr1' => 'Parameter1',
         'descr2' => 'Parameter2',
         'value1' => 'default1',
         'value2' => 'default2'
      };

To:
     [
       {
         'value' => 'default1',
         'id' => '1',
         'descr' => 'Parameter1'
       },
       {
         'value' => 'default2',
         'id' => '2',
         'descr' => 'Parameter2'
       }
     ];

=cut

sub transform_para {
    my ($self, $record) = @_;

    my (@aoh, $rec);

    foreach my $item ( @{$record} ) {
        while (my ($key, $value) = each ( %{$item} ) ) {
            if ($key =~ m{descr([0-9])} ) {
                $rec = {};      # new record
                $rec->{descr} = $value;
            }
            if ($key =~ m{value([0-9])} ) {
                $rec->{id} = $1;
                $rec->{value} = $value;
                push(@aoh, $rec);
            }
        }
    }

    return \@aoh;
}

=head2 ins_underline_mark

Insert ampersand character for underline mark in menu.

=cut

sub ins_underline_mark {
    my ( $self, $label, $position ) = @_;

    substr( $label, $position, 0 ) = '&';

    return $label;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1; # End of TpdaQrt::Utils
