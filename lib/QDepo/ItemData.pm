package QDepo::ItemData;

# ABSTRACT: Holds the current item data

use strict;
use warnings;

use QDepo::Config;

sub new {
    my ($class, $data) = @_;

    my $self = {};
    $self->{data} = $data;
    $self->{_cfg} = QDepo::Config->instance();
    bless $self, $class;

    return $self;
}

sub cfg {
    my $self = shift;
    return $self->{_cfg};
}

sub file {
    my $self = shift;
    return $self->{data}{file};
}

sub sql {
    my $self = shift;
    return $self->{data}{body}{sql};
}

sub params {
    my $self = shift;
    return $self->{data}{parameters};
}

sub output {
    my $self = shift;
    return $self->{data}{header}{output};
}

sub filename {
    my $self = shift;

    # The relative file path to display to the user
    $self->{data}{header}{filename}
        = File::Spec->abs2rel( $self->file, $self->cfg->qdfpath );
    return $self->{data}{header}{filename};
}

sub title {
    my $self = shift;
    return $self->{data}{header}{title};
}

sub descr {
    my $self = shift;
    return $self->{data}{header}{description};
}

1;
