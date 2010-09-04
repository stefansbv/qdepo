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
# |                                               p a c k a g e   C o n f i g |
# +---------------------------------------------------------------------------+
package Qrt::Config;

# Creating accessors for the config options automaticaly with the help
# of Class::Accessor
#
# Inspired from PM node: perlmeditation [id://234012]
# by trs80 (Priest) on Feb 10, 2003 at 04:25 UTC, Thanx!

use strict;
use warnings;

use File::HomeDir;
use File::Spec::Functions;
use YAML::Tiny;

use Qrt::Config::Instance;

our $VERSION = 0.05;

sub new {

    my ( $class, $args ) = @_;

    my $self = {};

    bless $self, $class;

    my $configs;
    if ($args) {
        $configs = $self->_merge_configs($args);
    }

    $self->{cfi} = Qrt::Config::Instance->instance($configs);

    return $self;
}

sub cfg {
    my $self = shift;

    my $cf = $self->{cfi};

    die ref($self) . " requires a config handle!"
        unless defined $cf and $cf->isa('Qrt::Config::Instance');

    return $cf;
}

#---

sub _merge_configs {
    my ( $self, $args ) = @_;

    # Merge all configs into a big hash, so we can create accessors
    # for every key

    # Configs for database
    my $cfg = {};

    # Add options from args
    $cfg->{arg} = $args;

    # General configs
    $self->check_file( $args->{cfg_gen}, 'die' );
    my $cfg_gen = $self->_load_yaml_config_file( $args->{cfg_gen} );
    $cfg->{general} = $self->_extract_configs( $cfg_gen, $args->{cfg_path} );

    # Load database configuration
    my $db_cfg = $self->connection_file($args);
    $self->check_file($db_cfg, 'die');
    my $db = $self->_load_yaml_config_file($db_cfg);

    # Merge contents to cfg hash
    $cfg->{connection} = $db->{connection};
    $cfg->{output}     = $db->{output};

    # Add qdf path
    $cfg->{qdf} = $self->qdf_path($args);
    $self->check_path( $cfg->{qdf}, 'die' );

    # Expand '~/' to HOME in output path
    my $output_p = $cfg->{output}{path};
    if ($output_p =~ s{^~/}{} ) {
        my $home = File::HomeDir->my_home;
        $output_p = catdir($home, $output_p);
        $cfg->{output}{path} = $output_p;
    }
    $self->check_path($output_p); # This prevents start if fails !!!

    # Add toolbar atributes to config
    my $tb_attrs_hr =
      $self->_load_yaml_config_file( $cfg->{general}{cfg_tlb_qn} );
    $cfg->{toolbar} = $tb_attrs_hr->{toolbar};

    return $cfg;
}

#--- Utility subs

sub _load_yaml_config_file {
    my ( $self, $cfg_fqn ) = @_;

    return YAML::Tiny::LoadFile( $cfg_fqn );
}

sub _extract_configs {
    my ($self, $cfgs, $path) = @_;

    # Only extract the configs we are interested in

    my $new_cfg = {};
    foreach my $sec ( keys %{$cfgs} ) {
        foreach my $cfg ( keys %{ $cfgs->{$sec} } ) {
            foreach my $key ( keys %{ $cfgs->{$sec}{$cfg} } ) {

                if ( $key eq 'var' ) {
                    $new_cfg->{ $cfgs->{$sec}{$cfg}{var} } =
                      catfile( $path, $cfgs->{$sec}{$cfg}{dst} );
                }
            }
        }
    }

    return $new_cfg;
}

sub check_path {
    my ($self, $path, $fatal) = @_;

    if (!-d $path) {
        print "Config error:\n";
        print "  $path does not exist?\n";
        if ($fatal) {
            exit;
        }
    }
}

sub check_file {
    my ($self, $file_qn, $fatal) = @_;

    if (!-f $file_qn) {
        print "Config error:\n";
        print "  $file_qn does not exist?\n";
        if ($fatal) {
            exit;
        }
    }
}

sub connection_file {
    my ( $self, $args ) = @_;

    return catfile( $args->{cfg_path}, 'db', $args->{conn}, 'etc',
        'connection.yml' );
}

sub qdf_path {
    my ( $self, $args ) = @_;

    return catdir( $args->{cfg_path}, 'db', $args->{conn}, 'qdf' );
}

#--

sub new_qdf_fqn {
    my ($self, $qdf_fn) = @_;

    my $rdfpath = $self->cfg->qdf;

    my $rdfpath_qn = catfile($rdfpath, $qdf_fn);

    return $rdfpath_qn;
}

sub output_fqn {
    my ($self, $out_fn) = @_;

    my $outdir = $self->cfg->output->{path};

    my $out_qfn = catfile($outdir, $out_fn);

    return $out_qfn;
}

1;
