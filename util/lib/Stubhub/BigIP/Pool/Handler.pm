package Stubhub::BigIP::Pool::Handler;

#
# To operate pool.
#

use strict;
use warnings;

use lib '/nas/reg/lib/perl';
use lib '/nas/home/minjzhang/ops/util/lib';

use Readonly;
use BigIP::iControl;

BEGIN {
  use Exporter();
  our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

  $VERSION = do { my @r = (q$Revision: 1.0 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

  @ISA          = qw( Exporter );
  @EXPORT       = qw();
  @EXPORT_OK    = qw(
                        &delete_env_pools
                        &get_pools
                        &get_env_pools
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;

#
# Get pool list for all the environments.
#
sub get_pool_list {
    my ( $iControl ) = @_;
    my @pool_list = $iControl->get_pool_list();
    return sort @pool_list;
}

#
# Get environment specific pool list.
#
sub get_env_pool_list {
    my ( $iControl, $pattern ) = @_;
    my @full_pool_list = get_pool_list( $iControl );
    my @pool_list = grep /$pattern/i, @full_pool_list;
    return @pool_list;
}

#
# Delete pools.
#
sub delete_env_pools {
    my ( $iControl, $pattern ) = @_;
    my @pools = get_env_pool_list( $iControl, $pattern );
    $iControl->delete_pools( \@pools );
}
