#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
    unshift @INC, 'lib';
}

my $cfg_name = shift;

$cfg_name ||= 'test';

my $opts = {
    cfgname => $cfg_name,
    cfgmain => 'etc/main.yml',
    user    => undef,
    pass    => undef,
};

use Qrt;

my $tpdaqrt = Qrt->new($opts);

$tpdaqrt->run;
