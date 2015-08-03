SHELL       := /usr/bin/env bash
export PATH := /usr/local/bin:$(PATH)

# Extra sanity checks.
DEPLOY-user:     ; @whoami | grep "deploy" > /dev/null
SSHAGENT-exists: ; @ssh-add -l >/dev/null
LOCAL-env:       ; @[ "$$(hostname)" != "minasanor"  ] && whoami | grep -qv "deploy\|vagrant"

BUNDLE   ?= /usr/bin/env bundle
BREW     ?= /usr/bin/env brew
NPM      ?= /usr/bin/env npm
BOWER    ?= /usr/bin/env bower
COMPOSER ?= /usr/bin/env composer
PHP      ?= /usr/bin/env php

# Colorize output
CSTART := $(shell echo -e "\033[0;31m>")
CEND := $(shell echo -e "...\033[0m")

DRUPAL_ROOT  ?= /var/www/drupal
