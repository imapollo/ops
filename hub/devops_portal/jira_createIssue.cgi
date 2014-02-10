#!/usr/bin/perl -w
use CGI qw(:standard);
use strict;

use Data::Dumper;
use DateTime;
use JIRA::Client;

my $q = new CGI;
my $reporter=`cat /tmp/username`;
chomp($reporter);
my $summary = $q->param("summary");
my $p = $q->param("p");
my $des = $q->param("des");

my $jirauser = 'loqiao';
my $passwd   = 'Angel9039';
my $url = "http:\/\/srwd00dvo002.stubcorp.dev\/~relmgt\/devops\/environments.cgi";
print "Content-type: text/html\n\n";
print "$reporter<br>";
my $jira = JIRA::Client->new('https://jira.stubcorp.dev', $jirauser, $passwd);
#my $issue = $jira->getIssue('TOOLS-10000');

my $baseurl = $jira->getServerInfo()->{baseUrl};

my $newissue = $jira->create_issue({
                project => 'TOOLS',
                type    => 'Env Support',
                summary => $summary,
                priority => $p,
                description => $des,
                reporter => $reporter,
                assignee => 'lecai',
                custom_fields =>{'customfield_10110' => 'Tech Stream',},
});
print "Created $baseurl/browse/$newissue->{key}<br>";

#my $comment = $jira->addComment($issue, 'Comment added with SOAP');
#system("$cmd >/dev/null");
print "<input type='button' name='Submit' value='Back' onclick ='javascript:history.go(-2);'/>";

