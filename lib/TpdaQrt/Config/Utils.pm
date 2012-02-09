package TpdaQrt::Config::Utils;

use warnings;
use strict;

use File::Basename;
use File::Find::Rule;
use File::Path 2.07 qw( make_path );
use File::Copy;
use YAML::Tiny;

=head1 NAME

TpdaQrt::Config::Utils - Utility functions for config paths and files

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

    use TpdaQrt::Config::Utils;

    my $cu = TpdaQrt::Config::Utils->new();

=head1 METHODS

=head2 load

Use YAML::Tiny to load a YAML file and return as a Perl hash data
structure.

=cut

sub load {
    my ( $self, $yaml_file ) = @_;

    return YAML::Tiny::LoadFile( $yaml_file );
}

=head2 create_path

Create a new path

=cut

sub create_path {
    my ($self, $new_path) = @_;

    make_path(
        $new_path,
        { error => \my $err }
    );
    if (@$err) {
        for my $diag (@$err) {
            my ($file, $message) = %$diag;
            if ($file eq '') {
                die "Error: $message\n";
            }
        }
    }

    return;
}

=head2 create_conn_cfg_tree

Create connection configuration tree and copy connection configuration
template to newly created path.

=cut

sub create_conn_cfg_tree {
    my ($self, $conn_tmpl, $conn_path, $conn_qdfp, $conn_file) = @_;

    # Create tree
    $self->create_path($conn_path);
    $self->create_path($conn_qdfp);
    $self->copy_files($conn_tmpl, $conn_path);
}

=head2 copy_files

Copy files

=cut

sub copy_files {
    my ($self, $src_fqn, $dst_p) = @_;

    if ( !-f $src_fqn ) {
        print "Source not found:\n $src_fqn\n";
        print "Use script/setup-cfg.pl to initialize the config path!\n";
        return;
    }
    if ( !-d $dst_p ) {
        print "Destination path not found:\n $dst_p\n";
        return;
    }

    copy( $src_fqn, $dst_p ) or die $!;
}

=head2 find_subdirs

Find subdirectories of a directory, not recursively

=cut

sub find_subdirs {
    my ($self, $dir) = @_;

    # Find all the sub directories of a given directory
    my $rule = File::Find::Rule->new
        ->mindepth(1)
        ->maxdepth(1);
    # Ignore git
    $rule->or(
        $rule->new
            ->directory
            ->name('.git')
            ->prune
            ->discard,
        $rule->new);

    my @subdirs = $rule->directory->in( $dir );

    my @dbs = map { basename($_); } @subdirs;

    return \@dbs;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 - 2011 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of TpdaQrt::Config::Utils
