#!/bin/bash

#################################################################################
# Script:       sesame                                                          #
# Purpose:      Create a unity session.                                         #
#################################################################################

script_dir="$(realpath "$0")"
script_dir="$(dirname $script_dir)"
source "$script_dir"/constants.sh

# Included files.
source "$SCRIPT_DIR"/logger.sh
source "$SCRIPT_DIR"/utils.sh
source "$SCRIPT_DIR"/configuration_reader.sh
source "$SCRIPT_DIR"/installation.sh

# Check if sesame is installed.
SESAME_INSTALLED="$(is_sesame_installed)"

# Get workspace to load.
IFS=$'\n' validate_arguments "$@"
retval="$?"
if [[ "$retval" -eq 11 ]]; then
    # Installing sesame."
    log INFO "Installing sesame."
    sesame_install
    exit 0
elif [[ "$retval" -eq 12 ]]; then
    # Uninstalling sesame.
    log INFO "Uninstalling sesame."
    sesame_uninstall
    exit 0
elif [[ "$retval" -eq 1 ]]; then
    # Print help was requested.
    print_usage
    exit 0
elif [[ "$retval" -eq 2 ]]; then
    # Printing sesame's log was requested.
    if [ "$SESAME_INSTALLED" = true ]; then
        log DEBUG "Printing sesame's log."
        cat "$LOG_FILE" >&2
        exit 0
    fi
elif [[ "$retval" -eq 3 ]]; then
    # Cleaning sesame's log was requested.
    if [ "$SESAME_INSTALLED" = true ]; then
        echo -n "" > "$LOG_FILE"
        log INFO "Cleaning sesame's log."
        exit 0
    fi
elif [[ "$retval" -eq 4 ]]; then
    # Configuring sesame was requested.
    if [ "$SESAME_INSTALLED" = true ]; then
        log DEBUG "configuring sesame."
        vim "$CONFIG_FILE"
        exit 0
    fi
elif [[ "$retval" -eq 5 ]]; then
    # Printing list of sesame's configured workspaces.
    loh INGO "Printing sesame's configured workspaces."
    list_workspaces "$CONFIG_FILE"
    exit 0
elif [[ "$retval" -eq 6 ]]; then
    # Printing Sesame's installed version.
    log INFO "Printing Sesame's installed version."
    echo "Sesame version: ""$VERSION"
    exit 0
elif ! [[ "$retval" -eq 0 ]]; then
    log CRITICAL "Validating arguments failed. Exiting."
    exit 1
fi

# Check if sesame is installed.
if [ "$SESAME_INSTALLED" = false ]; then
    log CRITICAL "Sesame is not installed."
    exit 1
fi

log INFO "Loading Workspace ""\"$WORKSPACE\""

# Get commands from database.
run_commands $WORKSPACE $CONFIG_FILE
