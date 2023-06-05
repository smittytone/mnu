#!/bin/sh
# This postinstall script is run by macOS' .pkg installer

# If MNU is running, close it and then launch the newly
# installed version. If it is not running, do not launch it
# Version 1.1.3

# Set the target
app="/Applications/MNU.app"

# FROM 1.1.0
# Add logging
log=~/.mnulog
if ! [ -e "$log" ]; then
    touch "$log"
fi

# Get MNU running instance -- will be empty if MNU not running
# FROM 1.1.0 -- use pgrep
old_pid=$(pgrep -x MNU)

# Check process is running, and kill if it is
# This will be the case if $pid has a non-zero length
if [ -n "$old_pid" ]; then
    # Get the actual PID and use it to kill the process
    # pid=$(echo "$pid" | awk {'print$1'})
    kill "$old_pid"
    echo "$(date) Existing MNU ($old_pid) instance closed down" >> "$log"

    # Open the newly installed version if we can
    if [ -e "$app" ]; then
        if open -a "$app" ; then
            new_pid=$(pgrep -x MNU)
            echo "$(date) New MNU ($new_pid) instance started" >> "$log"
        else
            echo "$(date) New MNU instance not started: ${?}" >> "$log"
        fi
    else
        echo "$(date) MNU not found in /Applications" >> "$log"
    fi
else
    echo "$(date) MNU not running -- please launch manually" >> "$log"
fi

exit 0