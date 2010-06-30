package Pdqm::FileIO;

use strict;
use warnings;

use Carp;
use File::Find::Rule;
use File::Spec::Functions;

use XML::Twig;

our $VERSION = 0.10;         # Version number

sub new {

    my ($class) = @_;

    my $self = {};

    bless( $self, $class );

    return $self;
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

sub process_all_files {

    my ($self) = @_;

    my $files = $self->get_file_list();

    if (! defined $files) {
        print "No report definition files.\n";
        return;
    }

    print "\nReading XML files...\n";
    print scalar @$files, " report definition files.\n";

    my $indice = 0;
    my $titles = {};
    # rdf : report definition file ;)
    foreach my $rdf_file ( @$files ) {

        # print " File : $rdf_file\n";
        my $nrcrt = $indice + 1;
        my $title;
        eval {
            $title = $self->read_simple($rdf_file, 'title');
        };
        if ($@) {
            print "$rdf_file: Not valid XML!\n";
        } else {
            print "Fisier: $rdf_file\n";
            if (ref $title) {
                $titles->{$indice} = [ $nrcrt, $title->{title}, $rdf_file ];
                $indice++;
            }
            else {
                print "$rdf_file: Not valid RdeF!\n";
            }
        }
    }

    return $titles;
}

sub process_file {

    my ($self, $rdf_file) = @_;

    # rdf : report definition file ;)
    if (! defined $rdf_file) {
        print "No report definition file?.\n";
        return;
    }

    my $indice = $self->{repo}->get_titles_max_index();
    my $titles = {};

    my $nrcrt = $indice + 1;
    my $title = $self->read_simple($rdf_file, 'title');
    $titles->{$indice} = [ $nrcrt, $title->{title}, $rdf_file ];

    return ($titles, $indice);
}

sub get_file_list {

    my $self = shift;

    my $rdfpath_qn = $self->{repo}{conf}->get_rdef_path();
    my $rdfext     = $self->{repo}{conf}->get_config_rdef('rdfext');

    if ( ! -d $rdfpath_qn ) {
        print "Wrong path for rdef files:\n$rdfpath_qn !\n";
        return;
    }

    # Report definition files can be arranged in subdirs; recursive find
    my @rapoarte = File::Find::Rule
        ->name( "*.$rdfext" )
        ->file
        ->nonempty
        ->in($rdfpath_qn);

    my $nrfisiere = scalar @rapoarte;    # Numãr total de fiºiere

    return \@rapoarte;
}

sub get_details {

    my ($self, $file) = @_;

    return $self->read_simple($file, 'report');
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
