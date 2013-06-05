package Stubhub::BigIP::Virtual::Handler;

#
# To operate virtual server.
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
                        &delete_env_virtual_servers
                        &get_virtual_servers
                        &get_env_virtual_servers
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;

#
# Get all the virtual servers.
#
sub get_virtual_servers {
    my ( $iControl ) = @_;
    my @virtual_servers = $iControl->get_vs_list();
    return sort @virtual_servers;
}

#
# Get environment specific virtual servers.
#
sub get_env_virtual_servers {
    my ( $iControl, $pattern ) = @_;
    my @full_virtual_servers = get_virtual_servers( $iControl );
    my @virtual_servers = grep /$pattern/i, @full_virtual_servers;
    return @virtual_servers;
}

#
# Delete virtual servers.
#
sub delete_env_virtual_servers {
    my ( $iControl, $envid ) = @_;
    my @virtual_servers = get_env_virtual_servers( $iControl, $envid );
    $iControl->delete_virtual_servers( \@virtual_servers );
}

