package Stubhub::Git::Client;

#
# Basic P4 client operations.
#

use strict;
use warnings;

use lib '/nas/home/minjzhang/ops/util/lib';
use lib '/nas/reg/lib/perl';

use Git::Repository;
use Readonly;

BEGIN {
  use Exporter();
  our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

  $VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
  @ISA          = qw( Exporter );
  @EXPORT       = qw();
  @EXPORT_OK    = qw(
                        check_out_file
                        check_out_branch_file
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;

sub check_out_branch_file {
    my ( $url, $branch, $path ) = @_;
    my $repository = check_out_file( $url, $path );
    _checkout_branch( $repository, $branch );
    return $repository;
}

sub check_out_file {
    my ( $url, $path ) = @_;
    my $repository = _clone_repository( $url, $path );
    return $repository;
}

sub _checkout_branch {
    my ( $repository, $branch_name ) = @_;
    $repository->run( checkout => $branch_name );
}

sub _clone_repository {
    my ( $url, $directory ) = @_;
    Git::Repository->run( clone => $url, $directory );
    my $repository = Git::Repository->new( work_tree => $directory );
    return $repository;
}

sub _fetch {
    my ( $repository ) = @_;
    $repository->command( fetch => "" );
}
