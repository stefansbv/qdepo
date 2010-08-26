# +---------------------------------------------------------------------------+
# | Name     : Qrt (Perl Database Query Manager)                             |
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
# |                                                     p a c k a g e   A p p |
# +---------------------------------------------------------------------------+
package Qrt::Wx::App;

use strict;
use warnings;

use Qrt::Wx::Controller;
use base qw(Wx::App);

sub create {
    my $self = shift->new;

    # # Check IDE param
    # my $app = shift;

    # # Save a link back to the parent ide ???
    # $self->{app} = $app;

    # wxSingleInstanceChecker ?

    # Qrt::Wx::Controller->new($self);
    my $controller = Qrt::Wx::Controller->new();

    # Populate list and connect to database ???
    $controller->start();

    return $self;
}

sub OnInit { 1 }

1;
