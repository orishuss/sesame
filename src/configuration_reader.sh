#!/bin/bash

# Header guard
if ! [ -z "$__CONFIGURATION_READER_SH__" ]; then
    return
fi
__CONFIGURATION_READER_SH__=true

# Included files.
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/logger.sh"
source "$SCRIPT_DIR/window_manager.sh"

#################################################################################
# Function:     get_workspace_configuration                                     #
# Purpose:      Get the configuration of a given workspace.                     #
# Arguments:        -   The workspace to get configuration of.                  #
#                   -   The configuration file to read.                         #
# Returns:      0 on success.                                                   #
#               -1 if configuration for the given workspace doesn't exist.      #
#################################################################################
get_workspace_configuration() {
    workspace="$1"
    config_file="$2"

    log INFO "Extracting configuration for workspace \"""$workspace""\"."

    # The line where the configuration for the workspace begins.
    config_start_line="workspace ""$workspace"":"
    if ! grep -q "$config_start_line" "$config_file" ; then
        log ERROR "Configuration for workspace \"""$workspace""\" doesn't exist."
        return -1
    fi
    start_line=$(grep -n "$config_start_line" "$config_file" | \
        cut -d':' -f1)

    # The line where the configuration for the workspace ends.
    line_to_start_search=$(($start_line+1))
    if ! tail -n +"$line_to_start_search" $config_file | grep '^workspace' ; then
        end_line=$(wc -l $config_file | cut -d' ' -f1)
    else
        end_line=$(tail -n +"$line_to_start_search" $config_file | \
            grep -n '^workspace' | \
            head -n 1 | \
            cut -d':' -f1)
        end_line=$(($end_line+$start_line - 1))
    fi

    log INFO "Found configuration on lines ""$start_line""-""$end_line""."

    # Get configuration lines.
    configuration=$(awk "NR >=""$start_line"" && NR <=""$end_line" "$config_file")

    log DEBUG "Configuration for workspace $workspace:\n""$configuration"

    echo "$configuration"
}

#################################################################################
# Function:     run_commands                                                    #
# Purpose:      Get the commands to run for a given workspace.                  #
# Arguments:        -   The workspace which commands are to be retrieved.       #
#                   -   The configuration file to read.                         #
#################################################################################
run_commands() {
    workspace="$1"
    config_file="$2"

    configuration="$(get_workspace_configuration "$workspace" "$config_file")"
    if ! [[ "$?" -eq 0 ]]; then
        return -1
    fi

    temp_conf_file="$(mktemp)"
    temp_conf_file2="$(mktemp)"
    echo "$configuration" > $temp_conf_file
    tail -n +2 $temp_conf_file > $temp_conf_file2
    window_command=""
    window_location=""
    selected_conf_type=""

    # Loop through configuration lines.
    while IFS='' read -r cur_line || [[ -n "$line" ]]; do
        # Check the configuration type that the next line will fill.
        conf_type=$(echo "$cur_line" | sed 's|^[[:space:]]*||')
        if [[ $conf_type == "#"* ]]; then
            # Line is commented out.
            log DEBUG "Found commented line in configuration\n: ""$cur_line"
            continue
        fi
        if [ "$conf_type" = "command:" ]; then
            selected_conf_type=window_command
        elif [ "$conf_type" = "location:" ]; then
            selected_conf_type=window_location
        elif [ "$conf_type" = "window:" ]; then
            # Starting a new window, store all current commands.
            run_command "$window_command" "$window_location"
            # Reset variables.
            window_command=""
            window_location=""
        else
            # This isn't conf line - save the value to the selected var.
            if [ "$selected_conf_type" = "" ]; then
                # Log that there's a bad configuration line if the line isn't empty
                # and the line isn't a 'workspace' line.
                if [ ! "$conf_type" = "" ] && [[ "$conf_type" != "workspace"*":" ]]; then
                    log WARNING "Bad configuration line: \n\t""$conf_type"
                fi
                continue
            fi
            eval "$selected_conf_type=\$conf_type"

            selected_conf_type=""
        fi
    done < $temp_conf_file2

    # Finished looping - execute final command.
    run_command "$window_command" "$window_location"
}

run_command() {
    window_command="$1"
    window_location="$2"

    log DEBUG "The command is: \"""$window_command""\""
    # Set the workspace arguments to the window command.
    # Loop while there are arguments to replace.
    while [[ $window_command == *"$args["* ]]; do
        arg_number="$(echo $window_command | sed -n 's|.*\$args\[\([0-9]*\)\].*|\1|p')"
        # Replace the string representing the argument location in the configuration,
        # with the user-given string.
        log DEBUG "Replacing \$args[""$arg_number""] with given argument \"""${WORKSPACE_ARGUMENTS[""$arg_number""]}""\""
        window_command="$(echo $window_command | \
            sed -n "s|\(.*\)\$args\[[0-9]*\]\(.*\)|\1""${WORKSPACE_ARGUMENTS[""$arg_number""]}""\2|p")"
    done

    IFS=$'\n' spawn_window "$window_command" "$window_location"
}

#################################################################################
# Function:     list_workspaces                                                 #
# Purpose:      List the workspaces configured in the given configuration file. #
#################################################################################
list_workspaces() {
    config_file="$1"

    workspaces="$(sed -n 's|[^ ]*workspace \([^ ]*\):.*|\1|p' $config_file)"

    echo "${workspaces[@]}"
}
