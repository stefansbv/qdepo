package Pdqm::Config;

use strict;
use warnings;

use Data::Dumper;
use Carp;

use File::Spec::Functions;
use File::Basename;

use XML::Twig;

our $VERSION = 0.60;         # Version number

sub new {

    my ($class, $opts) = @_;

    my $self = {};

    $self->{config} = {};

    bless( $self, $class );

    $self->_init($opts);

    return $self;
}

sub _init {

    my ($self, $opts) = @_;

    # Setup full path and filename for application config
    $self->{cfg}{fqn} = $self->get_config_file($opts);

    # Read configs
    $self->xml_read_simple('rex');
    $self->xml_read_simple('conninfo');

    # Setup full path for query definition files
    $self->{cfg}{qdf} = $self->get_rdef_path($opts);

    print Dumper( $self->{cfg} );

    return;
}

sub get_config_file {

    my ($self, $opts) = @_;

    return catfile(
        $opts->{cfg_ref}{conf_dir},
        $opts->{cfg_ref}{conf_file},
    );
}

sub get_rdef_path {

    my ($self, $opts) = @_;

    return catdir(
        $opts->{cfg_ref}{conf_dir},
        $self->get_config_rdef('qdfpath'),
    );
}

sub get_rdef_templ_name {

    # Return full qualified name of the report definition file template

    my ($self) = @_;

    my $templ_fqn = catfile(
        $self->{config}{cfg}{tmpl_dir},
        $self->get_config_rdef('qdftempl'),
    );

    return $templ_fqn;
}

sub get_rdef_fqn {

    # param : name of new rdef file
    # return: fqn

    my ($self, $newrepo_fn) = @_;

    my $rdef_fqn = catfile(
        $self->get_rdef_path(),
        $newrepo_fn,
    );

    return $rdef_fqn;
}

#-- Config read write

sub xml_read_simple {

    my ($self, $tag, $att, $val) = @_;

    # XPath syntax: "$tag\[\@$att]"
    my ( $config, $path );
    if ( $att and $val ) {
        $path = sprintf( "%s[@%s='$val']", $tag, $att, $val );
    }
    else {
        $path = sprintf( "%s", $tag );
    }

    # print "Path = $path\n";

    my $twig = new XML::Twig( TwigRoots => { $path => 1 } );

    if ( -f $self->{cfg}{fqn} ) {
        $config = $twig->parsefile( $self->{cfg}{fqn} )->simplify(
            keyattr    => 'key',
            group_tags => { columns => 'column', },
        );
        $self->{cfg}{$tag} = $config->{$tag};
    }
    else {
        print "Can't find application config file $self->{cfg}{fqn}!\n";
        exit 1;
    }

    return $self->{cfg};
}

# Data-access methods.

sub get_config_conninfo {

    my ($self, $prop) = @_;

    if (defined $prop) {
        return $self->{cfg}{conninfo}{$prop};
    }
    else {
        return $self->{cfg}{conninfo};
    }
}

sub get_config_rdef {

    my ($self, $prop) = @_;

    if (defined $prop) {
        return $self->{cfg}{rex}{$prop};
    }
    else {
        return $self->{cfg}{rex};
    }
}

1;
