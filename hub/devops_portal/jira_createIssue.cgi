#!/usr/bin/perl -w
use CGI qw(:standard);
use strict;

use Data::Dumper;
use DateTime;
use JIRA::Client;
use MIME::Base64;

my $q = new CGI;
my $summary = $q->param("summary");
my $p = $q->param("p");
my $des = $q->param("des");

my $jira_user     = $q->cookie('PORTALUSER');
my $jira_password = $q->cookie('PORTALPASSWD');

my $url = "http:\/\/srwd00dvo002.stubcorp.dev\/~relmgt\/devops\/environments.cgi";
my $jira = JIRA::Client->new( 'https://jira.stubcorp.com', $jira_user, decode_base64( $jira_password ) );

my $baseurl = $jira->getServerInfo()->{baseUrl};

my $newissue = $jira->create_issue({
                project => 'TOOLS',
                type    => 'Env Support',
                summary => $summary,
                priority => $p,
                description => $des,
                reporter => $jira_user,
                assignee => 'lecai',
                custom_fields =>{'customfield_10110' => 'Tech Stream',},
});

print "Content-type: text/html\n\n";
print "Created $baseurl/browse/$newissue->{key}<br>";

#my $comment = $jira->addComment($issue, 'Comment added with SOAP');
print "<input type='button' name='Submit' value='Back' onclick ='javascript:history.go(-2);'/>";

