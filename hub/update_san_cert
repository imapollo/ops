#!/usr/bin/perl -w
#
# Update "san_crt" and "san_key" in token-table-env-based based
# on new generated certs for specified environments.
#
# Usage:
#  update_san_cert [options]
#
# Options:
#  -e | --envs    The list of environments. Multiple environments
#                 will be separated by commas. No space is allowed.
#                 Required.
#  -f | --file    The path of the token-table-env-based file.
#                 Required.
#  -c | --certs   The directory of the new san certs. Required.
#  -h | --help    Help information.
#
# Examples:
#  $ update_san_cert -e srwd50,srwd60,srwd70 -f token-table-env-based \
#        -c /nas/reg/relmgt/new_certs_01142013
#  $ update_san_cert -h
#
# Author: minjzhang@ebay.com
#

use strict;
use Getopt::Long;

# get options
my $show_usage       = qw{};
my $envs             = qw{};
my $token_table_file = qw{};
my $san_cert_dir     = qw{};

my $options_okay = GetOptions (
    'h|help'     => \$show_usage,
    'e|envs=s'   => \$envs,
    'f|file=s'   => \$token_table_file,
    'c|certs=s'  => \$san_cert_dir,
);

if ( $show_usage ) {
    usage();
    exit 0;
}

if ( ! defined $envs || ! defined $token_table_file || ! defined $san_cert_dir ) {
    print "Error: Required options need to be set.\n";
    usage();
    exit 1;
}

#
# usage
#
sub usage {
    print <<END_OF_HELP

Update "san_crt" and "san_key" in token-table-env-based based
on new generated certs for specified environments.

Usage:
 update_san_cert [options]

Options:
 -e | --envs    The list of environments. Multiple environments
                will be separated by commas. No space is allowed.
                Required.
 -f | --file    The path of the token-table-env-based file.
                Required.
 -c | --certs   The directory of the new san certs. Required.
 -h | --help    Help information.

Examples:
 update_san_cert -e srwd50,srwd60,srwd70 -f token-table-env-based \
     -c /nas/reg/relmgt/new_certs_01142013
 update_san_cert -h
END_OF_HELP
}

#
# main
#
open OLDFILE, "<$token_table_file" or die $!;
open NEWFILE, ">$token_table_file.new" or die $!;

my $envid = "";
my $in_san_crt = 0;
my $in_san_key = 0;
my $start_document = 0;
my $new_document_written = 0;

my @environments = split(',', $envs);

while ( my $line = <OLDFILE> ) {
    if ( $line =~ m/^\s*<(srw[de][0-9]*)>\s*$/ ) {
        # catch the start line of a environment
        if ( grep /$1/, @environments ) {
            $envid = $1;
        }
    } elsif ( $line =~ m/^\s*<\/(srw[de][0-9]*)>\s*$/ ) {
        $envid = "";
    } elsif ( $envid ne "" and $line =~ m/^\s*san_crt\s*=\s*<<\s*EOD\s*$/ ) {
        # catch the start line of san_crt
        $in_san_crt = 1;
        $start_document = 1;
        $new_document_written = 0;
    } elsif ( $envid ne "" and $line =~ m/^\s*san_key\s*=\s*<<\s*EOD\s*$/ ) {
        # catch the start line of san_key
        $in_san_key = 1;
        $start_document = 1;
        $new_document_written = 0;
    } elsif ( $envid ne "" && $line =~ m/^\s*EOD\s*$/ ) {
        # catch the end line EOD
        $in_san_crt = 0;
        $in_san_key = 0;
    }

    if ( $start_document ) {
        $start_document = 0;
        print NEWFILE $line;
    } elsif ( $new_document_written == 0 && $in_san_crt ) {
        # write new san_crt
        open CRTFILE, "<$san_cert_dir/san.$envid.com.crt" or die $!;
        while ( my $crt_line = <CRTFILE> ) {
            print NEWFILE $crt_line;
        }
        close CRTFILE;
        $new_document_written = 1;
    } elsif ( $new_document_written == 0 && $in_san_key ) {
        # write new san_key
        open KEYFILE, "<$san_cert_dir/san.$envid.com.key" or die $!;
        while ( my $key_line = <KEYFILE> ) {
            print NEWFILE $key_line;
        }
        close KEYFILE;
        $new_document_written = 1;
    } elsif ( !$in_san_crt && !$in_san_key ) {
        print NEWFILE $line;
    }
}

close OLDFILE;
close NEWFILE;

print "Generated $token_table_file.new based on $token_table_file.\n";
exit 0;
