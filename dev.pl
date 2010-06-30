#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
    unshift @INC, 'lib';
}

my $opts = {
    'run_ref' => {
        'verbose'  => 1,
        'pass'     => undef,
        'user'     => undef,
        'app_id'   => 'Contracte',
        'cfg_para' => 'contracte-pg'
    },
    'cfg_ref' => {
        'conf_file' => 'contracte-pg.xml',
        'tmpl_dir'  => '/home/fane/.reports',
        'conf_dir'  => '/home/fane/.reports/Contracte'
    }
};

use Pdqm;

my $pdqm = Pdqm->new( $opts );

$pdqm->run;
