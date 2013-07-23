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
use Stubhub::Util::SSH qw (
                            login_ssh
                            close_ssh
                            execute_ssh
                            mute_execute_ssh
                        );
use Stubhub::BigIP::System::Info qw (
                                    get_bigip_server
                                    get_bigip_partition
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
                        &get_icontrol
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
# Get the iControl instance based on environment Id.
#
sub get_icontrol {
    my ( $envid ) = @_;

    Readonly my $BIGIP_USERNAME => 'svcacctrelmgt';
    Readonly my $BIGIP_PASSWORD => 'UjhiYml0U3Qzdw==';
    Readonly my $BIGIP_PORT     => 443;
    Readonly my $BIGIP_PROTOCOL => 'https';

    my $internal_bigip_server = get_bigip_server( $envid, "int" );
    my $external_bigip_server = get_bigip_server( $envid, "ext" );
    my $internal_partition = get_bigip_partition( $envid, "int" );
    my $external_partition = get_bigip_partition( $envid, "ext" );
    
    $logger->debug( "The internal BigIP server is: $internal_bigip_server" );
    $logger->debug( "The external BigIP server is: $external_bigip_server" );

    my $external_ic = BigIP::iControl->new(
                                    server => "$external_bigip_server",
                                    username => "$BIGIP_USERNAME",
                                    password => decode_base64($BIGIP_PASSWORD),
                                    port     => $BIGIP_PORT,
                                    proto    => "$BIGIP_PROTOCOL"
                                );
    my $internal_ic = BigIP::iControl->new(
                                    server => "$internal_bigip_server",
                                    username => "$BIGIP_USERNAME",
                                    password => decode_base64($BIGIP_PASSWORD),
                                    port     => $BIGIP_PORT,
                                    proto    => "$BIGIP_PROTOCOL"
                                );

    # set_partition( $internal_ic, $internal_partition );
    # set_partition( $external_ic, $external_partition );

    return ( $internal_ic, $external_ic );
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
# Download configuration from BigIP server.
#
sub download_configuration {
    my ( $iControl, $remote_file, $local_file ) = @_;
    open LOCAL_FILE_FH, ">$local_file"
        or $logger->logdie( "Error: Failed to open file: $local_file" );
    print LOCAL_FILE_FH $iControl->download_file($remote_file);
    close LOCAL_FILE_FH;
    $logger->debug( "Successfully download $remote_file to $local_file." );
    return $local_file;
}

#
# Deploy configuration onto BigIP server.
#
sub deploy_configuration {
    my ( $envid, $int_ext, $iControl, $file_name ) = @_;
    my $ssh = _init_ssh( get_bigip_server( $envid, $int_ext ) );

    my $remote_file_name = $file_name;
    $remote_file_name =~ s/.*\/(.*)/$1/;
    $remote_file_name = "/config/deploy/$remote_file_name";

    if ( not _upload_file( $iControl, $remote_file_name, $file_name) ) {
        $logger->logdie( "Error: Failed to upload file $file_name: $!" );
    }

    my @output = mute_execute_ssh( $ssh, "merge $remote_file_name" );
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
    my ( $iControl ) = @_;
    $logger->info( "Save the configuration successfully." );
    $iControl->save_configuration( 'today' );
}

#
# Sync configurations to the Standby BigIP server.
#
sub sync_configuration {
    my ( $iControl, $envid, $int_ext ) = @_;
    my $ssh = _init_ssh( get_bigip_server( $envid, $int_ext ) );
    if ( check_failover_state( $iControl ) eq 'FAILOVER_STATE_ACTIVE') {
        my @output = mute_execute_ssh( $ssh, "config sync all" );
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
        $logger->warn( "WARN: Did not sync configuration as the current server is not Active." );
    }
}

#
# Check the failover status for BigIP server.
#
sub check_failover_state {
    my ( $iControl ) = @_;
    $logger->debug( "The bigip failover state is: " . $iControl->get_failover_state() );
    return $iControl->get_failover_state();
}

#
# Upload file onto BigIP server.
#
sub _upload_file {
    my ( $iControl, $remote_file_name, $local_file_name ) = @_;
    $logger->debug( "Successfully uploaded $local_file_name to $remote_file_name." );
    my $success = $iControl->upload_file( $remote_file_name, $local_file_name);
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
