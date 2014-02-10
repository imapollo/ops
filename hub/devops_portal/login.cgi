#!/usr/bin/perl -w
use strict;

use MIME::Base64;
use CGI qw(:standard);
use CGI::Session;
use Net::SSH::Expect;

my $cgi = new CGI;
my $username=$cgi->param("username");
my $password=$cgi->param("passwd");

my $ssh = Net::SSH::Expect->new(
                host => "srwd00reg010.stubcorp.dev",
                user => "$username",
                password  => "$password",
                raw_pty => 1
                );

my $prompt = "[Pp]assword";
my $login_output = $ssh->login();
if ($login_output !~ /Welcome/ and $login_output !~ /Last login/ ) {
    print $cgi->redirect('http://srwd00dvo002.stubcorp.dev/~relmgt/devops/login.html');
} else {
    my $session = new CGI::Session( undef, $cgi, { Directory => '/tmp' } );
    my $cookie_sessionid = $cgi->cookie( -name=>'CGISESSID', -value=>$session->id, -expires=>'+12h' );
    my $cookie_username  = $cgi->cookie( -name=>'PORTALUSER', -value=>$username, -expires=>'+12h' );
    my $cookie_password  = $cgi->cookie( -name=>'PORTALPASSWD', -value=>encode_base64( $password ), -expires=>'+12h' );
    print $cgi->redirect( -url=>'http://srwd00dvo002.stubcorp.dev/~relmgt/devops/environments.cgi',
            -cookie=>[ $cookie_sessionid, $cookie_username, $cookie_password ] );
}
