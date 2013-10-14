package Stubhub::BigIP::Virtual::Handler;

#
# To operate virtual server.
#

use strict;
use warnings;

use lib '/nas/home/minjzhang/ops/util/lib';
use lib '/nas/reg/lib/perl';

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
                        &get_pub_env_virtual_servers
                        &delete_not_excluded_env_virtual_servers
                        &get_vs_default_pool
                        &get_vs_irules
                        &get_vs_destination
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;

#
# Get the default pool of a virtual server.
#
sub get_vs_default_pool {
    my ( $iControl, $vs_name ) = @_;
    return $iControl->get_default_pool_name( $vs_name );
}

#
# Get the irules of a virtual server.
# Return @irule.
#
sub get_vs_irules {
    my ( $iControl, $vs_name ) = @_;
    return $iControl->get_ltm_vs_rules( $vs_name );
}

#
# Get the destination ip of a virtual server.
#
sub get_vs_destination {
    my ( $iControl, $vs_name ) = @_;
    return $iControl->get_vs_destination( $vs_name );
}

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
    my @virtual_servers = grep /^$pattern/i, @full_virtual_servers;
    return @virtual_servers;
}

#
# Get environment specific virtual servers.
#
sub get_pub_env_virtual_servers {
    my ( $iControl, $pattern ) = @_;
    my @full_virtual_servers = get_virtual_servers( $iControl );
    my @virtual_servers = grep /^pub-$pattern/i, @full_virtual_servers;
    return @virtual_servers;
}

#
# Delete virtual servers.
#
sub delete_env_virtual_servers {
    my ( $iControl, $envid ) = @_;
    my @virtual_servers = get_env_virtual_servers( $iControl, $envid );
    $iControl->delete_virtual_servers( \@virtual_servers );
    my @pub_virtual_servers = get_pub_env_virtual_servers( $iControl, $envid );
    $iControl->delete_virtual_servers( \@pub_virtual_servers );
}

#
# Delete virtual servers, not including the excluded virtual servers.
#
sub delete_not_excluded_env_virtual_servers {
    my ( $iControl, $envid, @exclude_virtual_servers ) = @_;

    my @virtual_servers = get_env_virtual_servers( $iControl, $envid );
    my @filtered_virtual_servers;
    foreach my $virtual_server ( @virtual_servers ) {
        my $exclude = 0;
        foreach my $excluding_virtual_server ( @exclude_virtual_servers ) {
            if ( $virtual_server =~ /^$envid-$excluding_virtual_server$/i ) {
                $exclude = 1;
            }
        }
        if ( ! $exclude ) {
            push @filtered_virtual_servers, $virtual_server;
        }
    }
    $iControl->delete_virtual_servers( \@filtered_virtual_servers );

    my @pub_virtual_servers = get_pub_env_virtual_servers( $iControl, $envid );
    my @pub_filtered_virtual_servers;
    foreach my $virtual_server ( @pub_virtual_servers ) {
        my $exclude = 0;
        foreach my $excluding_virtual_server ( @exclude_virtual_servers ) {
            if ( $virtual_server =~ /^pub-$envid-$excluding_virtual_server$/i ) {
                $exclude = 1;
            }
        }
        if ( ! $exclude ) {
            push @pub_filtered_virtual_servers, $virtual_server;
        }
    }
    $iControl->delete_virtual_servers( \@pub_filtered_virtual_servers );
}

