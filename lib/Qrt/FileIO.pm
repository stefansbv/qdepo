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
# |                                               p a c k a g e   F i l e I O |
# +---------------------------------------------------------------------------+
package Qrt::FileIO;

use strict;
use warnings;

use Data::Dumper;
use Carp;

use File::Find::Rule;
use XML::Twig;

use Qrt::Config;

our $VERSION = 0.03;         # Version number

sub new {

    my ($class, $args) = @_;

    my $self = bless( {}, $class );

    $self->{args} = $args;

    return $self;
}

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
            print "$qdf_file: Not valid RdeF!\n";
            return;
        }
    }
}

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

sub _xml_read_simple {
    my ($self, $file, $tag) = @_;

    return unless $file;

    # XPath syntax: "$tag\[\@$att]"
    my $path = sprintf( "%s", $tag ); # Not needed if no attr :)
    # print "Path = $path\n";

    my $twig = XML::Twig( TwigRoots => { $path => 1 } )->new();
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

sub get_file_list {
    my $self = shift;

    my $cfg = Qrt::Config->instance();
    my $qdfpath_p = $cfg->{_cfgconn_p}; # ??? # query definition files path
    if ( !-d $qdfpath_p ) {
        print "Wrong path for qdf files:\n$qdfpath_p !\n";
        return;
    }

    # Report definition files can be arranged in subdirs; recursive find
    my @rapoarte = File::Find::Rule
        ->name( '*.qdf' )
        ->file
        ->nonempty
        ->in($qdfpath_p);

    my $nrfisiere = scalar @rapoarte;    # total file number
    return \@rapoarte;
}

sub get_details {
    my ($self, $file) = @_;
    return $self->_process_file($file, 'report');
}

sub get_title {
    my ($self, $file) = @_;
    return $self->_process_file($file, 'title');
}

sub get_titles {
    my ($self) = @_;
    return $self->_process_all_files('title');
}

#-- Update XML

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

    my $twig = XML::Twig(
        pretty_print  => 'indented',
        twig_handlers => $twig_handlers
    )->new();

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

sub _xml_proc_head {
    my ( $self, $t, $elt, $rec ) = @_;

    # print "Working on ", $elt->tag, "\n";

    $elt->cut_children;

    foreach my $item ( keys %{$rec} ) {
        my $ef = XML::Twig::Elt->new($item, $rec->{$item} );
        $ef->paste('last_child', $elt);
    }

    return;
}

sub _xml_proc_body {
    my ( $self, $t, $elt, $rec ) = @_;

    # print "Working on ", $elt->tag, "\n";

    $elt->cut_children;

    foreach my $item ( keys %{$rec} ) {
        my $ef = XML::Twig::Elt->new(
            '#CDATA' => $rec->{$item}
        )->wrap_in($item);
        $ef->paste('last_child', $elt);
    }

    return;
}

sub _xml_proc_para {
    my ( $self, $t, $elt, $rec ) = @_;

    # print "Working on ", $elt->tag, "\n";

    $elt->cut_children;

    foreach my $item ( @{$rec} ) {
        my $ef = XML::Twig::Elt->new('parameter');
        $ef->paste('last_child', $elt);
        $ef->set_att( %{$item} );
    }

    return;
}

1;
