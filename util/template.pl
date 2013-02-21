#!/usr/bin/perl -w
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
use Getopt::Long;

# Get options
my $show_usage = qw{};
my $show_verbose = qw{};
my $another = qw{};
my $options_okay = GetOptions (
   'a|another=s' => \$another,
   'v|verbose'   => \$show_verbose,
   'h|help'      => \$show_usage,
);

if ( $show_usage ) {
   usage();
}

#
# Usage
#
sub usage {
   print <<END_OF_HELP
Usage: <script> [options]

Options:
 -a | --another           Another parameter.
 -v | --verbose           Show verbose messages.
 -h | --help              Show help information.

Examples:
 <script> ..

Author: minjzhang

END_OF_HELP
}

#
# Main
#

exit 0;
