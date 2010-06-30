package Pdqm::Config;

use strict;
use warnings;
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

    # Application run options and run parameters
    $self->{config}{cfg} = $opts->{cfg_ref};
    $self->{config}{run} = $opts->{run_ref};

    # Full path and filename for application config
    $self->{config}{fqn} = $self->get_config_file();

    # Read configs
    $self->read_simple('rex');
    $self->read_simple('conninfo');

    return;
}

#-- Config from options

sub get_config_file {

    my ($self) = @_;

    return catfile(
        $self->{config}{cfg}{conf_dir},
        $self->{config}{cfg}{conf_file},
    );
}

sub get_rdef_path {

    # Return full path of the report definition files

    my ($self) = @_;

    my $rdfpath_qn = catdir(
        $self->{config}{cfg}{conf_dir},
        $self->get_config_rdef('rdfpath'),
    );

    return $rdfpath_qn;
}

sub get_rdef_templ_name {

    # Return full qualified name of the report definition file template

    my ($self) = @_;

    my $templ_fqn = catfile(
        $self->{config}{cfg}{tmpl_dir},
        $self->get_config_rdef('rdftempl'),
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

    if ( -f $self->{config}{fqn} ) {
        $config = $twig->parsefile( $self->{config}{fqn} )->simplify(
            keyattr    => 'key',
            group_tags => { columns => 'column', },
        );
        $self->{config}{$tag} = $config->{$tag};
    }
    else {
        print "Can't find application config file $self->{config}{fqn}!\n";
        exit 1;
    }

    return $self->{config};
}

# Data-access methods.

sub get_config_conninfo {

    my ($self, $prop) = @_;

    if (defined $prop) {
        return $self->{config}{conninfo}{$prop};
    }
    else {
        return $self->{config}{conninfo};
    }
}

sub get_config_rdef {

    my ($self, $prop) = @_;

    if (defined $prop) {
        return $self->{config}{rex}{$prop};
    }
    else {
        return $self->{config}{rex};
    }
}

1;

__END__
