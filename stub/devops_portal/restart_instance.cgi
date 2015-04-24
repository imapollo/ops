#!/usr/bin/perl -w

use CGI qw(:standard redirect referer);
use strict;

use Readonly;

my $q = new CGI;
my $host = $q->param("host");
my $instance = $q->param("instance");

Readonly my $SSH_COMMAND => '/usr/bin/ssh -oPasswordAuthentication=no -ostricthostkeychecking=no';
Readonly my $SUDO_COMMAND => '/usr/bin/sudo';
Readonly my $SERVICE_COMMAND => '/sbin/service';

Readonly my $SUPER_USR => 'relmgt';
Readonly my $SUPER_KEY_FILE => '/nas/reg/relmgt/.ssh/id_dsa';

if ( $instance eq "jboss" ) {
    `/nas/home/minjzhang/bin/restart_jboss $host`;
} elsif ( $instance eq "httpd" ) {
    `$SSH_COMMAND -i $SUPER_KEY_FILE $host '$SUDO_COMMAND $SERVICE_COMMAND httpd restart'`;
} elsif ( $instance eq "activemq" ) {
    if ( $host =~ /mqm/ ) {
        `$SSH_COMMAND -i $SUPER_KEY_FILE $host '$SUDO_COMMAND $SERVICE_COMMAND broker-slave stop'`;
        `$SSH_COMMAND -i $SUPER_KEY_FILE $host '$SUDO_COMMAND $SERVICE_COMMAND broker-master stop'`;
        `$SSH_COMMAND -i $SUPER_KEY_FILE $host '$SUDO_COMMAND $SERVICE_COMMAND broker-master start'`;
        `$SSH_COMMAND -i $SUPER_KEY_FILE $host '$SUDO_COMMAND $SERVICE_COMMAND broker-slave start'`;
    } else {
        `$SSH_COMMAND -i $SUPER_KEY_FILE $host '$SUDO_COMMAND $SERVICE_COMMAND activeMQ start'`;
    }
} elsif ( $instance eq "coldfusion" ) {
    `$SSH_COMMAND -i $SUPER_KEY_FILE $host '$SUDO_COMMAND $SERVICE_COMMAND coldfusionmx restart'`;
} elsif ( $instance eq "memcached" ) {
    `$SSH_COMMAND -i $SUPER_KEY_FILE $host '$SUDO_COMMAND $SERVICE_COMMAND memcached restart'`;
}

print $q->redirect( $q->referer() );
