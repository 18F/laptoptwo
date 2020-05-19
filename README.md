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
