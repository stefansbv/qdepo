# Experimenting with Virtual ListCtrl
# Stefan Suciu, 2013-04-06
#
# A simple module to hold the data for the virtual ListCtrl.
#
package QDepo::ListDataTable;

use strict;
use warnings;

sub new {
    my $class = shift;

    my $self = {};

    $self->{data} = [];

    bless $self, $class;

    return $self;
}

sub set_value {
    my ($self, $row, $col, $value) = @_;
    $self->{data}[$row][$col] = $value;
    return;
}

sub get_value {
    my ($self, $row, $col) = @_;
    return $self->{data}[$row][$col];
}

sub get_data {
    my $self = shift;
    return $self->{data};
}

sub get_item_count {
    my $self = shift;
    return scalar @{ $self->get_data };
}

1;
