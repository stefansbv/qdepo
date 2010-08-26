# +---------------------------------------------------------------------------+
# | Name     : Qrt (Perl Database Query Manager)                             |
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

use Qrt::Config::Instance;

our $VERSION = 0.04;

sub new {

    my ( $class, $args ) = @_;

    my $self = {};

    bless $self, $class;

    $self->{cfi} = Qrt::Config::Instance->instance( $args );

    return $self;
}

sub cfg {
    my $self = shift;

    my $cf = $self->{cfi};

    die ref($self) . " requires a config handle!"
        unless defined $cf and $cf->isa('Qrt::Config::Instance');

    return $cf;
}

sub new_qdf_fqn {
    my ($self, $qdf_fn) = @_;

    my $rdfpath = $self->cfg->options->{db_qdf_qn};

    my $rdfpath_qn = catfile($rdfpath, $qdf_fn);

    return $rdfpath_qn;
}

sub out_fqn {
    my ($self, $out_fn) = @_;

    my $outdir = $self->cfg->qdf->{outdir};

    my $out_qfn = catfile($outdir, $out_fn);

    return $out_qfn;
}

1;
