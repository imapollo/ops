package Stubhub::BigIP::Pool::Parser;

#
# Stubhub BIG-IP Pool Parser.
#

use strict;
use warnings;

use lib '/nas/home/minjzhang/ops/util/lib';
use lib '/nas/reg/lib/perl';

use Readonly;
use BigIP::Pool::Parser qw (
                                parse_pool
                              );

BEGIN {
  use Exporter();
  our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

  $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

  @ISA          = qw( Exporter );
  @EXPORT       = qw();
  @EXPORT_OK    = qw(
                      &parse_pools
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;

#
# Parse the pools from configuration files.
#
sub parse_pools {
    my ( $pools_config_dir ) = @_;
    opendir DH, $pools_config_dir or die "Cannot open $pools_config_dir: $!";
    my @pool_config_files = grep { ! -d } readdir DH;
    closedir DH;
    my @pools;
    foreach my $pool_config_file ( @pool_config_files ) {
        my $pool_ref = parse_pool("$pools_config_dir/$pool_config_file");
        push @pools, $pool_ref;
    }
    return \@pools;
}

