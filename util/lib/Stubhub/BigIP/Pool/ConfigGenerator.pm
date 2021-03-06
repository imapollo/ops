package Stubhub::BigIP::Pool::ConfigGenerator;

#
# Stubhub BIG-IP Pool Configuration file generator.
# To replace the tokens in template into real values.
#

use strict;
use warnings;

use lib '/nas/home/minjzhang/ops/util/lib';
use lib '/nas/reg/lib/perl';

use Readonly;
use Log::Transcript;
use Stubhub::Util::Host qw (
                            get_ip_by_hostname
                        );
use Stubhub::BigIP::System::Util qw (
                                    get_object_prefix
                                );

BEGIN {
  use Exporter();
  our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

  $VERSION = do { my @r = (q$Revision: 1.0 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

  @ISA          = qw( Exporter );
  @EXPORT       = qw();
  @EXPORT_OK    = qw(
                      &generate_pool_config
                      &generate_pool_configs
                      &generate_pool_separate_configs
                      &generate_not_excluded_pool_configs
                      &generate_not_excluded_pool_separate_configs
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;
#
# Generate pool configuration files based on templates
# under a folder, including not excluded pools.
#
sub generate_not_excluded_pool_configs {
    my ( $templates_dir, $envid, $output_dir, $excluded_pools_ref, $only_include_pool_ref, $bigip_ref ) = @_;
    my @excluded_pools = @{ $excluded_pools_ref };
    my @only_include_pool = @{ $only_include_pool_ref };
    opendir DH, $templates_dir or die "Cannot open $templates_dir: $!";
    my @template_files = grep { ! -d } readdir DH;
    closedir DH;
    my $output_file = "$output_dir/pool_$envid.conf";
    foreach my $pool_template ( @template_files ) {
        my $pool_template_filename = $pool_template;
        $pool_template_filename =~ s/.*\/(.*)/$1/;
        if ( scalar @only_include_pool > 0 ) {
            my $included = 0;
            foreach my $only_include ( @only_include_pool ) {
                if ( $only_include =~ /^$pool_template_filename$/i ) {
                    $included = 1;
                    last;
                }
            }
            next if not $included;
        } else {
            my $excluded = 0;
            foreach my $excluded_pool ( @excluded_pools ) {
                if ( $excluded_pool =~ /^$pool_template_filename$/i ) {
                    $excluded = 1;
                    last;
                }
            }
            next if $excluded;
        }

        generate_pool_config( $output_file, "$templates_dir/$pool_template", $envid, $bigip_ref );
    }
    return $output_file;
}

#
# Generate separate pool configuration files based on templates
# under a folder, including not excluded pools.
#
sub generate_not_excluded_pool_separate_configs {
    my ( $templates_dir, $envid, $output_dir, $excluded_pools_ref, $only_include_pool_ref, $bigip_ref ) = @_;
    my @excluded_pools = @{ $excluded_pools_ref };
    my @only_include_pool = @{ $only_include_pool_ref };
    opendir DH, $templates_dir or die "Cannot open $templates_dir: $!";
    my @template_files = grep { ! -d } readdir DH;
    closedir DH;
    foreach my $pool_template ( @template_files ) {
        my $pool_template_filename = $pool_template;
        $pool_template_filename =~ s/.*\/(.*)/$1/;
        if ( scalar @only_include_pool > 0 ) {
            my $included = 0;
            foreach my $only_include ( @only_include_pool ) {
                if ( $only_include =~ /^$pool_template_filename$/i ) {
                    $included = 1;
                    last;
                }
            }
            next if not $included;
        } else {
            my $excluded = 0;
            foreach my $excluded_pool ( @excluded_pools ) {
                if ( $excluded_pool =~ /^$pool_template_filename$/i ) {
                    $excluded = 1;
                    last;
                }
            }
            next if $excluded;
        }

        generate_pool_config( $output_dir, "$templates_dir/$pool_template", $envid, $bigip_ref );
    }
    return $output_dir;
}


#
# Generate pool configuration files based on templates
# under a folder.
#
sub generate_pool_configs {
    my ( $templates_dir, $envid, $output_dir, $bigip_ref ) = @_;
    opendir DH, $templates_dir or die "Cannot open $templates_dir: $!";
    my @template_files = grep { ! -d } readdir DH;
    closedir DH;
    my $output_file = "$output_dir/pool_$envid.conf";
    foreach my $pool_template ( @template_files ) {
        generate_pool_config( $output_file, "$templates_dir/$pool_template", $envid, $bigip_ref );
    }
    return $output_file;
}

#
# Generate pool configuration files based on templates
# under a folder.
#
sub generate_pool_separate_configs {
    my ( $templates_dir, $envid, $output_dir, $bigip_ref ) = @_;
    opendir DH, $templates_dir or die "Cannot open $templates_dir: $!";
    my @template_files = grep { ! -d } readdir DH;
    closedir DH;
    foreach my $pool_template ( @template_files ) {
        generate_pool_config( $output_dir, "$templates_dir/$pool_template", $envid, $bigip_ref );
    }
    return $output_dir;
}

#
# Generate pool configuration file based on template.
#
sub generate_pool_config {
    my ( $target_file_path, $template_file_path, $envid, $bigip_ref ) = @_;

    Readonly my $UC_ENVID_TOKEN => '%{uc_env_id}';
    Readonly my $ENVID_TOKEN => '%{env_id}';
    Readonly my $IPADDR_TOKEN => '%{env_id\..*\.ip}';
    Readonly my $FOREACH_BEGIN_TOKEN => '%{foreach .*}';
    Readonly my $FOREACH_END_TOKEN => '%{foreach}';

    my $object_prefix = get_object_prefix( $bigip_ref );

    open TEMPLATE_FH, "<$template_file_path" or die $!;

    # If $target_file_path is a directory, open new file to write.
    if ( -d $target_file_path ) {
        my $target_file_name = $template_file_path;
        $target_file_name =~ s/.*\/(.*)/$1/;
        $target_file_path = "$target_file_path/$target_file_name";
    }

    open TARGET_FH, ">>$target_file_path" or die $!;

    my $members_begin_line = 0;
    my $members_end_line = 0;
    while ( my $line = <TEMPLATE_FH> ) {
        if ( $line =~ /^\s*members\s*{\s*$/ ) {
            $members_begin_line = 1;
            next;
        } elsif ( $line =~ /^\s*}\s*$/ and $members_begin_line and
                ( $members_end_line == 0 ) ) {
            $members_end_line = 1;
            next;
        }

        if ( $line =~ /$FOREACH_BEGIN_TOKEN/ ) {

            $line =~ s/^\s*%{foreach (.*)}\s*$/$1/;
            my $token = $line;

            # Read the lines inside %{foreach}
            my @foreach_lines;
            while ( $line = <TEMPLATE_FH> ) {
                if ( $line !~ /$FOREACH_END_TOKEN/ ) {
                    push @foreach_lines, $line;
                } else {
                    last;
                }
            }

            # Print the lines inside %{foreach}
            my @pool_members = _get_ip_by_hostname_token( $token, $envid );
            $token =~ s/env_id\.(.*)\.ip/$1/;
            if ( scalar @pool_members == 0 ) {
                # $logger->warn( "No pool members for " . uc( $token ) );
            } else {
                print TARGET_FH "members {\n";
            }
            foreach my $pool_member ( @pool_members ) {
                foreach my $foreach_line ( @foreach_lines ) {
                    my $replacing_line = $foreach_line;
                    if ( $replacing_line =~ /$IPADDR_TOKEN/ ) {
                        if ( $bigip_ref->{ "version" } eq "10" ) {
                            $replacing_line =~ s/$IPADDR_TOKEN/$pool_member/;
                        } elsif ( $bigip_ref->{ "version" } eq "11" ) {
                            # For Bigip version 11.
                            $replacing_line =~ s\$IPADDR_TOKEN\$object_prefix$pool_member\;
                            my $pool_member_without_port = $pool_member;
                            $pool_member_without_port =~ s/(.*):.*/$1/;
                            $replacing_line =~ s/{/{ address $pool_member_without_port /;
                            if ( $replacing_line =~ /\slimit\s/ ) {
                                $replacing_line =~ s/limit/connection-limit/;
                            }
                        }
                    }
                    print TARGET_FH $replacing_line;
                }
            }
            if ( scalar @pool_members > 0 ) {
                print TARGET_FH "}\n";
            }
            next;
        }

        if ( $line =~ /^pool %{/ ) {
            $line =~ s\pool (.*)\pool ${object_prefix}$1\;
            if ( $object_prefix ne "" ) {
                $line = "ltm $line";
            }
        }
        # For BigIP version 11.
        if ( $bigip_ref->{ "version" } eq "11" ) {
            if ( $line =~ /\bmin active members\b/ ) {
                $line =~ s/min active members/min-active-members/;
            }
            if ( $line =~ /\bslow ramp time\b/ ) {
                $line =~ s/slow ramp time/slow-ramp-time/;
            }
            if ( $line =~ /\blb method\b/ ) {
                $line =~ s/lb method/load-balancing-mode/;
            }
            if ( $line =~ /\bfastest app resp\b/ ) {
                $line =~ s/fastest app resp/fastest-app-response/;
            }
            if ( $line =~ /\bmember least conn\b/ ) {
                $line =~ s/member least conn/least-connections-member/;
            }
            if ( $line =~ /\spredictive\s/ ) {
                $line =~ s/predictive/predictive-node/;
            }
            if ( $line =~ /^\s*monitor/ ) {
                $line =~ s/^\s*monitor\s*//;
                my @monitors = split( /\s+/, $line );
                $line = "monitor ";
                foreach my $monitor ( @monitors ) {
                    if ( $monitor eq "all" ) {
                        next;
                    }
                    if ( $monitor ne "and" ) {
                        $monitor = $object_prefix . $monitor;
                    }
                    $line = $line . "$monitor ";
                }
                $line = $line . "\n";
            }
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
            push @ip_addresses, get_ip_by_hostname( $line );
        }
    }
    return @ip_addresses;
}
