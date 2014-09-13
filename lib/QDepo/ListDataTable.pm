package QDepo::ListDataTable;

# ABSTRACT: A simple module to hold the data for the virtual ListCtrl.

use strict;
use warnings;

use List::MoreUtils qw/firstidx/;

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
    return $value;
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

sub get_item_default {
    my $self = shift;
    return $self->{default};
}

sub set_item_default {
    my ($self, $item) = @_;
    $self->{default} = $item;
    return;
}

sub get_item_selected {
    my $self = shift;
    return $self->{selected};
}

sub set_item_selected {
    my ($self, $item) = @_;
    $self->{selected} = $item;
    return;
}

=head2 toggle_item_marked

Add item if not present, delete if present.

=cut

sub toggle_item_marked {
    my ($self, $item) = @_;

    die "Undefined item parameter for 'toggle_item_marked'"
        unless defined $item;

    my $mark = 0;
    my $poz = firstidx { $_ == $item } @{ $self->{marked} };
    if ( $poz >= 0 ) {
        splice @{ $self->{marked} }, $poz, 1;
    }
    else {
        push @{ $self->{marked} }, $item;
        $mark = 1;
    }

    return $mark;
}

sub get_items_marked {
    my $self = shift;
    return \@{ $self->{marked} };
}

sub has_items_marked {
    my $self = shift;
    return ref $self->{marked}
        ? scalar @{ $self->{marked} }
        : 0;
}

1;
