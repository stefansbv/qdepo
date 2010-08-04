#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
    unshift @INC, 'lib';
}

my $opts = {
    db_name    => 'contracte',
    verbose    => 1,
    db_qdf_qn  => '/home/fane/.pdqm/db/contracte/qdf',
    db_cnf_qn  => '/home/fane/.pdqm/db/contracte/etc',
    pass       => undef,
    cnf_etc    => '/home/fane/.pdqm/etc',
    cnf_n      => '.pdqm',
    cnf_toolb  => '/home/fane/.pdqm/etc/interfaces/toolbar.yml',
    cfg_name   => 'contracte-pg.yml',
    db_base_qn => '/home/fane/.pdqm/db/contracte',
    cnf_templ  => '/home/fane/.pdqm/etc/template/template.qdf',
    user       => undef,
    db_root_qn => '/home/fane/.pdqm/db',
    home       => '/home/fane',
    cnf_qn     => '/home/fane/.pdqm',
    db_cnf_fqn => '/home/fane/.pdqm/db/contracte/etc/contracte-pg.yml',
};

use Pdqm;

my $pdqm = Pdqm->new($opts);

$pdqm->run;
