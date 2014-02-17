package QDepo::Config;

use strict;
use warnings;

use File::HomeDir;
use File::ShareDir qw(dist_dir);
use File::UserConfig;
use File::Spec::Functions qw(catdir catfile canonpath);
use File::Slurp;

require QDepo::Config::Utils;

use base qw(Class::Singleton Class::Accessor);

=head1 NAME

QDepo::Config - QDepo configuration module

=head1 VERSION

Version 0.39

=cut

our $VERSION = '0.39';

=head1 SYNOPSIS

Reads configuration files in I<YAML::Tiny> format and create a HoH.
Then using I<Class::Accessor>, automatically create methods from the
keys of the hash.

    use QDepo::Config;

    my $cfg = QDepo::Config->instance($args); # first time init

    my $cfg = QDepo::Config->instance(); # later, in other modules

=head1 METHODS

=head2 _new_instance

Constructor method, the first and only time a new instance is created.
All parameters passed to the instance() method are forwarded to this
method. (From I<Class::Singleton> docs).

=cut

sub _new_instance {
    my ($class, $args) = @_;

    my $self = bless {}, $class;

    $args->{cfgdefa} = 'default.yml';    # default mnemonic config file

    print "Loading configuration files ...\n" if $args->{verbose};

    $self->init_configurations($args);

    # Load main configs and create accessors
    $self->load_main_config($args);
    if ( $args->{mnemonic} ) {

        # If no config name don't bother to load this
        $self->load_interfaces_config();

        # Application configs
        $self->load_runtime_config();
    }

    return $self;
}

=head2 init_configurations

Initialize basic configuration options.

=cut

sub init_configurations {
    my ( $self, $args ) = @_;

    my $configpath = File::UserConfig->new(
        dist     => 'QDepo',
        sharedir => 'share',
    )->configdir;

    my $base_methods_hr = {
        cfpath  => $configpath,
        user    => $args->{user},                 # make accessors for user
        pass    => $args->{pass},                 # and pass
        verbose => $args->{verbose},
        dbpath  => catdir( $configpath, 'db' ),
        default => catfile( $configpath, 'etc', $args->{cfgdefa} ),
    };

    $self->make_accessors($base_methods_hr);

    # Fallback to the default mnemonic from default.yml if exists
    # unless list or init argument provied on the CLI
    $args->{mnemonic} = $self->get_default_mnemonic()
        unless ( $args->{mnemonic}
            or defined( $args->{list} )
            or defined( $args->{init} )
            or $args->{default} );

    return;
}

=head2 make_accessors

Automatically make accessors for the hash keys.

=cut

sub make_accessors {
    my ( $self, $cfg_hr ) = @_;

    __PACKAGE__->mk_accessors( keys %{$cfg_hr} );

    # Add data to object
    foreach ( keys %{$cfg_hr} ) {
        $self->$_( $cfg_hr->{$_} );
    }
}

=head2 configdir

Return application configuration directory.  The config name is an
optional parameter with default as the current application config
name.

=cut

sub configdir {
    my ( $self, $mnemonic ) = @_;

    $mnemonic ||= $self->mnemonic;

    return catdir( $self->dbpath, $mnemonic );
}

=head2 load_main_config

Initialize configuration variables from arguments, also initialize the
user configuration tree if not exists, with the I<File::UserConfig>
module.

Load the main configuration file and return a HoH data structure.

Make accessors.

=cut

sub load_main_config {
    my ($self, $args) = @_;

    # Main config file name, load
    my $main_fqn = catfile( $self->cfpath, 'etc', 'main.yml' );
    my $maincfg  = $self->config_data_from($main_fqn);

    my $main_hr = {
        cfiface  => $maincfg->{interface},
        icons    => catdir( $self->cfpath, $maincfg->{resource}{icons} ),
        output   => canonpath( $maincfg->{output}{path} ),
        qdf_tmpl => catfile( $self->cfpath, 'template', 'template.qdf' ),
    };

    # Setup when GUI runtime
    $main_hr->{mnemonic} = $args->{mnemonic} if $args->{mnemonic};

    $self->make_accessors($main_hr);

    return;
}

=head2 load_interfaces_config

Process the main configuration file and automaticaly load all the
other defined configuration files.  That means if we add a YAML
configuration file to the tree, all defined values should be available
at restart.

=cut

sub load_interfaces_config {
    my $self = shift;

    foreach my $section (qw{toolbar.yml menubar.yml}) {
        my $interface_file
            = catfile( $self->cfpath, 'etc', 'interfaces', $section );
        my $interface = $self->config_data_from($interface_file);
        $self->make_accessors($interface);
    }

    return;
}

=head2 load_runtime_config

Initialize the runtime connection configuration file name and path.

The B<connection> configuration is special.  More than one connection
configuration is allowed and the name of the used connection is
processed at runtime from the I<mnemonic> argument, or from a default
configuration.

=cut

sub load_runtime_config {
    my $self = shift;

    die "No mnemonic was set!\n" unless $self->can('mnemonic');

    my $mnemonic = $self->mnemonic;
    my $dbpath   = $self->dbpath;

    #- Connection data
    my $yml = catfile( $dbpath, $mnemonic, 'etc', 'connection.yml' );
    my $connection_data = $self->config_data_from($yml);

    #-  Accessors

    #-- Connection
    $self->make_accessors($connection_data);

    #-- Qdf files path
    my $hash_ref = {};
    $hash_ref->{qdfpath} = catdir( $dbpath, $mnemonic, 'qdf' );

    $self->make_accessors($hash_ref);

    return;
}

=head2 list_mnemonics

List all mnemonics or the selected one with details.

=cut

