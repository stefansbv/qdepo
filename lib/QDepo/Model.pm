package QDepo::Model;

use strict;
use warnings;

use File::Copy;
use File::Basename;
use File::Spec::Functions;
use SQL::Statement;
use Scalar::Util qw(blessed);

use QDepo::ItemData;
use QDepo::Config;
use QDepo::FileIO;
use QDepo::Observable;
use QDepo::Db;
use QDepo::Output;
use QDepo::Utils;
use QDepo::ListDataTable;

use Data::Printer;

=head1 NAME

QDepo::Wx::Model - The Model.

=head1 VERSION

Version 0.39

=cut

our $VERSION = '0.39';

=head1 SYNOPSIS

    use QDepo::Model;

    my $model = QDepo::Model->new();


=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;

    my $self = {
        _connected   => QDepo::Observable->new(),
        _stdout      => QDepo::Observable->new(),
        _message     => QDepo::Observable->new(),
        _exception   => QDepo::Observable->new(),
        _itemchanged => QDepo::Observable->new(),
        _appmode     => QDepo::Observable->new(),
        _choice      => QDepo::Observable->new(),
        _progress    => QDepo::Observable->new(),
        _continue    => QDepo::Observable->new(),
        _cfg         => QDepo::Config->instance(),
        _dbh         => undef,
        _lds         => {},                 # list data structure
        _marks       => 0,
        _file        => undef,
        _itemdata    => undef,
        _dt          => {},
    };

    bless $self, $class;

    return $self;
}

=head2 _cfg

Return config instance variable

=cut

sub cfg {
    my $self = shift;
    return $self->{_cfg};
}

sub dbh {
    my $self = shift;
    return $self->{_dbh};
}

=head2 dbc

Return the Connection module handler.

=cut

sub dbc {
    my $self = shift;
    my $db = QDepo::Db->instance;
    return $db->dbc;
}

sub itemdata {
    my $self = shift;
    return $self->{_itemdata};
}

sub get_query_file {
    my $self = shift;
    return $self->{_file};
}

sub set_query_file {
    my ($self, $file) = @_;
    $self->{_file} = $file;
    return;
}

=head2 db_connect

Database connection.  Connect to database or retry to connect.

=cut

