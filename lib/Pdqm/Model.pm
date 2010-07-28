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
# |                                                 p a c k a g e   M o d e l |
# +---------------------------------------------------------------------------+
package Pdqm::Model;

use strict;
use warnings;

use Pdqm::FileIO;
use Pdqm::Observable;
use Pdqm::Db;

sub new {
    my ($class, $args) = @_;

    my $self = {
        _connected   => Pdqm::Observable->new(),
        _stdout      => Pdqm::Observable->new(),
        _itemchanged => Pdqm::Observable->new(),
        _editmode    => Pdqm::Observable->new(),
    };

    bless $self, $class;

    return $self;
}

#- next: DB

sub db_connect {
    my $self = shift;

    if ( not $self->is_connected ) {
        $self->_connect();
    }
    if ( $self->is_connected ) {
        $self->get_connection_observable->set( 1 );
        $self->_print('Connected.');
    }
    else {
        $self->get_connection_observable->set( 0 );
        $self->_print('NOT connected.');
    }

    return $self;
}

sub _connect {
    my $self = shift;

    # Connect to database
    my $db = Pdqm::Db->new(); # user, pass ?

    # Is connected ?
    if ( ref( $db->dbh() ) =~ m{DBI} ) {
        $self->get_connection_observable->set( 1 );
    }
    else {
        $self->get_connection_observable->set( 0 );
    }
}

sub db_disconnect {
    my $self = shift;

    if ( $self->is_connected ) {
        $self->_disconnect;
        $self->get_connection_observable->set( 0 );
        $self->_print('Disconnected.');
    }
    return $self;
}

sub _disconnect {
    my $self = shift;

    my $db = Pdqm::Db->new();
    $db->dbh->disconnect;
}

sub is_connected {
    my $self = shift;

    return $self->get_connection_observable->get;
    # What if the connection is lost ???
}

sub get_connection_observable {
    my $self = shift;

    return $self->{_connected};
}

#- prev: DB
#- next: Log

sub get_stdout_observable {
    my $self = shift;

    return $self->{_stdout};
}

sub _print {
    my ( $self, $line ) = @_;

    print "$line\n";
    # $self->get_stdout_observable->set( $line );
}

#- prev: Log
#- next: Event

sub on_page_change {
    my ($self, $new_pg, $old_pg) = @_;
}

sub on_item_selected {
    my ($self) = @_;

    $self->get_itemchanged_observable->set( 1 );
    $self->_print('Item selected');
}

#- prev: Event
#- next: List

sub get_list_data {
    my ($self) = @_;

    # XML read - write module
    $self->{xmldata} = Pdqm::FileIO->new();
    my $titles = $self->{xmldata}->get_titles();
    my $titles_no = scalar keys %{$titles};

    return $titles;
}

sub run_export {
    my ($self) = @_;

    $self->_print("Running export :-)");
}

# prev:
# next:

sub get_detail_data {
    my ($self, $file_fqn) = @_;

    my $ddata_ref = $self->{xmldata}->get_details($file_fqn);

    return $ddata_ref;
}

sub get_itemchanged_observable {
    my $self = shift;

    return $self->{_itemchanged};
}

# prev: List
# next: Edit mode

sub set_editmode {
    my $self = shift;

    if ( !$self->is_editmode ) {
        $self->get_editmode_observable->set(1);
    }
    if ( $self->is_editmode ) {
        $self->_print("Edit mode.");
    }
    else {
        $self->_print("Idle mode.");
    }
}

sub set_idlemode {
    my $self = shift;

    if ( $self->is_editmode ) {
        $self->get_editmode_observable->set(0);
    }
    if ( $self->is_editmode ) {
        $self->_print("Edit mode.");
    }
    else {
        $self->_print("Idle mode.");
    }
}

sub is_editmode {
    my $self = shift;

    return $self->get_editmode_observable->get;
}

sub get_editmode_observable {
    my $self = shift;

    return $self->{_editmode};
}

sub save_query_def {
    my $self = shift;

    $self->_print("Edit mode");
}

# prev: Edit mode

1;
