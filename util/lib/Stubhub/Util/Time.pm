package Stubhub::Util::Time;

#
# Time utils.
#

use strict;
use warnings;

use lib '/nas/reg/lib/perl';
use lib '/nas/utl/devops/lib/perl';

use Readonly;
use Stubhub::Log::Util qw (
                            get_logger
                        );

BEGIN {
  use Exporter();
  our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

  $VERSION = do { my @r = (q$Revision: 1.0 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

  @ISA          = qw( Exporter );
  @EXPORT       = qw();
  @EXPORT_OK    = qw(
                        &get_timestamp
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;

#
# Get timestamp string.
#
sub get_timestamp {
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime(time);
    my $timestamp = sprintf( "%04d%02d%02d%02d%02d%02d",
                            $year+1900, $mon+1, $mday, $hour, $min, $sec);
    return $timestamp;
}
