#!/bin/bash
# this script displays system information

source reportfunctions.sh

# This function will send an error message to stderr
# Usage:
#   error-message ["some text to print to stderr"]
function error-message {
    local prog=`basename $0`
    echo "${prog}: ${1:-Unknown Error - a moose bit my sister once...}" >&2
}

# This function will send a message to stderr and exit with a failure status
# Usage:
#   error-exit ["some text to print to stderr" [exit-status]]
function error-exit {
    error-message "$1"
    exit "${2:-1}"
}

#This function displays help information if the user asks for it on the command line or gives us a bad command line
function displayhelp {
    echo "Usage:$0 [-h | --help]"
}

systemwanted=false

# process command line options
partialreport=
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      displayhelp
      error-exit
      ;;
    --system)
      systemwanted=true
      ;;
    --disk)
      diskwanted=true
      ;;
    --network)
      networkwanted=true
      ;;
    *)
      error-exit "$1 is invalid"
      ;;
  esac
  shift
done

# create output

if [ "$systemwanted" = true ]; then
    computerreport
    osreport
    cpureport
    ramreport
    videoreport
elif [ "$diskwanted" = true ]; then
    diskreport
elif [ "$networkwanted" = true ]; then
    networkreport
else
    computerreport
    osreport
    cpureport
    ramreport
    videoreport
    diskreport
    networkreport
fi

cleanup