SHELL           := /usr/bin/env bash
export PATH     := /usr/local/bin:$(PATH)

RSYNC_PULL_OPTS  ?= --no-perms --no-owner --no-group --verbose --recursive --exclude Makefile --exclude .vagrant/ --exclude Vagrantfile --exclude .git --exclude tmp --exclude sites/default/files/ --exclude .drush-lock-update --exclude vm
PULL_CUSTOM      ?= contrib

REPO_ROOT        ?= /var/www/drupal
DRUPAL_ROOT      ?= ${REPO_ROOT}

# Used in this Makefile.
RSYNC-version:   ; @rsync --version | grep "3.1" > /dev/null

# Used in Makefile.example
DRUSH-exists:    ; @which drush > /dev/null
DRUSH-version:   ; @drush --version | grep ':\s*6' > /dev/null
SSHAGENT-exists: ; @ssh-add -l >/dev/null
LOCAL-env:       ; @[ "$$(hostname)" != "minasanor" ] && whoami | grep -qv "deploy\|vagrant"

rsync-check: RSYNC-version

rsync-pull: rsync-check
	@echo -e "Rsync the updated files from the guest environment to the host"
	vagrant ssh-config --host default > vagrant-ssh-config
	@echo -e "Running dry run to display file changes"
	rsync --dry-run ${RSYNC_PULL_OPTS} -e 'ssh -F vagrant-ssh-config' default:${DRUPAL_ROOT}/ .
	read -p "Are you sure you want to run this command? [y/N]" -n 1 -r; \
		echo; \
		if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
			rsync ${RSYNC_PULL_OPTS} -e 'ssh -F vagrant-ssh-config' default:${DRUPAL_ROOT}/ .; \
		fi
	rm vagrant-ssh-config

rsync-pull-custom: rsync-check
	vagrant ssh-config --host default > vagrant-ssh-config
	@echo -e "Running dry run to display file changes"
	rsync --dry-run --verbose --recursive -e 'ssh -F vagrant-ssh-config' default:${DRUPAL_ROOT}/sites/all/modules/${PULL_CUSTOM}/ sites/all/modules/${PULL_CUSTOM}
	read -p "Are you sure you want to run this command? [y/N]" -n 1 -r; \
		echo; \
		if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
			rsync --recursive --verbose -e 'ssh -F vagrant-ssh-config' default:${DRUPAL_ROOT}/sites/all/modules/${PULL_CUSTOM}/ sites/all/modules/${PULL_CUSTOM}; \
		fi
	rm vagrant-ssh-config

rsync-pull-contrib:
	PULL_CUSTOM=contrib make rsync-pull-custom

rsync-pull-features:
	PULL_CUSTOM=features make rsync-pull-custom
