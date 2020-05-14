#!/bin/sh

# My goal is to do as little in bash/shell as possible.

# First, do the shell setup dance.
source environment/setup_shell.sh

# To bootstrap, we want to get to Ansible as quickly as possible.
# This suggests installing Python 3 (via Homebrew) and then
# pip installing Ansible. From there, use Ansible for automation.
source systems/brew.sh
source languages/python.sh

# At this point, Ansible should be installable.
# 'wheel' cuts down on warnings in the subsequent installs.
pip install --upgrade pip
pip install wheel ansible

# Once we have ansible, everything else happens there.
ansible-playbook -i hosts playbook.yaml