package Stubhub::BigIP::Virtual::ConfigGenerator;

#
# Stubhub BIG-IP Virtual Server Configuration file generator.
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

  $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

  @ISA          = qw( Exporter );
  @EXPORT       = qw();
  @EXPORT_OK    = qw(
                      &generate_vs_config
                      &generate_vs_configs
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;

#
# Generate virtual server configuration files based on templates
# under a folder.
#
sub generate_vs_configs {
    my ( $templates_dir, $envid ) = @_;
    opendir DH, $templates_dir or die "Cannot open $templates_dir: $!";
    my @template_files = grep { ! -d } readdir DH;
    closedir DH;
    foreach my $virtual_server_template ( @template_files ) {
        print generate_vs_config( "$templates_dir/$virtual_server_template", $envid );
    }
}

#
# Generate virtual server configuration file based on template.
#
sub generate_vs_config {
    my ( $template_file_path, $envid ) = @_;

    my $target_file_path = $template_file_path . ".out";

    Readonly my $ENVID_TOKEN => '#{env_id}';
    Readonly my $IPADDR_TOKEN => '#{.*\.env_id\.com}';

    open TEMPLATE_FH, "<$template_file_path" or die $!;
    open TARGET_FH, ">$target_file_path" or die $!;

    while ( my $line = <TEMPLATE_FH> ) {
        if ( $line =~ /$ENVID_TOKEN/ ) {
            $line =~ s/$ENVID_TOKEN/$envid/;
        }
        if ( $line =~ /$IPADDR_TOKEN/ ) {
            my $ip_address = _replace_token_hostname_by_ip( $line, $envid );
            $line =~ s/$IPADDR_TOKEN/$ip_address/;
        }
        print TARGET_FH $line;
    }

    close TEMPLATE_FH;
    close TARGET_FH;

    return $target_file_path;
}

#
# Replace the tokenized hostname with ip address.
# The ip address is got from 'nslookup' command.
#
sub _replace_token_hostname_by_ip {
    my ( $line, $envid ) = @_;

    Readonly my $DNS_COMMAND => '/usr/bin/host';

    $line =~ s/.*{(.*\.env_id\.com)}.*/$1/;
    $line =~ s/(.*)\.env_id\.com/$1.$envid.com/;
    chomp $line;

    my $ip_address = `$DNS_COMMAND $line`;
    $ip_address =~ s/.* has address (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/$1/;
    chomp $ip_address;

    my $reverse_dns = `$DNS_COMMAND $ip_address`;
    if ( $reverse_dns !~ /$line/ ) {
        print "Error: Reverse DNS for host $line is wrong:\n";
        print "\$ host $ip_address\n";
        system("host $ip_address");
        exit 1;
    }

    return $ip_address;
}
