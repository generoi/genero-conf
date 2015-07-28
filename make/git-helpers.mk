SHELL := /bin/bash

DRUPAL_CORE_FILES := CHANGELOG.txt COPYRIGHT.txt INSTALL*.txt LICENSE.txt MAINTAINERS.txt README.txt UPGRADE.txt authorize.php cron.php includes/ index.php install.php misc/ modules/ profiles/ scripts/ themes/ update.php web.config xmlrpc.php

drupal-commit-modules:
	cd sites/all/modules/contrib; \
	for m in $$(git status -s . | cut -c 4- | cut -d'/' -f1 | sort -u); do \
		git status -s $$m; \
		read -p "Are you sure you want to add it? [y/N]" -n 1 -r; \
		echo; \
		if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
			git add -A "$$m"; \
			git commit -n -m "$${m}: updated module"; \
		fi; \
	done

drupal-commit-core:
	git add -A ${DRUPAL_CORE_FILES}
		git status; \
		read -p "Are you sure you want to add it? [y/N]" -n 1 -r; echo; \
		if [[ $$REPLY =~ ^[Yy]$$ ]]; then git commit -m "drupal: updated core"; fi; \
