#!/bin/bash

ORG=jadudm
REPOS=laptoptwo
ORG_REPOS=${ORG}/${REPOS}

# GOAL
# Use Ansible for systems automation, not Bash.
# Therefore, my goal is to get to Ansible as quickly as possible.

# EXIT CODES
INSTALL_HOMEBREW_FAILED=-100
INSTALL_GIT_FAILED=-101
SETUP_VIRTUAL_ENV_FAILED=-102
INSTALL_ANSIBLE_FAILED=-103

####################################
# LOGGING AND MESSAGING
# These helper functions are used throughout for reporting and 
# logging what is going on. By default, very little goes to the
# user, but everything does go to the log.

create_logfile () {
    export LAPTOP_SETUP_LOGFILE=$(mktemp -t "laptop-log")
}

setup_logging () {
    # https://serverfault.com/questions/103501/how-can-i-fully-log-all-bash-scripts-actions
    # Save all the pipes.
    # 3 is Stdout. 4 is stderr.
    exec 3>&1 4>&2
    # Restore some.
    trap 'exec 2>&4 1>&3' 0 1 2 3
    # Redirect stdout/stderr to a logfile.
    exec 1>> "${LAPTOP_SETUP_LOGFILE}" 2>&1
    _status "Logfile started. It can be accessed for debugging purposes."
    _variable "LAPTOP_SETUP_LOGFILE"
}

# COLORS!
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
# No color
NC='\033[0m'

_msg () {
    TAG="$1"
    COLOR="$2"
    MSG="$3"
    printf "[${TAG}] ${MSG}\n" >&1
    printf "[${COLOR}${TAG}${NC}] ${MSG}\n" >&3
}

_status () {
    MSG="$1"
    _msg "STATUS" ${GREEN} "${MSG}"
}

_debug () {
    MSG="$1"
    _msg "DEBUG" ${YELLOW} "${MSG}"
}

_err () {
    MSG="$1"
    _msg "ERROR" ${RED} "${MSG}"
}

_variable () {
    VAR="$1"
    _msg "$VAR" ${PURPLE} "${!VAR}"
}

####################################
# CHECKS
# These are helper functions for checking if things exist,
# etc. Used a lot, clarifies the code.

# https://stackoverflow.com/questions/592620/how-can-i-check-if-a-program-exists-from-a-bash-script
command_exists () {
    type "$1" &> /dev/null ;
}

command_does_not_exist () {
    if command_exists "$1"; then
        return 1
    else 
        return 0
    fi
}

restore_console () {
    # https://stackoverflow.com/questions/21106465/restoring-stdout-and-stderr-to-default-value
    # Reconnect stdout and close the third filedescriptor.
    exec 1>&4 4>&-
    # Reconnect stderr
    exec 1>&3 3>&-
}

exit_with_status () {
    $EXITCODE = $1
    
    _err ""
    _err "The logfile for this run can be found at"
    _err ""
    _err "${LAPTOP_SETUP_LOGFILE}"
    _err ""
    _err "The contents of the logfile have been copied to the clipboard."
    _err "Please command-click the link below to open the laptoptwo issue tracker."
    _err ""
    _err "https://github.com/${ORG}/${REPOS}/issues"
    _err ""
    _err "Then, paste (command-v) the contents of the clipboard into a new issue."
    _err ""
    _err "You can run the command"
    _err ""
    _err "pbcopy < ${LAPTOP_SETUP_LOGFILE}"
    _err ""
    _err "to re-copy the log to the clipboard."
    _err "Exiting."

    pbcopy < "${LAPTOP_SETUP_LOGFILE}"
    exit $EXITCODE
}

# install_homebrew :: None -> None
# PURPOSE
# Installs homebrew.
install_homebrew () {
    if command_does_not_exist brew; then
        _status "Installing the Homebrew package manager."
        _status "You will probably be prompted for your password."
        ruby -e "$(curl --location --fail --silent --show-error https://raw.githubusercontent.com/Homebrew/install/master/install)"
        # This will be local to this script for now; Ansible will set the shell
        # variable properly once we're bootstrapped.
        export PATH="/usr/local/bin:$PATH"
    else
        _status "Update Homebrew."
        brew update
    fi
}

exit_if_install_homebrew_failed () {
    if command_does_not_exist brew; then
        _err "Homebrew cannot be found. Exiting."
        exit_with_status $INSTALL_HOMEBREW_FAILED
    fi
}

# install_tooling_via_brew :: None -> None
# PURPOSE
# What it says on the tin. Everything is easier if we have 
# python and git installed. 
install_tooling_via_brew () {
    _status "Installing python via brew."
    # This will error if the package is not installed.
    # Therefore, it will install. Or, if it is installed, nothing will happen.
    # https://apple.stackexchange.com/questions/284379/with-homebrew-how-to-check-if-a-software-package-is-installed
    brew list python || brew install python
    
    _status "Checking for git."
    if command_does_not_exist git; then
        _status "Installing git."
        brew list git || brew install git
    fi

    _status "Checking for ansible."
    if command_does_not_exist ansible; then
        _status "Installing ansible."
        brew list ansible || brew install ansible
    fi

}


exit_if_install_tooling_via_brew_failed () {
    if command_does_not_exist git; then
        _err "git should be installed at this point; it is not. Exiting."
        exit_with_status $INSTALL_GIT_FAILED
    fi
    if command_does_not_exist ansible; then
        _err "ansible should be installed at this point; it is not. Exiting."
        exit_with_status $INSTALL_ANSIBLE_FAILED
    fi
    if command_does_not_exist ansible-playbook; then
        _err "ansible-playbook should be installed at this point; it is not. Exiting."
        exit_with_status $INSTALL_ANSIBLE_FAILED
    fi
    if command_does_not_exist ansible-pull; then
        _err "ansible-pull should be installed at this point; it is not. Exiting."
        exit_with_status $INSTALL_ANSIBLE_FAILED
    fi    
}

# setup_tmp_dir :: None -> None
# PURPOSE
# Creates a temporary directory in the user's temp space.
# On macOS, mktemp doesn't behave the same as Linux. Beware.
setup_tmp_dir () {
    # See
    # https://unix.stackexchange.com/questions/30091/fix-or-alternative-for-mktemp-in-os-x
    # for why this is necessary.
    _status "Creating a temporary directory."
    _status "This is small, and will disappear on reboot."
    DIRNAME=laptop-$(date +%s)
    export LAPTOP_TMP_DIR
    LAPTOP_TMP_DIR=$(mktemp -d -t "$DIRNAME")
}

run_playbook () {
    pushd "${LAPTOP_TMP_DIR}" || exit
        restore_console
        ansible-pull -v -U https://github.com/${ORG_REPOS} playbook.yaml -v -i hosts
        setup_logging
    popd || exit
}

main () {
    create_logfile
    setup_logging
    install_homebrew
    exit_if_install_homebrew_failed
    install_tooling_via_brew
    exit_if_install_tooling_via_brew_failed
    setup_tmp_dir
    # Let the playbook drive the exit code.
    run_playbook
    exit $?
}

main