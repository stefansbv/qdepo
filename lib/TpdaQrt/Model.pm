package TpdaQrt::Model;

use strict;
use warnings;

use Data::Dumper;
use Ouch;

use File::Copy;
use File::Basename;
use File::Spec::Functions;
use Scalar::Util qw(blessed);

use TpdaQrt::Config;
use TpdaQrt::FileIO;
use TpdaQrt::Observable;
use TpdaQrt::Db;
use TpdaQrt::Output;
use TpdaQrt::Utils;

=head1 NAME

TpdaQrt::Wx::Model - The Model.

=head1 VERSION

Version 0.34

=cut

our $VERSION = '0.34';

=head1 SYNOPSIS

    use TpdaQrt::Model;

    my $model = TpdaQrt::Model->new();


=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;

    my $self = {
        _connected   => TpdaQrt::Observable->new(),
        _stdout      => TpdaQrt::Observable->new(),
        _message     => TpdaQrt::Observable->new(),
        _exception   => TpdaQrt::Observable->new(),
        _itemchanged => TpdaQrt::Observable->new(),
        _appmode     => TpdaQrt::Observable->new(),
        _choice      => TpdaQrt::Observable->new(),
        _progress    => TpdaQrt::Observable->new(),
        _cfg         => TpdaQrt::Config->instance(),
        _lds         => {},                 # list data structure
        _marks       => 0,
    };

    $self->{fio} = TpdaQrt::FileIO->new();

    bless $self, $class;

    return $self;
}

=head2 _cfg

Return config instance variable

=cut

sub _cfg {
    my $self = shift;

    return $self->{_cfg};
}

=head2 db_connect

Database connection

=cut

