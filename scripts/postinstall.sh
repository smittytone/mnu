#!/bin/sh
# This postinstall script is run on macOS .pkg installer

# Get MNU running instance
pid=`ps -A | grep -m1 MNU | grep -v grep`

# Check process is running, and kill if it is
# This will be the case if $pid has a non-zero length
if [ -n "$pid" ]; then
    # Get the actual PID and use it to kill the process
    pid=`ps -A | grep -m1 MNU | awk {'print$1'}`
    kill "$pid"
fi

# Open the installed version
open -a /Applications/MNU.app
exit 0