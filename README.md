QDepo
=====
Ștefan Suciu
2014-08-24

QDepo ia a desktop application for retrieving and exporting data from
relational database systems to spreadsheet files, (also formerly known
as "TPDA - Query Repository Tool").

The graphical user interface is based on wxPerl.

The main feature of the application is the SQL query repository
management.  The repository consists from a collection of XML files
that ca easily be moved or copied to other computers.

The supported formats are Excel (.xls), ODF and CSV. The Database
management system support includes CUBRID (new), Firebird, MySQL,
PostgreSQL and SQLite.

Please, read the Disclaimer of Warranty. from the GNU GENERAL PUBLIC
LICENSE.

The 'Makefile.PL' script lists the required modules.  From that list
'DBD::SQLite' is required for the tests and for the initial demo
configuration.  The other DBD modules are optional, use only the
needed ones.  Same is true for the modules used to generate the
output, like 'Spreadsheet::WriteExcel', 'OpenOffice::OODoc',
ODF::lpOD, and 'Text::CSV_XS'.

License And Copyright
---------------------

Copyright (C) 2010-2014 Ștefan Suciu

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
