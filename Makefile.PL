#
# Makefile.PL for tpda-qrt
#
# Copyright (C) 2010  Stefan Suciu
# GNU General Public License v3
#

use 5.010;
use strict;
use warnings;

use inc::Module::Install;

all_from  'lib/Qrt.pm';

requires 'perl'                        => 5.008005;
#requires 'POSIX'                      => 0;
#requires 'IO::Socket::PortState'      => 0;
requires 'Wx'                          => 0.970101;
requires 'Wx::Perl::ListCtrl'          => 0.03;
requires 'Class::Singleton'            => 1.4;
requires 'Class::Accessor'             => 0;
requires 'Number::Compare'             => 0;
requires 'File::Find::Rule'            => 0.30;
requires 'File::HomeDir'               => 0;
requires 'File::Spec::Functions'       => 0;
requires 'DBI'                         => 1.53;
requires 'DBD::InterBase'              => 0.44;
requires 'DBD::Pg'                     => 1.32;
requires 'XML::Twig'                   => 3.26;
requires 'Spreadsheet::WriteExcel'     => 0;
requires 'OpenOffice::OODoc'           => 2.103;
requires 'Text::CSV_XS'                => 0;

build_requires 'Module::Install'       => 0.30;
build_requires 'Test::More'            => 0.47;

#install_share  'share';
install_script 'bin/tpda-qrt';

WriteAll;
