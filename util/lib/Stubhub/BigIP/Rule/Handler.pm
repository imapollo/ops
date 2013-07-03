package Stubhub::BigIP::Rule::Handler;

#
# To operate iRules.
#

use strict;
use warnings;

use lib '/nas/reg/lib/perl';
use lib '/nas/home/minjzhang/ops/util/lib';

use Readonly;
use BigIP::iControl;

BEGIN {
  use Exporter();
  our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

  $VERSION = do { my @r = (q$Revision: 1.0 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

  @ISA          = qw( Exporter );
  @EXPORT       = qw();
  @EXPORT_OK    = qw(
                        &delete_env_rules
                        &get_rules
                        &get_env_rules
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;

#
# Get all the rules.
#
sub get_rules {
    my ( $iControl ) = @_;
    my @rules = $iControl->get_rule_list();
    return sort @rules;
}

#
# Get rules for specified environments.
#
sub get_env_rules {
    my ( $iControl, $pattern ) = @_;
    my @full_rules = get_rules( $iControl );
    my @rules = grep /^$pattern/i, @full_rules;
    return @rules;
}

#
# Delete rules.
#
sub delete_env_rules {
    my ( $iControl, $pattern ) = @_;
    my @rules = get_env_rules( $iControl, $pattern );
    $iControl->delete_rules( \@rules );
}
