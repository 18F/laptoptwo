#!/bin/bash

ORG=jadudm
REPOS=laptoptwo
ORG_REPOS=${ORG}/${REPOS}

# GOAL
# Use Ansible for systems automation, not Bash.
# Therefore, my goal is to get to Ansible as quickly as possible.

# install_homebrew :: None -> None
# PURPOSE
# Installs homebrew.
install_homebrew () {
    if ! command -v brew > /dev/null; then
        printf "[LAPTOP] Installing the Homebrew package manager."
        printf "[LAPTOP] You will probably be prompted for your password."
        ruby -e "$(curl --location --fail --silent --show-error https://raw.githubusercontent.com/Homebrew/install/master/install)"
        # This will be local to this script for now; Ansible will set the shell
        # variable properly once we're bootstrapped.
        export PATH="/usr/local/bin:$PATH"
    else
        printf "[LAPTOP] Update Homebrew\n"
        brew update
    fi
    printf "\n"    
}

exit_if_homebrew_install_failed () {
    if [[ ! -f "/usr/local/bin/brew" ]]; then
        printf "[ERROR] Homebrew cannot be found at /usr/local/bin/brew. Exiting."
        exit
    fi
}

# install_git :: None -> None
# PURPOSE
# What it says on the tin. Everything is easier if we have 
# python and git installed. 
install_git () {
    echo "[LAPTOP] Installing python via brew."
    # This will error if the package is not installed.
    # Therefore, it will install. Or, if it is installed, nothing will happen.
    # https://apple.stackexchange.com/questions/284379/with-homebrew-how-to-check-if-a-software-package-is-installed
    brew list python || brew install python
    echo "[LAPTOP] Checking for git."
    if ! command -v git > /dev/null; then
        brew list git || brew install git
    fi

}

exit_if_git_install_failed () {
    if ! command -v git > /dev/null; then
        printf "[ERROR] git should be installed at this point; it is not. Exiting."
        exit
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
    echo "[LAPTOP] Creating a temporary directory."
    echo "[LAPTOP] This is small, and will disappear on reboot."
    DIRNAME=laptop-$(date +%s)
    export TMP_DIR
    TMP_DIR=$(mktemp -d -t "$DIRNAME")
}

# update_user_pip :: None -> None
# PURRPOSE
# We always install a pip. Never trust what is local.
# This is slower, arguably, but provides consistency.
get_pip () { 
    if ! command -v pip3 > /dev/null; then
        echo "[LAPTOP] Installing a temporary pip for automation."
        pushd "${TMP_DIR}" || exit
            mkdir -p "${PIP_TARGET}"
            curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
            python get-pip.py --upgrade --no-cache-dir --no-warn-script-location
        popd || exit
    fi
}

# setup_virtual_environment :: None -> None
# PURPOSE
# Sets up a virtual environment in /tmp so that we can have a 
# known Python3 to work with. 
setup_virtual_environment () {
    echo "[LAPTOP] Setting up a venv."
    export PIP_TARGET=${TMP_DIR}/pip    
    export THIS_VENV=${TMP_DIR}/laptop-setup-venv
    pip3 install --no-cache-dir --upgrade virtualenv
    virtualenv --system-site-packages -p python3 "${THIS_VENV}"
    # Shellcheck wants to know where this is, but we can't say.
    # shellcheck source=/dev/null
    . "${THIS_VENV}/bin/activate"
}

# pip_install_ansible :: None -> None
# PURPOSE
# Installs Ansible via pip. We should be in the virtualenv at this point.
pip_install_ansible () {
    echo "[LAPTOP] Installing ansible into the venv."
    pip install --no-cache-dir --upgrade \
        wheel \
        ansible \
        github3.py
}

run_playbook () {
    ansible-pull -v -U https://github.com/${ORG_REPOS} playbook.yaml -v -i hosts
}

main () {
    install_homebrew
    exit_if_homebrew_install_failed
    install_git
    exit_if_git_install_failed
    setup_tmp_dir
    # get_pip
    setup_virtual_environment

    pip_install_ansible
    run_playbook
}

main