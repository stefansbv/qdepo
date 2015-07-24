package QDepo::Config::Utils;

# ABSTRACT: Utility functions for config paths and files

use warnings;
use strict;
use Carp;

use File::Basename;
use File::Copy;
use File::Find::Rule;
use File::Path 2.07 qw( make_path );
use File::ShareDir qw(dist_dir);
use File::Spec::Functions qw(catfile);
use File::Slurp qw(read_file);
use Try::Tiny;
use YAML::Tiny;

use QDepo::Exceptions;

sub read_yaml {
    my ( $self, $yaml_file ) = @_;
    return YAML::Tiny::LoadFile($yaml_file)
        || Exception::IO::ReadError->throw(
        filename => $yaml_file,
        message  => YAML::Tiny->errstr,
        );
}

sub write_yaml {
    my ( $self, $yaml_file, $section, $data ) = @_;

    my $yaml
        = ( -f $yaml_file )
        ? YAML::Tiny->read($yaml_file)
        : YAML::Tiny->new;

    $yaml->[0]->{$section} = $data;

    $yaml->write($yaml_file)
        or Exception::IO::WriteError->throw(
        filename => $yaml_file,
        message  => YAML::Tiny->errstr,
        );

    return;
}

sub create_path {
    my ( $self, $new_path ) = @_;
    make_path( $new_path, { error => \my $err } );
    if (@$err) {
        for my $diag (@$err) {
            my ( $file, $message ) = %$diag;
            if ( $file eq '' ) {
                croak "Error: $message\n";
            }
        }
    }
    return;
}

sub create_conn_cfg_tree {
    my ( $self, $conn_tmpl, $conn_path, $conn_qdfp, $conn_file ) = @_;

    # Create tree
    $self->create_path($conn_path);
    $self->create_path($conn_qdfp);
    $self->copy_files( $conn_tmpl, $conn_path );
    return;
}

sub copy_files {
    my ( $self, $src_fqn, $dst_p ) = @_;
    if ( !-f $src_fqn ) {
        print "Source not found:\n $src_fqn\n";
        print "Use script/setup-cfg.pl to initialize the config path!\n";
        return;
    }
    if ( !-d $dst_p ) {
        print "Destination path not found:\n $dst_p\n";
        return;
    }
    copy( $src_fqn, $dst_p ) or croak $!;
    return;
}

sub find_subdirs {
    my ( $self, $dir ) = @_;

    # Find all the sub directories of a given directory
    my $rule = File::Find::Rule->new->mindepth(1)->maxdepth(1);

    # Ignore git
    $rule->or( $rule->new->directory->name('.git')->prune->discard,
        $rule->new );

    my @subdirs = $rule->directory->in($dir);

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

    $yaml->write($yaml_file)
        or Exception::IO::WriteError->throw(
        filename => $yaml_file,
        message  => YAML::Tiny->errstr,
        );

    return;
}

sub get_license {
    my $self = shift;

    my $message = <<'END_LICENSE';

                      GNU GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

END_LICENSE

    my $license = catfile( dist_dir('QDepo'), 'license', 'gpl.txt' );

    if ( -f $license ) {
        return read_file($license);
    }
    else {
        return $message;
    }
}

sub get_help_text {
    my $self = shift;

    my $message = <<'END_HELP';

                     The HELP file is missing or misconfigured!

END_HELP

    my $help_file = catfile( dist_dir('QDepo'), 'help', $self->helpfile );
    if ( -f $help_file ) {
        return read_file( $help_file, binmode => ':utf8' );
    }
    else {
        return $message;
    }
}

1;

__END__

=pod

=head1 SYNOPSIS

    use QDepo::Config::Utils;

    my $cu = QDepo::Config::Utils->new();

=head2 load_yaml

Use YAML::Tiny to load a YAML file and return as a Perl hash data structure.

=head2 create_path

Create a new path

=head2 create_conn_cfg_tree

Create connection configuration tree and copy connection configuration template
to newly created path.

=head2 copy_files

Copy files

=head2 find_subdirs

Find subdirectories of a directory, not recursively

=head2 get_licence

Slurp licence file and return the text string.  Return only the title if the
license file is not found, just to be on the save side.

=head2 get_help_text

Return help file path.

=cut
