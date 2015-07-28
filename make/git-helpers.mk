SHELL := /bin/bash

DRUPAL_CORE_FILES := CHANGELOG.txt COPYRIGHT.txt INSTALL*.txt LICENSE.txt MAINTAINERS.txt README.txt UPGRADE.txt authorize.php cron.php includes/ index.php install.php misc/ modules/ profiles/ scripts/ themes/ update.php web.config xmlrpc.php
GIT_SHRINK_BRANCH ?= master

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

git-largest-blobs:
	@IFS=$$'\n';\
	objects=$$(git verify-pack -v .git/objects/pack/pack-*.idx | grep -v chain | sort -k3nr | head); \
	output=""; \
	for y in $$objects; do \
		size="$$(($$(echo $$y | cut -f 5 -d ' ')/1024/1024))MB"; \
		sha=$$(echo $$y | cut -f 1 -d ' '); \
		other="$$(git rev-list --all --objects | grep $$sha)"; \
		output="$${output}\n$${size},$${other}"; \
	done; \
	echo -e $$output | column -t -s ',';
	@echo "To prune the history of an unused file you can use:"
	@echo "git filter-branch --prune-empty --force --index-filter 'git rm --cached --ignore-unmatch FILEPATH FILEPATH_TWO'"
	@echo ""

git-shrink-repo:
	git update-ref -d refs/original/refs/heads/${GIT_SHRINK_BRANCH}
	git reflog expire --expire=now --all
	git gc --prune=now
