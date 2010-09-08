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

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

Reads configuration files in I<YAML::Tiny> format and create a HoH.
Then using I<Class::Accessor>, automatically create methods from the
keys of the hash.

    use Qrt::Config;

    my $cfg = Qrt::Config->instance($args); # first time init

    my $cfg = Qrt::Config->instance(); # later, in other modules


=head1 METHODS

=head2 _new_instance

Constructor method, the first and only time a new instance is created.
All parameters passed to the instance() method are forwarded to this
method. (From I<Class::Singleton> docs).

=cut

sub _new_instance {
    my ($class, $args) = @_;

    my $self = bless {}, $class;

    my $mcfg = $self->_config_main_load($args);

    my $cfg = {};
    $cfg = $self->_config_conn_load($mcfg, $cfg);
    $cfg = $self->_config_other_load($mcfg, $cfg);

    $self->_make_accessors( $cfg->{_cfg} );

    return $self;
}

=head2 _make_accessors

Automatically make accessors for the hash keys.

=cut

sub _make_accessors {
    my ( $self, $cfg_hr ) = @_;

    __PACKAGE__->mk_accessors( keys %{$cfg_hr} );

    # Add data to object
    foreach ( keys %{$cfg_hr} ) {
        $self->$_( $cfg_hr->{$_} );
    }
}

=head2 _config_main_load

Initialize configuration variables from arguments, also initialize the
user configuration tree if not exists, with the I<File::UserConfig>
module.

Load the main configuration file and return a HoH data structure.

=cut

sub _config_main_load {
    my ($self, $args) = @_;

    my $configpath = File::UserConfig->new(
        dist     => 'Tpda-Qrt',
        module   => 'Tpda::Qrt',
        dirname  => '.tpda-qrt',
        sharedir => 'share',
    )->configdir;

    $self->{_cfgpath} = $configpath;
    $self->{_cfgmain} = catfile( $configpath, $args->{cfgmain} );
    $self->{_cfgname} = $args->{cfgname};

    if ( !-f $self->{_cfgmain} ) {
        print "\nConfiguration error!, this should never happen.\n\n";
        die;
    }

    return $self->_config_file_load( $self->{_cfgmain} );
}

=head2 _config_conn_load

Initialize the runtime connection configuration file name and path and
some miscellaneous info from the main configuration file.

The B<connection> configuration is special.  More than one connection
configuration is allowed and the name of the used connection is known
only at runtime from the I<cfgname> argument.

Load the connection configuration file.  This is treated separately
because the path is only known at runtime.

=cut

sub _config_conn_load {
    my ($self, $mcfg, $cfg) = @_;

    # Connection
    my $connd = $mcfg->{paths}{connections};
    my $connf = $mcfg->{configs}{connection};

    # Misc
    $self->{_cfgmisc} = {
        qdfexte => $mcfg->{general}{qdfexte},
        icons   => catdir( $self->{_cfgpath}, $mcfg->{paths}{icons} ),
        qdfpath => $mcfg->{paths}{qdfpath},
    };

    # The connection configuration path and name
    $self->{_cfgconn_p} = catdir( $self->{_cfgpath}, $connd, $self->{_cfgname} );
    $self->{_cfgconn_f} = catfile($self->{_cfgconn_p}, $connf );

    my $cfg_data = $self->_config_file_load( $self->{_cfgconn_f} );
    $cfg = Qrt::Config::Utils->data_merge( $cfg, $cfg_data );

    return $cfg;
}

=head2 _config_other_load

Process the main configuration file and automaticaly load all the
other defined configuration files.  That means if we add a YAML
configuration file to the tree, all defined values should be available
at restart.

=cut

sub _config_other_load {
    my ( $self, $mcfg, $cfg ) = @_;

    foreach my $sec ( keys %{ $mcfg->{other} } ) {
        next if $sec eq 'connection';

        my $cfg_file = catfile( $self->{_cfgpath}, $mcfg->{other}{$sec} );
        my $cfg_data = $self->_config_file_load($cfg_file);
        $cfg = Qrt::Config::Utils->data_merge( $cfg, $cfg_data );
    }

    return $cfg;
}

=head2 _config_file_load

Load a generic config file in YAML format and return the Perl data
structure.

=cut

sub _config_file_load {
    my ($self, $yaml_file) = @_;

    if (! -f $yaml_file) {
        # print "\nConfiguration error, to fix, run\n\n";
        # print "  tpda-qrt -init ";
        # print $self->{_cfgname},"\n\n";
        # print "then edit: ", $yaml_file, "\n\n";
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
