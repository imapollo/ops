#!/usr/bin/perl -w
use CGI qw(:standard);
use strict;

use Net::SSH::Expect;


my $q = new CGI;
my $username=$q->param("username");
my $passwd=$q->param("passwd");

system("echo $username > /tmp/username");

my $ssh = Net::SSH::Expect->new(
                host => "srwd00reg010.stubcorp.dev",
                user => "$username",
                password  => "$passwd",
                raw_pty => 1
                );

my $prompt = "[Pp]assword";
my $login_output = $ssh->login();
if ($login_output !~ /Welcome/ and $login_output !~ /Last login/ ) {
           print $q->redirect('http://srwd00dvo002.stubcorp.dev/~relmgt/devops/login.html');
        }
else { print $q->redirect('http://srwd00dvo002.stubcorp.dev/~relmgt/devops/environments.cgi');
}


#system("$cmd >/dev/null");
#print "<input type='button' name='Submit' value='Back' onclick ='javascript:history.back();'/>";

