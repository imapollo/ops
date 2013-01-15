#!/usr/bin/perl
#

open OLDFILE, "<token-table-env-based" or die $!;
open NEWFILE, ">token-table-env-based.new" or die $!;

my $envid = "";
my $in_san_crt = 0;
my $in_san_key = 0;
my $start_document = 0;
my $new_document_written = 0;

my $envs = "srwd40,srwd50,srwd70";
my @environments = split(',', $envs);

# TODO accept parameter to proceed selected environments
# TODO accept parameter to pass the path of new san certs

my $san_cert_dir = "/nas/reg/relmgt/new_certs_01142013";

while ( my $line = <OLDFILE> ) {
    if ( $line =~ m/^\s*<(srwd[0-9]*)>\s*$/ ) {
        # catch the start line of a environment
        if ( grep /$1/, @environments ) {
            $envid = $1;
        }
    } elsif ( $line =~ m/^\s*<\/(srwd[0-9]*)>\s*$/ ) {
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
        open CRTFILE, "<$san_cert_dir/san.$envid.com.crt" or die $!;
        while ( my $crt_line = <CRTFILE> ) {
            print NEWFILE $crt_line;
        }
        close CRTFILE;
        $new_document_written = 1;
    } elsif ( $new_document_written == 0 && $in_san_key ) {
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
