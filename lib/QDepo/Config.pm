package QDepo::Config;

# ABSTRACT: The QDepo configuration module

use strict;
use warnings;

use File::HomeDir;
use File::ShareDir qw(dist_file);
use File::UserConfig;
use File::Spec::Functions qw(catdir catfile canonpath);
use File::Slurp;
use Try::Tiny;
use Locale::TextDomain 1.20 qw(QDepo);
use QDepo::Config::Connection;
use QDepo::Config::Utils;
use QDepo::Exceptions;

use base qw(Class::Singleton Class::Accessor);

sub _new_instance {
    my ($class, $args) = @_;

    my $self = bless {}, $class;

    print "Loading configuration files ...\n" if $args->{verbose};

    $self->init_configurations($args);

    # Load main configs and create accessors
    $self->load_main_config($args);

    return $self;
}

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
        default_yml => catfile( $configpath, 'etc', 'default.yml' ),
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

sub make_accessors {
    my ( $self, $cfg_hr ) = @_;

    __PACKAGE__->mk_accessors( keys %{$cfg_hr} );

    # Add data to object
    foreach ( keys %{$cfg_hr} ) {
        $self->$_( $cfg_hr->{$_} );
    }
}

sub configdir {
    my ( $self, $mnemonic ) = @_;
    $mnemonic ||= $self->mnemonic;
    return catdir( $self->dbpath, $mnemonic );
}

sub load_main_config {
    my ($self, $args) = @_;

    # Main config file name, load
    my $main_fqn = catfile( $self->cfpath, 'etc', 'main.yml' );
    my $maincfg  = $self->config_data_from($main_fqn);

    my $main_hr = {
        icons    => catdir( $self->cfpath, $maincfg->{resource}{icons} ),
        output   => canonpath( $maincfg->{output}{path} ),
        qdf_tmpl => catfile( $self->cfpath, 'template', 'template.qdf' ),
    };

    # Setup when GUI runtime
    $main_hr->{mnemonic} = $args->{mnemonic} if $args->{mnemonic};

    $self->make_accessors($main_hr);

    return;
}

sub connection {
    my $self = shift;

    my $connection_yml
        = catfile( $self->dbpath, $self->mnemonic, 'etc', 'connection.yml' );
    my $connection_data;
    if (-f $connection_yml) {
        $connection_data = $self->config_data_from($connection_yml);
    }
    else {
        print "Connection config not found: $connection_yml\n";
    }

    my $conn = QDepo::Config::Connection->new( $connection_data->{connection} );
    $conn->user( $self->user );
    $conn->pass( $self->pass );

    return $conn;
}

sub qdfpath {
    my $self = shift;
    return catdir( $self->dbpath, $self->mnemonic, 'qdf' );
}

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

sub list_mnemonics_all {
    my $self = shift;

    my @mnemonics = map { $_->{mnemonic} } @{ $self->get_mnemonics };

    my $cc_no = scalar @mnemonics;
    if ( $cc_no == 0 ) {
        print "Configurations (mnemonics): none\n";
        print ' in ', $self->dbpath, "\n";
        return;
    }

    my $default = $self->get_default_mnemonic();

    print "Configurations (mnemonics):\n";
    foreach my $name ( @mnemonics ) {
        my $d = $default eq $name ? '*' : ' ';
        print " ${d}> $name\n";
    }

    print ' in ', $self->dbpath, "\n";

    return;
}

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

sub get_details_for {
    my ($self, $mnemonic) = @_;

    die "The 'get_details_for' method reqires the 'mnemonic' parameter"
        unless $mnemonic;

    my $conn_file = $self->config_file_name($mnemonic);
    my @mnemonics = map { $_->{mnemonic} } @{ $self->get_mnemonics };

    my $conn_ref = {};
    if ( grep { $mnemonic eq $_ } @mnemonics ) {
        my $cfg_file = $self->config_file_name($mnemonic);
        $conn_ref = $self->config_data_from($conn_file);
    }

    return $conn_ref;
}

sub config_data_from {
    my ( $self, $conf_file, $not_fatal ) = @_;

    return if $not_fatal and ( ! -f $conf_file );

    my $conf;
    try {
        $conf = QDepo::Config::Utils->read_yaml($conf_file);
    }
    catch {
        if ( my $e = Exception::Base->catch($_) ) {
            if ( $e->isa('Exception::IO::ReadError') ) {
                $self->model->message_log(
                    __x('{ert} Read failed: {message} ({filename})',
                        ert      => 'EE',
                        message  => $e->message,
                        filename => $e->filename,
                    ) );
            }
            else {
                $self->model->message_log(
                    __x('{ert} {message}',
                        ert     => 'EE',
                        message => __ 'Unknown exception',
                    ) );
            }
        }
    };

    return $conf;
}

