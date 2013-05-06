package Stubhub::BigIP::Virtual::Parser;

#
# Stubhub BIG-IP Virtual Server Parser.
#

use strict;
use warnings;

use lib '/nas/reg/lib/perl';
use lib '/nas/home/minjzhang/ops/util/lib';

use Readonly;
use BigIP::Virtual::Parser qw (
                                parse_virtual
                              );

BEGIN {
  use Exporter();
  our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

  $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

  @ISA          = qw( Exporter );
  @EXPORT       = qw();
  @EXPORT_OK    = qw(
                      &parse_virtual_servers
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;

#
# Parse the virtual servers from configuration files.
#
sub parse_virtual_servers {
    my ( $virtual_servers_config_dir ) = @_;
    opendir DH, $virtual_servers_config_dir or die "Cannot open $virtual_servers_config_dir: $!";
    my @virtual_server_config_files = grep { ! -d } readdir DH;
    closedir DH;
    foreach my $virtual_server_config_file ( @virtual_server_config_files ) {
        parse_virtual("$virtual_servers_config_dir/$virtual_server_config_file");
    }
}
