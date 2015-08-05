RSYNC_PULL_OPTS := --no-perms --no-owner --no-group --verbose --recursive --exclude Makefile --exclude .vagrant/ --exclude Vagrantfile --exclude .git --exclude tmp --exclude sites/default/files/ --exclude .drush-lock-update
PULL_CUSTOM     ?= contrib

RSYNC-version:   ; @rsync --version | grep "3.1" > /dev/null

rsync-check: LOCAL-env RSYNC-version

rsync: rsync-check
	@echo -e "${CSTART} Rsync the updated files from the host environment to the VM ${CEND}"
	vagrant rsync
	vagrant ssh -c 'cd ${DRUPAL_ROOT}; make drupal-permissions'

rsync-pull: rsync-check
	@echo -e "${CSTART} Rsync the updated files from the guest environment to the host ${CEND}"
	vagrant ssh-config --host default > vagrant-ssh-config
	@echo -e "${CSTART} Running dry run to display file changes ${CEND}"
	rsync --dry-run ${RSYNC_PULL_OPTS} -e 'ssh -F vagrant-ssh-config' default:${DRUPAL_ROOT}/ .
	read -p "Are you sure you want to run this command? [y/N]" -n 1 -r; \
		echo; \
		if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
			rsync ${RSYNC_PULL_OPTS} -e 'ssh -F vagrant-ssh-config' default:${DRUPAL_ROOT}/ .; \
		fi
	rm vagrant-ssh-config

rsync-pull-custom: rsync-check
	vagrant ssh-config --host default > vagrant-ssh-config
	@echo -e "${CSTART} Running dry run to display file changes ${CEND}"
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
