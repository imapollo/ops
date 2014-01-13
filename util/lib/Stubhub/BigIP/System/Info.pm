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
use Stubhub::Log::Util qw (
                            get_logger
                        );
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
                        &get_bigip_version
                        &get_exclude_list
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;
our $logger = get_logger();

#
# Get BigIP partition name.
#
sub get_bigip_partition {
    my ( $envid, $type ) = @_;
    my $bigip_server;
    my $bigip_partition;
    my $bigip_version;

    if ( $type =~ /(int|ext)/ ) {
        ( $bigip_server, $bigip_partition, $bigip_version ) = _get_bigip_server_partition( $envid, $type );
    } else {
        ( $bigip_server, $bigip_partition, $bigip_version ) = _get_special_bigip_server_partition( $envid, $type );
    }

    return $bigip_partition;
}

#
# Get BigIP version.
#
sub get_bigip_version {
    my ( $envid, $type ) = @_;
    my $bigip_server;
    my $bigip_partition;
    my $bigip_version;

    if ( $type =~ /(int|ext)/ ) {
        ( $bigip_server, $bigip_partition, $bigip_version ) = _get_bigip_server_partition( $envid, $type );
    } else {
        ( $bigip_server, $bigip_partition, $bigip_version ) = _get_special_bigip_server_partition( $envid, $type );
    }

    return $bigip_version;
}

#
# Get BigIP server name.
#
sub get_bigip_server {
    my ( $envid, $type ) = @_;
    my $bigip_server;
    my $bigip_partition;
    my $bigip_version;

    if ( $type =~ /(int|ext)/ ) {
        ( $bigip_server, $bigip_partition, $bigip_version ) = _get_bigip_server_partition( $envid, $type );
    } else {
        ( $bigip_server, $bigip_partition, $bigip_version ) = _get_special_bigip_server_partition( $envid, $type );
    }

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
        $logger->error( "Parameter object type must be 'pool', 'rule' or 'virtual'.\n" );
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
    my $internal_bigip_version = qw{};
    my $external_bigip_version = qw{};

    my $env_number = $envid;
    my $env_prefix = $envid;
    $env_number =~ s/srw[deq]//ig;
    $env_prefix =~ s/(srw[deq]).*/$1/ig;
    chomp $env_number;
    if ( $env_number >= 76 or $env_prefix =~ /srwq/i ) {
        $internal_bigip_server = '10.80.158.5'; # srwd00lba014/015
        $internal_bigip_server = '10.80.157.5' if $env_prefix =~ /srwq/i ; # srwd00lba017/018
        $external_bigip_server = '10.80.159.3'; # srwd00lba042
        $internal_bigip_version = "10";
        $internal_bigip_version = "11" if $env_prefix =~ /srwq/i ; # Only srwd00lba017/018 is 11.x 2014-01-13
        $external_bigip_version = "10";
    } else {
        $internal_bigip_server = '10.80.159.40'; # srwd00lba012/013
        $external_bigip_server = '10.80.159.37'; # srwd00lba040/041
        $internal_bigip_version = "10";
        $external_bigip_version = "10";
    }
    # $internal_bigip_server = 'srwd00lba013.stubcorp.dev';
    # $external_bigip_server = 'srwd00lba041.stubcorp.dev';

    if ( $int_ext =~ /int/ ) {
        return ( $internal_bigip_server, $internal_partition, $internal_bigip_version );
    } elsif ( $int_ext =~ /ext/ ) {
        return ( $external_bigip_server, $external_partition, $external_bigip_version );
    }
}

#
# Get special BigIP server and partition.
#
sub _get_special_bigip_server_partition {
    my ( $envid, $type ) = @_;
    my $bigip_server = qw{};
    my $partition = "Common";
    my $version = qw{};

    my $env_number = $envid;
    my $env_prefix = $envid;
    $env_number =~ s/srw[deq]//ig;
    $env_prefix =~ s/(srw[deq]).*/$1/ig;
    chomp $env_number;

    if ( $type eq "apigateway" ) {
        $bigip_server = '10.80.159.37'; # srwd00lba040/041
        $version = "10";
    }

    return ( $bigip_server, $partition );
}
