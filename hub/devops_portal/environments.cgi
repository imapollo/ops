#!/usr/bin/perl -w

use CGI qw(:standard);
use strict;

use Readonly;
use Data::Dumper;

my $q = new CGI;

print header;

Readonly my $GREP_COMMAND => '/bin/grep';
Readonly my $CAT_COMMAND => '/bin/cat';
Readonly my $SED_COMMAND => '/bin/sed';
Readonly my $UNIQ_COMMAND => '/usr/bin/uniq';
Readonly my $SSH_COMMAND => '/usr/bin/ssh';

Readonly my $SUPER_USR => 'relmgt';
Readonly my $SUPER_KEY_FILE => '/nas/reg/relmgt/.ssh/id_dsa';
Readonly my $REG_HOST => 'srwd00reg015';

Readonly my $BIGIP_POOL_STATUS => '/nas/home/minjzhang/bigip.rpt';

my $srwd_envs = `$GREP_COMMAND 'srwd' /nas/reg/etc/dev-qa-hosts | $SED_COMMAND 's/\\(srwd[0-9]\\+\\).*/\\1/' | $UNIQ_COMMAND`;
my $srwe_envs = `$GREP_COMMAND 'srwe' /nas/reg/etc/dev-qa-hosts | $SED_COMMAND 's/\\(srwe[0-9]\\+\\).*/\\1/' | $UNIQ_COMMAND`;
my $srwq_envs = `$GREP_COMMAND 'srwq' /nas/reg/etc/dev-qa-hosts | $SED_COMMAND 's/\\(srwq[0-9]\\+\\).*/\\1/' | $UNIQ_COMMAND`;

open POOL_STATUS_FH, "<$BIGIP_POOL_STATUS" or die "Error: cannot open file $BIGIP_POOL_STATUS: $!";

my %env_pool_status;

while ( my $line = <POOL_STATUS_FH> ) {
    chomp $line;
    my $report_envid = $line;
    my $report_status = $line;
    $report_envid =~ s/(\S*) .*/$1/;
    $report_status =~ s/.* (\S*)/$1/;
    $env_pool_status{ "$report_envid" } = $report_status;
}

close POOL_STATUS_FH;

my @srwd_env_list = split "\n", $srwd_envs;
my @srwq_env_list = split "\n", $srwq_envs;
my @srwe_env_list = split "\n", $srwe_envs;

print "<html><head>
<style type='text/css'>
body { font-family: 'Trebuchet MS', Arial, Helvetica, sans-serif; }
a { color: #000 }
a:hover { color: #000; bottom }
#header { margin: 0 auto 10px; height: 80px; width: 1000px; padding-bottom: 10px; border-bottom: 1px solid #444 }
#logo { float: left }
#jira_link { float: right; padding-top: 60px; }
#wrapper { margin: 0 auto; width: 1000px; clear: both }
</style>
</head>";

print "<body>";

print "<div id='header'>
<div id='logo'><a href='environments.cgi'><img src='static/devops_logo.png'/></a></div>
<div id='jira_link'><a href='jira_createIssue.html'>Create ENV Support Ticket</a></div>
</div>";
print "<div id='wrapper'>";

print "<br>SRWD Environments<br><br>";
print_env_list( \@srwd_env_list, \%env_pool_status );

print "<br>SRWQ Environments<br><br>";
print_env_list( \@srwq_env_list, \%env_pool_status );

print "<br>SRWE Environments<br><br>";
print_env_list( \@srwe_env_list, \%env_pool_status );

sub print_env_list {
    my ( $env_list_ref, $env_pool_status_ref ) = @_;

    print "<table>\n";
    my $index = 0;
    foreach my $env ( @$env_list_ref ) {
        chomp $env;
        my $uc_env = uc($env);

        if ( $index == 0 ) {
            print "<tr>\n";
        }
        print "<td><a href='http://www.$env.com'><div style='background:url(static/env_icon.png);height: 60px;width: 60px'><b>$uc_env</b></div></a></td>\n";
        if ( $env_pool_status{ "$env" } == 0 ) {
            print "<td><img src='static/green-light.png' alt='PASS' title='PASS'/></td>\n";
        } elsif ( $env_pool_status{ "$env" } == 1 ) {
            print "<td><img src='static/blue-light.png' alt='WARN' title='WARN'/></td>\n";
        } else {
            print "<td><img src='static/red-light.png' alt='FAIL' title='FAIL'/></td>\n";
        }
        print "<td><form action='environment_status.cgi'><input id='envid' name='envid' type='hidden' value='" .$env . "'/><input type='submit' value='Check Status'/></form></td>\n";
        print "<td><form action='devops_tools.cgi'><input id='envid' name='envid' type='hidden' value='" . $env . "'.><input type='submit' value='Tools' /></form></td>\n";

        if ( $index == 3 ) {
            print "</tr>\n";
            $index = 0;
            next;
        }
        $index += 1;
    }
    print "</table>\n";
}

print "</div>
</body></html>";
