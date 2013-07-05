#!/bin/bash
#
# <brief information about the script>
# <detail information about the script if any>
#
# Usage: <script> [options]
#
# Options:
#  -a | --another=..   Another option.
#  -v | --verbose      Print verbose messages.
#
# Author: <email address>
#

options=$@

another_option=0
verbose=0

#
# Usage
#
function _usage() {
    cat <<EOF

<script> $options
$*
Usage: <script> [options]

Options:
  -a | --another=..   Another option.
  -v | --verbose      Print verbose messages.
EOF
}

#
# Get options
#
OPTS=`getopt -o a:v -l another:,verbose -- $options`
if [ $? != 0 ]; then
    echo "Error: Unrecognized parameters."
    _usage
    exit 1
fi

eval set -- "$OPTS"

while true ; do
    case "$1" in
        -a | --another) echo "Got a, arg: ${2// }"; shift 2;;
        -v | --verbose) verbose=1; shift;;
        --) shift; break;;
    esac
done

#
# Print verbose message
#
function _print_verbose_msg {
    verbose_message=$1
    if [[ "$verbose" == 1 ]]; then
        echo $verbose_message
    fi
}

#
# Main
#

exit 0
