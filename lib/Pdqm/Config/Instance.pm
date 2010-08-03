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
# |                                           p a c k a g e   I n s t a n c e |
# +---------------------------------------------------------------------------+
package Pdqm::Config::Instance;

use strict;
use warnings;

use Data::Dumper;

use base qw(Class::Singleton Class::Accessor);
use YAML::Tiny;

our $VERSION = 0.05;

sub _new_instance {
    my ($class, $args) = @_;

    my $self = bless {}, $class;

    # Weak check for parameter validity
    if ( $args->{cfg_name} ) {
        $self->_make_accessors($args);
    }

    return $self;
}

sub _make_accessors {
    my ( $self, $args ) = @_;

    my $config_hr = $self->_merge_configs($args);

    print Dumper( $config_hr);

    __PACKAGE__->mk_accessors( keys %{$config_hr} );

    # Add data to object
    foreach ( keys %{$config_hr} ) {
        $self->$_( $config_hr->{$_} );
    }
}

sub _merge_configs {
    my ($self, $args) = @_;

    # Configs from yaml file
    my $cnf = $self->_get_usr_config_file($args);

    # Add options from args
    $cnf->{options} = $args;

    # Add toolbar atributes to config
    my $tb_attrs_hr = $self->_get_tb_settings($args);
    $cnf->{toolbar} = $tb_attrs_hr->{toolbar};

    return $cnf;
}

#--- Utility subs

sub _get_usr_config_file {
    my ( $self, $args ) = @_;

    return  YAML::Tiny::LoadFile( $args->{db_cnf_fqn} );
}

sub _get_tb_settings {
    my ($self, $args) = @_;

    return YAML::Tiny::LoadFile( $args->{cnf_toolb} );
}

1;

__END__
