package Stubhub::Util::Host;

use strict;
use warnings;

use lib '/nas/home/minjzhang/ops/util/lib';
use lib '/nas/reg/lib/perl';

use Readonly;
use Stubhub::Log::Util qw (
                            get_logger
                        );

BEGIN {
  use Exporter();
  our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

  $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

  @ISA          = qw( Exporter );
  @EXPORT       = qw();
  @EXPORT_OK    = qw(
                      &get_ip_by_hostname
                      &get_public_ip_by_hostname
                      &get_hostname_by_ip
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;
our $logger = get_logger();

#
# Get IP address by hostname.
#
sub get_ip_by_hostname {
    my ( $hostname ) = @_;

    Readonly my $DNS_COMMAND => '/usr/bin/host';
    Readonly my $GREP_COMMAND => '/bin/grep';
    Readonly my $HEAD_COMMAND => '/usr/bin/head';

    my $ip_address = `$DNS_COMMAND $hostname | $GREP_COMMAND "has address" | $HEAD_COMMAND -n 1`;
    $ip_address =~ s/.* has address (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/$1/;
    chomp $ip_address;
    $logger->debug( "IP address: [$ip_address]\n" );

    if ( $ip_address !~ /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ ) {
        $logger->warn( "Cannot get IP address for [$hostname].\n" );
        return "";
    }

    my $is_alias = 0;
    my $dns_result = `$DNS_COMMAND $hostname`;
    if ( $dns_result =~ /alias/ ) {
        $is_alias = 1;
    }

    my $reverse_dns = `$DNS_COMMAND $ip_address`;
    if ( $reverse_dns !~ /$hostname/ and ! $is_alias ) {
        $logger->warn( "Reverse DNS for host [$hostname] is wrong.\n" );
    }

    return $ip_address;
}

#
# Get Public IP address by hostname.
#
sub get_public_ip_by_hostname {
    my ( $hostname ) = @_;

    Readonly my $DNS_COMMAND => '/usr/bin/host';
    Readonly my $GREP_COMMAND => '/bin/grep';
    Readonly my $HEAD_COMMAND => '/usr/bin/head';

    my $name_server = `$DNS_COMMAND $hostname 8.8.8.8 | $GREP_COMMAND 8.8.8.8 | $HEAD_COMMAND -n 1`;
    return "" if $name_server !~ /8.8.8.8/;

    my $ip_address = `$DNS_COMMAND $hostname 8.8.8.8 | $GREP_COMMAND "has address"`;
    my $dns_hostname = $ip_address;
    $dns_hostname =~ s/(.*) has address .*/$1/;
    $ip_address =~ s/.* has address (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/$1/;
    chomp $ip_address;

    if ( $ip_address !~ /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ ) {
        $logger->warn( "Cannot get external IP address for [$hostname].\n" );
        return "";
    }

    if ( $dns_hostname =~ /${hostname}.stubprod.com/ ) {
        $logger->debug( "No external IP for [$hostname].\n" );
        return "";
    }

    my $is_alias = 0;
    my $dns_result = `$DNS_COMMAND $hostname 8.8.8.8`;
    if ( $dns_result =~ /aliases:\s*\S+/i ) {
        $is_alias = 1;
    }

    my $reverse_dns = `$DNS_COMMAND $ip_address 8.8.8.8`;
    if ( $reverse_dns =~ /not found/ ) {
        $logger->warn( "Reverse DNS for public host [$hostname] is wrong.\n" );
    }
    if ( $reverse_dns !~ /smf\.ragingwire\.net/ and ! $is_alias ) {
        $logger->warn( "Reverse DNS for public host [$hostname] is wrong.\n" );
    }

    return $ip_address;
}

#
# Get hostname by IP address.
#
sub get_hostname_by_ip {
    my ( $ip_address ) = @_;
    $ip_address =~ s/(.*):.*/$1/;
    my $hostnames = `nslookup $ip_address | grep name | cut -d" " -f3`;
    chomp $hostnames;
    $hostnames =~ s/\n/,/g;
    $hostnames =~ s/\.$//;
    return $hostnames;
}
