package QDepo::ListDataTable;

# ABSTRACT: A simple module to hold the data for the virtual ListCtrl.

use strict;
use warnings;
use Carp;

use List::MoreUtils qw/firstidx/;
use Locale::TextDomain 1.20 qw(QDepo);

sub new {
    my ( $class, $meta ) = @_;
    my $self = {};
    $self->{meta}     = $meta;
    $self->{data}     = [];
    $self->{default}  = undef;
    $self->{current}  = undef;
    $self->{selected} = undef;
    $self->{marked}   = [];
    bless $self, $class;
    return $self;
}

sub set_value {
    my ( $self, $row, $col, $value ) = @_;
    $self->{data}[$row][$col] = $value;
    return $value;
}

sub get_value {
    my ( $self, $row, $col ) = @_;
    my $value = $self->{data}[$row][$col];
    my $type  = $self->{meta}[$col]{type};
    return ( $value ? __('Yes') : q() ) if $type eq 'bool';
    return $value;
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
    my ( $self, $item ) = @_;
    $self->{default} = $item;
    $self->set_default($item);
    return;
}

sub set_default {
    my ( $self, $item ) = @_;
    my $max_idx = $self->get_item_count - 1;
    foreach my $idx ( 0 .. $max_idx ) {
        my $value = $idx == $item ? 1 : 0;
        $self->set_value( $idx, 2, $value );
    }
    return;
}

sub get_item_current {
    my $self = shift;
    return $self->{current};
}

sub set_item_current {
    my ( $self, $item ) = @_;
    $self->{current} = $item;
    $self->set_current($item);
    return;
}

sub set_current {
    my ( $self, $item ) = @_;
    my $max_idx = $self->get_item_count - 1;
    foreach my $idx ( 0 .. $max_idx ) {
        my $value = $idx == $item ? 1 : 0;
        $self->set_value( $idx, 3, $value );
    }
    return;
}

sub get_item_selected {
    my $self = shift;
    return $self->{selected};
}

sub set_item_selected {
    my ( $self, $item ) = @_;
    $self->{selected} = $item;
    return;
}

sub toggle_item_marked {
    my ( $self, $item ) = @_;

    croak "Undefined item parameter for 'toggle_item_marked'"
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

sub clear_all_items {
    my $self = shift;
    splice @{ $self->{data} };
    return;
}

1;
