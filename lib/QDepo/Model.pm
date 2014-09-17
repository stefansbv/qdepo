package QDepo::Model;

# ABSTRACT: The Model

use strict;
use warnings;

use File::Copy;
use File::Basename;
use File::Spec::Functions;
use SQL::Statement;
use Locale::TextDomain 1.20 qw(QDepo);
use Try::Tiny;
use QDepo::Exceptions;
use QDepo::ItemData;
use QDepo::Config;
use QDepo::FileIO;
use QDepo::Observable;
use QDepo::Db;
use QDepo::Output;
use QDepo::Utils;
use QDepo::ListDataTable;

sub new {
    my $class = shift;

    my $self = {
        _connected   => QDepo::Observable->new(),
        _stdout      => QDepo::Observable->new(),
        _message     => QDepo::Observable->new(),
        _itemchanged => QDepo::Observable->new(),
        _appmode     => QDepo::Observable->new(),
        _choice      => QDepo::Observable->new(),
        _progress    => QDepo::Observable->new(),
        _continue    => QDepo::Observable->new(),
        _cfg         => QDepo::Config->instance(),
        _dbh         => undef,
        _lds         => {},                 # list data structure
        _file        => undef,
        _itemdata    => undef,
        _dt          => {},
    };

    bless $self, $class;

    return $self;
}

sub cfg {
    my $self = shift;
    return $self->{_cfg};
}

sub dbh {
    my $self = shift;
    if ( QDepo::Db->has_instance ) {
        my $db = QDepo::Db->instance;
        if ( $self->is_connected ) {
            return $db->dbh;
        }
        else {
            Exception::Db::Connect->throw(
                logmsg  => 'Not connected',
                usermsg => 'Database error',
            );
        }
    }
    else {
        return $self->db_connect_new->dbh;
    }
    return;
}

