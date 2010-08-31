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
# |                                           p a c k a g e   I n s t a n c e |
# +---------------------------------------------------------------------------+
package Qrt::Config::Instance;

use strict;
use warnings;

use base qw(Class::Singleton Class::Accessor);
use YAML::Tiny;
use File::Spec::Functions;
use File::HomeDir;

our $VERSION = 0.05;

sub _new_instance {
    my ($class, $args) = @_;

    my $self = bless {}, $class;

    # Make accessors once!
    if ( $args ) {
        $self->_make_accessors($args);
    }

    return $self;
}

sub _make_accessors {
    my ( $self, $args ) = @_;

    my $config_hr = $self->_merge_configs($args);

    __PACKAGE__->mk_accessors( keys %{$config_hr} );

    # Add data to object
    foreach ( keys %{$config_hr} ) {
        $self->$_( $config_hr->{$_} );
    }
}

sub _merge_configs {
    my ( $self, $args ) = @_;

    # Merge all configs into a big hash, so we can create accessors
    # for every key

    # Configs for database
    my $cfg = {};

    # Add options from args
    $cfg->{arg} = $args;

    # General configs
    my $cfg_gen = $self->_load_yaml_config_file( $args->{cfg_gen} );
    $cfg->{general} = $self->_extract_configs($cfg_gen, $args->{cfg_path} );

    # Load database configuration
    my $db_cfg =
      catfile( $args->{cfg_path}, 'db', $args->{db}, 'etc', 'database.yml' );
    my $db = $self->_load_yaml_config_file( $db_cfg );
    # Merge contents to cfg hash
    $cfg->{connection} = $db->{connection};
    $cfg->{output} = $db->{output};
    # Add qdf path
    $cfg->{qdf} = catdir( $args->{cfg_path}, 'db', $args->{db}, 'qdf' );

    # Expand ~/ to home in output path
    my $output_p = $cfg->{output}{path};
    if ($output_p =~ s{^~/}{} ) {
        my $home = File::HomeDir->my_home;
        $output_p = catdir($home, $output_p);
        $cfg->{output}{path} = $output_p;
    }
    # Check path
    if ($output_p) {

        # Check config early, but don't die, just warn, for now
        if ( !-d $output_p ) {
            warn "\nWARNING: Bad output directory configuration!\n";
            warn " output path : $output_p\n";
        }
    }
    else {
        warn "\nWARNING: No output directory configuration!\n";
    }

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

1;

__END__
