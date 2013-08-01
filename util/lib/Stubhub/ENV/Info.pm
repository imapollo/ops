package Stubhub::ENV::Info;

#
# Get basic Stubhub Dev environment information.
#

use strict;
use warnings;

use lib '/nas/home/minjzhang/ops/util/lib';
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
                        &get_instance_list
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

#
# Get the instance list.
#
sub get_instance_list {
    my ( $hostname ) = @_;
    Readonly my $SSH_COMMAND => '/usr/bin/sudo /usr/bin/ssh -oPasswordAuthentication=no -ostricthostkeychecking=no';
    Readonly my $RELMGT_SSH => '-i /nas/reg/relmgt/.ssh/id_dsa relmgt@';
    Readonly my $LS_COMMAND => '/bin/ls';
    Readonly my $GREP_COMMAND => '/bin/grep';

    Readonly my $JBOSS_DIR => '/opt/jboss';
    Readonly my $HTTPD_DIR => '/etc/httpd/conf/httpd.conf';
    Readonly my $ACTIVEMQ_DIR => '/opt/activemq';
    Readonly my $COLDFUSION_DIR => '/opt/coldfusionmx';
    Readonly my $MEMCACHED_DIR => '/etc/init.d/memcached';

    my @instance_list;

    push @instance_list, "httpd" if $hostname !~ /mqm/ and $hostname !~ /mch/ and $hostname !~ /bpm/;

    my $jboss_instance = `$SSH_COMMAND $RELMGT_SSH$hostname "$LS_COMMAND -ld $JBOSS_DIR" 2>/dev/null`;
    push @instance_list, "jboss" if $jboss_instance ne "";

    my $activemq_instance = `$SSH_COMMAND $RELMGT_SSH$hostname "$LS_COMMAND -ld $ACTIVEMQ_DIR" 2>/dev/null`;
    push @instance_list, "activemq" if $activemq_instance ne "";

    my $coldfusion_instance = `$SSH_COMMAND $RELMGT_SSH$hostname "$LS_COMMAND -ld $COLDFUSION_DIR" 2>/dev/null`;
    push @instance_list, "coldfusion" if $coldfusion_instance ne "";

    my $memcached_instance = `$SSH_COMMAND $RELMGT_SSH$hostname "$LS_COMMAND -ld $MEMCACHED_DIR" 2>/dev/null`;
    push @instance_list, "memcached" if $memcached_instance ne "";

    return @instance_list;
}
