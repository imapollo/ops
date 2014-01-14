package Stubhub::BigIP::Rule::Handler;

#
# To operate iRules.
#

use strict;
use warnings;

use lib '/nas/home/minjzhang/ops/util/lib';
use lib '/nas/reg/lib/perl';

use Readonly;
use BigIP::iControl;
use Stubhub::BigIP::System::Util qw (
                                    add_object_prefix
                                );

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
                        &get_rule_definition
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;

#
# Get all the rules.
#
sub get_rules {
    my ( $bigip_ref ) = @_;
    my @rules = $bigip_ref->{ "iControl" }->get_rule_list();
    return sort @rules;
}

#
# Get rules for specified environments.
#
sub get_env_rules {
    my ( $bigip_ref, $pattern ) = @_;
    my @full_rules = get_rules( $bigip_ref );
    $pattern = add_object_prefix( $bigip_ref, $pattern );
    my @rules = grep m\^$pattern\i, @full_rules;
    return @rules;
}

#
# Delete rules.
#
sub delete_env_rules {
    my ( $bigip_ref, $pattern ) = @_;
    my @rules = get_env_rules( $bigip_ref, $pattern );
    $bigip_ref->{ "iControl" }->delete_rules( \@rules );
}

#
# Get the definition of a specified rule.
#
sub get_rule_definition {
    my ( $bigip_ref, $rule ) = @_;
    $bigip_ref->{ "iControl" }->get_rule( $rule );
}
