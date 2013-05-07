package Stubhub::ENV::Info;

#
# TODO baseic inforamtion about the module.
#

use strict;
use warnings;

use lib '/nas/reg/lib/perl';
use lib '/nas/home/minjzhang/ops/util/lib'; # TODO Determine if this should be removed

use Readonly;

BEGIN {
  use Exporter();
  our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

  $VERSION = do { my @r = (q$Revision: 1.0 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

  @ISA          = qw( Exporter );
  @EXPORT       = qw();
  # TODO rename the function
  @EXPORT_OK    = qw(
                        &sample_function
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;

#
# TODO rename the function
#
sub sample_function {
}
