package Stubhub::Util::Host;

use strict;
use warnings;

use lib '/nas/reg/lib/perl';
use lib '/nas/home/minjzhang/ops/util/lib';

use Readonly;

BEGIN {
  use Exporter();
  our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

  $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

  @ISA          = qw( Exporter );
  @EXPORT       = qw();
  @EXPORT_OK    = qw(
                      &get_ip_by_hostname
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;

#
# Get IP address by hostname.
#
sub get_ip_by_hostname {
    my ( $hostname ) = @_;

    Readonly my $DNS_COMMAND => '/usr/bin/host';
    Readonly my $GREP_COMMAND => '/bin/grep';

    my $ip_address = `$DNS_COMMAND $hostname | $GREP_COMMAND "has address"`;
    $ip_address =~ s/.* has address (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/$1/;
    chomp $ip_address;

    my $is_alias = 0;
    my $dns_result = `$DNS_COMMAND $hostname`;
    if ( $dns_result =~ /alias/ ) {
        $is_alias = 1;
    }

    my $reverse_dns = `$DNS_COMMAND $ip_address`;
    if ( $reverse_dns !~ /$hostname/ and ! $is_alias ) {
        print "Error: Reverse DNS for host $hostname is wrong:\n";
        return "";
    }

    return $ip_address;
}
