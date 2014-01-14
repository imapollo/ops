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
use Stubhub::BigIP::System::Util qw (
                                    add_object_prefix
                                );

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
                        &get_vss_destinations
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;

#
# Get the default pool of a virtual server.
#
sub get_vs_default_pool {
    my ( $bigip_ref, $vs_name ) = @_;
    return $bigip_ref->{ "iControl" }->get_default_pool_name( $vs_name );
}

#
# Get the irules of a virtual server.
# Return @irule.
#
sub get_vs_irules {
    my ( $bigip_ref, $vs_name ) = @_;
    return $bigip_ref->{ "iControl" }->get_ltm_vs_rules( $vs_name );
}

#
# Get the destination ip of a virtual server.
#
sub get_vs_destination {
    my ( $bigip_ref, $vs_name ) = @_;
    return $bigip_ref->{ "iControl" }->get_vs_destination( $vs_name );
}

#
# Get the destination ip of a virtual server.
#
sub get_vss_destinations {
    my ( $bigip_ref, @vss_name ) = @_;
    return $bigip_ref->{ "iControl" }->get_vss_destinations( \@vss_name );
}

#
# Get all the virtual servers.
#
sub get_virtual_servers {
    my ( $bigip_ref ) = @_;
    my @virtual_servers = $bigip_ref->{ "iControl" }->get_vs_list();
    return sort @virtual_servers;
}

#
# Get environment specific virtual servers.
#
sub get_env_virtual_servers {
    my ( $bigip_ref, $pattern ) = @_;
    my @full_virtual_servers = get_virtual_servers( $bigip_ref );
    $pattern = add_object_prefix( $bigip_ref, $pattern );
    my @virtual_servers = grep m\^$pattern\i, @full_virtual_servers;
    return @virtual_servers;
}

#
# Get environment specific virtual servers.
#
sub get_pub_env_virtual_servers {
    my ( $bigip_ref, $pattern ) = @_;
    my @full_virtual_servers = get_virtual_servers( $bigip_ref );
    $pattern = "pub-$pattern";
    $pattern = add_object_prefix( $bigip_ref, $pattern );
    my @virtual_servers = grep m\^$pattern\i, @full_virtual_servers;
    return @virtual_servers;
}

#
# Delete virtual servers.
#
sub delete_env_virtual_servers {
    my ( $bigip_ref, $envid ) = @_;
    my @virtual_servers = get_env_virtual_servers( $bigip_ref, $envid );
    $bigip_ref->{ "iControl" }->delete_virtual_servers( \@virtual_servers );
    my @pub_virtual_servers = get_pub_env_virtual_servers( $bigip_ref, $envid );
    $bigip_ref->{ "iControl" }->delete_virtual_servers( \@pub_virtual_servers );
}

#
# Delete virtual servers, not including the excluded virtual servers.
#
sub delete_not_excluded_env_virtual_servers {
    my ( $bigip_ref, $envid, @exclude_virtual_servers ) = @_;

    my @virtual_servers = get_env_virtual_servers( $bigip_ref, $envid );
    my @filtered_virtual_servers;
    foreach my $virtual_server ( @virtual_servers ) {
        my $exclude = 0;
        foreach my $excluding_virtual_server ( @exclude_virtual_servers ) {
            $excluding_virtual_server = "$envid-$excluding_virtual_server";
            $excluding_virtual_server = add_object_prefix( $bigip_ref, $excluding_virtual_server );
            if ( $virtual_server =~ m\^$excluding_virtual_server$\i ) {
                $exclude = 1;
            }
        }
        if ( ! $exclude ) {
            push @filtered_virtual_servers, $virtual_server;
        }
    }
    $bigip_ref->{ "iControl" }->delete_virtual_servers( \@filtered_virtual_servers );

    my @pub_virtual_servers = get_pub_env_virtual_servers( $bigip_ref, $envid );
    my @pub_filtered_virtual_servers;
    foreach my $virtual_server ( @pub_virtual_servers ) {
        my $exclude = 0;
        foreach my $excluding_virtual_server ( @exclude_virtual_servers ) {
            my $excludeing_virtual_server = "pub-$envid-$excluding_virtual_server";
            $excluding_virtual_server = add_object_prefix( $bigip_ref, $excluding_virtual_server );
            if ( $virtual_server =~ m\^$excluding_virtual_server$\i ) {
                $exclude = 1;
            }
        }
        if ( ! $exclude ) {
            push @pub_filtered_virtual_servers, $virtual_server;
        }
    }
    $bigip_ref->{ "iControl" }->delete_virtual_servers( \@pub_filtered_virtual_servers );
}

