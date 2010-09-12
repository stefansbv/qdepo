# +---------------------------------------------------------------------------+
# | Name     : tpda-qrt (TPDA - Query Repository Tool)                        |
# | Author   : Stefan Suciu  [ stefansbv 'at' users . sourceforge . net ]     |
# | Website  : http://tpda-qrt.sourceforge.net                                |
# |                                                                           |
# | Copyright (C) 2004-2010  Stefan Suciu                                     |
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
package Qrt::Model;

use strict;
use warnings;

use Data::Dumper;

use File::Copy;
use File::Basename;
use File::Spec::Functions;

use Qrt::Config;
use Qrt::FileIO;
use Qrt::Observable;
use Qrt::Db;
use Qrt::Output;

=head1 NAME

Qrt::Wx::Model - The Model


=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';


=head1 SYNOPSIS

    use Qrt::Model;

    my $model = Qrt::Model->new();


=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;

    my $self = {
        _connected   => Qrt::Observable->new(),
        _stdout      => Qrt::Observable->new(),
        _itemchanged => Qrt::Observable->new(),
        _editmode    => Qrt::Observable->new(),
        _choice      => Qrt::Observable->new(),
    };

    $self->{fio} = Qrt::FileIO->new();

    bless $self, $class;

    return $self;
}

=head2 toggle_db_connect

Toggle database connection

=cut

sub toggle_db_connect {
    my $self = shift;

    if ( $self->is_connected ) {
        $self->_disconnect();
    }
    else {
        $self->_connect();
    }

    return $self;
}

=head2 _connect

Connect to the database

=cut

sub _connect {
    my $self = shift;

    # Connect to database
    $self->{_dbh} = Qrt::Db->instance->dbh;

    # Is realy connected ?
    if ( ref( $self->{_dbh} ) =~ m{DBI} ) {
        $self->get_connection_observable->set( 1 ); # yes
        $self->_print('Connected');
    }
    else {
        $self->get_connection_observable->set( 0 ); # no ;)
        $self->_print('Disconnected.');
    }
}

=head2 _disconnect

Disconnect from the database

=cut

sub _disconnect {
    my $self = shift;

    $self->{_dbh}->disconnect;
    $self->get_connection_observable->set( 0 );
    $self->_print('Disconnected.');
}

=head2 is_connected

Return true if connected

=cut

sub is_connected {
    my $self = shift;

    # TODO: What if the connection is lost?

    return $self->get_connection_observable->get;
}

=head2 get_connection_observable

Get connection observable status

=cut

sub get_connection_observable {
    my $self = shift;

    return $self->{_connected};
}

=head2 get_stdout_observable

Get STDOUT observable status

=cut

sub get_stdout_observable {
    my $self = shift;

    return $self->{_stdout};
}

=head2 _print

Put a message on a Wx text controll

=cut

sub _print {
    my ( $self, $line, $sb_id ) = @_;

    $sb_id = 0 if not defined $sb_id;

    $self->get_stdout_observable->set( "$line:$sb_id" );
}

=head2 on_item_selected

On list item selection make the event observable

=cut

sub on_item_selected {
    my $self = shift;

    $self->get_itemchanged_observable->set( 1 );
}

=head2 get_list_data

Get the titles from all the QDF files

=cut

sub get_list_data {
    my $self = shift;

    my $data_ref = $self->{fio}->get_titles();

    my $indice = 0;
    my $titles = {};

    # Format titles
    foreach my $rec ( @{$data_ref} ) {
        if (ref $rec) {
            my $nrcrt = $indice + 1;
            $titles->{$indice} = [ $nrcrt, $rec->{title}, $rec->{file} ];
            $indice++;
        }
    }

    return $titles;
}

=head2 run_export

Run SQL query and generate output data in selected data format

TODO: Check if exists and selected at least one qdf in list

=cut

sub run_export {
    my ($self, $outfile, $bind, $sql) = @_;

    $self->_print('Running...');

    my $choice = $self->get_choice();
    my (undef, $option) = split(':', $choice);

    my $cfg     = Qrt::Config->instance();
    my $out_fqn = catfile($cfg->output->{path}, $outfile);

    my $output = Qrt::Output->new();

    my ($err, $out) = $output->db_generate_output(
        $option,
        $sql,
        $bind,
        $out_fqn,
     );

    if ($err) {
        $self->_print('DB Error!');
    }
    else {
        if ($out) {
            $self->_print("$out created");
        }
    }
}

