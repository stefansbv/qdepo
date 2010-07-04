package Pdqm::Config::Instance;

use strict;
use warnings;

use Data::Dumper;
use File::HomeDir;
use File::Spec::Functions;

use base qw(Class::Singleton Class::Accessor);
use YAML::Tiny;

our $VERSION = 0.03;

sub _new_instance {
    my ($class, $args) = @_;

    my $self = bless {}, $class;

    # Weak check for parameter validity
    if ( $args->{cfg_name} ) {
        $self->_make_accessors( $args );
    }

    return $self;
}

sub _make_accessors {
    my ( $self, $args ) = @_;

    my $usr_cfg_fqn = $self->get_usr_config_file($args);
    my $config1 = YAML::Tiny::LoadFile( $usr_cfg_fqn );

    # Replace paths and filenames with fqn
    $self->make_fqn($args, $config1);

    my $tb_cfg_fqn = $self->get_tb_config_file();
    my $config2 = YAML::Tiny::LoadFile( $tb_cfg_fqn );

    print Dumper( $config1 );
    __PACKAGE__->mk_accessors( keys %{$config1} );
    foreach ( keys %{$config1} ) {
        $self->$_( $config1->{$_} );
    }
}

sub make_fqn {
    my ($self, $args, $config) = @_;

    my $pdqm_path  = '.pdqm';
    my $home_path  = File::HomeDir->my_home;
    # Application config path
    my $app_path_qn = catdir( $home_path, $pdqm_path, $args->{app_id} );

    #- Template
    my $templ_dir_qn = catdir( $home_path, $pdqm_path );
    my $templ_file_qn = catfile( $templ_dir_qn, $config->{qdf}{template} );
    $config->{qdf}{template} = $templ_file_qn;

    #- QDF path
    my $qdf_path = catdir( $app_path_qn, $config->{qdf}{path} );
    $config->{qdf}{path} = $qdf_path;

    #- Output
    my $out_dir_qn = catdir( $home_path, $config->{qdf}{output} );
    $config->{qdf}{output} = $out_dir_qn;

    return $config;
}

sub get_usr_config_file {
    my ($self, $args) = @_;

    my $home_path  = File::HomeDir->my_home;

    # Application config path
    my $app_path_qn = catdir(
        $home_path,
        '.pdqm',          # dir name for app config and data
        $args->{app_id},  # per application user config directory
    );

    # User configurations file (fqn)
    my $user_app_config_file = catfile(
        $app_path_qn,
        $args->{cfg_name}.'.yml',
    );

    return $user_app_config_file;
}

sub get_tb_config_file {
    my ($self, $args) = @_;

    my $home_path  = File::HomeDir->my_home;

    # Application interface config path
    my $interface_dqn = catdir( $home_path, '.pdqm', 'config/interfaces', );

    # ToolBar configurations file (fqn)
    my $tb_cfg_fqn = catfile( $interface_dqn, 'toolbar.yml', );

    return $tb_cfg_fqn;
}

1;

__END__
