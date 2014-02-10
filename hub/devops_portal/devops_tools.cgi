#!/usr/bin/perl -w

use CGI qw(:standard);
use strict;

use Readonly;

my $cgi = new CGI;
my $envid = $cgi->param("envid");

# Check if already login
my $login_user = $cgi->cookie('PORTALUSER');
if ( not $login_user ) {
    # system('$SLEEP_COMMAND 3');
    print $cgi->redirect('http://srwd00dvo002.stubcorp.dev/~relmgt/devops/login.html');
}

print header;

Readonly my $GREP_COMMAND => '/bin/grep';

Readonly my $SUPER_USR => 'relmgt';
Readonly my $SUPER_KEY_FILE => '/nas/reg/relmgt/.ssh/id_dsa';
Readonly my $REG_HOST => 'srwd00reg015';

print "<html><head>
<style type='text/css'>
body { font-family: 'Trebuchet MS', Arial, Helvetica, sans-serif; }
a { color: #000 }
a:hover { color: #000; bottom }
#header { margin: 0 auto 10px; height: 80px; width: 760px; padding-bottom: 10px; border-bottom: 1px solid #444 }
#logo { float: left }
#jira_link { float: right; padding-top: 60px }
#wrapper { margin: 0 auto; width: 760px; clear: both }
#wrapper td { width: 250px; vertical-align: top }
#wrapper td.table_header { width: 250px; padding-bottom: 15px }
</style>
</head>";

print "<body>";

print "<div id='header'>
<div id='logo'><a href='environments.cgi'><img src='static/devops_logo.png'/></a></div>
<div id='jira_link'>
    <a href='jira_createIssue.html'>Create ENV Support Ticket</a>
    <a href='logout.cgi'>Log Off</a>
</div>
</div>";

print "<div id='wrapper'>";

print "<table><tr>
<td class='table_header'>DevOps</td><td class='table_header'>REG</td><td class='table_header'>QA/DEV</td>
</tr>";

print "<tr>";

# DevOps Tools
print "<td>";
print "<form action='deploy_bigip.cgi'><input name='envid' type='hidden' value='" . $envid . "'/><input type='submit' value='Deploy BigIP'/></form>";
print "<form action=''><input name='envid' type='hidden' value='" . $envid . "'/><input type='submit' value='EOM'/></form>";
print "</td>";

# REG Tools
print "<td>";
print "<p><a href='https:\/\/rabbit.stubcorp.dev\/login'>Rabbit</a></p>";
print "<p><a href='http:\/\/jenkins.stubcorp.dev'>Jenkins</a></p>";
print "<p><a href='https:\/\/jira.stubcorp.dev'>JIRA</a></p>";
print "<p><a href='https:\/\/footprints.stubcorp.com\/MRcgi\/MRentrancePage.pl'>Footprint</a></p>";
print "</td>";

# QA/DEV Tools
print "<td>";
print "<form action=''><input name='envid' type='hidden' value='" . $envid . "'/><input type='submit' value='Switch Driver'/></form>";
print "<form action=''><input name='envid' type='hidden' value='" . $envid . "'/><input type='submit' value='Republish Index'/></form>";
print "</td>";

print "<tr/>";

print "</div>
</body></html>";
