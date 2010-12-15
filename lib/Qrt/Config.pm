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

Version 0.10

=cut

our $VERSION = '0.10';

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

    $args->{cfgmain} = 'etc/main.yml'; # hardcoded main config file name

    # Load configuration and create accessors
    $self->_config_main_load($args);
    if ( $args->{cfgname} ) {
        # If no config name don't bother to load this
        $self->_config_conn_load($args);
        $self->_config_other_load();
    }

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

Make accessors.

=cut

sub _config_main_load {
    my ( $self, $args ) = @_;

    my $configpath = File::UserConfig->new(
        dist     => 'Qrt',
        sharedir => 'share',
    )->configdir;

    # Main config file name, load
    my $main_qfn = catfile( $configpath, $args->{cfgmain} );

    my $msg = qq{\nConfiguration error: \n Can't read 'main.yml'};
    $msg   .= qq{\n  from '$main_qfn'!};
    my $maincfg = $self->_config_file_load($main_qfn, $msg);

    # Misc
    my $main_hr = {
        cfgpath => $configpath,
        qdfexte => $maincfg->{general}{qdfexte},
        icons   => catdir( $configpath, $maincfg->{paths}{icons} ),
        qdftmpl => catdir( $configpath, $maincfg->{paths}{qdftmpl} ),
        contmpl => catdir( $configpath, $maincfg->{paths}{contmpl} ),
        conpath => catdir( $configpath, $maincfg->{paths}{connections} ),
        confile => $maincfg->{configs}{connection},
        cfother => $maincfg->{other},
    };

    # Setup when GUI runtime
    if ( $args->{cfgname} ) {
        $main_hr->{cfgname} = $args->{cfgname};
        $main_hr->{qdfpath} =
            catdir( $configpath, $maincfg->{paths}{connections},
                    $args->{cfgname}, 'qdf', );
    }

    $self->_make_accessors($main_hr);

    return $maincfg;
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
    my ( $self, $args ) = @_;

    # Connection
    my $cfgconn_f = $self->conn_cfg_filename($self->cfgname);

    my $msg = qq{\nConfiguration error, to fix, run\n\n};
    $msg   .= qq{  tpda-qrt -init };
    $msg   .= $self->cfgname . qq{\n\n};
    $msg   .= qq{then edit: $cfgconn_f\n};
    my $cfg_data = $self->_config_file_load($cfgconn_f, $msg);

    $cfg_data->{cfgconnf} = $cfgconn_f; # Accessor for connection file
    $cfg_data->{conninfo}{user} = $args->{user};
    $cfg_data->{conninfo}{pass} = $args->{pass};

    $self->_make_accessors($cfg_data);

    return;
}

=head2 _config_other_load

Process the main configuration file and automaticaly load all the
other defined configuration files.  That means if we add a YAML
configuration file to the tree, all defined values should be available
at restart.

=cut

sub _config_other_load {
    my $self = shift;

    foreach my $sec ( keys %{ $self->cfother } ) {
        next if $sec eq 'connection';

        my $cfg_file = catfile( $self->cfgpath, $self->cfother->{$sec} );
        my $msg = qq{\nConfiguration error: \n Can't read configurations};
        $msg   .= qq{\n  from '$cfg_file'!};
        my $cfg_data = $self->_config_file_load($cfg_file, $msg);

        $self->_make_accessors($cfg_data);
    }

    return;
}

=head2 _config_file_load

Load a generic config file in YAML format and return the Perl data
structure.  Die, if can't read file.

=cut

sub _config_file_load {
    my ($self, $yaml_file, $message) = @_;

    # print "YAML file: $yaml_file\n";
    if (! -f $yaml_file) {
        print "$message\n";
        die;
    }

    return Qrt::Config::Utils->load($yaml_file);
}

=head2 list_configs

List all existing connection configurations.

=cut

sub list_configs {
    my $self = shift;

    my $conpath = $self->conpath;
    my $conn_list = Qrt::Config::Utils->find_subdirs($conpath);

    print "Connection configurations:\n";
    foreach my $cfg_name ( @{$conn_list} ) {
        my $ccfn = $self->conn_cfg_filename($cfg_name);
        # If connection file exist than list as connection name
        if (-f $ccfn) {
            print "  > $cfg_name\n";
        }
    }
    print " in '$conpath'\n";
}

=head2 init_configs

Create new connection configuration directory and install new
configuration file from template.

=cut

sub init_configs {
    my ( $self, $conn_name ) = @_;

    my $conn_tmpl = $self->contmpl;
    my $conn_path = catfile( $self->conpath, $conn_name, 'etc' );
    my $conn_qdfp = catfile( $self->conpath, $conn_name, 'qdf' );
    my $conn_file = $self->conn_cfg_filename($conn_name);

    if ( -f $conn_file ) {
        print "Connection configuration exists, can't overwrite.\n";
        print " > $conn_name\n";
        return;
    }

    Qrt::Config::Utils->create_conn_cfg_tree( $conn_tmpl, $conn_path,
        $conn_qdfp, $conn_file, );

    print "New configuration: $conn_name\n";
}

=head2 conn_cfg_filename

Return full path to connection file.

=cut

sub conn_cfg_filename {
    my ($self, $cfgname) = @_;

    return catfile($self->conpath, $cfgname, 'etc', $self->confile );
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at users . sourceforge . net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of Qrt::Config
