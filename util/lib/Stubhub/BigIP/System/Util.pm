package Stubhub::BigIP::System::Util;

#
# Operate BigIp system actions.
#

use strict;
use warnings;

use lib '/nas/home/minjzhang/ops/util/lib';
use lib '/nas/reg/lib/perl';

use Readonly;
use MIME::Base64;
use Data::Dumper;
use Stubhub::Util::SSH qw (
                            login_ssh
                            close_ssh
                            execute_ssh
                            mute_execute_ssh
                        );
use Stubhub::BigIP::System::Info qw (
                                    get_bigip_server
                                    get_bigip_partition
                                    get_bigip_version
                                );
use Stubhub::Log::Util qw (
                            get_logger
                        );
use BigIP::iControl;

BEGIN {
  use Exporter();
  our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

  $VERSION = do { my @r = (q$Revision: 1.0 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

  @ISA          = qw( Exporter );
  @EXPORT       = qw();
  @EXPORT_OK    = qw(
                        &deploy_configuration
                        &download_configuration
                        &get_bigip
                        &get_icontrol
                        &add_object_prefix
                        &del_object_prefix
                        &get_object_prefix
                        &get_special_bigip
                        &get_special_icontrol
                        &get_icontrol_instance
                        &set_partition
                        &save_configuration
                        &check_failover_state
                        &sync_configuration
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;
our $logger = get_logger();

#
# Get the iControl instance for the server.
# Parameters:
# - lba_server : BigIP load balance server name.
# - username   : Username to login to the BigIP server.
# - password   : Password.
#
sub get_icontrol_instance {
    my ( $lba_server, $username, $password ) = @_;
    Readonly my $BIGIP_PORT     => 443;
    Readonly my $BIGIP_PROTOCOL => 'https';

    my $iControl = BigIP::iControl->new (
                                server   => "$lba_server",
                                username => "$username",
                                password => "$password",
                                port     => $BIGIP_PORT,
                                proto    => "$BIGIP_PROTOCOL"
                            );
    return $iControl;
}

#
# Get the bigip reference.
#
# Return \%bigip => {
#   int => {
#     iControl  => xxx,
#     server    => xxx,
#     partition => xxx,
#     version   => xxx,
#   },
#   ext => {
#     iControl  => xxx,
#     server    => xxx,
#     partition => xxx,
#     version   => xxx,
#   }
# }
#
sub get_bigip {
    my ( $envid ) = @_;
    my ( $internal_ic, $external_ic ) = get_icontrol( $envid );

    my %bigip = ();
    my %internal_bigip = ();
    my %external_bigip = ();

    $internal_bigip{ "iControl" } = $internal_ic;
    $internal_bigip{ "server" } = get_bigip_server( $envid, "int" );
    $internal_bigip{ "partition" } = get_bigip_partition( $envid, "int" );
    $internal_bigip{ "version" } = get_bigip_version( $envid, "int" );
    $external_bigip{ "iControl" } = $external_ic;
    $external_bigip{ "server" } = get_bigip_server( $envid, "ext" );
    $external_bigip{ "partition" } = get_bigip_partition( $envid, "ext" );
    $external_bigip{ "version" } = get_bigip_version( $envid, "ext" );

    $bigip{ "int" } = \%internal_bigip;
    $bigip{ "ext" } = \%external_bigip;

    return \%bigip;
}

#
# Get the DEV/QA iControl instances based on environment Id.
#
sub get_icontrol {
    my ( $envid ) = @_;

    Readonly my $BIGIP_USERNAME => 'svcacctrelmgt';
    Readonly my $BIGIP_PASSWORD => 'UjhiYml0U3Qzdw==';

    my $internal_bigip_server = get_bigip_server( $envid, "int" );
    my $external_bigip_server = get_bigip_server( $envid, "ext" );
    my $internal_partition = get_bigip_partition( $envid, "int" );
    my $external_partition = get_bigip_partition( $envid, "ext" );
    
    $logger->debug( "The internal BigIP server is: $internal_bigip_server" );
    $logger->debug( "The external BigIP server is: $external_bigip_server" );

    my $external_ic = get_icontrol_instance( $external_bigip_server, $BIGIP_USERNAME, decode_base64( $BIGIP_PASSWORD ) );
    my $internal_ic = get_icontrol_instance( $internal_bigip_server, $BIGIP_USERNAME, decode_base64( $BIGIP_PASSWORD ) );

    # set_partition( $internal_ic, $internal_partition );
    # set_partition( $external_ic, $external_partition );

    return ( $internal_ic, $external_ic );
}

#
# Get special bigip instances, for example api gateway.
#
sub get_special_bigip {
    my ( $envid, $type ) = @_;
    my $icontrol = get_special_icontrol( $envid, $type );

    my %bigip = ();

    $bigip{ "iControl" } = $icontrol;
    $bigip{ "server" } = get_bigip_server( $envid, $type );
    $bigip{ "partition" } = get_bigip_partition( $envid, $type );
    $bigip{ "version" } = get_bigip_version( $envid, $type );

    return \%bigip;
}

#
# Get special iControl instances, for example api gateway.
#
sub get_special_icontrol {
    my ( $envid, $type ) = @_;

    Readonly my $BIGIP_USERNAME => 'svcacctrelmgt';
    Readonly my $BIGIP_PASSWORD => 'UjhiYml0U3Qzdw==';

    my $bigip_server = get_bigip_server( $envid, $type );
    my $partition = get_bigip_partition( $envid, $type );
    
    $logger->debug( "The BigIP server is: $bigip_server" );

    my $icontrol = get_icontrol_instance( $bigip_server, $BIGIP_USERNAME, decode_base64( $BIGIP_PASSWORD ) );

    return $icontrol;
}

#
# Set active paration.
#
sub set_partition {
    my ( $iControl, $partition_name ) = @_;
    $logger->debug( "Set partition $partition_name." );
    $iControl->set_active_partition( $partition_name );
    return;
}

#
# Get the prefix for the object.
# - Partition name like /Common/ if BigIP version is 11.
# - No partition name if BigIP version is 10.
#
sub get_object_prefix {
    my ( $bigip_ref ) = @_;
    my $prefix = "";
    if ( defined $bigip_ref->{ "version" } and $bigip_ref->{ "version" } eq "11" ) {
        $prefix = "/$bigip_ref->{ 'partition' }/";
    }
    return $prefix;
}

#
# Add the prefix to the object name.
#
sub add_object_prefix {
    my ( $bigip_ref, $object_name ) = @_;
    my $prefix = get_object_prefix ( $bigip_ref );
    return $prefix . $object_name;
}

#
# Remove the prefix from the object name.
#
sub del_object_prefix {
    my ( $bigip_ref, $object_name ) = @_;
    my $prefix = get_object_prefix ( $bigip_ref );
    $object_name =~ s"$prefix"";
    return $object_name;
}

#
# Download configuration from BigIP server.
#
sub download_configuration {
    my ( $bigip_ref, $remote_file, $local_file ) = @_;
    open LOCAL_FILE_FH, ">$local_file"
        or $logger->logdie( "Failed to open file: $local_file" );
    print LOCAL_FILE_FH $bigip_ref->{ "iControl" }->download_file($remote_file);
    close LOCAL_FILE_FH;
    $logger->debug( "Successfully download $remote_file to $local_file." );
    return $local_file;
}

#
# Deploy configuration onto BigIP server.
#
sub deploy_configuration {
    my ( $envid, $int_ext, $bigip_ref, $file_name ) = @_;
    my $ssh = _init_ssh( get_bigip_server( $envid, $int_ext ) );

    my $remote_file_name = $file_name;
    $remote_file_name =~ s/.*\/(.*)/$1/;
    $remote_file_name = "/config/deploy/$remote_file_name";

    if ( not _upload_file( $bigip_ref, $remote_file_name, $file_name) ) {
        $logger->logdie( "Failed to upload file $file_name: $!" );
    }

    my @output;
    if ( $bigip_ref->{ "version" } eq "10" ) {
        @output = mute_execute_ssh( $ssh, "merge $remote_file_name" );
    } elsif ( $bigip_ref->{ "version"} eq "11" ) {
        @output = mute_execute_ssh( $ssh, "load /sys config file $remote_file_name merge" );
    }
    if ( grep /error/i, @output ) {
        foreach my $line ( @output ) {
            $logger->error( $line );
        }
        return 1;
    } else {
        foreach my $line ( @output ) {
            $logger->debug( $line );
        }
    }
}

#
# Save configuration on BigIP server.
#
sub save_configuration {
    my ( $bigip_ref ) = @_;
    $logger->info( "Save the configuration successfully." );
    $bigip_ref->{ "iControl" }->save_configuration( 'today' );
}

#
# Sync configurations to the Standby BigIP server.
#
sub sync_configuration {
    my ( $bigip_ref, $envid, $int_ext ) = @_;
    my $ssh = _init_ssh( get_bigip_server( $envid, $int_ext ) );
    if ( check_failover_state( $bigip_ref ) eq 'FAILOVER_STATE_ACTIVE') {
        my @output;
        if ( $bigip_ref->{ "version" } eq "10" ) {
            @output = mute_execute_ssh( $ssh, "config sync all" );
        } elsif ( $bigip_ref->{ "version"} eq "11" ) {
            @output = mute_execute_ssh( $ssh, "run /cm config-sync to-group device-group" );
        }
        if ( grep /error/i, @output ) {
            foreach my $line ( @output ) {
                $logger->error( $line );
            }
        } else {
            foreach my $line ( @output ) {
                $logger->info( $line );
            }
        }
    } else {
        $logger->warn( "Did not sync configuration as the current server is not Active." );
    }
}

#
# Check the failover status for BigIP server.
#
sub check_failover_state {
    my ( $bigip_ref ) = @_;
    $logger->debug( "The bigip failover state is: " . $bigip_ref->{ "iControl" }->get_failover_state() );
    return $bigip_ref->{ "iControl" }->get_failover_state();
}

#
# Upload file onto BigIP server.
#
sub _upload_file {
    my ( $bigip_ref, $remote_file_name, $local_file_name ) = @_;
    $logger->debug( "Successfully uploaded $local_file_name to $remote_file_name." );
    my $success = $bigip_ref->{ "iControl" }->upload_file( $remote_file_name, $local_file_name);
    return $success;
}

#
# Initial SSH connection.
#
sub _init_ssh {
    my ( $server ) = @_;
    Readonly my $BIGIP_USERNAME => 'svcacctrelmgt';
    Readonly my $BIGIP_PASSWORD => 'UjhiYml0U3Qzdw==';
    my $ssh = login_ssh( $server, $BIGIP_USERNAME, decode_base64($BIGIP_PASSWORD) );
    return $ssh;
}
