#!/bin/bash

# Header Guard
if [ -n "$__INSTALLATION_SH__" ]; then
    return
fi
__INSTALLATION_SH__=true

# Included files
source "$SCRIPT_DIR/constants.sh"
source "$SCRIPT_DIR/logger.sh"

#################################################################################
# Function:     sesame_install                                                  #
# Purpose:      Install sesame on the system.                                   #
# Actions:          -   Make sure script is running with root privileges.       #
#                   -   Create log file.                                        #
#                   -   Copy sources to system directory.                       #
#                   -   Create binary symlink in PATH.                          #
#################################################################################
sesame_install() {
    # Make sure running with root privileges.
    if [ "$(id -u)" != 0 ]; then
        log ERROR "This operation must be run with root privileges."
        return 1
    fi

    # Make sure sesame isn't already installed.
    if [ "$(is_sesame_installed)" = true ]; then
        # Sesame already installed. Ask the user about updating.
        log INFO "Sesame is already installed."
        installed_sesame_version="$(sesame --version 2>/dev/null)"
        if [[ "$?" -ne 0 ]]; then
            log DEBUG "Sesame's installed version doesn't support printing version."
            installed_sesame_version="unknown"
        else
            installed_sesame_version="$(echo ""$installed_sesame_version"" | \
                grep 'Sesame version:' | cut -d':' -f2 | tr -d ' ')"
        fi
        log DEBUG "Asking the user about upgrading Sesame's version."
        echo "Sesame's installed version is ""$installed_sesame_version""."
        read -r -p "Would you like to upgrade to version ""$VERSION""? [y/n] " user_input
        log DEBUG "User entered: \"""$user_input""\"."
        case "$user_input" in
            [yY])
                log INFO "Upgrading Sesame from version ""$installed_sesame_version"" to ""$VERSION""."
                sesame_upgrade
                log INFO "Sesame successfully upgraded."
                return "$?"
                ;;
            *)
                log INFO "Terminating Sesame's installation."
                return 1
                ;;
        esac
    fi

    # Create log file.
    log INFO "Creating log file..."
    touch "$LOG_FILE"
    chmod 666 "$LOG_FILE"

    # Copy sources to system directory.
    log INFO "Copying source files..."
    mkdir -p "$SOURCE_DIR"
    cp -r "$SCRIPT_DIR"/* "$SOURCE_DIR"/

    # Create binary symlink.
    log INFO "Creating binary symlink..."
    ln -s "$SOURCE_BINARY" "$SESAME_SYMLINK"
}

#################################################################################
# Function:     sesame_upgrade                                                  #
# Purpose:      Upgrade Sesame's version to the one running this function.      #
# Actions:          -   Backup Sesame's configuration file.                     #
#                   -   Remove Sesame's sources from system directory.          #
#                   -   Install Sesame's new version.                           #
#                   -   Restore Sesame's configuration file.                    #
# Remarks:          -   Assumes the script is running with root privileges.     #
#################################################################################
sesame_upgrade() {
    # Get the location of Sesame's installed configuration file.
    installed_sesame_configuration_file="$SOURCE_DIR""/""${CONFIG_FILE##*/}"
    tmp_config_file="$(mktemp)"
    log INFO "Backing up Sesame's configuration to \"""$tmp_config_file""\"."
    mv "$installed_sesame_configuration_file" "$tmp_config_file"

    # Remove sources from system directory.
    log INFO "Removing old source files..."
    rm -r "$SOURCE_DIR"

    # Install Sesame's new version's sources.
    log INFO "Copying new source files..."
    mkdir -p "$SOURCE_DIR"
    cp -r "$SCRIPT_DIR"/* "$SOURCE_DIR"/

    # Restore Sesame's old configuration file.
    log INFO "Restoring Sesame's configuration."
    mv "$tmp_config_file" "$installed_sesame_configuration_file"

    return 0
}

#################################################################################
# Function:     sesame_uninstall                                                #
# Purpose:      Uninstall sesame on the system.                                 #
# Actions:          -   Make sure script is running with root privileges.       #
#                   -   Remove log file.                                        #
#                   -   Remove sources from system directory.                   #
#                   -   Remove binary symlink from PATH.                        #
#################################################################################
sesame_uninstall() {
    # Make sure running with root privileges.
    if [ "$(id -u)" != 0 ]; then
        log ERROR "This operation must be run with root privileges."
        return 1
    fi

    # Remove log file.
    log INFO "Deleting log file..."
    rm "$LOG_FILE"

    # Remove sources from system directory.
    log INFO "Removing source files..."
    rm -r "$SOURCE_DIR"

    # Remove binary symlink.
    log INFO "Removing binary symlink..."
    rm "$SESAME_SYMLINK"
}

#################################################################################
# Function:     is_sesame_installed                                             #
# Purpose:      Check if sesame is installed on the system.                     #
# Actions:      Checks if all are true:                                         #
#                   -   Log file exists.                                        #
#                   -   Source directory and binary exist.                      #
#                   -   Sesame's symlink exists.                                #
#################################################################################
is_sesame_installed() {
    local installed=true

    # Check if log file exists.
    if ! [ -w "$LOG_FILE" ]; then
        installed=false
    fi

    # Check if sources directory exist.
    if ! [ -d "$SOURCE_DIR" ]; then
        installed=false
    fi

    # Check if source binary exists.
    if ! [ -f "$SOURCE_BINARY" ]; then
        installed=false
    fi

    # Check if sesame's symbolic link exists.
    if ! [ -L "$SESAME_SYMLINK" ]; then
        installed=false
    fi

    echo "$installed"
}
