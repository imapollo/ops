package Stubhub::ENV::Info;

#
# Get basic Stubhub Dev environment information.
#

use strict;
use warnings;

use lib '/nas/utl/devops/lib/perl';
use lib '/nas/reg/lib/perl';

use Readonly;
use Stubhub::Util::Command qw (
                                ssh_cmd
                            );

BEGIN {
  use Exporter();
  our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

  $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

  @ISA          = qw( Exporter );
  @EXPORT       = qw();
  @EXPORT_OK    = qw(
                        &get_env_branch
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;

#
# Get the branch name of the environment.
#
sub get_env_branch {
    my ( $envid ) = @_;
    Readonly my $JOB_SERVER => "${envid}job001.${envid}.com";
    Readonly my $STUBHUB_EAR_PATH => '/opt/jboss/server/job/deploy/stubhub';
    my $command = "ls -l $STUBHUB_EAR_PATH | awk '{ print \$11 }' | awk -F/ '{ print \$4 }' | awk -F- '{ print \$1 }'";
    my ( $status, @output ) = ssh_cmd( $JOB_SERVER, $command );
    my $branch_name = join "", @output;
    chomp $branch_name;
    return $branch_name;
}
