#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
    unshift @INC, 'lib';
}

my $opts = {
    'verbose'  => 1,
    'pass'     => 'stefan',
    'user'     => 'tba790k',
    'app_id'   => 'Contracte',
    'cfg_name' => 'contracte-pg',
};

use Pdqm;

my $pdqm = Pdqm->new( $opts );

$pdqm->run;
