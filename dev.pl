#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
    unshift @INC, 'lib';
}

my $conn_name = shift;

$conn_name ||= 'classicmodels';

my $opts = {
    'verbose'  => 1,
    'pass'     => undef,
    'cfg_gen'  => '/home/fane/.tpda-qrt/etc/general.yml',
    'cfg_path' => '/home/fane/.tpda-qrt',
    'conn'     => $conn_name,
    'user'     => undef
};

use Qrt;

my $tpdaqrt = Qrt->new($opts);

$tpdaqrt->run;
