package Stubhub::Cobbler::Reports;

use strict;
use warnings;

use lib '/nas/reg/lib/perl';
use lib '/nas/home/minjzhang/ops/util/lib';

use Readonly;
use Stubhub::Util::Command qw ( ssh_cmd );

BEGIN {
  use Exporter();
  our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

  $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

  @ISA          = qw( Exporter );
  @EXPORT       = qw();
  @EXPORT_OK    = qw(
                      &list_systems
                      &list_matched_systems
                      &get_readable_system_profile
                      &get_system_profile
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;

Readonly my $COBBLER_SERVER => "srwd00pup001.stubcorp.dev";

Readonly my $COBBLER_LIST_SYSTEMS_COMMAND => "sudo cobbler system list";
Readonly my $COBBLER_SHOW_SYSTEM_PROFILE  => "sudo cobbler system report --name=";
Readonly my $COBBLER_DUMP_SYSTEM_VARS     => "sudo cobbler system dumpvars --name=";

#my %profile = ();

#
# Get all the systems in cobbler.
#
sub get_systems {
  my ( $status, @output ) = ssh_cmd($COBBLER_SERVER, $COBBLER_LIST_SYSTEMS_COMMAND);
  my @systems;
  foreach my $system ( @output ) {
    $system =~ s/\s*(\S*)\s*/$1/;
    push @systems, $system;
  }
  @systems = sort @systems;
  return @systems;
}

#
# List all the systems in cobbler.
#
sub list_systems {
  my @systems = get_systems();
  foreach my $system ( @systems ) {
    print "$system\n";
  }
}

#
# List all the cobbler systems which match the pattern.
#
sub list_matched_systems {
  my ( $pattern ) = @_;
  my @systems =  get_systems();
  my @matched_systems = grep /$pattern/, @systems;
  foreach my $system ( @matched_systems ) {
    print "$system\n";
  }
}

#
# Show readable settings for specific system.
#
sub get_readable_system_profile {
  my ( $system ) = @_;
  my ( $status, @output ) = ssh_cmd($COBBLER_SERVER, "$COBBLER_SHOW_SYSTEM_PROFILE$system");
  print @output;
}

#
# Get settings for specific system.
#
sub get_system_profile {
  my ( $system ) = @_;
  my ( $status, @output ) = ssh_cmd($COBBLER_SERVER, "$COBBLER_DUMP_SYSTEM_VARS$system");

  my %profile = ();
  $profile{"distro"}          = get_system_value( "distro", @output );
  $profile{"gateway"}         = get_system_value( "gateway", @output );
  $profile{"hostname"}        = get_system_value( "hostname", @output );
  $profile{"ldap_type"}       = get_system_value( "ldap_type", @output );
  $profile{"netboot_enabled"} = get_system_value( "netboot_enabled", @output );
  $profile{"power_type"}      = get_system_value( "power_type", @output );
  $profile{"profile"}         = get_system_value( "profile", @output );
  $profile{"system_name"}     = get_system_value( "system_name", @output );

  # name_servers : ['10.80.10.175', '10.80.10.176']
  # eth0
  # eth0:0
  # havnic0
  # imaging
  get_network_interfaces( @output );

  return %profile;
}

#
# Get network interfaces.
#
sub get_network_interfaces {
  my ( @settings ) = @_;
  my @interface_names = grep /^mac_address_/, @settings;
  print @interface_names;
  @interface_names = map { local $_ = $_; s/^mac_address_(\S*)\s*:.*$/$1/; $_ } @interface_names;

  my %interfaces = ();
  foreach my $interface_name ( @interface_names ) {
    $interfaces{"$interface_name"} = get_network_interface_values($interface_name, @settings);
  }
  return %interfaces;
}

#
# Get specific network interface values.
sub get_network_interface_values {
  my ( $interface, @settings ) = @_;
  my %interface_values = (
    "ip_address" => get_system_value("ip_address_$interface");
    "mac_address" => get_system_value("mac_address_$interface");
    "netmask" => get_system_value("netmask_$interface");
    "static" => get_system_value("static_$interface");
    "virt_bridge" => get_system_value("virt_bridge_$interface");
  );
  return %interface_values;
}

#
# Get system value for specific system.
#
sub get_system_value {
  my ( $key, @settings ) = @_;
  my @values = grep /^$key/, @settings;
  my $value = $values[0];
  $value =~ s/^$key\s+:\s+(\S*)\s*$/$1/;
  return $value;
}
