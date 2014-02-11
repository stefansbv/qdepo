package QDepo::ItemData;

use strict;
use warnings;

use QDepo::Config;

=head1 NAME

QDepo::ItemData - Holds the current item data.

=head1 VERSION

Version 0.39

=cut

our $VERSION = '0.39';

=head1 SYNOPSIS

    use QDepo::ItemData;

    my $out = QDepo::ItemData->new();


=head1 METHODS

=head2 new

Constructor.

=cut

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

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of QDepo::ItemData
