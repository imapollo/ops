package Stubhub::BigIP::Pool::ConfigGenerator;

#
# Stubhub BIG-IP Pool Configuration file generator.
# To replace the tokens in template into real values.
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
                      &generate_pool_config
                      &generate_pool_configs
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;

#
# Generate pool configuration files based on templates
# under a folder.
#
sub generate_pool_configs {
    my ( $templates_dir, $envid, $output_dir ) = @_;
    opendir DH, $templates_dir or die "Cannot open $templates_dir: $!";
    my @template_files = grep { ! -d } readdir DH;
    closedir DH;
    my $output_file = "$output_dir/pool_$envid.conf";
    foreach my $pool_template ( @template_files ) {
        generate_pool_config( $output_file, "$templates_dir/$pool_template", $envid );
    }
    return $output_file;
}

#
# Generate pool configuration file based on template.
#
sub generate_pool_config {
    my ( $target_file_path, $template_file_path, $envid ) = @_;

    Readonly my $UC_ENVID_TOKEN => '#{uc_env_id}';
    Readonly my $ENVID_TOKEN => '#{env_id}';
    Readonly my $IPADDR_TOKEN => '#{env_id\..*\.ip}';
    Readonly my $FOREACH_BEGIN_TOKEN => '#{foreach .*}';
    Readonly my $FOREACH_END_TOKEN => '#{foreach}';

    open TEMPLATE_FH, "<$template_file_path" or die $!;
    open TARGET_FH, ">>$target_file_path" or die $!;

    while ( my $line = <TEMPLATE_FH> ) {
        if ( $line =~ /$FOREACH_BEGIN_TOKEN/ ) {

            $line =~ s/^\s*#{foreach (.*)}\s*$/$1/;
            my $token = $line;

            # Read the lines inside #{foreach}
            my @foreach_lines;
            while ( $line = <TEMPLATE_FH> ) {
                if ( $line !~ /$FOREACH_END_TOKEN/ ) {
                    push @foreach_lines, $line;
                } else {
                    last;
                }
            }

            # Print the lines inside #{foreach}
            my @pool_members = _get_ip_by_hostname_token( $token, $envid );
            foreach my $pool_member ( @pool_members ) {
                foreach my $foreach_line ( @foreach_lines ) {
                    if ( $foreach_line =~ /$IPADDR_TOKEN/ ) {
                        $foreach_line =~ s/$IPADDR_TOKEN/$pool_member/;
                    }
                    print TARGET_FH $foreach_line;
                }
            }
            next;
        }
        if ( $line =~ /$ENVID_TOKEN/ ) {
            $line =~ s/$ENVID_TOKEN/$envid/;
        }
        if ( $line =~ /$UC_ENVID_TOKEN/ ) {
            $line =~ s/$UC_ENVID_TOKEN/uc($envid)/eg;
        }
        print TARGET_FH $line;
    }

    close TEMPLATE_FH;
    close TARGET_FH;

    return $target_file_path;
}

#
# Get the IP address array from token.
#
sub _get_ip_by_hostname_token {
    my ( $token, $envid ) = @_;

    Readonly my $DEVQA_HOSTS => '/nas/reg/etc/dev-qa-hosts';

    $token =~ s/env_id\.(.*)\.ip/$1/;
    my @ip_addresses;

    open DEVQA_HOSTS_FH, "<$DEVQA_HOSTS" or die $!;
    while ( my $line = <DEVQA_HOSTS_FH> ) {
        if ( $line =~ /^$envid$token/ ) {
            chomp $line;
            push @ip_addresses, _get_ip_by_hostname( $line );
        }
    }
    return @ip_addresses;
}

#
# Get IP address from hostname.
#
sub _get_ip_by_hostname {
    my ( $hostname ) = @_;
    Readonly my $DNS_COMMAND => '/usr/bin/host';
    my $ip_address = `$DNS_COMMAND $hostname`;
    $ip_address =~ s/.* has address (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/$1/;
    chomp $ip_address;

    my $reverse_dns = `$DNS_COMMAND $ip_address`;
    if ( $reverse_dns !~ /$hostname/ ) {
        print "Error: Reverse DNS for host $hostname is wrong:\n";
        print "\$ host $ip_address\n";
        system("host $ip_address");
        exit 1;
    }

    return $ip_address;
}