SHELL := /bin/bash

# Extra sanity checks.
DEPLOY-user:     ; @whoami | grep "deploy" > /dev/null
SSHAGENT-exists: ; @ssh-add -l >/dev/null
LOCAL-env:       ; @[ "$$(hostname)" != "minasanor"  ] && whoami | grep -qv "deploy\|vagrant"

# Colorize output
CSTART := $(shell echo -e "\033[0;31m>")
CEND := $(shell echo -e "...\033[0m")

DRUPAL_ROOT  ?= /var/www/drupal