sub db_connect {
    my $self = shift;

    # Connect to database or retry to connect
    if (TpdaQrt::Db->has_instance) {
        $self->{_dbh} = TpdaQrt::Db->instance->db_connect($self)->dbh;
    }
    else {
        $self->{_dbh} = TpdaQrt::Db->instance($self)->dbh;
    }

    my $conninfo = $self->_cfg->conninfo;
    my $driver = $conninfo->{driver};
    my $dbname = $conninfo->{dbname};
    my $host   = $conninfo->{host} || 'localhost';

    # Is realy connected ?
    if ( blessed $self->{_dbh} and $self->{_dbh}->isa('DBI::db') ) {
        $self->get_connection_observable->set(1);    # assuming yes
        $self->message_log("II Connected to \"$dbname\" with '$driver', on '$host'");
    }
    else {
        $self->get_connection_observable->set(0);    # no ;)
        $self->message_log("EE Connection to '$dbname' failed");
    }

    return $self;
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

Get STDOUT observable status.

=cut

sub get_stdout_observable {
    my $self = shift;

    return $self->{_stdout};
}


=head2 set_mode

Set mode

=cut

sub set_mode {
    my ( $self, $mode ) = @_;

    $self->get_appmode_observable->set($mode);

    return;
}

=head2 is_appmode

Return true if application mode is L<$ck_mode>.

=cut

sub is_appmode {
    my ( $self, $ck_mode ) = @_;

    my $mode = $self->get_appmode_observable->get;

    return unless $mode;

    return 1 if $mode eq $ck_mode;

    return;
}

=head2 get_appmode_observable

Return add mode observable status

=cut

sub get_appmode_observable {
    my $self = shift;

    return $self->{_appmode};
}

=head2 get_appmode

Return application mode

=cut

sub get_appmode {
    my $self = shift;

    return $self->get_appmode_observable->get;
}

=head2 message_status

Put a message on the status bar.

=cut

sub message_status {
    my ( $self, $line, $sb_id ) = @_;

    $sb_id = 0 if not defined $sb_id;

    $self->get_stdout_observable->set($line);

    return;
}

=head2 get_message_observable

Get message observable object.

=cut

sub get_message_observable {
    my $self = shift;

    return $self->{_message};
}

=head2 message_log

Log a user message on a Tk/Wx text controll.

=cut

sub message_log {
    my ( $self, $message ) = @_;

    $self->get_message_observable->set($message);
}

=head2 progress_update

Update progress value.

=cut

sub progress_update {
    my ( $self, $count ) = @_;

    $self->get_progress_observable->set($count);
}

=head2 get_progress_observable

Get progres observable status.

=cut

sub get_progress_observable {
    my $self = shift;

    return $self->{_progress};
}

=head2 on_item_selected

On list item selection make the event observable.

=cut

sub on_item_selected {
    my $self = shift;

    $self->get_itemchanged_observable->set( 1 );
}

=head2 load_qdf_data_wx

Return the titles and file names from all the QDF files to fill the
List control. Th Wx List control has a feature to store data in the
controls, so we don't need a data structure in the Model.

=cut

sub load_qdf_data_wx {
    my $self = shift;

    my $data_ref = $self->{fio}->get_titles();

    my $indecs = 0;
    my $titles = {};

    # Format titles
    foreach my $rec ( @{$data_ref} ) {
        if (ref $rec) {

            # Make records
            $titles->{$indecs} = $rec;
            $titles->{$indecs}{nrcrt} = $indecs + 1;
            $indecs++;
        }
    }

    return $titles;
}

=head2 read_qdf_data_tk

Read the titles and file names from all the QDF files and store in
a data structure used to fill the List control.

=cut

sub read_qdf_data_tk {
    my $self = shift;

    my $data_ref = $self->{fio}->get_titles();

    my $indecs = 0;
    my $titles = {};

    # Format titles
    foreach my $rec ( @{$data_ref} ) {
        if (ref $rec) {

            # Store records
            $self->{_lds}{$indecs} = $rec;
            $self->{_lds}{$indecs}{nrcrt} = $indecs + 1;

            $indecs++;
        }
    }

    return;
}

=head2 append_list_record_wx

Return a new record for the list data structure.

=cut

sub append_list_record_wx {
    my ($self, $rec, $idx) = @_;

    $rec->{nrcrt} = $idx + 1;
    $self->{_lds}{$idx} = $rec;

    return {$idx => $rec};
}

=head2 append_list_record_tk

Append and return a new record in the list data structure.

=cut

sub append_list_record_tk {
    my ($self, $rec) = @_;

    my @items = sort keys %{ $self->{_lds} };
    my $idx = scalar @items == 0 ? 0 : $#items + 1;

    $rec->{nrcrt} = $idx + 1;
    $self->{_lds}{$idx} = $rec;

    return {$idx => $rec};
}

=head2 get_qdf_data_tk

Get data from List data structure, for single item or all.  Toggle
delete mark on items if L<$toggle_mark> parameter is true.

=cut

sub get_qdf_data_tk {
    my ( $self, $item, $toggle_mark ) = @_;

    my $data;
    if ( defined $item ) {
        $self->toggle_mark($item) if $toggle_mark;
        $data = $self->{_lds}{$item};
    }
    else {
        $data = $self->{_lds};
    }

    return $data;
}

=head2 toggle_mark

Toggle deleted mark on list item.

=cut

sub toggle_mark {
    my ($self, $item) = @_;

    if ( exists $self->{_lds}{$item}{mark} ) {
        $self->{_lds}{$item}{mark} == 1
            ? ($self->{_lds}{$item}{mark} = 0)
            : ($self->{_lds}{$item}{mark} = 1)
            ;
    }
    else {
        $self->{_lds}{$item}{mark} = 1; # set mark
    }

    # Keep a count of marks
    $self->{_lds}{$item}{mark} == 1
        ? $self->{_marks}++
        : $self->{_marks}--
        ;

    return;
}

=head2 get_qdf_data_file_tk

Get data file full path from data structure attached to the  List.

=cut

sub get_qdf_data_file_tk {
    my ($self, $item) = @_;

    return unless defined $item;

    return $self->{_lds}{$item}{file};
}

=head2 run_export

Run SQL query and generate output data in selected data format

TODO: Check if exists and selected at least one qdf in list

=cut

sub run_export {
    my ($self, $data) = @_;

    my ($bind, $sqltext) = $self->string_replace_for_run(
        $data->{body}{sql},
        $data->{parameters},
    );

    my $outfile = $data->{header}{output};

    $self->message_log('II Running data export ...');

    my $outpath = $self->_cfg->output->{path};
    if ( !-d $outpath ) {
        $self->message_status('Wrong output path!', 0);
        $self->message_log("EE Wrong output path '$outpath'");
        return;
    }

    my $option = $self->get_choice();

    my $out_fqn = catfile($outpath, $outfile);

    my $output = TpdaQrt::Output->new($self);

    # trim SQL text;
    $sqltext = TpdaQrt::Utils->trim($sqltext);

    my $out = $output->db_generate_output(
        $option,
        $sqltext,
        $bind,
        $out_fqn,
    );

    if ($out) {
        $self->message_status("Output generated");
        $self->message_log("II '$out' generated");
    }
    else {
        $self->message_status("No output file generated");
        $self->message_log("EE No output file generated");
    }

    $self->progress_update(0); # reset

    return;
}

=head2 read_qdf_data

Get all contents from the selected QDF title (file).

For Wx the file parameter is required.

=cut

sub read_qdf_data {
    my ($self, $item, $file) = @_;

    $file ||= $self->get_qdf_data_file_tk($item);

    my $ddata_ref = $self->{fio}->get_details($file);

    return ( $ddata_ref, $file );
}

=head2 get_itemchanged_observable

Return observable status on item changed ???

=cut

sub get_itemchanged_observable {
    my $self = shift;

    return $self->{_itemchanged};
}

=head2 save_qdf_file

Save current query definition data from controls into a qdf file.

=cut

sub save_qdf_file {
    my ($self, $item, $head, $para, $body) = @_;

    my $file = $self->get_qdf_data_file_tk($item);

    # Transform records to match data in xml format
    $head = TpdaQrt::Utils->transform_data($head);
    $para = TpdaQrt::Utils->transform_para($para);
    $body = TpdaQrt::Utils->transform_data($body);

    # Asemble data
    my $record = {
        header     => $head,
        parameters => $para,
        body       => $body,
    };

    $self->{fio}->xml_update($file, $record);

    my ($name, $path, $ext) = fileparse( $file, qr/\.[^\.]*/ );
    $self->message_log("II Saved '${name}$ext'");

    return;
}

=head2 report_add

Create new QDF file from template.

If the L<$items_no> parameter is defined, then the Wx interface is used.

=cut

sub report_add {
    my ($self, $items_no) = @_;

    my $new_qdf_file = $self->report_name();

    my $src_fqn = $self->_cfg->qdftemplate;
    my $dst_fqn = catfile($self->_cfg->qdfpath, $new_qdf_file);

    print "Add *************\n";
    print "$src_fqn -> $dst_fqn\n";

    if ( !-f $dst_fqn ) {
        $self->message_log("II Create new report from template ...");
        if ( copy( $src_fqn, $dst_fqn ) ) {
            $self->message_log("II Made: '$new_qdf_file'");
        }
        else {
            $self->message_log("EE Failed: $!");
            return;
        }

        # Read the title and the file name from the new file
        my $data_ref = $self->{fio}->get_title($dst_fqn);

        if (defined $items_no) {
            $data_ref = $self->append_list_record_wx($data_ref, $items_no);
        }
        else {
            $data_ref = $self->append_list_record_tk($data_ref);
        }

        return $data_ref;
    }
    else {
        $self->message_log("WW File exists! ($dst_fqn)");
        ouch 'FileExists', "File exists! ($dst_fqn)";

        return;
    }
}

=head2 report_name

Create report name.
Find a new number to create a file name like raport-nnnnn.xml
Try to fill the gaps between numbers in file names

=cut

sub report_name {
    my $self = shift;

    my $reports_ref = $self->{fio}->get_file_list();

    my $files_no = scalar @{$reports_ref};

    # Search for an non existent file name ;)
    my ( %numbers, $num );
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
    $num_max = 0 if !defined $num_max;

    # Find first gap
    my $found = 0;
    foreach my $trynum ( 1 .. $num_max ) {
        if ( not exists $numbers{$trynum} ) {
            $num   = $trynum;
            $found = 1;
            last;
        }
    }

    # If gap not found, just asign the next number
    if ( $found == 0 ) {
        $num = $num_max + 1;
    }

    # Template for new qdf file names, can be anything but with
    # the configured extension (.qdf)
    my $new_qdf_file = 'report-' . sprintf( "%05d", $num ) . '.qdf';

    return $new_qdf_file;
}

=head2 report_remove

Remove B<.qdf> file from list and from disk.  Have to confirm the
action first, to get here.  For safety, the file is renamed with a
B<.bak> extension, so it can be I<manualy> recovered.

=cut

sub report_remove {
    my ($self, $file) = @_;                  # $item

    unless (-f $file) {
        $self->message_log("EE '$file' not found!");
        return;
    }

    # Rename file as backup
    my $file_bak = "$file.bak";
    if ( move($file, $file_bak) ) {
        $self->message_log("WW '$file' deleted");
        return 1;
    }

    return;
}

=head2 set_choice

Set choice to value

=cut

sub set_choice {
    my ($self, $choice) = @_;

    $self->message_log("II Output format set to '$choice'");

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

Return choice observable status.

=cut

sub get_choice_observable {
    my $self = shift;

    return $self->{_choice};
}

=head2 string_replace_for_run

Prepare sql text string for execution.  Replace the 'valueN' string
with with '?'.  Create an array of parameter values, used for binding.

Need to check if number of parameters match number of 'valueN' strings
in SQL statement text and print an error if not.

=cut

sub string_replace_for_run {
    my ( $self, $sqltext, $params ) = @_;

    my @bind;
    foreach my $rec ( @{ $params->{parameter} } ) {
        my $value = $rec->{value};
        my $p_num = $rec->{id};         # Parameter number for bind_param
        my $var   = 'value' . $p_num;
        unless ( $sqltext =~ s/($var)/\?/pm ) {
            $self->log_msg("EE Parameter mismatch, to few parameters in SQL");
            return;
        }

        push( @bind, [ $p_num, $value ] );
    }

    # Check for remaining not substituted 'value[0-9]' in SQL
    if ( $sqltext =~ m{(value[0-9])}pm ) {
        $self->log_msg("EE Parameter mismatch, to many parameters in SQL");
        return;
    }

    return ( \@bind, $sqltext );
}


=head2 string_replace_pos

Replace string pos.

=cut

sub string_replace_pos {
    my ($self, $text, $params) = @_;

    my @strpos;

    while (my ($key, $value) = each ( %{$params} ) ) {
        next unless $key =~ m{value[0-9]}; # Skip 'descr'

        # Replace  text and return the strpos
        $text =~ s/($key)/$value/pm;
        my $pos = $-[0];
        push(@strpos, [ $pos, $key, $value ]);
    }

    # Sorted by $pos
    my @sortedpos = sort { $a->[0] <=> $b->[0] } @strpos;

    return ($text, \@sortedpos);
}

=head2 get_exception_observable

Get exception observable status.

=cut

sub get_exception_observable {
    my $self = shift;

    return $self->{_exception};
}

=head2 exception_log

Log an exception.

=cut

sub exception_log {
    my ( $self, $message ) = @_;
print " exception_log set $message\n";
    $self->get_exception_observable->set($message);
}

=head2 get_exception

Get exception message and then clear it.

=cut

sub get_exception {
    my $self = shift;

    my $exception = $self->get_exception_observable->get;
print "get exc $exception\n";
    $self->get_exception_observable->set();  # clear

    return $exception;
}

=head2 has_marks

Return true if there are items marked for deletion.

=cut

sub has_marks {
    my $self = shift;

    print "$self->{_marks} marks.\n";

    return $self->{_marks} > 0 ? 1 : 0;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of TpdaQrt::Model
