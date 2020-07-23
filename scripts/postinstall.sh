#!/bin/bash
# This postinstall script is run by macOS' .pkg installer

# If MNU is running, close it and then launch the newly
# installed version. If it is not running, do not launch it
# Version 1.0.4

app="/Applications/MNU.app"

# Get MNU running instance -- will be empty if MNU not running
pid=$(ps -A | grep -m1 MNU | grep -v grep)

# Check process is running, and kill if it is
# This will be the case if $pid has a non-zero length
if [ -n "$pid" ]; then
    # Get the actual PID and use it to kill the process
    pid=$(echo "$pid" | awk {'print$1'})
    kill "$pid"
    syslog -s -l error "Existing MNU version closed"

    # Open the newly installed version if we can
    if [ -e "$app" ]; then
        if open "$app"; then
            syslog -s -l error "New MNU version started"
        else
            syslog -s -l error "MNU not launched"
        fi
    else
        syslog -s -l error "MNU not found in /Applications"
    fi
else
    syslog -s -l error "MNU not running"
fi

exit 0
