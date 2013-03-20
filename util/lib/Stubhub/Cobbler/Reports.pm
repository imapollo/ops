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
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;

Readonly my $COBBLER_SERVER => "srwd00pup001.stubcorp.dev";

Readonly my $COBBLER_LIST_SYSTEMS_COMMAND => "sudo cobbler system list";
Readonly my $COBBLER_SHOW_SYSTEM_PROFILE  => "sudo cobbler system report --name=";
Readonly my $COBBLER_DUMP_SYSTEM_VARS     => "sudo cobbler system dumpvars --name=";

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
  return @output;
}
