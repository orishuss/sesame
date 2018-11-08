#!/bin/bash

# Header guard
if ! [ -z "$__CONSTANTS_SH__" ]; then
    return
fi
__CONSTANTS_SH__=true

# The directory where the script's sources are.
SCRIPT_DIR="$(realpath "$0")"
SCRIPT_DIR="$(dirname $SCRIPT_DIR)"

# The directory where installed sesame files are.
SOURCE_DIR="/usr/lib/sesame"
# Sesame's binary.
SOURCE_BINARY="$SOURCE_DIR""/sesame.sh"

# Sesame's symlink the system's PATH.
SESAME_SYMLINK="/usr/bin/sesame"

# The file that contains sesame's configuration.
CONFIG_FILE="$SCRIPT_DIR""/sesame.cfg"

# File that sesame writes logs to.
LOG_FILE="/var/log/sesame.log"

# The usage string for the script.
USAGE="USAGE: \
sesame [options] <workspace> \n\
\tworkspace:\tthe workspace to load.\n\
 options:\n
\t--help\t\tPrint help and exit.\n\
\t--version\t\tPrint Sesame's installed version.\n\
\t--args=\t\tGive an argument to a workspace. Split arguments by ';'.\n\
\t\t\texample: sesame --args=\"arg1;arg2\"\n
\t--debug\t\tPrint debug level logs.\n\
\t--log\t\tPrint sesame's log and exit.\n\
\t--clean-log\tClean sesame's log and exit.\n\
\t--config\tEdit sesame's log and exit.\n\
\t--list\t\tList sesame's configured workspaces.\n\
\t--install\tInstall sesame on your system.\n\
\t--uninstall\tUninstall sesame from your system."

# Sesame's version.
VERSION=1.1.1
