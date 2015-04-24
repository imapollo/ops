#!/usr/bin/perl -w
use strict;

use CGI qw(:standard);
use CGI::Session;

my $cgi = new CGI;

my $cookie_sessionid = $cgi->cookie( -name=>'CGISESSID', -value=>'', -expires => '-1d'  );
my $cookie_username  = $cgi->cookie( -name=>'PORTALUSER', -value=>'', -expires => '-1d' );
my $cookie_password  = $cgi->cookie( -name=>'PORTALPASSWD', -value=>'', -expires => '-1d' );

$cgi->header( -cookie=>[ $cookie_sessionid, $cookie_username, $cookie_password ] );
print $cgi->redirect( -url=>'http://srwd00dvo002.stubcorp.dev/~relmgt/devops/login.html',
        -cookie=>[ $cookie_sessionid, $cookie_username, $cookie_password ] );
