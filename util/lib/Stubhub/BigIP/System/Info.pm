package Stubhub::BigIP::System::Info;

#
# Get basic information of the BigIP servers.
#

use strict;
use warnings;

use lib '/nas/reg/lib/perl';
use lib '/nas/home/minjzhang/ops/util/lib';

use Readonly;

BEGIN {
  use Exporter();
  our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

  $VERSION = do { my @r = (q$Revision: 1.0 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

  @ISA          = qw( Exporter );
  @EXPORT       = qw();
  @EXPORT_OK    = qw(
                        &get_bigip_server
                        &get_bigip_partition
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;

#
# Get BigIP partition name.
#
sub get_bigip_partition {
    my ( $envid, $int_ext ) = @_;
    my ( $bigip_server, $bigip_partition ) = _get_bigip_server_partition( $envid, $int_ext );
    return $bigip_partition;
}

#
# Get BigIP server name.
#
sub get_bigip_server {
    my ( $envid, $int_ext ) = @_;
    my ( $bigip_server, $bigip_partition ) = _get_bigip_server_partition( $envid, $int_ext );
    return $bigip_server;
}

#
# Get BigIP server and partition.
#
sub _get_bigip_server_partition {
    my ( $envid, $int_ext ) = @_;
    my $internal_bigip_server = qw{};
    my $external_bigip_server = qw{};
    my $internal_partition = "Common";
    my $external_partition = "Common";

    my $env_number = $envid;
    my $env_prefix = $envid;
    $env_number =~ s/srw[deq]//ig;
    $env_prefix =~ s/(srw[dqe]).*/$1/ig;
    chomp $env_number;
    if ( $env_number >= 76 or $env_prefix =~ /srwq/i ) {
        $internal_bigip_server = 'srwd00lba014.stubcorp.dev';
        $external_bigip_server = 'srwd00lba042-cl.stubcorp.dev';
        if ( $env_prefix =~ /srwq/i ) {
            $internal_partition = "Noconly";
            $external_partition = "data-group";
        }
    } else {
        $internal_bigip_server = '10.80.139.232';
        $external_bigip_server = '10.80.139.242';
    }
    # TODO For test
    $internal_bigip_server = 'srwd00lba013.stubcorp.dev';
    $external_bigip_server = 'srwd00lba041.stubcorp.dev';

    if ( $int_ext =~ /int/ ) {
        return ( $internal_bigip_server, $internal_partition );
    } else {
        return ( $external_bigip_server, $external_partition );
    }
}
