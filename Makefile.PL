#
# Makefile.PL for qdepo
#
# Copyright (C) 2010-2012 Stefan Suciu
# GNU General Public License v3
#

use 5.008005;
use strict;
use warnings;

use inc::Module::Install;

name 'QDepo';
all_from 'lib/QDepo.pm';

my $guitk = 0;

#-  GUI toolkits

#-- Wx

eval { require Wx; };
unless ($@) {
    $guitk++;
    requires 'Wx'                 => '0.970101';
    requires 'Wx::Perl::ListCtrl' => '0.03';
}

#-- and/or Tk

eval { require Tk; };
unless ($@) {
    $guitk++;
    requires 'Tk'            => '804.028';
    requires 'Tk::ToolBar'   => '0.09';
    requires 'Tk::StatusBar' => '0.04';
    requires 'Tk::MListbox'  => '1.11';
    requires 'Tk::MsgBox'    => '0';
}

if ($guitk == 0) {
    die "wxPerl or PerlTk is required!\nPlease install at least one of them first.";
}

#-  Other modules

requires 'Class::Singleton'      => '1.4';
requires 'Class::Accessor'       => '0';
requires 'Try::Tiny'             => '0.07';
requires 'Number::Compare'       => '0';
requires 'File::UserConfig'      => '0';
requires 'File::Find::Rule'      => '0.30';
requires 'File::HomeDir'         => '0.89';
requires 'File::Spec::Functions' => '0';
requires 'File::Slurp'           => '0';
requires 'YAML::Tiny'            => '0';
requires 'DBI'                   => '1.53';
requires 'DBD::SQLite'           => '1.29';  # for testing
requires 'HTML::TreeBuilder'     => '0';     # for XML::Twig tests
requires 'XML::Twig'             => '3.26';
requires 'Ouch'                  => '0.0401';
requires 'Hash::Merge'           => '0';
requires 'Regexp::Common'        => '0';

#-- Database
recommends 'DBD::cubrid'   => '1.32';
recommends 'DBD::Firebird' => '0.80';
recommends 'DBD::Pg'       => '1.32';
recommends 'DBD::mysql'    => '0';

#-- For Output
requires 'Spreadsheet::WriteExcel' => '0';
# other optional modules
recommends 'OpenOffice::OODoc' => '2.103';
recommends 'Text::CSV_XS'      => '0';
recommends 'ODF::lpOD'         => '0';

test_requires 'Test::More' => '0.47';

install_share 'share';
install_script 'bin/qdepo';

# Cleanup test output files
makemaker_args(
    clean => { FILES => qq(*.xls *.od? qdepo-test.db) },
);

WriteAll;
