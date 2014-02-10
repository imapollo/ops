#!/usr/bin/perl -w

use CGI qw(:standard);
use strict;

use Readonly;

my $q = new CGI;
my $envid = $q->param("envid");

print header;

Readonly my $SSH_COMMAND => '/usr/bin/ssh';
Readonly my $NOHUP_COMMAND => '/usr/bin/nohup';
Readonly my $TEE_COMMAND => '/usr/bin/tee';
Readonly my $DEPLOY_BIGIP_SCRIPT => '/nas/utl/devops/bin/deploy_bigip';

Readonly my $SUPER_USR => 'relmgt';
Readonly my $SUPER_KEY_FILE => '/nas/reg/relmgt/.ssh/id_dsa';
Readonly my $REG_HOST => 'srwd00reg015';

print "Deploying BigIP Configurations to $envid ...<br>";
print "It would take about 5-10 minutes ...<br>";

my $return = `$SSH_COMMAND -i $SUPER_KEY_FILE $REG_HOST '$DEPLOY_BIGIP_SCRIPT -e srwd59 -b pb_f5_automate -v | $TEE_COMMAND /nas/reg/relmgt/bigip_work/bigip_$envid.out &'`;
