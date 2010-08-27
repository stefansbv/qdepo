#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
    unshift @INC, 'lib';
}

my $opts = {
    db_name    => 'contracte',
    verbose    =>  1,
    db_qdf_qn  => '/home/fane/.tpda-qrt/db/contracte/qdf',
    db_cnf_qn  => '/home/fane/.tpda-qrt/db/contracte/etc',
    pass       =>  undef,
    cnf_etc    => '/home/fane/.tpda-qrt/etc',
    cnf_n      => '.tpda-qrt',
    cnf_toolb  => '/home/fane/.tpda-qrt/etc/interfaces/toolbar.yml',
    cfg_name   => 'contracte-pg.yml',
    db_base_qn => '/home/fane/.tpda-qrt/db/contracte',
    cnf_templ  => '/home/fane/.tpda-qrt/etc/template/template.qdf',
    user       =>  undef,
    db_root_qn => '/home/fane/.tpda-qrt/db',
    home       => '/home/fane',
    cnf_qn     => '/home/fane/.tpda-qrt',
    db_cnf_fqn => '/home/fane/.tpda-qrt/db/contracte/etc/contracte-pg.yml',
};

use Qrt;

my $tpdaqrt = Qrt->new($opts);

$tpdaqrt->run;
