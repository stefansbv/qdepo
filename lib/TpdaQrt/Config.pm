package TpdaQrt::Config;

use strict;
use warnings;

use Data::Dumper;

use Hash::Merge qw(merge);
use File::HomeDir;
use File::UserConfig;
use File::Spec::Functions;

use TpdaQrt::Config::Utils;

use base qw(Class::Singleton Class::Accessor);

=head1 NAME

TpdaQrt::Config - Tpda TpdaQrt configuration module

=head1 VERSION

Version 0.33

=cut

our $VERSION = '0.33';

=head1 SYNOPSIS

Reads configuration files in I<YAML::Tiny> format and create a HoH.
Then using I<Class::Accessor>, automatically create methods from the
keys of the hash.

    use TpdaQrt::Config;

    my $cfg = TpdaQrt::Config->instance($args); # first time init

    my $cfg = TpdaQrt::Config->instance(); # later, in other modules

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
    if ( $args->{cfname} ) {
        # If no config name don't bother to load this
        $self->_config_conn_load($args);
        $self->_config_interface_load();
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
        dist     => 'TpdaQrt',
        sharedir => 'share',
    )->configdir;

    my $base_methods_hr = {
        cfpath => $configpath,
        cfdb   => catdir( $configpath, 'db' ),
        user   => $args->{user},                   # make accessors for user
        pass   => $args->{pass},                   # and pass
    };

    # Merge args hashref
    my $methods_new = merge($base_methods_hr, $args);

    $self->_make_accessors($methods_new);

    # Main config file name, load
    my $main_fqn = catfile( $configpath, $args->{cfgmain} );

    my $msg = qq{\nConfiguration error: \n Can't read 'main.conf'};
    $msg .= qq{\n  from '$main_fqn'!};
    my $maincfg = $self->_config_file_load( $main_fqn, $msg );

    my $main_hr = {
        widgetset => $maincfg->{interface}{widgetset},    # Wx or Tk
        ymltoolbar =>
            catfile( $configpath, $maincfg->{interface}{path}{toolbar} ),
        ymlmenubar =>
            catfile( $configpath, $maincfg->{interface}{path}{menubar} ),
        icons => catdir( $configpath, $maincfg->{resource}{icons} ),
        ymlconnection =>
            catdir( $configpath, $maincfg->{templates}{connection} ),
        qdftemplate => catfile( $configpath, $maincfg->{templates}{qdf} ),
    };

    if ( $self->can('cfname') ) {
        my $cfname = $self->cfname;
        $main_hr->{connfile}
            = catfile( $self->cfdb, $cfname, 'etc', 'connection.yml' );
        $main_hr->{qdfpath} = catdir( $self->cfdb, $cfname, 'qdf' );
    }

    my @accessor = keys %{$main_hr};

    $self->_make_accessors($main_hr);

    return $maincfg;
}

=head2 _config_conn_load

Initialize the runtime connection configuration file name and path and
some miscellaneous info from the main configuration file.

The B<connection> configuration is special.  More than one connection
configuration is allowed and the name of the used connection is known
only at runtime from the I<cfname> argument.

Load the connection configuration file.  This is treated separately
because the path is only known at runtime.

=cut

sub _config_conn_load {
    my ( $self, $args ) = @_;

    # Connection
    my $conn_file = $self->connfile;

    my $msg = qq{\nConfiguration error, to fix, run\n\n};
    $msg   .= qq{ tpda-qrt -init };
    $msg   .= $self->cfname . qq{\n\n};
    $msg   .= qq{then edit: $conn_file\n};
    my $cfg_data = $self->_config_file_load($conn_file, $msg);

    $cfg_data->{cfgconnfile} = $conn_file; # accessor for connection file

    $self->_make_accessors($cfg_data);

    return;
}

=head2 _config_interface_load

Process the main configuration file and automaticaly load all the
other defined configuration files.  That means if we add a YAML
configuration file to the tree, all defined values should be available
at restart.

=cut

sub _config_interface_load {
    my $self = shift;

    my $cfg_toolbar = $self->_config_file_load($self->ymltoolbar);
    my $cfg_menubar = $self->_config_file_load($self->ymlmenubar);

    my $methods = merge($cfg_toolbar, $cfg_menubar);

    $self->_make_accessors($methods);

    return;
}

=head2 _config_file_load

Load a generic config file in YAML format and return the Perl data
structure.  Die, if can't read file.

=cut

sub _config_file_load {
    my ($self, $yaml_file) = @_;

    # print "YAML file: $yaml_file\n";
    if (! -f $yaml_file) {
        my $msg = qq{\nConfiguration error: \n Can't read configurations};
        $msg   .= qq{\n  from '$yaml_file'!};
        print "$msg\n";
        die;
    }

    return TpdaQrt::Config::Utils->load($yaml_file);
}

=head2 list_configs

List all existing connection configurations.

=cut

sub list_configs {
    my $self = shift;

    my $dbpath = $self->cfdb;
    my $conn_list = TpdaQrt::Config::Utils->find_subdirs($dbpath);

    print "Connection configurations:\n";
    foreach my $cfg_name ( @{$conn_list} ) {
        my $ccfn = $self->conn_cfg_filename($cfg_name);
        # If connection file exist than list as connection name
        if (-f $ccfn) {
            print "  > $cfg_name\n";
        }
    }
    print " in '$dbpath'\n";
}

=head2 init_configs

Create new connection configuration directory and install new
configuration file from template.

=cut

sub init_configs {
    my ( $self, $conn_name ) = @_;

    my $conn_tmpl = $self->ymlconnection;
    my $conn_path = catdir( $self->cfpath, 'db', $conn_name, 'etc' );
    my $conn_qdfp = catdir( $self->cfpath, 'db', $conn_name, 'qdf' );
    my $conn_file = $self->conn_cfg_filename($conn_name);

    if ( -f $conn_file ) {
        print "Connection configuration exists, can't overwrite.\n";
        print " > $conn_name\n";
        return;
    }

    TpdaQrt::Config::Utils->create_conn_cfg_tree( $conn_tmpl, $conn_path,
        $conn_qdfp, $conn_file, );

    print "New configuration: $conn_name\n";
}

=head2 conn_cfg_filename

Return full path to connection file.

=cut

sub conn_cfg_filename {
    my ($self, $cfname) = @_;

    return catfile($self->cfpath, 'db', $cfname, 'etc', 'connection.yml');
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at users . sourceforge . net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of TpdaQrt::Config
