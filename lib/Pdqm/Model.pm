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

use File::Copy;
use File::Basename;
use Data::Dumper;

use Pdqm::Config;
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
        $self->_print('Connected');
    }
    else {
        $self->get_connection_observable->set( 0 );
        $self->_print('Not connected');
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
    my ( $self, $line, $sb_id ) = @_;

    $sb_id = 0 if not defined $sb_id;

    $self->get_stdout_observable->set( "$line:$sb_id" );
}

#- prev: Log
#- next: Event

sub on_page_change {
    my ($self, $new_pg, $old_pg) = @_;
}

sub on_item_selected {
    my ($self) = @_;

    $self->get_itemchanged_observable->set( 1 );
    # $self->_print('Item selected');
}

#- prev: Event
#- next: List

sub get_list_data {
    my ($self) = @_;

    # XML read - write module
    $self->{fio} = Pdqm::FileIO->new();
    my $data_ref = $self->{fio}->get_titles();

    my $indice = 0;
    my $titles = {};

    # Format titles
    foreach my $rec ( @{$data_ref} ) {
        my $nrcrt = $indice + 1;
        $titles->{$indice} = [ $nrcrt, $rec->{title}, $rec->{file} ];
        $indice++;
    }

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

    my $ddata_ref = $self->{fio}->get_details($file_fqn);

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
        $self->_print('edit', 1);
    }
    else{
        $self->_print('idle', 1);
    }
}

sub set_idlemode {
    my $self = shift;

    if ( $self->is_editmode ) {
        $self->get_editmode_observable->set(0);
    }
    if ( $self->is_editmode ) {
        $self->_print('edit', 1);
    }
    else {
        $self->_print('idle', 1);
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
    my ($self, $file_fqn, $head, $para, $body) = @_;

    # Transform records to match data in xml format
    $head = $self->transform_data($head);
    $para = $self->transform_para($para);
    $body = $self->transform_data($body);

    # Asemble data
    my $record = {
        header     => $head,
        parameters => $para,
        body       => $body,
    };

    $self->{fio}->xml_update($file_fqn, $record);

    $self->_print("Saved.");

    return $head->{title};
}

sub transform_data {

    my ($self, $record) = @_;

    my $rec;

    foreach my $item ( @{$record} ) {
        while (my ($key, $value) = each ( %{$item} ) ) {
            $rec->{$key} = $value;
        }
    }

    return $rec;
}

sub transform_para {

    my ($self, $record) = @_;

    my (@aoh, $rec);

    foreach my $item ( @{$record} ) {
        while (my ($key, $value) = each ( %{$item} ) ) {
            if ($key =~ m{descr([0-9])} ) {
                $rec = {};      # new record
                $rec->{descr} = $value;
            }
            if ($key =~ m{value([0-9])} ) {
                $rec->{id} = $1;
                $rec->{value} = $value;
                push(@aoh, $rec);
            }
        }
    }

    return \@aoh;
}

# prev: Edit mode

sub report_add {

    my ( $self ) = @_;

    my $reports_ref = $self->{fio}->get_file_list();

    # Find a new number to create a file name like raport-nnnnn.xml
    # Try to fill the gaps between numbers in file names
    my $files_no = scalar @{$reports_ref};

    my $cnf    = Pdqm::Config->new();
    my $qdfext = $cnf->cfg->qdf->{extension};

    # Search for an non existent file name
    my %numbers;
    my $num;
    foreach my $item ( @{$reports_ref} ) {
        my $filename = basename($item);
        if ( $filename =~ m/raport\-(\d{5})\.$qdfext/ ) {
            $num = sprintf( "%d", $1 );
            $numbers{$num} = 1;
        }
    }

    # Sort and find max
    my @numbers = sort { $a <=> $b } keys %numbers;
    my $num_max = $numbers[-1];
    $num_max = 0 if ! defined $num_max;

    # Find first gap
    my $fnd = 0;
    foreach my $trynum ( 1 .. $num_max ) {
        if ( !$numbers{$trynum} ) {
            $num = $trynum;
            $fnd = 1;
            last;
        }
    }
    # If not found, just asign the next number
    if ( $fnd == 0 ) {
        $num = $num_max + 1;
    }

    # Create new report definition file
    my $newrepo_fn = 'raport-' . sprintf( "%05d", $num ) . ".$qdfext";

    my $qdf = $cnf->cfg->qdf;    # query definition files

    my $src_fqn  = $cnf->cfg->qdf->{template};
    my $dest_fqn = $cnf->new_qdf_fqn($newrepo_fn);

    # print " $src_fqn -> $dest_fqn\n";

    if ( !-f $dest_fqn ) {
        print "Create new report from template ...";
        if ( copy( $src_fqn, $dest_fqn ) ) {
            print " done: ($newrepo_fn)\n";
        }
        else {
            print " failed: $!\n";
        }

        # Adauga titlul si noul fisier
        $self->{fio} = Pdqm::FileIO->new();
        my $data_ref = $self->{fio}->get_title($dest_fqn);

        return $data_ref;
    }
    else {
        warn "File exists! ($dest_fqn)\n";
        # &status_mesaj_l("Eroare, nu am creat raport nou");
    }
}

sub report_remove {

    my ($self, $file_fqn) = @_;

    # Move file to backup
    my $file_bak_fqn = "$file_fqn.bak";
    if ( move($file_fqn, $file_bak_fqn) ) {
        print " Deleted $file_fqn\n";
    }

    return;
}

1;