sub list_mnemonics {
    my ( $self, $mnemonic ) = @_;

    $mnemonic ||= q{};    # default empty

    if ($mnemonic) {
        $self->list_mnemonic_details_for($mnemonic);
    }
    else {
        $self->list_mnemonics_all();
    }

    return;
}

=head2 list_mnemonics_all

List all the configured mnemonics.

=cut

sub list_mnemonics_all {
    my $self = shift;

    my $mnemonics = $self->get_mnemonics();

    my $cc_no = scalar @{$mnemonics};
    if ( $cc_no == 0 ) {
        print "Configurations (mnemonics): none\n";
        print ' in ', $self->dbpath, "\n";
        return;
    }

    my $default = $self->get_default_mnemonic();

    print "Configurations (mnemonics):\n";
    foreach my $name ( @{$mnemonics} ) {
        my $d = $default eq $name ? '*' : ' ';
        print " ${d}> $name\n";
    }

    print ' in ', $self->dbpath, "\n";

    return;
}

=head2 list_mnemonic_details_for

List details about the configuration name (mnemonic) if exists.

=cut

sub list_mnemonic_details_for {
    my ($self, $mnemonic) = @_;

    my $conn_ref = $self->get_details_for($mnemonic);

    unless (scalar %{$conn_ref} ) {
        print "Configuration mnemonic '$mnemonic' not found!\n";
        return;
    }

    print "Configuration:\n";
    print "  > mnemonic: $mnemonic\n";
    while ( my ( $key, $value ) = each( %{ $conn_ref->{connection} } ) ) {
        print sprintf( "%*s", 11, $key ), ' = ';
        print $value if defined $value;
        print "\n";
    }
    print ' in ', $self->dbpath, "\n";

    return;
}

=head2 get_details_for

Return the connection configuration details.  Check the name and
return the reference only if the name matches.

=cut

sub get_details_for {
    my ($self, $mnemonic) = @_;

    my $conn_file = $self->config_file_name($mnemonic);
    my $conlst    = $self->get_mnemonics();

    my $conn_ref = {};
    if ( grep { $mnemonic eq $_ } @{$conlst} ) {
        my $cfg_file = $self->config_file_name($mnemonic);
        $conn_ref = $self->config_data_from($conn_file);
    }

    return $conn_ref;
}

=head2 config_data_from

Load a config file and return the Perl data structure.  It loads a
file in Config::General format or in YAML::Tiny format, depending on
the extension of the file.

=cut

sub config_data_from {
    my ( $self, $conf_file, $not_fatal ) = @_;

    if ( !-f $conf_file ) {
        print " $conf_file ... not found\n" if $self->verbose;
        if ($not_fatal) {
            return;
        }
        else {
            my $msg = 'Configuration error!';
            $msg .= $self->verbose ? '' : ", file not found:\n$conf_file";
            die $msg;
        }
    }
    else {
        print " $conf_file ... found\n" if $self->verbose;
    }

    return QDepo::Config::Utils->load_yaml($conf_file);
}

=head2 config_file_name

Return full path to a configuration file.  Default is the connection
configuration file.

=cut

sub config_file_name {
    my ( $self, $cfg_name, $cfg_file ) = @_;

    $cfg_file ||= catfile('etc', 'connection.yml');

    return catfile( $self->configdir($cfg_name), $cfg_file);
}

=head2 get_mnemonics

Get the connections configs list.  If connection file exist than add
to connections list and return it.

=cut

sub get_mnemonics {
    my $self = shift;

    my $list = QDepo::Config::Utils->find_subdirs( $self->dbpath );

    my $default = $self->get_default_mnemonic;

    my @mnx;
    my $idx = 0;
    foreach my $name ( @{$list} ) {
        my $ccfn = $self->config_file_name($name);
        if ( -f $ccfn ) {
            push @mnx,
                { recno => $idx + 1, mnemonic => $name };
            $idx++;
        }
    }

    return \@mnx;
}

=head2 new_config_tree

Create new connection configuration directory and install new
configuration file from template.

=cut

sub new_config_tree {
    my ( $self, $conn_name ) = @_;

    my $conn_path = catdir( $self->cfpath, 'db', $conn_name, 'etc' );
    my $conn_qdfp = catdir( $self->cfpath, 'db', $conn_name, 'qdf' );
    my $conn_tmpl = catfile( $self->cfpath, 'template/connection.yml' );
    my $conn_file = $self->config_file_name($conn_name);

    if ( -f $conn_file ) {
        print "Connection configuration exists, can't overwrite.\n";
        print " > $conn_name\n";
        return;
    }

    QDepo::Config::Utils->create_conn_cfg_tree( $conn_tmpl, $conn_path,
        $conn_qdfp, $conn_file, );

    return $conn_name;
}

=head2 get_resource_file

Return resource file path.

=cut

sub get_resource_file {
    my ($self, $dir, $file_name) = @_;

    return catfile( $self->cfpath, $dir, $file_name );
}

=head2 get_default_mnemonic

Set mnemonic to the value read from the optional L<default.yml>
configuration file.

=cut

sub get_default_mnemonic {
    my $self = shift;

    my $defaultapp_fqn = $self->default();
    if (-f $defaultapp_fqn) {
        my $cfg_hr = $self->config_data_from($defaultapp_fqn);
        return $cfg_hr->{mnemonic};
    }
    else {
        # $self->{_log}->info("No valid default found, using 'test'");
        print "No valid default found, using 'test'\n";
        return 'test';
    }
}

=head2 set_default_mnemonic

Save the default mnemonic in the configs.

=cut

sub set_default_mnemonic {
    my ($self, $arg) = @_;

    QDepo::Config::Utils->save_default_yaml(
        $self->default, 'mnemonic', $arg );

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>.

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of QDepo::Config
