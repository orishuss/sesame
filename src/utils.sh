#!/bin/bash

# Header Guard
if [ -n "$__UTILS_SH__" ]; then
    return
fi

__TUILS_SH__=true

# Included files.
source "$SCRIPT_DIR/constants.sh"
source "$SCRIPT_DIR/logger.sh"
source "$SCRIPT_DIR"/configuration_reader.sh

#################################################################################
# Function:     print_usage                                                     #
# Purpose:      Print the script's usage to the screen.                         #
#################################################################################
print_usage() {
    echo -e $USAGE>&2
}

#################################################################################
# Function:     validate_arguments                                              #
# Purpose:      Validate the script's arguments.                                #
# Actions:          -   Check if usage is to be printed (--help flag).          #
#                   -   Check if configuring is selected (--config flag).       #
#                   -   Validate that only one argument is given.               #
#                       If none are given, let the user choose a workspace to   #
#                       load.                                                   #
#                   -   Validate that the chosen argument is indeed a string.   #
# Arguments:        -   The arguments given to the script.                      #
# Returns:      The chosen workspace in variable WORKSPACE                      #
#               other return values:                                            #
#                   -1  :   Failure.                                            #
#                    1  :   Printing help.                                      #
#                    2  :   Printing log.                                       #
#                    3  :   Cleaning log.                                       #
#                    4  :   Configuring.                                        #
#                    5  :   Print workspace list.                               #
#                    6  :   Print Sesame's version.                             #
#                    11 :   Installing.                                         #
#                    12 :   Uninstalling.                                       #
#################################################################################
validate_arguments() {
    # Looping arguments.
    for i in "$@"; do
        case "$i" in
            # Check if debug mode is set.
            --debug)
                SCREEN_LOG_LEVEL="DEBUG"
                shift
                ;;

            # Check if printing help.
            --help)
                return 1
                ;;

            # Check if printing log.
            --log)
                return 2
                ;;

            # Check if cleaning log.
            --clean-log)
                return 3
                ;;

            # Check if editing the configuration file.
            --config)
                return 4
                ;;

            # Check if listing sesame's workspaces.
            --list)
                return 5
                ;;

            # Check if printing Sesame's version.
            --version)
                return 6
                ;;

            # Check if installing sesame.
            --install)
                # Errors are ignored because the log file doesn't exist yet.
                return 11
                ;;

            # Check if uninstalling sesame.
            --uninstall)
                return 12
                ;;

            # Check if workspace arguments were given.
            --args=*)
                # Split arguments by ';' and store them in WORKSPACE_ARGUMENTS.
                IFS=';' read -r -a WORKSPACE_ARGUMENTS <<< "${i#*=}"
                shift
                ;;

            # None of the options above - argument is workspace identifier.
            *)
            if ! [ -z "$workspace" ]; then
                # Workspace already found.
                log ERROR "Too many arguments given."
                print_usage
                return -1
            fi
            workspace="$1"
            shift
            ;;
        esac
    done

    # If no command line workspace id, wait for user input.
    if [ -z "$workspace" ]; then
        workspace="$(get_workspace_from_user_input)"
    fi

    # If no arguments were given, allow user to enter if needed.
    if [ -z "$WORKSPACE_ARGUMENTS" ]; then
        get_workspace_arguments_from_user_input "$workspace"
    fi

    # Validate workspace id is string.
    re='^[0-9a-zA-Z_]+$'
    if ! [[ $workspace =~ $re ]]; then
        # Argument is not valid.
        log ERROR "Invalid workspace identifier \"""$workspace""\"."
        print_usage
        return -1
    fi

    # Return the workspace
    WORKSPACE="$workspace"
    return 0
}

#################################################################################
# Function:     get_workspace_from_user_input                                   #
# Purpose:      Get a workspace identifier from the user.                       #
#################################################################################
get_workspace_from_user_input() {
    log DEBUG "Asking user for input to determine what workspace to load."

    # Get all possible workspaces, and sort them lexicographically.
    workspaces=( $(list_workspaces "$CONFIG_FILE" | sort) )

    # Allow the user to choose a workspace.
    workspace="$(zenity --title="Choose Workspace" --list --column="Workspaces" \
        "${workspaces[@]}" --height=600 --width=350 \
        --text="Choose a workspace for Sesame to load." 2>/dev/null)"

    log DEBUG "User-chosen workspace: ""$workspace"

    # Echo the workspace - as return string.
    echo "$workspace"

    return 0
}

#################################################################################
# Function:     get_workspace_arguments_from_user_input                         #
# Purpose:      Get workspace arguments from the user.                          #
#               Store the arguments in WORKSPACE_ARGUMENTS.                     #
# Arguments:        -   The workspace that arguments are needed for.            #
#################################################################################
get_workspace_arguments_from_user_input() {
    workspace="$1"
    log DEBUG "Getting arguments for workspace \"""$workspace""\"."

    # Get the configuration of the workspace.
    workspace_configuration="$(get_workspace_configuration ""$workspace"" ""$CONFIG_FILE"")"
    # Get all occurrences of args[X] in the workspace's configuration in order
    # to find whether there are any arguments.
    workspace_numbers=( $(echo ""$workspace_configuration"" | \
        grep -oP "args\[[0-9]*\]") )

    if [ -n "$workspace_numbers" ]; then
        log DEBUG "Workspace requires arguments. Getting them from user."
        text="Provide arguments for workspace \""$workspace"\". "
        text="$text""Separate them by a space."
        arguments="$(zenity --title="Provide arguments" --entry \
            --text="$text" 2>/dev/null)"
        IFS=' ' read -r -a WORKSPACE_ARGUMENTS <<< "${arguments}"
        log DEBUG "Got ""${#WORKSPACE_ARGUMENTS[@]}"" arguments from the user."
    else
        log DEBUG "Workspace \"""$workspace""\" doesn't require arguments."
    fi

    return 0
}
