
This document briefly explores the what, why, and how of a new laptop configuration script. It also lays out the assumptions that are made, and guiding principles of design/development.

- [What](#what)
- [Why](#why)
- [How](#how)
- [Assumptions](#assumptions)
- [Principles](#principles)
- [Vision](#vision)
- [Governance](#governance)

## What

This script creates a common point for configuration and maintenance of 18F laptops.

## Why

For several reasons. First, the existing script did not work. Second, it was referred to as "fragile" (this always seems like a dangerous starting point). Finally, it has a number of tickets that could be quickly addressed using a different set of tools, but might be difficult to address robustly in the `bash` regime. Lastly, it is my hope/belief that CI/CD will be easier against `ansible` playbooks vs. freeform `bash` scripts.

## How

The script attempts to bootstrap to [Ansible](https://www.ansible.com/) as quickly as possible. 

1. Begin by installing/updating `homebrew`. 
2. `homebrew` is used to install `python` and `git`.
3.  The `bash` script then creates a `pip` environment (effectively) in `/tmp`.
4.  This temporary/local `pip` is used to bootstrap a temporary `python3` virtual environment.
5.  `ansible` is installed into the venv.
6.  This repository is checked out using `ansible-pull`.
7.  The playbook `playbook.yaml` is executed using `ansible`.

Once `ansible` is installed, idempotent management of packages can commence. With every run, this repository is checked out, meaning the playbook being executed is always the most up-to-date.

## Assumptions

The bootstrap script assumes the only thing on the machine is `bash`. 

At no point is `pip`, `homebrew`, `git`, `python`, or `ansible` assumed to be present. This means that with every run, we are guaranteed to have these tools available.

## Principles

- Do as little work in `bash` as possible.
- Achieve idempotency using tools designed for purpose.

## Vision

Laptop setup should *just work*. The script should also serve to *maintain* the tooling installed. Users should be able to stop using the script with no loss of access, generality, or functionality if they choose.

## Governance

Mercy. If we get to needing governance, we'll write it.




