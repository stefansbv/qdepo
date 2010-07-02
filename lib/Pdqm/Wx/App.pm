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

    # wxSingleInstanceChecker ?

    # Pdqm::Wx::Controller->new($self);
    my $controller = Pdqm::Wx::Controller->new();

    # Populate list and connect to database ???
    $controller->start();

    return $self;
}

sub OnInit { 1 }

1;
