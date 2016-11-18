#!/usr/bin/perl
#
# <Brief description of the script>
# <More information about the script>
#
# Usage: <script> [options]
#
# Options:
#  -a | --another           Another parameter.
#  -v | --verbose           Show verbose messages.
#  -h | --help              Show help information.
#
# Examples:
#  <script> ..
#
# Author: minjzhang
#

use strict;
use warnings;
use Carp;
use Getopt::Long;

# use lib '/nas/utl/devops/lib/perl';
use lib '/nas/home/minjzhang/ops/util/lib';

use Stubhub::Log::Util qw (
                            init
                            get_logger_with_loglevel
                        );

# Get options
my $show_usage = qw{};
my $show_verbose = qw{};
my $another = qw{};
my $options_okay = GetOptions (
    'a|another=s' => \$another,
    'v|verbose'   => \$show_verbose,
    'h|help'      => \$show_usage,
);

#
# Initiate log instance
#
Stubhub::Log::Util->init();
our $logger = get_logger_with_loglevel( $show_verbose );

#
# Signal Handler
#
$SIG{'INT'} = \&sigIntHandler;

#
# Clean up and exit when catch SIGINT(2)
#
sub sigIntHandler {
    exit;
}

if ( $show_usage ) {
    usage();
    exit 0;
}

#
# Usage
#
sub usage {
    print <<END_OF_HELP
<copy from header>

END_OF_HELP
}

#
# Parameter validation
#
if ( ! defined $another) {
    $logger->error( "The pamameter '-a' must be set.\n" );
    usage();
    exit 1;
}

#
# Main
#

exit 0;
