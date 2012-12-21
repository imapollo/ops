#!/bin/perl -w

use strict;
use Getopt::Long;

# get options
my $show_usage = qw{};
my $options_okay = GetOptions (
   'h|help'      => \$show_usage,
);

if ( $show_usage ) {
   usage();
}

#
# usage
#
sub usage {
   print <<END_OF_HELP
Usage:
Options:
Examples:
END_OF_HELP
}
