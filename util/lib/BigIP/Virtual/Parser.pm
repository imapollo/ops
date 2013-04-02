package BigIP::Virtual::Parser;

#
# BIG-IP Virtual Server Parser.
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
                      &parse_virtual
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;

sub parse_virtual {
    my ( $virtual_server_config_file ) = @_;
    open VSCONFIG_FH, "<$virtual_server_config_file" or die $!;

    my $virtual_name = qw{};
    my $default_pool = qw{};
    my $irule = qw{};
    my $in_rules_section = 0;
    while ( my $line = <VSCONFIG_FH> ) {
        if ( $in_rules_section ) {
            if ( $line =~ m/^\s*}\s*$/ ) {
                $in_rules_section = 0;
                next;
            } else {
                $line =~ s/^\s*(\S*)\s*$/$1/;
                if ( ! defined $irule ) {
                    $irule = $line;
                } else {
                    $irule = "$irule,$line";
                }
            }
        } else {
            if ( $line =~ m/^virtual\s+/ ) {
                $virtual_name = $line;
                $virtual_name =~ s/^virtual\s+(\S+)\s{\s*$/$1/;
            }
            if ( $line =~ m/^\s*pool\s+/ ) {
                $default_pool = $line;
                $default_pool =~ s/^\s*pool\s+(\S+)\s*$/$1/;
            }
            if ( $line =~ m/^\s*rules\s*{\s*$/ ) {
                $in_rules_section = 1;
            } elsif ( $line =~ m/^\s*rules\s+/ ) {
                $irule = $line;
                $irule =~ s/^\s*rules\s+(\S+)\s*$/$1/;
            }
        }
    }
    print "virtual: $virtual_name\n" if defined $virtual_name;
    print "pool: $default_pool\n" if defined $default_pool;
    print "irule: $irule\n" if defined $irule;
}
