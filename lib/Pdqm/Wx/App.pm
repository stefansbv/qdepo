package Pdqm::Wx::App;

use strict;
use warnings;

use Pdqm::Wx::Controller;
use base qw(Wx::App);

sub OnInit {

    Pdqm::Wx::Controller->new();
}

1;
