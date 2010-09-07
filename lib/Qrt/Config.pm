package Qrt::Config;

use warnings;
use strict;

use File::HomeDir;
use File::UserConfig;
use File::Spec::Functions;

use Qrt::Config::Utils;

use base qw(Class::Singleton Class::Accessor);

=head1 NAME

Qrt::Config - Tpda Qrt configuration module

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

Reads configuration files in I<YAML::Tiny> format and create a HoH.
Then using I<Class::Accessor>, automatically create methods from the
keys of the hash.

    use Qrt::Config;

    my $cfg = Qrt::Config->instance($args);

    ...

=head1 METHODS

=head2 _new_instance

Constructor method, the first and only time a new instance is created.
All parameters passed to the instance() method are forwarded to this
method. (From I<Class::Singleton> docs).

=cut

sub _new_instance {
    my ($class, $args) = @_;

    my $self = bless {}, $class;

    $self->_init_cfg_vars($args);

    my $maincfg = $self->_load_main_cfg();

    $self->_init_cfg_conn($maincfg);

    my $cfg = $self->_load_conn_cfg();

    $cfg = $self->_load_other_cfgs($maincfg, $cfg);

    $self->_make_accessors( $cfg->{_cfg} );

    return $self;
}

=head2 _make_accessors

Automatically make accessors for the hash keys.

=cut

sub _make_accessors {
    my ( $self, $cfg ) = @_;

    __PACKAGE__->mk_accessors( keys %{$cfg} );

    # Add data to object
    foreach ( keys %{$cfg} ) {
        $self->$_( $cfg->{$_} );
    }
}

=head2 _init_cfg_vars

Initialize configuration variables from arguments, also initialize the
user configuration tree if not exists, with the I<File::UserConfig>
module.

=cut

sub _init_cfg_vars {
    my ($self, $args) = @_;

    my $configpath = File::UserConfig->new(
        dist     => 'TpdaQrt',
        module   => 'Tpda::Qrt',
        dirname  => '.tpda-qrt',
        sharedir => 'share',
    )->configdir;

    $self->{_cfgpath} = $configpath;
    $self->{_cfgmain} = catfile( $self->{_cfgpath}, $args->{cfgmain} );
    $self->{_cfgname} = $args->{cfgname};
}

=head2 _init_cfg_conn

Initialize the runtime connection configuration file name and path and
some miscellaneous info from the main configuration file.

The B<connection> configuration is special.  More than one connection
configuration is allowed and the name of the used connection is known
only at runtime from the I<cfgname> argument.

Variables:

=over

=item _cfgconn_f

The connection configuration file name

=item _cfgconn_p

The connection configuration path

=back

=cut

sub _init_cfg_conn {
    my ($self, $mcgf) = @_;

    # Connection
    my $connd = $mcgf->{paths}{connections};
    my $connf = $mcgf->{configs}{connection};

    # Misc
    $self->{_cfgmisc} = {
        qdfexte => $mcgf->{general}{qdfexte},
        icons   => $mcgf->{paths}{icons},
        qdfpath => $mcgf->{paths}{qdfpath},
    };

    $self->{_cfgconn_p} = catdir( $self->cfgpath, $connd, $self->cfgname );
    $self->{_cfgconn_f} = catfile($self->{_cfgconn_p}, $connf );
}

=head2 cfgpath

Getter for the application configuration path.

=cut

sub cfgpath {
    my $self = shift;

    return $self->{_cfgpath};
}

=head2 cfgmain

Getter for the main configuration file.

=cut

sub cfgmain {
    my $self = shift;

    return $self->{_cfgmain};
}

=head2 cfgname

Getter for the  runtime configuration name.

=cut

sub cfgname {
    my $self = shift;

    return $self->{_cfgname};
}

=head2 cfgconn

Getter for the runtime connection configuration file name.

=cut

sub cfgconn {
    my ($self, $connd) = @_;

    return $self->{_cfgconn_f};
}

=head2 cfgmisc

Getter for miscellaneous configurations.

=cut

sub cfgmisc {
    my $self = shift;

    return $self->{_cfgmisc};
}

=head2 _load_main_cfg

Load the connection configuration file and return a Perl data
structure.

=cut

sub _load_main_cfg {
    my $self = shift;

    my $yaml_file = $self->cfgmain;

    if (! -f $yaml_file) {
        print "\nConfiguration error!, this should never happen.\n\n";
        die;
    }

    return Qrt::Config::Utils->load($yaml_file);
}

=head2 _load_conn_cfg

Load the connection configuration file.  This is treated separately
because the path is only known at runtime.

=cut

sub _load_conn_cfg {
    my ($self) = @_;

    my $cfg = {};

    my $cfg_data = $self->_load_cfg_file( $self->cfgconn );
    $cfg = Qrt::Config::Utils->merge_data( $cfg, $cfg_data );

    return $cfg;
}

=head2 _load_other_cfgs

Process the main configuration file and automaticaly load all the
other defined configuration files.  That means if we add a YAML
configuration file to the tree, all defined values should be available
at restart.

=cut

sub _load_other_cfgs {
    my ( $self, $mcfg, $cfg ) = @_;

    foreach my $sec ( keys %{ $mcfg->{other} } ) {
        next if $sec eq 'connection';

        my $cfg_file = catfile( $self->cfgpath, $mcfg->{other}{$sec} );
        my $cfg_data = $self->_load_cfg_file($cfg_file);
        $cfg = Qrt::Config::Utils->merge_data( $cfg, $cfg_data );
    }

    return $cfg;
}

=head2 _load_cfg_file

Load a generic config file in YAML format and return the Perl data
structure.

=cut

sub _load_cfg_file {
    my ($self, $yaml_file) = @_;

    if (! -f $yaml_file) {
        print "\nConfiguration error, to fix, run\n\n";
        print "  tpda-qrt -init ";
        print $self->cfgname,"\n\n";
        print "then edit: ", $yaml_file, "\n\n";
        die;
    }

    return Qrt::Config::Utils->load($yaml_file);
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at users . sourceforge . net> >>


=head1 BUGS

None known.

Please report any bugs or feature requests to the author.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Qrt::Config


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of Qrt::Config
