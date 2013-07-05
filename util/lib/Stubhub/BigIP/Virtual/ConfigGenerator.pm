package Stubhub::BigIP::Virtual::ConfigGenerator;

#
# Stubhub BIG-IP Virtual Server Configuration file generator.
# To replace the tokens in template into real values.
#

use strict;
use warnings;

use lib '/nas/home/minjzhang/ops/util/lib';
use lib '/nas/reg/lib/perl';

use Readonly;
use Stubhub::Util::Host qw (
                           get_ip_by_hostname 
                        );

BEGIN {
  use Exporter();
  our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

  $VERSION = do { my @r = (q$Revision: 1.0 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

  @ISA          = qw( Exporter );
  @EXPORT       = qw();
  @EXPORT_OK    = qw(
                      &generate_vs_configs
                      &generate_pub_vs_configs
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;

#
# Generate public virtual server configuration file bsed on
# templates.
# Return empty string if no public ip for the environment.
#
sub generate_pub_vs_configs {
    my ( $templates_dir, $public_ip_list, $envid, $output_dir ) = @_;
    my $public_vs = _get_env_public_ip( $public_ip_list, $envid );
    my $public_vs_number = scalar keys %$public_vs;
    my $output_file = "$output_dir/virtual_server_$envid.conf";
    if ( $public_vs_number == 0 ) {
        return $output_file;
    }
    opendir DH, $templates_dir or die "Cannot open $templates_dir: $!";
    my @template_files = grep { ! -d } readdir DH;
    closedir DH;
    foreach my $virtual_server_template ( @template_files ) {
        my $vs_template_filename = $virtual_server_template;
        $vs_template_filename =~ s/.*\/(.*)/$1/;
        if ( exists $public_vs->{ "pub-$envid-$vs_template_filename" } ) {
            generate_vs_config( $output_file, "$templates_dir/$virtual_server_template", $envid,
                $public_vs->{ "pub-$envid-$vs_template_filename" } );
        }
    }
    return $output_file;
}

#
# Generate virtual server configuration files based on templates
# under a folder.
#
sub generate_vs_configs {
    my ( $templates_dir, $envid, $output_dir ) = @_;
    opendir DH, $templates_dir or die "Cannot open $templates_dir: $!";
    my @template_files = grep { ! -d } readdir DH;
    closedir DH;
    my $output_file = "$output_dir/virtual_server_$envid.conf";
    foreach my $virtual_server_template ( @template_files ) {
        generate_vs_config( $output_file, "$templates_dir/$virtual_server_template", $envid, "" );
    }
    return $output_file;
}

#
# Generate virtual server configuration file based on template.
#
sub generate_vs_config {
    my ( $target_file_path, $template_file_path, $envid, $public_ip ) = @_;

    Readonly my $UC_ENVID_TOKEN => '#{uc_env_id}';
    Readonly my $ENVID_TOKEN => '#{env_id}';
    Readonly my $IPADDR_TOKEN => '#{\S*env_id\S*\.com}';

    open TEMPLATE_FH, "<$template_file_path" or die $!;
    open TARGET_FH, ">>$target_file_path" or die $!;

    my @lines = <TEMPLATE_FH>;
    my @destination_line = grep /$IPADDR_TOKEN/, @lines;
    my $destination_size = @destination_line;
    if ( $destination_size > 0 ) {
        my $destination_ip = $destination_line[0];
        $destination_ip =~ s/.*{(\S*env_id\S*\.com)}.*/$1/;
        $destination_ip =~ s/(\S*)env_id(\S*)\.com/$1$envid$2.com/;
        chomp $destination_ip;
        if ( get_ip_by_hostname( $destination_ip ) eq "" ) {
            return $target_file_path;
        }
    }

    foreach my $line ( @lines ) {
        if ( $public_ip ne "" ) {
            if ( $line =~ /^virtual #{/ ) {
                $line =~ s/virtual (.*)/virtual pub-$1/;
            }
        }
        if ( $line =~ /$ENVID_TOKEN/ ) {
            $line =~ s/$ENVID_TOKEN/$envid/;
        }
        if ( $line =~ /$UC_ENVID_TOKEN/ ) {
            $line =~ s/$UC_ENVID_TOKEN/uc($envid)/eg;
        }
        if ( $line =~ /$IPADDR_TOKEN/ ) {
            my $ip_address;
            if ( $public_ip eq "" ) {
                $ip_address = _replace_token_hostname_by_ip( $line, $envid );
            } else {
                $ip_address = $public_ip;
            }
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

    $line =~ s/.*{(.*env_id.*\.com)}.*/$1/;
    $line =~ s/(.*)env_id(.*)\.com/$1$envid$2.com/;
    chomp $line;

    return get_ip_by_hostname( $line );
}

#
# Get public ip address for the specific environment.
#
sub _get_env_public_ip {
    my ( $pub_ip_list, $env_id ) = @_;
    open PUB_IP_LIST, "<$pub_ip_list" or die "Cannot open file $pub_ip_list: $!";
    my @lines = <PUB_IP_LIST>;
    my @env_public_ip = grep /^pub-$env_id-/, @lines;
    my %env_public_vs;
    foreach my $virtual_server_line ( @env_public_ip ) {
        my $virtual_server_name = $virtual_server_line;
        my $virtual_server_ip   = $virtual_server_line;
        $virtual_server_name =~ s/(.*) .*/$1/;
        $virtual_server_ip   =~ s/.* (.*)/$1/;
        chomp $virtual_server_name;
        chomp $virtual_server_ip;
        $env_public_vs{ $virtual_server_name } = $virtual_server_ip;
    }
    return \%env_public_vs;
}
