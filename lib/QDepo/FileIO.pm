package QDepo::FileIO;

# ABSTRACT: The QDepo XML file operations module

use strict;
use warnings;
use Carp;

use File::Find::Rule;
use XML::Twig;
use Try::Tiny;
use Locale::TextDomain 1.20 qw(QDepo);
use QDepo::Config;
use QDepo::Utils;

sub new {
    my ( $class, $model ) = @_;
    my $self = bless( {}, $class );
    $self->{model} = $model;
    return $self;
}

sub _model {
    my $self = shift;
    return $self->{model};
}

sub _process_file {
    my ( $self, $qdf_file, $tag_name ) = @_;

    croak 'Missing "tag_name" parameter to _process_file()' unless $tag_name;
    return unless defined $qdf_file;

    my $data;
    try {
        $data = $self->_xml_read_simple( $qdf_file, $tag_name );
    }
    catch {
        $self->_model->message_log(
            __x('{qdf_file} is not a valid XML file', qdf_file => $qdf_file
            )
        );
    };

    if ( ref $data ) {
        $data->{file} = $qdf_file;
        return $data;
    }
    else {
        $self->_model->message_log(
            __x('{qdf_file} is not a valid qdf file', qdf_file => $qdf_file
            )
        );
        return;
    }
}

sub _process_all_files {
    my ( $self, $tag_name ) = @_;

    $self->{model}->message_status( __ 'Reading qdf files...' );

    my $qdf_ref = $self->get_file_list();

    my $qdf_files_no;
    if ( ref $qdf_ref ) {
        $qdf_files_no = scalar @{$qdf_ref};
    }
    else {
        $self->_model->message_status( __ 'No .qdf files to process' );
        return;
    }

    $self->{model}->message_status(
        __nx(
            'one qdf file',
            '{count} qdf files',
            $qdf_files_no,
            count => $qdf_files_no
        )
    );

    my @qdfdata;
    foreach my $qdf_file ( @{$qdf_ref} ) {
        my $data = $self->_process_file( $qdf_file, $tag_name );
        push( @qdfdata, $data );
    }

    return \@qdfdata;
}

sub _xml_read_simple {
    my ( $self, $file, $path ) = @_;

    return unless $file;

    my $twig = XML::Twig->new( twig_roots => { $path => 1 } );
    my $xml_data;

    if ( -f $file ) {
        $xml_data = $twig->parsefile($file)->simplify(
            forcearray => ['parameter'],
            keyattr    => 'id',
        );    # should parameterize options?
              # Removed group_tags => { parameters => 'parameter', },
              # because xml::twig throws an error if no parameters elements
              # are present
    }
    else {
        croak "Can't find file: $file!\n";
    }

    return $xml_data;
}

sub get_file_list {
    my $self = shift;

    my $cfg = QDepo::Config->instance();

    my $qdfpath = $cfg->qdfpath;
    my $qdfexte = 'qdf';
    if ( !-d $qdfpath ) {
        my $msg = qq{\nNonexistent mnemonic, create it with:\n\n};
        $msg .= qq{ qdepo -init };
        $msg .= $cfg->mnemonic . qq{\n\n};
        $msg .= qq{then edit: };
        $msg .= $cfg->config_file_name . qq{\n};
        croak "$msg\n";
    }

    # QDFs can NOT be arranged in subdirs
    my @qdf_files
        = File::Find::Rule->mindepth(1)->maxdepth(1)->name(qq{*.$qdfexte})
        ->file->nonempty->in($qdfpath);
    return \@qdf_files;
}

sub get_details {
    my ( $self, $file ) = @_;
    return $self->_process_file( $file, 'report' );
}

sub get_title {
    my ( $self, $file ) = @_;
    return $self->_process_file( $file, 'title' );
}

sub get_titles {
    my ($self) = @_;
    return $self->_process_all_files('title');
}

sub xml_update {
    my ( $self, $file, $rec ) = @_;

    croak "Not a valid XML file parameter\n" unless -f $file;

    my $old = $file;
    my $new = "$file.tmp.$$";
    my $bak = "$file.orig";

    # Output new file.rex
    ## no critic (RequireBriefOpen)
    open my $file_fh, '>:encoding(utf8)', $new
        or croak "Can't open file ", $new, ": $!";

    # print {$file_fh} '<?xml version="1.0" encoding="UTF-8" ?>', "\n";

    my $twig_handlers = {
        header     => sub { $self->_xml_proc_head( @_, $rec->{header} ) },
        parameters => sub { $self->_xml_proc_para( @_, $rec->{parameters} ) },
        body       => sub { $self->_xml_proc_body( @_, $rec->{body} ) },
    };

    my $twig = XML::Twig->new(
        pretty_print  => 'indented',
        twig_handlers => $twig_handlers
    );

    if ( -f $file ) {
        $twig->parsefile($file);    # build it (the twig...)
    }
    else {
        croak "No report file!\n";
    }

    # Print header to rex
    $twig->flush($file_fh);

    close $file_fh;
    ## use critic

    # Redenumeste
    rename( $old, $bak ) or croak "can't rename $old to $bak: $!";
    rename( $new, $old ) or croak "can't rename $new to $old: $!";

    return;
}

sub _xml_proc_head {
    my ( $self, $t, $elt, $rec ) = @_;
    $elt->cut_children;
    foreach my $item ( keys %{$rec} ) {
        my $ef = XML::Twig::Elt->new( $item, $rec->{$item} );
        $ef->paste( 'last_child', $elt );
    }
    return;
}

sub _xml_proc_body {
    my ( $self, $t, $elt, $rec ) = @_;
    $elt->cut_children;
    foreach my $item ( keys %{$rec} ) {
        my $ef = XML::Twig::Elt->new(
            '#CDATA' => QDepo::Utils->trim( $rec->{$item} ) )->wrap_in($item);
        $ef->paste( 'last_child', $elt );
    }
    return;
}

sub _xml_proc_para {
    my ( $self, $t, $elt, $rec ) = @_;
    $elt->cut_children;
    foreach my $item ( @{$rec} ) {
        my $ef = XML::Twig::Elt->new('parameter');
        $ef->paste( 'last_child', $elt );
        $ef->set_att( %{$item} );
    }
    return;
}

1;

=head2 new

Constructor method.

=head2 _model

Model.

=head2 _process_file

Process an XML file's tag.

=head2 _process_all_files

Loop and process all files.

=head2 _xml_read_simple

Read an XML file and return its conents as an Perl data structure.

=head2 get_file_list

Use File::Find::Rule to get all the file names from the configured path.

=head2 get_details

Process an XML file an return the contents of all the elements.

=head2 get_title

Process an XML file an return the contents of the title element.

=head2 get_titles

Process all XML files an return the contents of the title element.

=head2 xml_update

Update an XML file with the new values from record.

=head2 _xml_proc_head

Remove head element childrens, then recreate with the new values.

=head2 _xml_proc_body

Remove body element childrens, then recreate with the new values. Values are
trimmed before saving.

=head2 _xml_proc_para

Remove parameters element childrens, then recreate with the new values.

=cut
