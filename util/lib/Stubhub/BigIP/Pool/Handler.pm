package Stubhub::BigIP::Pool::Handler;

#
# To operate pool.
#

use strict;
use warnings;

use lib '/nas/reg/lib/perl';
use lib '/nas/home/minjzhang/ops/util/lib';

use Readonly;
use Data::Dumper;
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
                        &enable_pool_member
                        &disable_pool_member
                        &get_monitor_state
                        &delete_env_pools
                        &get_pool_list
                        &get_env_pool_list
                        &delete_not_excluded_env_pools
                        &get_pool_members_status
                        &get_env_pool_members
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;

#
# Get pool list for all the environments.
#
sub get_pool_list {
    my ( $bigip_ref ) = @_;
    my @pool_list = $bigip_ref->{ "iControl" }->get_pool_list();
    return sort @pool_list;
}

#
# Get environment specific pool list.
#
sub get_env_pool_list {
    my ( $bigip_ref, $pattern ) = @_;
    my @full_pool_list = get_pool_list( $bigip_ref );
    $pattern = add_object_prefix( $bigip_ref, $pattern );
    my @pool_list = grep m\^$pattern\i, @full_pool_list;
    return @pool_list;
}

#
# Delete pools.
#
sub delete_env_pools {
    my ( $bigip_ref, $pattern ) = @_;
    my @pools = get_env_pool_list( $bigip_ref, $pattern );
    $bigip_ref->{ "iControl" }->delete_pools( \@pools );
}

#
# Delete pools with exclude list.
#
sub delete_not_excluded_env_pools {
    my ( $bigip_ref, $pattern, @exclude_pools ) = @_;
    my @pools = get_env_pool_list( $bigip_ref, $pattern );
    my @filtered_pools;
    foreach my $pool ( @pools ) {
        my $exclude = 0;
        foreach my $excluding_pool ( @exclude_pools ) {
            if ( $pool =~ /^$pattern-$excluding_pool$/i ) {
                $exclude = 1;
            }
        }
        if ( ! $exclude ) {
            push @filtered_pools, $pool;
        }
    }
    $bigip_ref->{ "iControl" }->delete_pools( \@filtered_pools );
}

#
# Get pool_members status.
#
sub get_pool_members_status {
    my ( $bigip_ref, $pool ) = @_;
    my $pool_members_status = $bigip_ref->{ "iControl" }->get_pool_member_status( $pool );
    return $pool_members_status;
}

#
# Get the pool members.
#
sub get_env_pool_members {
    my ( $bigip_ref, $pool ) = @_;
    return $bigip_ref->{ "iControl" }->get_pool_members( $pool );
}

#
# Enable a pool member.
#
sub enable_pool_member {
    my ( $bigip_ref, $pool, $pool_member ) = @_;
    $bigip_ref->{ "iControl" }->enable_pool_member( $pool, $pool_member );
}
#
# Disable a pool member.
#
sub disable_pool_member {
    my ( $bigip_ref, $pool, $pool_member ) = @_;
    $bigip_ref->{ "iControl" }->disable_pool_member( $pool, $pool_member );
}

sub get_monitor_state {
    my ( $bigip_ref, $pool ) = @_;
    my @states = $bigip_ref->{ "iControl" }->get_monitor_states( $pool );
    my $pool_state_ref = $states[0];
    foreach my $monitor_state_ref ( @{ $pool_state_ref->[0] } ) {
        print $monitor_state_ref->{ "enabled_state" } . "\n";
        print $monitor_state_ref->{ "instance_state" } . "\n";
        print $monitor_state_ref->{ "instance" }->{ "template_name"} . "\n";
        print $monitor_state_ref->{ "instance" }->{ "instance_definition" }->{ "ipport"}->{ "address" } . "\n";
        print $monitor_state_ref->{ "instance" }->{ "instance_definition" }->{ "ipport"}->{ "port" } . "\n";
    }
}