sub config_file_name {
    my ( $self, $mnemonic, $cfg_file ) = @_;
    $cfg_file ||= catfile('etc', 'connection.yml');
    return catfile( $self->configdir($mnemonic), $cfg_file);
}

sub get_mnemonics {
    my $self = shift;

    my $list = QDepo::Config::Utils->find_subdirs( $self->dbpath );

    my $default_name = $self->get_default_mnemonic;
    my $current_name = $self->can('mnemonic')
        ? $self->mnemonic
        : $default_name;

    my @mnx;
    my $idx = 0;
    foreach my $name ( @{$list} ) {
        my $default = $default_name eq $name ? 1 : 0;
        my $current = $current_name eq $name ? 1 : 0;
        my $ccfn = $self->config_file_name($name);
        if ( -f $ccfn ) {
            push @mnx,
                {
                recno    => $idx + 1,
                mnemonic => $name,
                default  => $default,
                current  => $current,
                };
            $idx++;
        }
    }

    return \@mnx;
}

sub new_config_tree {
    my ( $self, $conn_name ) = @_;

    my $conn_path = catdir( $self->cfpath, 'db', $conn_name, 'etc' );
    my $conn_qdfp = catdir( $self->cfpath, 'db', $conn_name, 'qdf' );
    my $conn_tmpl = catfile( $self->cfpath, 'template', 'connection.yml' );
    my $conn_file = $self->config_file_name($conn_name);

    if ( -f $conn_file ) {
        Exception::IO::PathExists->throw(
            pathname => $conn_name,
            message  => 'Connection configuration exists',
        );
        return;
    }

    QDepo::Config::Utils->create_conn_cfg_tree( $conn_tmpl, $conn_path,
        $conn_qdfp, $conn_file, );

    return $conn_name;
}

sub get_resource_file {
    my ($self, $dir, $file_name) = @_;
    return catfile( $self->cfpath, $dir, $file_name );
}

sub get_dist_file {
    my ($self, @path) = @_;
    return dist_file( 'QDepo', catfile(@path) );
}

sub get_default_mnemonic {
    my $self = shift;
    my $default_yml_file = $self->default_yml;
    if (-f $default_yml_file) {
        my $cfg_hr = $self->config_data_from($default_yml_file);
        return $cfg_hr->{mnemonic};
    }
    else {
        warn "No valid default mnemonic found, fall-back to 'test'\n";
        return 'test';
    }
}

sub save_default_mnemonic {
    my ($self, $arg) = @_;
    QDepo::Config::Utils->save_default_yaml(
        $self->default_yml, 'mnemonic', $arg );
    return;
}

1;

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

=head2 init_configurations

Initialize basic configuration options.  Initialize the user
configuration tree if not exists, with the I<File::UserConfig> module.

=head2 make_accessors

Automatically make accessors for the hash keys.

=head2 configdir

Return application configuration directory.  The mnemonic is an
optional parameter with default as the current mnemonic.

=head2 load_main_config

Initialize configuration variables from arguments.  Load the main
configuration file and return a HoH data structure.

Make accessors.

=head2 list_mnemonics

List all mnemonics or the selected one with details.

=head2 list_mnemonics_all

List all the configured mnemonics.

=head2 list_mnemonic_details_for

List details about the configuration name (mnemonic) if exists.

=head2 get_details_for

Return the connection configuration details.  Check the name and
return the reference only if the name matches.

=head2 config_data_from

Load a config file and return the Perl data structure.  It loads a
file in Config::General format or in YAML::Tiny format, depending on
the extension of the file.

=head2 config_file_name

Return full path to a configuration file.  Default is the connection
configuration file.

=head2 get_mnemonics

Get the connections configs list.  If connection file exist than add
to connections list and return it.

=head2 config_new

Create new connection configuration directory and install new
configuration file from template.

=head2 get_resource_file

Return resource file path.

=head2 get_dist_file

Find and return a specific file in our dist shared dir.  For example
L<help/qdepo-manual.htb>.

=head2 get_default_mnemonic

Set mnemonic to the value read from the optional L<default.yml>
configuration file.

=head2 save_default_mnemonic

Save the default mnemonic in the configs.

=cut
