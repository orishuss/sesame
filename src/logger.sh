#!/bin/bash

# Header Guard
if ! [ -z "$__LOGGER_SH__" ]; then
    return
fi
__LOGGER_SH__=true

# Included files.
source "$SCRIPT_DIR/constants.sh"

#################################################################################
#                                 CONSTANTS                                     #
#################################################################################

# The log levels supported by this logger.
declare -A LOG_LEVELS=(\
        ["DEBUG"]=1 \
        ["INFO"]=2 \
        ["WARNING"]=3 \
        ["ERROR"]=4 \
        ["CRITICAL"]=5 \
    )

# Ansi colors that allow writing to the screen in color.
declare -A COLORS=(\
        ["DEFAULT"]="\e[0m" \
        ["RED"]="\e""[0;31m" \
        ["GREEN"]="\e[0;32m" \
        ["YELLOW"]="\e[0;33m" \
        ["BLUE"]="\e[0;34m" \
        ["PURPLE"]="\e[0;35m" \
        ["CYAN"]="\e[0;36m" \
        ["WHITE"]="\e[0;37m" \
        ["DARK_GRAY"]="\e[1;30m" \
        ["BOLD_RED"]="\e[1;31m" \
        ["BOLD_GREEN"]="\e[1;32m" \
        ["BOLD_YELLOW"]="\e[1;33m" \
        ["BOLD_LIGHT_BLUE"]="\e[1;34m" \
        ["BOLD_LIGHT_PURPLE"]="\e[1;35m" \
        ["BOLD_LIGHT_CYAN"]="\e[1;36m" \
        ["BOLD_WHITE"]="\e[1;37m" \
    )

# The minimum level at which the logging will be written to the screen alongside
# the log file.
SCREEN_LOG_LEVEL="INFO"

#################################################################################
# Function:     get_color_for_level                                             #
# Purpose:      Get the color a string will be written at, according to the     #
#               logging level.                                                  #
# Arguments:        -   The logging level.                                      #
# Remarks:          -   Assumes that the given log level is valid.              #
#################################################################################
get_color_for_level() {
    level="$1"

    case "$level" in
        "DEBUG")
            color="WHITE"
            ;;
        "INFO")
            color="GREEN"
            ;;
        "WARNING")
            color="YELLOW"
            ;;
        "ERROR")
            color="RED"
            ;;
        "CRITICAL")
            color="RED"
            ;;
    esac

    echo "$color"
}

#################################################################################
# Function:     log                                                             #
# Purpose:      Log a string to the log file.                                   #
# Actions:      Logs the given string to the log file.                          #
#               If the log level is lower or equal to SCREEN_LOG_LEVEL, also    #
#               writes the log to the screen.                                   #
# Arguments:        -   The logging level.                                      #
#                   -   The string to be logged.                                #
#################################################################################
log() {
    local level="$1"
    string="$2"

    # Check that given level is valid.
    if ! [[ "${!LOG_LEVELS[@]}" =~ "$level" ]]; then
        log ERROR "Log level ""$level"" doesn't exist."
        return 1
    fi

    # Get the logging timestamp.
    timestamp="$(date +"%d.%m.%y-%T")"

    # Get the string that will represent the level of the log.
    level_color="$(get_color_for_level $level)"
    level_string="${COLORS[$level_color]}""$level""${COLORS[DEFAULT]}"
    level_string_colon="$level_string"":"
    # Pad the string with spaces to make it 9 characters.
    spaces_to_pad="$((9 - ${#level}))"
    for i in $(seq 1 $spaces_to_pad); do
        level_string_colon="$level_string_colon"" "
    done
    level_name_string="$(printf '%s' "$level_string_colon")"

    # Generate the logging string.
    log_string="$timestamp""  ""$level_name_string""""$string"

    # Make sure writing to the log file is possible.
    if [ -w "$LOG_FILE" ]; then
        echo -e "$log_string" >> "$LOG_FILE"
    fi

    # Write the log to the screen if log level is higher than the level chosen for
    # writing log to screen.
    if [ "${LOG_LEVELS[$level]}" -ge "${LOG_LEVELS[$SCREEN_LOG_LEVEL]}" ]; then
        echo -e "$log_string" >&2
    fi

    return 0
}
