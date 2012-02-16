#
# Makefile.PL for tpda-qrt
#
# Copyright (C) 2010-2012 Stefan Suciu
# GNU General Public License v3
#

use 5.008005;
use strict;
use warnings;

use inc::Module::Install;

name 'TpdaQrt';
all_from 'lib/TpdaQrt.pm';

requires 'Wx'                    => '0.9701';
requires 'Wx::Perl::ListCtrl'    => '0.03';
requires 'Class::Singleton'      => '1.4';
requires 'Class::Accessor'       => '0';
requires 'Try::Tiny'             => '0.07';
requires 'Number::Compare'       => '0';
requires 'File::UserConfig'      => '0';
requires 'File::Find::Rule'      => '0.30';
requires 'File::HomeDir'         => '0.89';
requires 'File::Spec::Functions' => '0';
requires 'YAML::Tiny'            => '0';
requires 'DBI'                   => '1.53';
requires 'DBD::SQLite'           => '1.29';
requires 'XML::Twig'             => '3.26';
requires 'Hash::Merge'           => '0';
# for Output
requires 'Spreadsheet::WriteExcel' => '0';
requires 'OpenOffice::OODoc'       => '2.103';
requires 'Text::CSV_XS'            => '0';
requires 'ODF::lpOD'               => '0';

test_requires 'Test::More' => '0.47';

install_share 'share';
install_script 'bin/tpda-qrt';

WriteAll;
