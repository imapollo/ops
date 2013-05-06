package Stubhub::Util::Command;

use strict;
use warnings;

use lib '/nas/reg/lib/perl';
use lib '/nas/home/minjzhang/ops/util/lib';

use Readonly;

BEGIN {
  use Exporter();
  our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

  $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

  @ISA          = qw( Exporter );
  @EXPORT       = qw();
  @EXPORT_OK    = qw(
                      &run_cmd
                      &ssh_cmd
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;

#
# Run External Command.
#
sub run_cmd {
  my ( $command ) = @_;
  my @output = `$command`;
  my $status = $? >> 8;
  return ( $status, @output );
}

#
# SSH to the host and run external command without password.
#
sub ssh_cmd {
  my ( $server, $command ) = @_;
  Readonly my $SSH => "ssh";
  Readonly my $SSH_TIMEOUT => 10;
  return run_cmd("$SSH -o ConnectTimeout=$SSH_TIMEOUT $server $command");
}
