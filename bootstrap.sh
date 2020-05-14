#!/bin/sh

ORG=jadudm
REPOS=laptoptwo
ORG_REPOS=${ORG}/${REPOS}

# My goal is to do as little in bash/shell as possible.
pushd /tmp
    curl --remote-name https://raw.githubusercontent.com/${ORG_REPOS}/master/support/setup_shell.sh
    curl --remote-name https://raw.githubusercontent.com/${ORG_REPOS}/master/support/brew.sh
    curl --remote-name https://raw.githubusercontent.com/${ORG_REPOS}/master/support/python.sh
    # First, do the shell setup dance.
    source setup_shell.sh
    # To bootstrap, we want to get to Ansible as quickly as possible.
    # This suggests installing Python 3 (via Homebrew) and then
    # pip installing Ansible. From there, use Ansible for automation.
    source brew.sh
    source python.sh

    # I'm going to need 'git' to bootstrap.
    if command -v git >/dev/null 2>&1; then
        brew install git
    fi
popd

# At this point, Ansible should be installable.
# 'wheel' cuts down on warnings in the subsequent installs.
pip install --upgrade pip
pip install wheel ansible

pushd /tmp
    # Get the repository. This lets us update the Ansible scripts
    # arbitrarily, and know that, on re-run, we always get the most
    # recent version of the configuration/automation.
    if [[ -d ${REPOS} ]]; then
        pushd ${REPOS}
            git pull
        popd
    else
        git clone https://github.com/${ORG_REPOS}
    fi

    pushd ${REPOS}
        # At this point, we have the repository, and can 
        # run the most up-to-date playbook.
        ansible-playbook -i hosts playbook.yaml
    popd
popd