sub db_connect {
    my $self = shift;

    if (QDepo::Db->has_instance) {
        $self->{_dbh} = QDepo::Db->instance->db_connect($self)->dbh;
    }
    else {
        $self->{_dbh} = QDepo::Db->instance($self)->dbh;
    }

    return;
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

=head2 on_item_selected_load

On list item selection make the event observable and store the item
index.

=cut

sub on_item_selected_load {
    my ($self, $item) = @_;

    my $data = $self->get_qdf_data_tk($item);
    $self->set_query_file( $data->{file} );
    my $itemdata = $self->read_qdf_data_file;
    $self->{_itemdata} = QDepo::ItemData->new($itemdata);
    $self->get_itemchanged_observable->set($item);

    return;
}

=head2 get_query_item

Get the item index.

=cut

sub get_query_item {
    my $self = shift;
    $self->get_itemchanged_observable->get;
}

=head2 load_qdf_data_wx

Return the titles and file names from all the QDF files to fill the
List control. The Wx List control has a feature to store data in the
controls, so we don't need a data structure in the Model.

=cut

# sub load_qdf_data_wx {
#     my $self = shift;

#     my $fio = QDepo::FileIO->new($self);

#     my $data_ref = $fio->get_titles();

#     my $indecs = 0;
#     my $titles = {};

#     # Format titles
#     foreach my $rec ( @{$data_ref} ) {
#         if (ref $rec) {

#             # Make records
#             $titles->{$indecs} = $rec;
#             $titles->{$indecs}{nrcrt} = $indecs + 1;
#             $indecs++;
#         }
#     }

#     return $titles;
# }

=head2 load_qdf_data_tk

Read the titles and file names from all the QDF files and store in
a data structure used to fill the List control.

=cut

sub load_qdf_data_tk {
    my $self = shift;

    my $fio = QDepo::FileIO->new($self);

    my $data_ref = $fio->get_titles();

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

sub get_sql_stmt {
    my $self = shift;

    my ($bind, $sql) = $self->string_replace_for_run(
        $self->itemdata->sql,
        $self->itemdata->params,
    );
    $sql =~ s{;$}{}m;                         # remove final ';'

    return ($bind, $sql);
}

sub get_columns_list {
    my $self = shift;

    my $parser = SQL::Parser->new();

    my ($bind, $sql_text) = $self->get_sql_stmt;

    $parser->parse($sql_text);

    #-- Table
    my $tables_ref   = $parser->structure->{org_table_names};
    my $table = $tables_ref->[0];

    #-- Columns
    my $all_cols_ref;
    if ( $self->dbc->can('table_info_short') ) {
        $all_cols_ref = $self->dbc->table_info_short($table);
    }
    else {
        $self->message_log("WW Not implemented: 'table_info_short'");
    }
    my $sql_cols_ref = $parser->structure->{org_col_names};
    unless (ref $sql_cols_ref) {
        print "get cols in other way...\n";
    }

    # p $all_cols_ref;
    # p $sql_cols_ref;

    my $cols_list;
    foreach my $field (@$sql_cols_ref) {
        my $type = $all_cols_ref->{$field}{type};
        push @$cols_list, { name => $field, type => $type };
    }

    p $cols_list;

    return $cols_list;
}

=head2 run_export

Run SQL query and generate output data in selected data format

TODO: Check if exists and selected at least one qdf in list

=cut

sub run_export {
    my $self = shift;

    my ($bind, $sqltext) = $self->get_sql_stmt;
    unless ( $bind and $sqltext ) {
        $self->message_status( 'Parameter error!', 0 );
        return;
    }

    my $outfile = $self->itemdata->output;

    $self->message_log('II Running data export ...');

    my $outpath = $self->cfg->output();
    if ( !-d $outpath ) {
        $self->message_status('Wrong output path!', 0);
        $self->message_log("EE Wrong output path: '$outpath'");
        return;
    }

    my $option  = $self->get_choice();
    my $out_fqn = catfile($outpath, $outfile);
    my $output  = QDepo::Output->new($self);

    # trim SQL text;
    $sqltext = QDepo::Utils->trim($sqltext);

    my $out = $output->db_generate_output(
        $option,
        $sqltext,
        $bind,
        $out_fqn,
    );

    return unless ref $out;

    my ($file, $rows, $percent) = @{$out};
    $rows    = defined $rows    ? $rows    : '?';
    $percent = defined $percent ? $percent : '?';
    if ($file) {
        $self->message_status("Generated, $rows rows ($percent%)");
        $self->message_log("II Output generated, $rows rows ($percent%)");
    }
    else {
        $self->message_status("No output file generated");
        $self->message_log("EE No output file generated");
    }

    $self->progress_update(0); # reset

    return;
}

=head2 read_qdf_data_file

Get all contents from the selected QDF title (file).

=cut

sub read_qdf_data_file {
    my $self = shift;

    #$file ||= $self->get_qdf_data_file_tk($item); ??? Tk
    my $file = $self->get_query_file;
    my $fio = QDepo::FileIO->new($self);

    return $fio->get_details($file);
}

=head2 get_itemchanged_observable

Return observable status on item changed ???

=cut

sub get_itemchanged_observable {
    my $self = shift;

    return $self->{_itemchanged};
}

=head2 write_qdf_data_file

Save current query definition data from controls into a qdf file.

=cut

sub write_qdf_data_file {
    my ($self, $file, $head, $para, $body) = @_;

    # Transform records to match data in xml format
    $head = QDepo::Utils->transform_data($head);
    $para = QDepo::Utils->transform_para($para);
    $body = QDepo::Utils->transform_data($body);

    # Asemble data
    my $record = {
        header     => $head,
        parameters => $para,
        body       => $body,
    };

    my $fio = QDepo::FileIO->new($self);
    $fio->xml_update($file, $record);

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

    my $src_fqn = $self->cfg->qdf_tmpl;
    my $dst_fqn = catfile($self->cfg->qdfpath, $new_qdf_file);

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
        my $fio = QDepo::FileIO->new($self);
        my $data_ref = $fio->get_title($dst_fqn);

        if (defined $items_no) {
            $data_ref = $self->append_list_record_wx($data_ref, $items_no);
        }
        else {
            $data_ref = $self->append_list_record_tk($data_ref);
        }

        return $data_ref;
    }
    else {
        $self->message_log("EE File exists! ($dst_fqn)");
    }

    return;
}

=head2 report_name

Create report name.
Find a new number to create a file name like raport-nnnnn.xml
Try to fill the gaps between numbers in file names

=cut

sub report_name {
    my $self = shift;

    my $fio = QDepo::FileIO->new($self);

    my $reports_ref = $fio->get_file_list();

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

    print "Remove '$file' ";
    # Rename file as backup
    my $file_bak = "$file.bak";
    if ( move($file, $file_bak) ) {
        print " done\n";
        return 1;
    }
    else {
        print " failed\n";
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

Prepare SQL text string for execution.  Replace the 'valueN' string
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
            my $error_msg = "EE Parameter mismatch, to few parameters in SQL";
            $self->message_log($error_msg);
            return;
        }

        push( @bind, [ $p_num, $value ] );
    }

    # Check for remaining not substituted 'value[0-9]' in SQL
    if ( $sqltext =~ m{(value[0-9])}pm ) {
        my $error_msg = "EE Parameter mismatch, to many parameters in SQL";
        $self->message_log($error_msg);
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
    $self->get_exception_observable->set($message);
}

=head2 get_exception

Get exception message and then clear it.

=cut

sub get_exception {
    my $self = shift;
    my $exception = $self->get_exception_observable->get;
    $self->get_exception_observable->set();  # clear
    return $exception;
}

=head2 get_continue_observable

Get continue operation observable status.  Flag used by the progress
indicator to stop the output file generation process.

=cut

sub get_continue_observable {
    my $self = shift;
    return $self->{_continue};
}

=head2 set_continue

Set continue to false if Cancel button on the progress dialog is
activated (Wx only).

=cut

sub set_continue {
    my ( $self, $cont ) = @_;
    $self->get_continue_observable->set($cont);
    return;
}

=head2 has_marks

Return true if there are items marked for deletion.

=cut

sub has_marks {
    my $self = shift;
    return $self->{_marks} > 0 ? 1 : 0;
}

sub report_cols_list {
    my $self = shift;
    return [
        {   field => 'nrcrt',
            label => '#',
            align => 'left',
            width => 50,
        },
        {   field => 'title',
            label => 'Query name',
            align => 'left',
            width => 345,
        },
    ];
}

sub init_header {
    my $self = shift;
    return $self->report_cols_list;
}

sub init_data_table {
    my ($self, $list) = @_;
    die "List name is required for 'init_data_table'" unless $list;
    $self->{_dt}{$list} = QDepo::ListDataTable->new;
    return;
}

sub get_data_table_for {
    my ($self, $list) = @_;
    die "List name is required for 'init_data_table'" unless $list;
    return $self->{_dt}{$list};
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

1; # End of QDepo::Model
