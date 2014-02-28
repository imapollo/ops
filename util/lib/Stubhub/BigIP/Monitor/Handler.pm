package Stubhub::BigIP::Monitor::Handler;

#
# To operate monitor.
#

use strict;
use warnings;

use lib '/nas/reg/lib/perl';
use lib '/nas/home/minjzhang/ops/util/lib';

use Readonly;
use Data::Dumper;
use BigIP::iControl;

BEGIN {
  use Exporter();
  our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

  $VERSION = do { my @r = (q$Revision: 1.0 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

  @ISA          = qw( Exporter );
  @EXPORT       = qw();
  @EXPORT_OK    = qw(
                        &get_monitor_send_url
                    );
  %EXPORT_TAGS  = ();
}

our %monitors_send_url = qw();

our @EXPORT_OK;

#
# Get monitor list.
#
sub get_monitor_send_url {
    my ( $bigip_ref, $the_template_name ) = @_;
    my $send_string = qw();
    if ( not defined $the_template_name or $the_template_name =~ /\/none$/ ) {
    } else {
        if ( exists $monitors_send_url{ $the_template_name } ) {
            $send_string = $monitors_send_url{ $the_template_name };
        } else {
            $send_string = $bigip_ref->{ "iControl" }->get_monitor_template_send( $the_template_name );
            $monitors_send_url{ $the_template_name } = $send_string;
        }
    }
    return $send_string;
}
