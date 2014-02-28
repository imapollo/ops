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
use Stubhub::Util::Host qw (
                                    get_hostname_by_ip
                                );
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
                        &get_pool_members_status_without_monitor
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
# Get pool member status details
sub get_pool_members_status_details {
    my ( $bigip_ref, $pool, $get_monitor ) = @_;
    my $pool_members_status = ${ $bigip_ref->{ "iControl" }->get_pool_member_status( $pool )}[0];

    my $pool_members_monitor_status;
    if ( $get_monitor ) {
        $pool_members_monitor_status = get_monitor_state( $bigip_ref, $pool );
    }

    my @no_bless_pool_members_status;

    # Convert to no bless data structure due to JSON module limitation.
    foreach my $pool_member_status_ref ( @{ $pool_members_status } ) {
        my %no_bless_pool_status;
        $no_bless_pool_status{ 'member' }{ 'address' } = get_hostname_by_ip( $pool_member_status_ref->{ 'member' }->{ 'address' } );
        $no_bless_pool_status{ 'member' }{ 'port' } = $pool_member_status_ref->{ 'member' }->{ 'port' };
        $no_bless_pool_status{ 'object_status' }{ 'availability_status' } = $pool_member_status_ref->{ 'object_status' }->{ 'availability_status' };
        $no_bless_pool_status{ 'object_status' }{ 'enabled_status' } = $pool_member_status_ref->{ 'object_status' }->{ 'enabled_status' };

        if ( $get_monitor ) {
            foreach my $pool_member_monitor_status ( @{ $pool_members_monitor_status } ) {
                if ( get_hostname_by_ip( $pool_member_monitor_status->{ 'member' }{ 'address' } ) eq $no_bless_pool_status{ 'member' }{ 'address' } ) {
                    # and $pool_member_monitor_status->{ 'member' }{ 'port' } eq $no_bless_pool_status{ 'member' }{ 'port' } ) {
                    $no_bless_pool_status{ 'monitor' } = $pool_member_monitor_status->{ 'monitor' };
                }
            }
        }
        push @no_bless_pool_members_status, \%no_bless_pool_status;
    }
    return \@no_bless_pool_members_status;
}

#
# Get pool members status.
#
sub get_pool_members_status {
    my ( $bigip_ref, $pool ) = @_;
    return get_pool_members_status_details( $bigip_ref, $pool, 1 );
}

#
# Get pool members status without monitor details.
#
sub get_pool_members_status_without_monitor {
    my ( $bigip_ref, $pool ) = @_;
    return get_pool_members_status_details( $bigip_ref, $pool, 0 );
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

#
# Get the status of monitors.
#
sub get_monitor_state {
    my ( $bigip_ref, $pool ) = @_;
    my @states = $bigip_ref->{ "iControl" }->get_monitor_states( $pool );
    my $pool_state_ref = $states[0];
    my @pool_members_monitor_status;
    foreach my $monitor_state_ref ( @{ $pool_state_ref->[0] } ) {
        my %pool_member_monitor_status;

        my $the_address = $monitor_state_ref->{ "instance" }->{ "instance_definition" }->{ "ipport"}->{ "address" };
        my $the_port = $monitor_state_ref->{ "instance" }->{ "instance_definition" }->{ "ipport"}->{ "port" };
        my $the_enabled_state = $monitor_state_ref->{ "enabled_state" };
        my $the_instance_state = $monitor_state_ref->{ "instance_state" };
        my $the_template_name = $monitor_state_ref->{ "instance" }->{ "template_name"};

        # TODO store the template string into a static hash
        my $send_string = $bigip_ref->{ "iControl" }->get_monitor_template_send( $the_template_name ) if defined $the_template_name and $the_template_name !~ /\/none$/;
        if ( $send_string ) {
            $send_string =~ s/^GET //;
            $send_string =~ s/\\r\\n$//;
            $send_string = get_hostname_by_ip( $the_address ) . $send_string;
        }

        # Check if the member address:ip already in
        # @pool_members_monitor_status
        my %pool_monitor_status;
        my @pool_monitors_status;

        my $found_pool_member = 0;

        foreach my $added_pool_members_monitor_status ( @pool_members_monitor_status ) {
            if ( $added_pool_members_monitor_status->{ "member" }{ "address" } eq $the_address 
                    and $added_pool_members_monitor_status->{ "member" }{ "port" } eq $the_port ) {
                @pool_monitors_status = @{ $added_pool_members_monitor_status->{ "monitor" } };
                $pool_monitor_status{ "enabled_state" } = $the_enabled_state;
                $pool_monitor_status{ "instance_state" } = $the_instance_state;
                $pool_monitor_status{ "template_name" } = $the_template_name;
                $pool_monitor_status{ "send_string" } = $send_string;
                push @pool_monitors_status, \%pool_monitor_status;
                $added_pool_members_monitor_status->{ "monitor" } = \@pool_monitors_status;
                $found_pool_member = 1;
                last;
            }
        }
        next if $found_pool_member;

        $pool_member_monitor_status{ "member" }{ "address" } = $the_address;
        $pool_member_monitor_status{ "member" }{ "port" } = $the_port;

        $pool_monitor_status{ "enabled_state" } = $the_enabled_state;
        $pool_monitor_status{ "instance_state" } = $the_instance_state;
        $pool_monitor_status{ "template_name" } = $the_template_name;
        $pool_monitor_status{ "send_string" } = $send_string;
        push @pool_monitors_status, \%pool_monitor_status;
        $pool_member_monitor_status{ "monitor" } = \@pool_monitors_status;

        push @pool_members_monitor_status, \%pool_member_monitor_status;
    }
    return \@pool_members_monitor_status;
}
