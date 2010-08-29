#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
    unshift @INC, 'lib';
}

my $opts = {
    db_name    => 'contracte',
    verbose    =>  1,
    db_qdf_p   => '/home/fane/.tpda-qrt/db/contracte/qdf',
    db_cnf_p   => '/home/fane/.tpda-qrt/db/contracte/etc',
    pass       =>  undef,
    cnf_etc_p  => '/home/fane/.tpda-qrt/etc',
    cnf_n      => '.tpda-qrt',
    cnf_tlb_qn => '/home/fane/.tpda-qrt/etc/interfaces/toolbar.yml',
    cfg_name   => 'contracte-pg.yml',
    db_base_p  => '/home/fane/.tpda-qrt/db/contracte',
    cnf_tpl_qn => '/home/fane/.tpda-qrt/etc/template/template.qdf',
    user       =>  undef,
    db_root_p  => '/home/fane/.tpda-qrt/db',
    home       => '/home/fane',
    cnf_p      => '/home/fane/.tpda-qrt',
    db_cnf_fqn => '/home/fane/.tpda-qrt/db/contracte/etc/tpda-qrt.yml',
};

use Qrt;

my $tpdaqrt = Qrt->new($opts);

$tpdaqrt->run;
