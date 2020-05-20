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

# https://stackoverflow.com/questions/592620/how-can-i-check-if-a-program-exists-from-a-bash-script
command_exists () {
    type "$1" &> /dev/null ;
}

command_does_not_exist () {
    return ! command_exists "$1"
}

setup_logging () {
    # https://serverfault.com/questions/103501/how-can-i-fully-log-all-bash-scripts-actions
    # Save all the pipes.
    exec 3>&1 4>&2
    # Restore some.
    trap 'exec 2>&4 1>&3' 0 1 2 3
    # Redirect stdout/stderr to a logfile.
    LAPTOP_SETUP_LOGFILE=$(mktemp -t "laptop-log")
    _status "Logfile started. It can be accessed for debugging purposes."
    _variable "LAPTOP_SETUP_LOGFILE"
    exec 1> "${LAPTOP_SETUP_LOGFILE}" 2>&1
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
        _status "Update Homebrew"
        brew update
    fi
}

exit_if_install_homebrew_failed () {
    if [[ ! -f "/usr/local/bin/brew" ]]; then
        _err "Homebrew cannot be found at /usr/local/bin/brew. Exiting."
        exit $INSTALL_HOMEBREW_FAILED
    fi
}

# install_git :: None -> None
# PURPOSE
# What it says on the tin. Everything is easier if we have 
# python and git installed. 
install_git () {
    _status "Installing python via brew."
    # This will error if the package is not installed.
    # Therefore, it will install. Or, if it is installed, nothing will happen.
    # https://apple.stackexchange.com/questions/284379/with-homebrew-how-to-check-if-a-software-package-is-installed
    brew list python || brew install python
    _status "Checking for git."
    if ! command -v git > /dev/null; then
        brew list git || brew install git
    fi

}

exit_if_install_git_failed () {
    if command_does_not_exist git; then
        _err "git should be installed at this point; it is not. Exiting."
        exit $INSTALL_GIT_FAILED
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

# setup_virtual_environment :: None -> None
# PURPOSE
# Sets up a virtual environment in /tmp so that we can have a 
# known Python3 to work with. 
setup_virtual_environment () {
    _status "Setting up a venv."
    export PIP_TARGET="${LAPTOP_TMP_DIR}/pip"
    export LAPTOP_SETUP_VENV="${LAPTOP_TMP_DIR}/laptop-setup-venv"
    _variable "LAPTOP_SETUP_VENV"
    pip3 install --no-cache-dir --upgrade virtualenv
    virtualenv --system-site-packages -p python3 "${LAPTOP_SETUP_VENV}"
    # Shellcheck wants to know where this is, but we can't say.
    # shellcheck source=/dev/null
    . "${LAPTOP_SETUP_VENV}/bin/activate"
}

exit_if_setup_virtual_env_failed () {
    # Check the venv directory exists.
    if [[ ! -d "${LAPTOP_SETUP_VENV}" ]]; then
        _err "The virtual env directory was not created."
        _variable "LAPTOP_SETUP_VENV"
        exit $SETUP_VIRTUAL_ENV_FAILED    
    fi
    # Check if we can activate it.
    LAPTOP_VENV_ACTIVATE="${LAPTOP_SETUP_VENV}/bin/activate"
    if command_does_not_exist "${LAPTOP_VENV_ACTIVATE}"; then
        _err "Cannot find the 'activate' script for the local venv."
        _variable "LAPTOP_VENV_ACTIVATE"
        exit $SETUP_VIRTUAL_ENV_FAILED
    fi
}

# pip_install_ansible :: None -> None
# PURPOSE
# Installs Ansible via pip. We should be in the virtualenv at this point.
pip_install_ansible () {
    _status "Installing ansible into the venv. This takes a while. ☕️"
    pip install --no-cache-dir --upgrade \
        wheel \
        ansible \
        github3.py
}

exit_if_install_ansible_failed () {
    if command_does_not_exist ansible-playbook; then
        _err "Cannot find 'ansible-playbook'; exiting."
        return $INSTALL_ANSIBLE_FAILED
    fi

    if command_does_not_exist ansible-pull; then
        _err "Cannot find 'ansible-pull'; exiting."
        return $INSTALL_ANSIBLE_FAILED
    fi
}

run_playbook () {
    pushd "${LAPTOP_TMP_DIR}" || exit
       ansible-pull -v -U https://github.com/${ORG_REPOS} playbook.yaml -v -i hosts
    popd || exit
}

main () {
    setup_logging
    install_homebrew
    exit_if_install_homebrew_failed
    install_git
    exit_if_install_git_failed
    setup_tmp_dir
    setup_virtual_environment
    exit_if_setup_virtual_env_failed
    pip_install_ansible
    exit_if_install_ansible_failed
    # Let the playbook drive the exit code.
    run_playbook
    exit $?
}

main