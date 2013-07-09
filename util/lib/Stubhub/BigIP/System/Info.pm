package Stubhub::BigIP::System::Info;

#
# Get basic information of the BigIP servers.
#

use strict;
use warnings;

use lib '/nas/home/minjzhang/ops/util/lib';
use lib '/nas/reg/lib/perl';

use Readonly;
use YAML qw( LoadFile );
use Data::Dumper;
use Log::Transcript;
use Stubhub::P4::Client qw (
                            check_out_perforce_file
                            clean_perforce_client
                        );

BEGIN {
  use Exporter();
  our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

  $VERSION = do { my @r = (q$Revision: 1.0 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

  @ISA          = qw( Exporter );
  @EXPORT       = qw();
  @EXPORT_OK    = qw(
                        &get_bigip_server
                        &get_bigip_partition
                        &get_exclude_list
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
# Get the exclude list for the specific environment.
# Param: pool, rule or virtual.
#
sub get_exclude_list {
    my ( $envid, $intext, $object_type ) = @_;
    if ( $object_type ne "pool"
            and $object_type ne "rule"
            and $object_type ne "virtual" ) {
        logecho "Error: parameter object type must be 'pool', 'rule' or 'virtual'.\n";
        exit 1;
    }
    Readonly my $EXCLUDE_LIST => '/internal/devops/network/bigip/exclude.lst';
    my ( $dynamic_perforce_client, $dynamic_perforce_dir ) = check_out_perforce_file( "/$EXCLUDE_LIST" );
    my $exclude_settings = LoadFile( "$dynamic_perforce_dir$EXCLUDE_LIST" );
    clean_perforce_client( $dynamic_perforce_client, $dynamic_perforce_dir );
    my $object_list = $exclude_settings->{$envid}->{$intext}->{$object_type};
    my @objects;
    if ( defined $object_list ) {
        @objects = split ",", $object_list;
    }
    return @objects;
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
    $env_prefix =~ s/(srw[deq]).*/$1/ig;
    chomp $env_number;
    if ( $env_number >= 76 or $env_prefix =~ /srwq/i ) {
        $internal_bigip_server = 'srwd00lba014.stubcorp.dev';
        $external_bigip_server = 'srwd00lba042-cl.stubcorp.dev';
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
