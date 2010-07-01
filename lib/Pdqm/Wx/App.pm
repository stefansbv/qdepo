package Pdqm::Wx::App;

use strict;
use warnings;

use Data::Dumper;

use Pdqm::Wx::Controller;
use base qw(Wx::App);

sub create {
    my $self = shift->new;

    # # Check IDE param
    # my $app = shift;

    # # Save a link back to the parent ide ???
    # $self->{app} = $app;

    # Pdqm::Wx::Controller->new($self);
    Pdqm::Wx::Controller->new();

    return $self;
}

sub OnInit { 1 }

1;
