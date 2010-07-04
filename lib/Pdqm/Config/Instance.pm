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
        $self->_make_accessors($args);
    }

    return $self;
}

sub _make_accessors {
    my ( $self, $args ) = @_;

    my $config_hr = $self->_unify_configs($args);

    __PACKAGE__->mk_accessors( keys %{$config_hr} );

    # Add data to object
    foreach ( keys %{$config_hr} ) {
        $self->$_( $config_hr->{$_} );
    }
}

sub _unify_configs {
    my ($self, $args) = @_;

    my $config_hr = $self->_get_usr_config_file($args);

    # Replace paths and filenames with fqn
    $self->_configs_make_fqn( $args, $config_hr );

    # Add arguments hash to config file
    $config_hr->{run_args} = $args;

    # Add toolbar atributes to config
    my $tb_attrs_hr = $self->_get_tb_settings($args);
    $config_hr->{toolbar} = $tb_attrs_hr->{toolbar};

    return $config_hr;
}

#--- Utility subs

sub _home_path {
    my $self = shift;
    return File::HomeDir->my_home;
}

sub _prg_config_path {
    my $self = shift;

    my $pdqm_path = '.pdqm';               # hardwired
    my $home_path = $self->_home_path();

    return catdir( $home_path, $pdqm_path );
}

sub _app_config_path {
    my ( $self, $args ) = @_;

    # Application config path

    my $pdqm_path = '.pdqm';               # hardwired
    my $home_path = $self->_home_path();

    return catdir( $home_path, $pdqm_path, $args->{app_id} );
}

sub _configs_make_fqn {
    my ( $self, $args, $config ) = @_;

    my $home_path   = $self->_home_path();          # Home
    my $app_path_qn = $self->_app_config_path($args);    # App config path

    #- Template
    my $templ_dir_qn = $self->_prg_config_path();
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

sub _get_usr_config_file {
    my ( $self, $args ) = @_;

    my $app_path_qn = $self->_app_config_path($args);

    # User configurations file (fqn)
    my $usr_cfg_fqn = catfile( $app_path_qn, $args->{cfg_name}.'.yml', );

    my $user_cfg_hr = YAML::Tiny::LoadFile($usr_cfg_fqn);

    return $user_cfg_hr;
}

sub _get_tb_settings {
    my $self = shift;

    my $app_path_qn = $self->_prg_config_path();

    # Application interface config path
    my $interface_path_qn = catdir( $app_path_qn, 'config/interfaces' );

    # ToolBar configurations file (fqn)
    my $tb_cfg_fqn = catfile( $interface_path_qn, 'toolbar.yml', );

    # Toolbar settings hash ref
    my $tb_attr_hr = YAML::Tiny::LoadFile($tb_cfg_fqn);

    return $tb_attr_hr;
}

1;

__END__
