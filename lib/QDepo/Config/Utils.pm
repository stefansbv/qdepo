package QDepo::Config::Utils;

use warnings;
use strict;

use File::Basename;
use File::Copy;
use File::Find::Rule;
use File::Path 2.07 qw( make_path );
use File::ShareDir qw(dist_dir);
use File::Spec::Functions qw(catfile);
use File::Slurp qw(read_file);
use Try::Tiny;
use YAML::Tiny;

=head1 NAME

QDepo::Config::Utils - Utility functions for config paths and files

=head1 VERSION

Version 0.39

=cut

our $VERSION = '0.39';

=head1 SYNOPSIS

    use QDepo::Config::Utils;

    my $cu = QDepo::Config::Utils->new();

=head1 METHODS

=head2 load_yaml

Use YAML::Tiny to load a YAML file and return as a Perl hash data
structure.

=cut

sub load_yaml {
    my ( $self, $yaml_file ) = @_;

    my $conf;
    try {
        $conf = YAML::Tiny::LoadFile($yaml_file);
    }
    catch {
        my $msg = YAML::Tiny->errstr;
        die " but failed to load because:\n $msg\n";
    };

    return $conf;
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

sub save_default_yaml {
    my ( $self, $yaml_file, $key, $value ) = @_;

    my $yaml
        = ( -f $yaml_file )
        ? YAML::Tiny->read($yaml_file)
        : YAML::Tiny->new;

    $yaml->[0]->{$key} = $value;    # add new key => value

    $yaml->write($yaml_file);

    return;
}

=head2 get_licence

Slurp licence file and return the text string.  Return only the title
if the license file is not found, just to be on the save side.

=cut

sub get_license {
    my $self = shift;

    my $message = <<'END_LICENSE';

                      GNU GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

END_LICENSE

    my $license = catfile( dist_dir('QDepo'), 'license', 'gpl.txt' );

    if (-f $license) {
        return read_file($license);
    }
    else {
        return $message;
    }
}

=head2 get_help_text

Return help file path.

=cut

sub get_help_text {
    my $self = shift;

    my $message = <<'END_HELP';

                     The HELP file is missing or misconfigured!

END_HELP

    my $help_file = catfile( dist_dir('QDepo'), 'help', $self->helpfile);
    if (-f $help_file) {
        return  read_file( $help_file, binmode => ':utf8' );
    }
    else {
        return $message;
    }
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

1; # End of QDepo::Config::Utils