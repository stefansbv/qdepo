package TpdaQrt::FileIO;

use strict;
use warnings;
use Carp;

use File::Find::Rule;
use XML::Twig;

use TpdaQrt::Config;

=head1 NAME

TpdaQrt::FileIO - Tpda TpdaQrt XML file operations module

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use TpdaQrt::FileIO;

    my $app = TpdaQrt::FileIO->new();

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;

    my $self = bless( {}, $class );

    return $self;
}

=head2 _process_file

Process an XML file's tag.

=cut

sub _process_file {

    my ($self, $qdf_file, $tag_name) = @_;

    if (! defined $qdf_file) {
        print "No report definition file?.\n";
        return;
    }

    my $data;
    eval {
        $data = $self->_xml_read_simple($qdf_file, $tag_name);
    };
    if ($@) {
        print "> $qdf_file: Not valid XML!\n";
    } else {
        if (ref $data) {
            $data->{file} = $qdf_file;
            return $data;
        }
        else {
            print "$qdf_file: Not valid query file!\n";
            return;
        }
    }
}

=head2 _process_all_files

Loop and process all files.

=cut

sub _process_all_files {

    my ($self, $tag_name) = @_;

    my $qdf_ref = $self->get_file_list();

    if (! defined $qdf_ref) {
        print "No query definition files.\n";
        return;
    }

    print "\nReading XML files...\n";
    print scalar @{$qdf_ref}, " query definition files found.\n";

    my @qdfdata;
    foreach my $qdf_file ( @{$qdf_ref} ) {
        my $data = $self->_process_file( $qdf_file, $tag_name );
        push( @qdfdata, $data );
    }

    return \@qdfdata;
}

=head2 _xml_read_simple

Read an XML file and return its conents as an Perl data structure.

=cut

sub _xml_read_simple {
    my ($self, $file, $path) = @_;

    return unless $file;

    my $twig = XML::Twig->new( twig_roots => { $path => 1 } );
    my $xml_data;

    if ( -f $file ) {
        $xml_data = $twig->parsefile( $file )->simplify(
            forcearray => [ 'parameter' ],
            keyattr    => 'id',
        );                      # should parameterize options?
        # Removed group_tags => { parameters => 'parameter', },
        # because xml::twig throws an error if no parameters elements
        # are present
    }
    else {
        croak "Can't find file: $file!\n";
    }

    return $xml_data;
}

=head2 get_file_list

Use File::Find::Rule to get all the file names from the configured
path.

=cut

sub get_file_list {
    my $self = shift;

    my $cfg = TpdaQrt::Config->instance();

    my $qdfpath = $cfg->qdfpath;
    my $qdfexte = $cfg->qdfexte;
    if ( !-d $qdfpath ) {
        my $msg = qq{\nWrong path for '$qdfexte' files:\n $qdfpath!\n};
        $msg   .= qq{\nConfiguration error, try to fix with\n\n};
        $msg   .= qq{ qrt -init };
        $msg   .= $cfg->cfgname . qq{\n\n};
        $msg   .= qq{then edit: };
        $msg   .=  $cfg->cfgconnf . qq{\n};
        print $msg;
        die;
    }

    # Report definition files can be arranged in subdirs; recursive find
    my @rapoarte = File::Find::Rule
        ->name( qq{*.$qdfexte} )
        ->file
        ->nonempty
        ->in($qdfpath);

    my $nrfisiere = scalar @rapoarte;    # total file number
    return \@rapoarte;
}

=head2 get_details

Process an XML file an return the contents of all the elements.

=cut

sub get_details {
    my ($self, $file) = @_;
    return $self->_process_file($file, 'report');
}

=head2 get_title

Process an XML file an return the contents of the title element.

=cut

sub get_title {
    my ($self, $file) = @_;
    return $self->_process_file($file, 'title');
}

=head2 get_titles

Process all XML files an return the contents of the title element.

=cut

sub get_titles {
    my ($self) = @_;

    return $self->_process_all_files('title');
}

=head2 xml_update

Update an XML file with the new values from record.

=cut

sub xml_update {
    my ($self, $file, $rec) = @_;

    my $old = $file;
    my $new = "$file.tmp.$$";
    my $bak = "$file.orig";

    # Output new file.rex
    open my $file_fh, '>', $new
        or die "Can't open file ",$new, ": $!";

    my $twig_handlers = {
        header     => sub { $self->_xml_proc_head(@_, $rec->{header} ) },
        parameters => sub { $self->_xml_proc_para(@_, $rec->{parameters}) },
        body       => sub { $self->_xml_proc_body(@_, $rec->{body}) },
    };

    my $twig = XML::Twig->new(
        pretty_print  => 'indented',
        twig_handlers => $twig_handlers
    );

    if (-f $file) {
        $twig->parsefile($file);    # build it (the twig...)
    }
    else {
        print "NIX report file!\n";
        return;
    }

    # Print header to rex
    $twig->flush($file_fh);

    close $file_fh;

    # Redenumeste
    rename($old, $bak) or die "can't rename $old to $bak: $!";
    rename($new, $old) or die "can't rename $new to $old: $!";

    return;
}

=head2 _xml_proc_head

Remove head element childrens, then recreate with the new values.

=cut

sub _xml_proc_head {
    my ( $self, $t, $elt, $rec ) = @_;

    $elt->cut_children;

    foreach my $item ( keys %{$rec} ) {
        my $ef = XML::Twig::Elt->new($item, $rec->{$item} );
        $ef->paste('last_child', $elt);
    }

    return;
}

=head2 _xml_proc_body

Remove body element childrens, then recreate with the new values.

=cut

sub _xml_proc_body {
    my ( $self, $t, $elt, $rec ) = @_;

    $elt->cut_children;

    foreach my $item ( keys %{$rec} ) {
        my $ef = XML::Twig::Elt->new(
            '#CDATA' => $rec->{$item}
        )->wrap_in($item);
        $ef->paste('last_child', $elt);
    }

    return;
}

=head2 _xml_proc_para

Remove parameters element childrens, then recreate with the new
values.

=cut

sub _xml_proc_para {
    my ( $self, $t, $elt, $rec ) = @_;

    $elt->cut_children;

    foreach my $item ( @{$rec} ) {
        my $ef = XML::Twig::Elt->new('parameter');
        $ef->paste('last_child', $elt);
        $ef->set_att( %{$item} );
    }

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of TpdaQrt::FileIO
