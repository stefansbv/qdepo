# +---------------------------------------------------------------------------+
# | Name     : Pdqm (Perl Database Query Manager)                             |
# | Author   : Stefan Suciu  [ stefansbv 'at' users . sourceforge . net ]     |
# | Website  :                                                                |
# |                                                                           |
# | Copyright (C) 2010  Stefan Suciu                                          |
# |                                                                           |
# | This program is free software; you can redistribute it and/or modify      |
# | it under the terms of the GNU General Public License as published by      |
# | the Free Software Foundation; either version 2 of the License, or         |
# | (at your option) any later version.                                       |
# |                                                                           |
# | This program is distributed in the hope that it will be useful,           |
# | but WITHOUT ANY WARRANTY; without even the implied warranty of            |
# | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             |
# | GNU General Public License for more details.                              |
# |                                                                           |
# | You should have received a copy of the GNU General Public License         |
# | along with this program; if not, write to the Free Software               |
# | Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA |
# +---------------------------------------------------------------------------+
# |
# +---------------------------------------------------------------------------+
# |                                           p a c k a g e   I n s t a n c e |
# +---------------------------------------------------------------------------+
package Pdqm::Db::Instance;

use strict;
use warnings;

use Pdqm::Db::Connection;
use base qw(Class::Singleton);

our $VERSION = 0.03;

sub _new_instance {
    my ($class, $args) = @_;

    my $conn = Pdqm::Db::Connection->new( $args );
    my $dbh = $conn->db_connect(
        'stefan',   # ??? from cli params !!!
        'tba790k',  # ??? from cli params !!!
    );

    # Some defaults
    $dbh->{AutoCommit}  = 1;            # disable transactions
    $dbh->{RaiseError}  = 1;
    $dbh->{LongReadLen} = 512 * 1024;

    return bless {dbh => $dbh}, $class;
}


1;

__END__