sub dbc {
    my $self = shift;
    if ( QDepo::Db->has_instance ) {
        my $db = QDepo::Db->instance;
        if ( $self->is_connected ) {
            return $db->dbc;
        }
        else {
            Exception::Db::Connect->throw(
                logmsg  => 'Not connected',
                usermsg => 'Database error',
            );
        }
    }
    else {
        return $self->db_connect_new->dbc;
    }
    return;
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

sub db_connect_new {
    my $self = shift;
    return QDepo::Db->instance->db_connect($self);
}

sub is_connected {
    my $self = shift;
    return $self->get_connection_observable->get;
}

sub get_connection_observable {
    my $self = shift;
    return $self->{_connected};
}

sub get_stdout_observable {
    my $self = shift;
    return $self->{_stdout};
}

sub set_mode {
    my ( $self, $mode ) = @_;
    $self->get_appmode_observable->set($mode);
    return;
}

sub is_appmode {
    my ( $self, $ck_mode ) = @_;
    my $mode = $self->get_appmode_observable->get;
    return unless $mode;
    return 1 if $mode eq $ck_mode;
    return;
}

sub get_appmode_observable {
    my $self = shift;
    return $self->{_appmode};
}

sub get_appmode {
    my $self = shift;
    return $self->get_appmode_observable->get;
}

sub message_status {
    my ( $self, $line, $sb_id ) = @_;
    $sb_id = 0 if not defined $sb_id;
    $self->get_stdout_observable->set($line);
    return;
}

sub get_message_observable {
    my $self = shift;
    return $self->{_message};
}

sub message_log {
    my ( $self, $message ) = @_;
    $self->get_message_observable->set($message);
}

sub progress_update {
    my ( $self, $count ) = @_;
    $self->get_progress_observable->set($count);
}

sub get_progress_observable {
    my $self = shift;
    return $self->{_progress};
}

sub on_item_selected_load {
    my $self = shift;

    my $dt   = $self->get_data_table_for('qlist');
    my $item = $dt->get_item_selected;
    my $data = $self->get_qdf_data($item);
    $self->set_query_file( $data->{file} );
    my $itemdata = $self->read_qdf_data_file;
    $self->{_itemdata} = QDepo::ItemData->new($itemdata);
    $self->get_itemchanged_observable->set($item);

    return;
}

sub get_query_item {
    my $self = shift;
    $self->get_itemchanged_observable->get;
}

sub load_qdf_data {
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

sub append_list_record {
    my ($self, $rec, $idx) = @_;

    $rec->{nrcrt} = $idx + 1;
    $self->{_lds}{$idx} = $rec;

    return {$idx => $rec};
}

sub get_qdf_data {
    my ( $self, $item ) = @_;
    return ( defined $item )
        ? $self->{_lds}{$item}
        : $self->{_lds};
}

sub run_export {
    my $self = shift;

    my ($bind, $sqltext) = $self->get_sql_stmt;
    unless ( $bind and $sqltext ) {
        $self->message_status( 'Parameter error!', 0 );
        return;
    }

    my $outfile = $self->itemdata->output;

    $self->message_log( __x('{ert} Running data export...', ert => 'II') );

    my $outpath = $self->cfg->output();
    if ( !-d $outpath ) {
        $self->message_status(__ 'Wrong output path', 0);
        $self->message_log(
            __x('{ert} Wrong output path: {outpath}',
                outpath => $outpath,
                ert     => 'EE',
            )
        );
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
        $self->message_status(
            __x('Generated {rows} rows ({percent}%)',
                rows    => $rows,
                percent => $percent,
            )
        );
        $self->message_log(
            __x('{ert} Output generated, {rows} rows ({percent}%)',
                ert     => 'II',
                rows    => $rows,
                percent => $percent,
            )
        );
    }
    else {
        $self->message_status( __ 'No output file generated' );
        $self->message_log(
            __x( '{ert} No output file generated', ert => 'EE' ) );
    }

    $self->progress_update(0); # reset

    return;
}

sub read_qdf_data_file {
    my $self = shift;

    my $file = $self->get_query_file;
    my $fio = QDepo::FileIO->new($self);

    return $fio->get_details($file);
}

sub get_itemchanged_observable {
    my $self = shift;
    return $self->{_itemchanged};
}

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
    $self->message_log(
        __x('{ert} Saved "{name}{ext}"',
            ert  => 'II',
            name => $name,
            ext  => $ext,
        )
    );
    return;
}

sub report_add {
    my ($self, $item_new) = @_;

    die "The new item parameter is required for 'report_add'\n"
        unless defined $item_new;

    my $new_qdf_file = $self->report_name();

    my $src_fqn = $self->cfg->qdf_tmpl;
    my $dst_fqn = catfile($self->cfg->qdfpath, $new_qdf_file);

    if ( -f $dst_fqn ) {
        $self->message_log(
            __x('{ert} File exists ({dst_fqn})',
                ert     => 'WW',
                dst_fqn => $dst_fqn,
            )
        );
        return;
    }

    $self->message_log(
        __x( '{ert} Create new report from template ...', ert => 'II' ) );

    if ( copy( $src_fqn, $dst_fqn ) ) {
        $self->message_log(
            __x('{ert} Created "{new_qdf_file}"',
                ert          => 'II',
                new_qdf_file => $new_qdf_file,
            )
        );
    }
    else {
        $self->message_log(
            __x('{ert} Failed: {error}'), ert => 'EE', error => $! );
        return;
    }

    # Read the title and the file name from the new file
    my $fio      = QDepo::FileIO->new($self);
    my $data_ref = $fio->get_title($dst_fqn);

    return $self->append_list_record($data_ref, $item_new);
}

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

sub report_remove {
    my ($self, $file) = @_;                  # $item

    unless (-f $file) {
        $self->message_log( __x('{ert} "file" not found!', ert => 'EE') );
        return;
    }

    my $file_bak = "$file.bak";
    if ( move($file, $file_bak) ) {
        $self->message_log(
            __x( '{ert} Removed "{file}"', ert => 'II', file => $file ) );
        return 1;
    }
    else {
        $self->message_log(
            __x( '{ert} Remove "{file}" failed', ert => 'EE', file => $file )
        );
    }

    return;
}

sub set_choice {
    my ($self, $choice) = @_;
    $self->message_log(
        __x('{ert} Output format set to "{choice}"',
            ert    => 'II',
            choice => $choice,
        )
    );
    $self->get_choice_observable->set($choice);
}

sub get_choice {
    my $self = shift;
    return $self->get_choice_observable->get;
}

sub get_choice_observable {
    my $self = shift;
    return $self->{_choice};
}

sub string_replace_for_run {
    my ( $self, $sqltext, $params ) = @_;

    my @bind;
    foreach my $rec ( @{ $params->{parameter} } ) {
        my $value = $rec->{value};
        my $p_num = $rec->{id};         # Parameter number for bind_param
        my $var   = 'value' . $p_num;
        unless ( $sqltext =~ s/($var)/\?/pm ) {
            my $error_msg = __x('{ert} Parameter mismatch, to few parameters in SQL', ert => 'EE');
            $self->message_log($error_msg);
            return;
        }

        push( @bind, [ $p_num, $value ] );
    }

    # Check for remaining not substituted 'value[0-9]' in SQL
    if ( $sqltext =~ m{(value[0-9])}pm ) {
        my $error_msg = __x('{ert} Parameter mismatch, to many parameters in SQL', ert => 'EE');
        $self->message_log($error_msg);
        return;
    }

    return ( \@bind, $sqltext );
}

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

sub get_continue_observable {
    my $self = shift;
    return $self->{_continue};
}

sub set_continue {
    my ( $self, $cont ) = @_;
    $self->get_continue_observable->set($cont);
    return;
}

### Virtual lists meta data

sub list_meta_data {
    my ($self, $list) = @_;
    return
          $list eq q{}     ? undef
        : $list eq 'qlist' ? $self->get_query_list_meta
        : $list eq 'dlist' ? $self->get_conn_list_meta
        : $list eq 'tlist' ? $self->get_field_list_meta
        :                    undef
        ;
}

sub get_query_list_meta {
    return [
        {   field => 'nrcrt',
            label => '#',
            align => 'left',
            width => 50,
        },
        {   field => 'title',
            label => __ 'Query name',
            align => 'left',
            width => 345,
        },
    ];
}

sub get_field_list_meta {
    return [
        {   field => 'recno',
            label => '#',
            align => 'left',
            width => 50,
        },
        {   field => 'field',
            label => __ 'Name',
            align => 'left',
            width => 150,
        },
        {   field => 'type',
            label => __ 'Type',
            align => 'left',
            width => 195,
        },
    ];
}

sub get_conn_list_meta {
    return [
        {   field => 'recno',
            label => '#',
            align => 'left',
            width => 50,
        },
        {   field => 'mnemonic',
            label => __ 'Mnemonic',
            align => 'left',
            width => 100,
        },
        {   field => 'default',
            label => __ 'Default',
            align => 'left',
            width => 60,
        },
        {   field => 'description',
            label => __ 'Description',
            align => 'left',
            width => 185,
        },
    ];
}

###

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

sub get_sql_stmt {
    my $self = shift;
    my ($bind, $sql) = $self->string_replace_for_run(
        $self->itemdata->sql,
        $self->itemdata->params,
    );
    $sql =~ s{;$}{}m;                    # remove final ';' if exists
    return ($bind, $sql);
}

sub get_columns_list {
    my $self = shift;

    my $parser = SQL::Parser->new('AnyData', { RaiseError => 1 } );

    my ($bind, $sql_text) = $self->get_sql_stmt;

    try {
        $parser->parse($sql_text) or die $@;
    }
    catch {
        Exception::Db::SQL::Parser->throw(
            logmsg  => $_,
            usermsg => 'SQL parser error',
        );
    };

    #-- Table
    my $tables_ref = $parser->structure->{org_table_names};
    my $table      = $tables_ref->[0];
    if ($table) {
        unless ( $self->dbc->table_exists($table) ) {
            my $msg
                = __x( 'The {table} table does not exists', table => $table );
            Exception::Db::SQL::Parser->throw(
                logmsg  => $msg,
                usermsg => 'SQL parser error',
            );
        }
    }
    else {
        Exception::Db::SQL::Parser->throw(
            logmsg  => __ 'Can not parse the name of the table',
            usermsg => 'SQL parser error',
        );
    }

    #-- Columns
    my $all_cols_href;
    if ( $self->dbc->can('table_info_short') ) {
        $all_cols_href = $self->dbc->table_info_short($table);
    }
    else {
        $self->message_log(
            __x( '{ert} Not implemented: "table_info_short"', ert => 'II' ) );
        return;
    }
    my $sql_cols_aref = $parser->structure->{org_col_names};

    # When using: SELECT * FROM...
    unless (ref $sql_cols_aref) {
        $sql_cols_aref = QDepo::Utils->sort_hash_by('pos', $all_cols_href);
    }

    my $cols_aref;
    my $row = 0;
    foreach my $field ( @{$sql_cols_aref} ) {
        my $type = $all_cols_href->{$field}{type};
        push @{$cols_aref}, { field => $field, type => $type, recno => $row };
        $row++
    }

    return ($cols_aref, $sql_cols_aref);
}

sub dlist_default_item {
    my $self = shift;

    my $mnemonx = $self->cfg->get_mnemonics;
    my $default = $self->cfg->get_default_mnemonic;
    my ($idx, $item) = (0, undef);
    foreach my $mnx ( @{$mnemonx} ) {
        if ($mnx->{mnemonic} eq $default) {
            $item = $idx;
            last;
        }
        $idx++;
    }

    my $dt = $self->get_data_table_for('dlist');
    $dt->set_item_default($item);

    return $item;
}

1;

=head2 _cfg

Return config instance variable

=head2 dbh

Return the database handler.

=head2 dbc

Return the Connection module handler.

=head2 db_connect_new

Database connection instance.  Connect to database or retry to connect.

=head2 is_connected

Return true if connected

=head2 get_connection_observable

Get connection observable status

=head2 get_stdout_observable

Get STDOUT observable status.

=head2 set_mode

Set mode

=head2 is_appmode

Return true if application mode is L<$ck_mode>.

=head2 get_appmode_observable

Return add mode observable status

=head2 get_appmode

Return application mode

=head2 message_status

Put a message on the status bar.

=head2 get_message_observable

Get message observable object.

=head2 message_log

Log a user message on a Tk/Wx text controll.

=head2 progress_update

Update progress value.

=head2 get_progress_observable

Get progres observable status.

=head2 on_item_selected_load

On list item selection make the event observable and store the item
index.

=head2 get_query_item

Get the item index.

=head2 load_qdf_data

Read the titles and file names from all the QDF files and store in
a data structure used to fill the List control.

=head2 append_list_record

Return a new record for the list data structure.

=head2 get_qdf_data

Get data from List data structure, for single item or all.

=head2 run_export

Run SQL query and generate output data in selected data format

=head2 read_qdf_data_file

Get all contents from the selected QDF title (file).

=head2 get_itemchanged_observable

Return observable status on item changed.

=head2 write_qdf_data_file

Save current query definition data from controls into a qdf file.

=head2 report_add

Create new QDF file from template.  The L<$item_new> parameter is
mandatory.

=head2 report_name

Create report name.  Find a new number to create a file name like
raport-nnnnn.xml Try to fill the gaps between numbers in file names

=head2 report_remove

Remove B<.qdf> file from list and from disk.  Have to confirm the
action first, to get here.  For safety, the file is renamed with a
B<.bak> extension, so it can be I<manualy> recovered.

=head2 set_choice

Set choice to value

=head2 get_choice

Return choice to value

=head2 get_choice_observable

Return choice observable status.

=head2 string_replace_for_run

Prepare SQL text string for execution.  Replace the 'valueN' string
with '?'.  Create an array of parameter values, used for binding.

Need to check if number of parameters match number of 'valueN' strings
in SQL statement text and print an error if not.

=head2 string_replace_pos

Replace string pos.

=head2 get_continue_observable

Get continue operation observable status.  Flag used by the progress
indicator to stop the output file generation process.

=head2 set_continue

Set continue to false if Cancel button on the progress dialog is
activated (Wx only).

=head2 get_columns_list

The list of the columns.

First parse the SQL query and get the column list from it.  If it has
a column list return it, if not (for ex. when using: SELECT * FROM...)
than use the table info to get the column list and return that
instead.

=cut
