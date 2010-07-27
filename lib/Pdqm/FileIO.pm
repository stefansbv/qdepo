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
# |                                               p a c k a g e   F i l e I O |
# +---------------------------------------------------------------------------+
package Pdqm::FileIO;

use strict;
use warnings;

use Data::Dumper;
use Carp;

use File::Find::Rule;
use XML::Twig;

use Pdqm::Config;

our $VERSION = 0.03;         # Version number

sub new {

    my ($class, $args) = @_;

    my $self = bless( {}, $class );

    $self->{args} = $args;

    return $self;
}

sub process_all_files {

    my ($self) = @_;

    my $qdf_ref = $self->get_file_list();

    if (! defined $qdf_ref) {
        print "No query definition files.\n";
        return;
    }

    print "\nReading XML files...\n";
    print scalar @{$qdf_ref}, " query definition files found.\n";

    my $indice = 0;
    my $titles = {};
    # qdf : report definition file ;)
    foreach my $qdf_file ( @{$qdf_ref} ) {

        # print " File : $qdf_file\n";
        my $nrcrt = $indice + 1;
        my $title;
        eval {
            $title = $self->xml_read_simple($qdf_file, 'title');
        };
        if ($@) {
            print "$qdf_file: Not valid XML!\n";
        } else {
            # print "Fisier: $qdf_file\n";
            if (ref $title) {
                $titles->{$indice} = [ $nrcrt, $title->{title}, $qdf_file ];
                $indice++;
            }
            else {
                print "$qdf_file: Not valid RdeF!\n";
            }
        }
    }

    return $titles;
}

sub xml_read_simple {

    my ($self, $file, $tag) = @_;

    return unless $file;

    # XPath syntax: "$tag\[\@$att]"
    my $path = sprintf( "%s", $tag ); # Not needed if no attr :)
    # print "Path = $path\n";

    my $twig = new XML::Twig( TwigRoots => { $path => 1 } );
    my $xml_data;

    if ( -f $file ) {
        $xml_data = $twig->parsefile( $file )->simplify(
            forcearray => [ 'parameter' ],
            keyattr    => 'id',
            group_tags => { parameters => 'parameter', },
        );                      # should parameterize options?
    }
    else {
        croak "Can't find file: $file!\n";
    }

    return $xml_data;
}

sub process_file {

    my ($self, $qdf_file) = @_;

    # qdf : report definition file ;)
    if (! defined $qdf_file) {
        print "No report definition file?.\n";
        return;
    }

    my $data = $self->xml_read_simple($qdf_file, 'report');

    return $data;
}

sub get_file_list {

    my $self = shift;

    my $cnf = Pdqm::Config->new();
    my $qdf = $cnf->cfg->qdf;    # query definition files

    my $qdfext     = $cnf->cfg->qdf->{extension};
    my $qdfpath_qn = $cnf->cfg->qdf->{path};

    print "qdfpath_qn is $qdfpath_qn\n";
    if ( ! -d $qdfpath_qn ) {
        print "Wrong path for rdef files:\n$qdfpath_qn !\n";
        return;
    }

    # Report definition files can be arranged in subdirs; recursive find
    my @rapoarte = File::Find::Rule
        ->name( "*.$qdfext" )
        ->file
        ->nonempty
        ->in($qdfpath_qn);

    my $nrfisiere = scalar @rapoarte;    # Numãr total de fiºiere

    return \@rapoarte;
}

sub get_details {

    my ($self, $file) = @_;

    return $self->process_file($file);
}

sub get_titles {

    my ($self) = @_;

    return $self->process_all_files('title');
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

    my $twig = new XML::Twig(
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

sub _xml_proc_head {

    my ( $self, $t, $elt, $rec ) = @_;

    print "Working on ", $elt->tag, "\n";

    $elt->cut_children;

    foreach my $item ( keys %{$rec} ) {
        my $ef = XML::Twig::Elt->new($item, $rec->{$item} );
        $ef->paste('last_child', $elt);
    }

    return;
}

sub _xml_proc_body {

    my ( $self, $t, $elt, $rec ) = @_;

    print "Working on ", $elt->tag, "\n";

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

    print "Working on ", $elt->tag, "\n";

    $elt->cut_children;

    foreach my $item ( @{$rec} ) {
        my $ef = XML::Twig::Elt->new('parameter');
        $ef->paste('last_child', $elt);
        $ef->set_att( %{$item} );
    }

    return;
}

1;
