package Stubhub::BigIP::System::Util;

#
# Operate BigIp system actions.
#

use strict;
use warnings;

use lib '/nas/reg/lib/perl';
use lib '/nas/home/minjzhang/ops/util/lib';

use Readonly;
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

BEGIN {
  use Exporter();
  our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

  $VERSION = do { my @r = (q$Revision: 1.0 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

  @ISA          = qw( Exporter );
  @EXPORT       = qw();
  @EXPORT_OK    = qw(
                        &deploy_configuration
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;

#
# Deploy configuration onto BigIP server.
#
sub deploy_configuration {
    my ( $envid, $int_ext, $iControl, $file_name ) = @_;
    my $ssh = _init_ssh( get_internal_bigip_server( $envid, $int_ext ) );

    my $remote_file_name = $file_name;
    $remote_file_name =~ s/.*\/(.*)/$1/;
    $remote_file_name = "/Config/deployment/$remote_file_name";

    if ( not _upload_file( $iControl, $remote_file_name, $file_name) ) {
        die "Error: Failed to upload file $file_name: $!\n";
    }

    my @output = mute_execute_ssh( $ssh, "merge $remote_file_name" );
    if ( grep /error/i, @output ) {
        foreach my $line ( @output ) {
            logecho $line;
        }
        exit 1;
    } elsif ( $show_verbose ) {
        foreach my $line ( @output ) {
            logecho $line;
        }
    }
}


#
# Upload file onto BigIP server.
#
sub _upload_file {
    my ( $iControl, $remote_file_name, $local_file_name ) = @_;
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
