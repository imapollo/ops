#!/usr/bin/perl -w

use CGI qw(:standard);
use strict;

use lib '/nas/utl/devops/lib/perl';

use Readonly;
use JSON;
use Data::Dumper;
use Stubhub::ENV::Info qw (
                            get_instance_list
                        );

my $q = new CGI;
my $envid = $q->param("envid");

print header;

Readonly my $GREP_COMMAND => '/bin/grep';
Readonly my $SED_COMMAND => '/bin/sed';
Readonly my $AWK_COMMAND => '/bin/awk';
Readonly my $LS_COMMAND => '/bin/ls';
Readonly my $UNIQ_COMMAND => '/usr/bin/uniq';
Readonly my $SSH_COMMAND => '/usr/bin/ssh -oPasswordAuthentication=no -ostricthostkeychecking=no';

Readonly my $SUPER_USR => 'relmgt';
Readonly my $SUPER_KEY_FILE => '/nas/reg/relmgt/.ssh/id_dsa';
Readonly my $REG_HOST => 'srwd00reg015';
Readonly my $VALIDATE_BIGIP_SCRIPT => '/nas/reg/bin/validate_bigip';

sub get_build_label {
    my ( $pool_host ) = @_;
    my $build_label = `$SSH_COMMAND -i $SUPER_KEY_FILE $pool_host '$LS_COMMAND -la /nas/deployed'`;
    $build_label =~ s/.*\/nas\/release\/([^\/]+)$/$1/;
    chomp $build_label;
    return $build_label;
}

sub print_pools_status {
    my ( $pools_status_ref ) = @_;

    foreach my $pool_status_ref ( @{ $pools_status_ref } ) {
        print "<tr>";
        my $pool_name = $pool_status_ref->{ 'pool' };
        my $pool_members_ref = $pool_status_ref->{ 'members' };
        my $pool_status = $pool_status_ref->{ 'status' };
        my $pool_status_description = $pool_status_ref->{ 'status_description' };

        if ( $pool_status eq 'AVAILABILITY_STATUS_GREEN' ) {
            $pool_status_description = "<img src='static/green-light.png' alt='PASS' title='PASS'/>";
        } elsif ( $pool_status eq  'AVAILABILITY_STATUS_RED' ) {
            $pool_status_description = "<img src='static/red-light.png' alt='FAIL' title='" . $pool_status_description . "'/>";
        } else {
            $pool_status_description = "<img src='static/blue-light.png' alt='WARN' title='" . $pool_status_description . "'/>";
        }

        print "<td>$pool_name</td>";
        print "<td>$pool_status_description</td>";

        my $first_member_line = 0;
        foreach my $pool_member_ref ( @{ $pool_members_ref } ) {
            if ( $pool_member_ref->{ 'member' }->{ 'address' } ne "" ) {
                if ( $first_member_line == 1 ) {
                    print "<td></td><td></td>";
                }
                print "<td>$pool_member_ref->{ 'member' }->{ 'address' }:$pool_member_ref->{ 'member' }->{ 'port' }</td>";
                if ( $pool_member_ref->{ 'object_status' }->{ 'enabled_status' } eq "ENABLED_STATUS_ENABLED" ) {
                    print "<td><img src='static/green-light.png' alt='Enabled' title='Enabled'/></td>";
                } else {
                    print "<td><img src='static/green-disable-light.png' alt='Disabled' title='Disabled'/></td>";
                }
                if ( $pool_member_ref->{ 'object_status' }->{ 'availability_status' } eq "AVAILABILITY_STATUS_GREEN" ) {
                    print "<td><img src='static/green-light.png' alt='PASS' title='PASS'/></td>";
                } else {
                    print "<td><img src='static/red-light.png' alt='FAIL' title='FAIL'/></td>";
                }
                print "<td>" . get_build_label( $pool_member_ref->{ 'member' }->{ 'address' } ) . "</td>";

                print "<td><form action='restart_instance.cgi'>
                <input name='host' value='" . $pool_member_ref->{ 'member' }->{ 'address' } . "' type='hidden'/>
                <select name='instance'>";
                foreach my $instance ( get_instance_list( $pool_member_ref->{ 'member' }->{ 'address' } ) ) {
                    print "<option value='$instance'>$instance</option>";
                }
                print "</select>
                <input type='submit' value='Restart' onclick='display_restarting_alert()'/>
                </form></td>";

                $first_member_line = 1;
                print "</tr>";
            }
        }
    }
}

print "<html><head>
<script type='text/javascript'>
function display_restarting_alert() {
    alert(\"In progress...\\nPlease click OK and wait for minutes ...\");
}
</script>
<style type='text/css'>
body { font-family: 'Trebuchet MS', Arial, Helvetica, sans-serif; }
a { color: #000 }
a:hover { color: #000; bottom }
#header { margin: 0 auto 10px; height: 80px; width: 1000px; padding-bottom: 10px; border-bottom: 1px solid #444 }
#logo { float: left }
#jira_link { float: right; padding-top: 60px; }
#wrapper { margin: 0 auto; width: 1000px; clear: both }
</style>
</head>
<body>";

print "<div id='header'>
<div id='logo'><a href='environments.cgi'><img src='static/devops_logo.png'/></a></div>
<div id='jira_link'><a href='jira_createIssue.html'>Create ENV Support Ticket</a></div>
</div>";
print "<div id='wrapper'>";
print "<table>";

my $env_json_result = `$SSH_COMMAND -i $SUPER_KEY_FILE $REG_HOST '$VALIDATE_BIGIP_SCRIPT -e $envid -j'`;
my $env_status_ref = from_json( $env_json_result );

print "<tr><td>Pool</td><td>Pool Status</td><td>Pool Member</td><td>Enable Status</td><td>Status</td><td>Build Label</td><td>Actions</td></tr>";

print_pools_status( $env_status_ref->{ 'internal' } );
print_pools_status( $env_status_ref->{ 'external' } );

print "</table>";
print "</div>";
print "</body></html>"
