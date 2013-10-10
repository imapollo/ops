package Stubhub::P4::Info;

#
# P4 basic information.
#

use strict;
use warnings;

use lib '/nas/reg/lib/perl';
use lib '/nas/utl/devops/lib/perl';

use Readonly;
use Stubhub::Log::Util qw (
                            get_logger
                        );

our $logger = get_logger();

BEGIN {
  use Exporter();
  our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

  $VERSION = do { my @r = (q$Revision: 1.0 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

  @ISA          = qw( Exporter );
  @EXPORT       = qw();
  @EXPORT_OK    = qw(
                        &get_p4_branch_path
                    );
  %EXPORT_TAGS  = ();
}

our @EXPORT_OK;

#
# Get the P4 branch path.
#
sub get_p4_branch_path {
    my ( $branch_name ) = @_;
    my $p4_branch_path = qw{};
    if ( $branch_name eq "main" ) {
        $p4_branch_path = "/depot/main";
    } elsif ( $branch_name =~ m/^rb_/ ) {
        $p4_branch_path = "/depot/release/$branch_name";
    } elsif ( $branch_name =~ m/^pb_/ ) {
        $p4_branch_path = "/depot/project/$branch_name";
    } else {
        $logger->logdie( "Branch name $branch_name doesn't look good." );
    }
    return $p4_branch_path;
}