=head2 get_detail_data

Get all contents from the selected QDF title (file)

=cut

sub get_detail_data {
    my ($self, $file_fqn) = @_;

    my $ddata_ref = $self->{fio}->get_details($file_fqn);

    return $ddata_ref;
}

=head2 get_itemchanged_observable

Return observable status on item changed ???

=cut

sub get_itemchanged_observable {
    my $self = shift;

    return $self->{_itemchanged};
}

=head2 set_editmode

Set edit mode

=cut

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

=head2 set_idlemode

Set idle mode

=cut

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

=head2 is_editmode

Return true if is edit mode

=cut

sub is_editmode {
    my $self = shift;

    return $self->get_editmode_observable->get;
}

=head2 get_editmode_observable

Return edit mode observable status

=cut

sub get_editmode_observable {
    my $self = shift;

    return $self->{_editmode};
}

=head2 save_query_def

Save current query definition data from controls

=cut

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

=head2 transform_data

Transform data to be suitable to save in XML format

=cut

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

=head2 transform_para

Transform parameters data to be suitable to save in XML format

=cut

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

=head2 report_add

Create new QDF file from template

=cut

sub report_add {
    my $self = shift;

    my $reports_ref = $self->{fio}->get_file_list();

    # Find a new number to create a file name like raport-nnnnn.xml
    # Try to fill the gaps between numbers in file names
    my $files_no = scalar @{$reports_ref};

    # Search for an non existent file name ;)
    my (%numbers, $num);
    foreach my $item ( @{$reports_ref} ) {
        my $filename = basename($item);
        if ( $filename =~ m/report\-(\d{5})\.qdf/ ) {
            $num = sprintf( "%d", $1 );
            $numbers{$num} = 1;
        }
    }

    # Sort and find max
    my @numbers = sort { $a <=> $b } keys %numbers;
    my $num_max = $numbers[-1];
    $num_max = 0 if ! defined $num_max;

    # Find first gap
    my $found = 0;
    foreach my $trynum ( 1 .. $num_max ) {
        if ( not exists $numbers{$trynum} ) {
            $num = $trynum;
            $found = 1;
            last;
        }
    }
    # If gap not found, just asign the next number
    if ( $found == 0 ) {
        $num = $num_max + 1;
    }

    # Template for new qdf file names, can be anything but with
    # configured extension
    my $newqdf = 'report-' . sprintf( "%05d", $num ) . '.qdf';

    my $cfg = Qrt::Config->instance();

    my $src_fqn = $cfg->qdftmpl;
    my $dst_fqn = catfile($cfg->qdfpath, $newqdf);

    # print " $src_fqn -> $dst_fqn\n";

    if ( !-f $dst_fqn ) {
        print "Create new report from template ...";
        if ( copy( $src_fqn, $dst_fqn ) ) {
            print " done: ($newqdf)\n";
        }
        else {
            print " failed: $!\n";
            return;
        }

        # Add title and file name in list
        my $data_ref = $self->{fio}->get_title($dst_fqn);

        return $data_ref;
    }
    else {
        warn "File exists! ($dst_fqn)\n";
        $self->_print("File exists! ($dst_fqn)");
    }
}

=head2 report_remove

Remove QDF from list and from disk.  NO CONFIRMATION DIALOG yet!

TODO: Make  CONFIRMATION DIALOG

=cut

sub report_remove {
    my ($self, $file_fqn) = @_;

    # Move file to backup
    my $file_bak_fqn = "$file_fqn.bak";
    if ( move($file_fqn, $file_bak_fqn) ) {
        print "$file_fqn deleted.\n";
    }

    return;
}

=head2 set_choice

Set choice to value

=cut

sub set_choice {
    my ($self, $choice) = @_;

    $self->get_choice_observable->set($choice);
}

=head2 get_choice

Return choice to value

=cut

sub get_choice {
    my $self = shift;

    return $self->get_choice_observable->get;
}

=head2 get_choice_observable

Return choice observable status

=cut

sub get_choice_observable {
    my $self = shift;

    return $self->{_choice};
}


=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>


=head1 BUGS

None known.

Please report any bugs or feature requests to the author.


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1; # End of Qrt::Model
