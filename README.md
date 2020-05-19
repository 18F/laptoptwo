# LaptopTwo

LaptopTwo is a script to set up an OS X computer for web development, and to keep
it up to date.

It can be run multiple times on the same machine safely.
It installs, upgrades, or skips packages
based on what is already installed on the machine.

## Requirements


This script has been tested on:

* [macOS Mojave 10.14](https://www.apple.com/osx/)

## Installing and Running

Begin by opening the Terminal application on your Mac. The easiest way to open
an application in OS X is to search for it via [Spotlight]. The default
keyboard shortcut for invoking Spotlight is &#8984;-Space (or, hold the command key and press space). Once Spotlight
is up, just start typing the first few letters of the app you are looking for,
and once it appears, press `return` to launch it.

In your Terminal window, copy and paste the command below, then press `return`.

```sh
bash <(curl -s https://raw.githubusercontent.com/jadudm/laptoptwo/master/bootstrap.sh)
```
The [script](https://github.com/jadudm/laptoptwo/blob/master/bootstrap.sh) itself is
available in this repo for you to review if you want to see what it does
and how it works.

Note that the script will ask you to enter your OS X password at various
points. This is the same password that you use to log in to your Mac.
If you don't already have it installed, GitHub for Mac will launch
automatically at the end of the script so you can set up everything you'll
need to push code to GitHub.

**Once the script is done, make sure to quit and relaunch Terminal.**

## What It Does

The script assumes you have nothing on your Mac laptop to support your work in developing software. It does the following things:

1. Installs [homebrew](https://brew.sh/). 
   1. If homebrew exists, it updates it.
2. Uses `brew` to install `git` and `python`.
   1. This gives us a known python to work against.
3. Creates a virtual environment.
4. Installs Ansible into the virtual environment.
5. Checks out this repository via `ansible-pull`.
6. Runs the Ansible playbook.

The playbook is organized into roles. Each role carries out a different set of tasks:

* `install` installs software for development.
* `gpg` installs GPG and configures `pinetry` (which is a GUI for password entry). In combination, these two tools let you [sign your commits](https://help.github.com/en/github/authenticating-to-github/signing-commits).
* `seekret` installs git-seekret for scanning your commits for tokens, passwords, and things you shouldn't have in your repository. This is installed as a binary from an [18F GitHub repository](https://github.com/18F/git-seekret).

## Contributing

If you want to extend the work of the script, it is almost certainly the case that it should be through 1) changes to existing roles, or 2) the addition of a new role. 

For example, if there is additional software that we should consider installing by default, then it should be a modification of the `install` role. If we have a completely new setup task (e.g. automating the ordering takeaway via a fancy API before calling the installation "done"), it should be added as a new role.

