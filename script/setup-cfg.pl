#!/usr/bin/perl
#
# Script to create the initial configuration tree for tpda-qrt.
#
# This uses the information from the general.yml file to create the
# tree and copy the template files.  The goal was to describe that
# tree only in the YAML file, and use it all over the place, but for
# now there is redundant info used in tpda-qrt script and in the
# Qrt::Config::Instance.pm module

use strict;
use warnings;

use Cwd;
use File::Basename;
use File::HomeDir;
use File::Spec::Functions;
use File::Path 2.07 qw( make_path remove_tree );
use File::Copy;
use File::Find::Rule;

use YAML::Tiny;

my $cwd  = getcwd();
my $home = File::HomeDir->my_home;

# Build in variables
my $cfg_p = '.tpda-qrt';
my $src_p = 'share';
my $cfg_n = 'general.yml';

# General config file
my $cfg_yml = catfile($cwd, $src_p, 'config', $cfg_n);

my $cfgs = load_yaml_config_file($cfg_yml);

# Source and destination paths
my $src_qn = catdir( $cwd, $src_p  );
my $dst_qn = catdir( $home, $cfg_p );

print "Create user configuration path and copy default config files:\n";
foreach my $cfg ( keys %{ $cfgs->{configs} } ) {

    # Loop and make destination if necessary
    foreach my $key ( keys %{ $cfgs->{configs}{$cfg} } ) {
        if ( $key eq 'dst' ) {
            my $dst = $cfgs->{configs}{$cfg}{$key};
            my ($name, $path) = fileparse($dst);
            print " create '$path' ...";
            if ( create_path($path) ) {
                print " done\n";
            }
            else { print " ERORR!\n"; }
        }
    }

    # Loop again and copy sources
    foreach my $key ( keys %{ $cfgs->{configs}{$cfg} } ) {
        if ( $key eq 'src' ) {
            print " copy '$cfgs->{configs}{$cfg}{$key}' ... ";
            my $src = $cfgs->{configs}{$cfg}{src};
            my $dst = $cfgs->{configs}{$cfg}{dst};
            if ( copy_files( $src, $dst ) ) {
                print " done\n";
            }
            else { print " ERORR!\n"; }
        }
    }
}

print "Create user configuration path and copy icons:\n";
foreach my $ico ( keys %{ $cfgs->{icons} } ) {

    # Loop and make destination if necessary
    foreach my $key ( keys %{ $cfgs->{icons}{$ico} } ) {
        if ( $key eq 'dst' ) {
            my $dst = $cfgs->{icons}{$ico}{$key};
            print " create '$dst' ...";
            if ( create_path($dst) ) {
                print " done\n";
            }
            else { print " ERORR!\n"; }
        }
    }

    # Loop again and copy icons and other files from src
    foreach my $key ( keys %{ $cfgs->{icons}{$ico} } ) {
        if ( $key eq 'src' ) {
            print " copy '$cfgs->{icons}{$ico}{$key}' ... ";
            my $src = $cfgs->{icons}{$ico}{src};
            my $dst = $cfgs->{icons}{$ico}{dst};
            if ( copy_files_recursive($src, $dst) ) {
                print " done\n";
            }
            else {
                print " ERORR!\n";
            }
        }
    }
}

sub create_path {
    my $path = shift;

    my $dst_fqn = catdir( $dst_qn, $path );

    # Check path
    if ( -d $dst_fqn ) { return 1; }

    # Only if not exists
    make_path( $dst_fqn, { error => \my $err } );
    if   (@$err) { return; }
    else         { return 1; }
}

sub copy_files {
    my ($src_n, $dst_p) = @_;

    # my ($dst_fn) = fileparse($src_n);

    my $src_fqn = catfile( $src_qn, $src_n );
    my $dst_fqn = catfile( $dst_qn, $dst_p );

    return copy($src_fqn, $dst_fqn);
}

sub copy_files_recursive {
    my ($src_p, $dst_p) = @_;

    my $src_qp = catdir( $src_qn, $src_p );

    my $files_ref = find_files($src_qp);

    my @errors;
    foreach my $src_n ( @{$files_ref} ) {
        my $src_qn = catfile($src_p, $src_n);
        push(@errors, $src_n) if not copy_files($src_qn, $dst_p);
    }

    if ( scalar @errors == 0 ) {
        return 1;
    }
    else {
        return 0;
    }
}

#---

sub load_yaml_config_file {
    my ($cnf_fqn) = @_;

    return YAML::Tiny::LoadFile($cnf_fqn);
}

sub find_files {
    my $dir = shift;

    my @files = File::Find::Rule
        ->relative
        ->file->name( '*' )
        ->in( $dir );

    return \@files;
}
