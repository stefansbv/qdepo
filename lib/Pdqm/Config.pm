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
# |                                               p a c k a g e   C o n f i g |
# +---------------------------------------------------------------------------+
package Pdqm::Config;

# Creating accessors for the config options automaticaly with the help
# of Class::Accessor
#
# Inspired from PM node: perlmeditation [id://234012]
# by trs80 (Priest) on Feb 10, 2003 at 04:25 UTC

use strict;
use warnings;

use Data::Dumper;

use File::HomeDir;
use File::Spec::Functions;

use Pdqm::Config::Instance;

our $VERSION = 0.04;

sub new {

    my ( $class, $args ) = @_;

    my $self = {};

    bless $self, $class;

    $self->{cfi} = Pdqm::Config::Instance->instance( $args );

    return $self;
}

sub cfg {
    my $self = shift;

    my $cf = $self->{cfi};

    die ref($self) . " requires a config handle!"
        unless defined $cf and $cf->isa('Pdqm::Config::Instance');

    return $cf;
}

sub process_configs {
    my ($self, ) = @_;

    my $home_path  = File::HomeDir->my_home;

    my $rdfext  = $self->cfg->rex->{rdfext};
    my $rdfpath = $self->cfg->rex->{rdfpath};

    my $rdfpath_qn = catdir($home_path, '.reports/Contracte' ,);

    return $rdfext;
}

sub save_config {

    my ( $self, ) = @_;

    # Save the file
    YAML::Tiny::DumpFile( 'recipe.conf.new', $self->{conf} );

    return;
}

1;
