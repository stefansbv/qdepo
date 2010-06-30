package Pdqm::Wx::App;

use strict;
use warnings;

use Data::Dumper;

use Pdqm::Wx::Controller;
use base qw(Wx::App);

sub create {
    my $self = shift->new;

    # Check IDE param
    my $ide = shift;

    # Save a link back to the parent ide
    $self->{ide} = $ide;

    Pdqm::Wx::Controller->new();

    print Dumper( $self);
    return $self;
}

sub OnInit { 1 }

1;
