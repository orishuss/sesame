#!/bin/bash

# Header guard
if ! [ -z "$__WINDOW_MANAGER_SH__" ]; then
    return
fi
__WINDOW_MANAGER_SH__=true

# Included files.
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/logger.sh"

# Constants
MAX_TIME_TO_WAIT_FOR_WINDOW_TO_OPEN=3 # seconds

#################################################################################
# Function:     get_open_window_for_process                                     #
# Purpose:      Get a window opened by a process or its children.               #
# Arguments:        -   The process id.                                         #
# Remarks:          -   This doesn't return window if opened by children of     #
#                       children, only by first degree children.                #
#                   -   Returns only the first window it finds, as assumes that #
#                       a command will only spawn one window.                   #
#################################################################################
get_open_window_for_process() {
    pid="$1"

    # Get the children of the process.
    # Log every child if there are any.
    children="$(pgrep -P "$pid")"
    if [ -n "$children" ]; then
        log INFO "process \"""$pid""\" spawned processes:"
        for p in "$children"; do log INFO "$p"; done
    fi

    # Loop through processes, wait for a window to open.
    windows=()
    max_time="$MAX_TIME_TO_WAIT_FOR_WINDOW_TO_OPEN"
    sleep_time=0.25
    while [ 0 -eq "${#windows[@]}" ]; do
        # Find window spawned by main process.
        log DEBUG "Checking if process \"""$pid""\" opened a window."
        window_id="$(wmctrl -lp | grep "$pid" | cut -d' ' -f1)"
        if [ -n "$window_id" ]; then
            log INFO "Found window \"""$window_id""\" opened by process \"""$pid""\""
            windows+=($window_id)
            break
        fi
        window_id=""

        # Find windows for all the children processes.
        if [ -n "$children" ]; then
            for p in "${children[@]}"; do
                log DEBUG "Checking if child process \"""$p""\" opened a window."
                # Find window opened by current process, if there is one.
                window_id="$(wmctrl -lp | grep "$p" | cut -d' ' -f1)"

                # Add the new window found to the window list.
                if [ -n "$window_id" ]; then
                    log INFO "Found window \"""$window_id""\" opened by child \"""$p""\""
                    windows+=$(window_id)
                    break
                fi
                window_id=""
            done
        fi

        # Wait a bit for window to open.
        sleep $sleep_time
        # Check if max time per process has passed.
        max_time=$(python -c "print(""$max_time""-""$sleep_time"")")
        if [ $(echo "$max_time""<0" | bc -l) -gt 0 ]; then break; fi
    done

    # Return window.
    echo "${windows[@]}"
}

#################################################################################
# Function:     set_process_location                                            #
# Purpose:      Set the location of a given process.                            #
# Arguments:        -   The process id.                                         #
#                   -   The location the process is to be moved to.             #
#################################################################################
set_process_location() {
    pid="$1"
    location="$2"

    IFS=$'\n' window=$(get_open_window_for_process "$pid")

    if [ -z "$window" ]; then
        log INFO "Command didn't spawn a window for process \"""$pid""\"."

        log INFO "Checking if a window has spawned for an already-running \"""$COMMAND_NAME""\" process."
        # Get all the windows open by the command.
        tmp="$(wmctrl -lp | \
            grep -i ""$COMMAND_NAME"" | tr -s ' ' | cut -d' ' -f1)"
        IFS=$'\n' read -rd '' -a windows_open_for_command <<< "$tmp"

        # Check if a new window for the command has spawned while we polled for windows
        # opened by the process.
        log INFO "Windows opened for process \"""$COMMAND_NAME""\":"
        for w in "${windows_open_for_command[@]}"; do log INFO "$w"; done

        log INFO "Comparing the windows open before running the command and after it."
        for w in "${windows_open_for_command[@]}"; do
            log DEBUG "Checking if window \"""$w""\" is new."
            if [[ ! "$WINDOWS_ALREADY_OPEN_FOR_COMMAND[*]}" == *"$w"* ]]; then
                log INFO "Window \"""$w""\" is new."
                window="$w"
            fi
        done

        # Check if a new window was found by comparing the windows open before
        # and after the command.
        if [ -z "$window" ]; then
            log INFO "Didn't find any new windows."
            log ERROR "Configuration dictates to set location \"""$location""\" but the command didn't spawn a window."
            return 1
        fi
    fi

    # Set the location of the spawned window.
    log INFO "Setting location of window \"""$window""\" to \"""$location""\""
    wmctrl -i -r "$window" -e "$location"

    return 0
}

#################################################################################
# Function:     spawn_window                                                    #
# Purpose:      Spawn a window with the given command in the given location.    #
# Arguments:        -   The command that will spawn the wanted window.          #
#                   -   The location of the window. Can be empty if default is  #
#                       wanted.                                                 #
#################################################################################
spawn_window() {
    local cmd="$1"
    local location="$2"

    # Make sure the command exists.
    if [ -z "$cmd" ]; then return 1; fi

    # Get the name of the command.
    # This is the first part of the command line from the configuration file.
    COMMAND_NAME="$(echo $cmd | cut -d' ' -f1 | cut -d'-' -f1 | cut -d'_' -f1)"
    log DEBUG "The command name is \"""$COMMAND_NAME""\""

    # Check if a window for a similar command is already open.
    tmp="$(wmctrl -lp | \
        grep -i ""$COMMAND_NAME"" | tr -s ' ' | cut -d' ' -f1)"
    IFS=$'\n' read -rd '' -a WINDOWS_ALREADY_OPEN_FOR_COMMAND <<< "$tmp"
    if [ -n "$WINDOWS_ALREADY_OPEN_FOR_COMMAND" ]; then
        log INFO "Process \"""$COMMAND_NAME""\" already has open windows:"
        for w in "${WINDOWS_ALREADY_OPEN_FOR_COMMAND[@]}"; do log INFO "$w"; done
    fi

    # Run the command.
    log INFO "Running command: \"""$cmd""\""
    eval "$cmd" >/dev/null 2>/dev/null
    process_id="$!"
    log INFO "Command started on process id \"""$process_id""\""

    # If no location, return.
    if [ "$location" = "" ]; then
        return 0
    fi

    # Location is present.
    set_process_location "$process_id" "$location"

    return 0
}
