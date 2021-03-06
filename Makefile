# This is the makefile for setting up or updating a projects configuration files.
# ------------------------

# Directory of this makefile
MAKEFILE_PATH := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
# The execution path
CURRENT_PATH  := $(shell pwd)
# The path from CWD to this repo
DIFF_PATH     := $(subst $(CURRENT_PATH)/,,$(MAKEFILE_PATH))

PROJECT ?= <project>
HOST    ?= <host>
THEME   ?= <theme>

SED_REPLACE := -e 's@<project>@$(PROJECT)@g' -e 's@<theme>@$(THEME)@g' -e 's@<host>@$(HOST)@g'

check: index.php .git

# PROJECT=guestcomfort THEME=public HOST=guestcomfort.com make -f lib/genero-conf/Makefile install
install: submodules symlink copy
	@echo "You still need to set a unique Vagrant IP"

submodules: check
	-git submodule add git@github.com:generoi/capistrano-tasks.git lib/capistrano
	-git submodule add git@github.com:generoi/git-hooks.git lib/git-hooks
	-git submodule add https://github.com/geerlingguy/drupal-vm.git lib/drupal-vm

symlink: check
	ln -sf $(DIFF_PATH)/jshintrc .jshintrc
	ln -sf $(DIFF_PATH)/Capfile Capfile
	ln -sf $(DIFF_PATH)/Vagrantfile Vagrantfile
	ln -sf ../$(DIFF_PATH)/config/drushrc.php config/drushrc.php
	ln -sf ../../../config/aliases.drushrc.php sites/all/drush/aliases.drushrc.php
	ln -sf ../../../config/drushrc.php sites/all/drush/drushrc.php
	ln -sf ../../../$(DIFF_PATH)/drush/policy.drush.inc sites/all/drush/policy.drush.inc
	ln -sf ../../../$(DIFF_PATH)/drush/sync_enable.drush.inc sites/all/drush/sync_enable.drush.inc
	ln -sf ../../../../.jshintrc sites/all/themes/$(THEME)/.jshintrc

copy: check
	sed $(SED_REPLACE) $(DIFF_PATH)/gitignore >| .gitignore
	sed $(SED_REPLACE) $(DIFF_PATH)/Gemfile >| Gemfile
	sed $(SED_REPLACE) $(DIFF_PATH)/Gemfile.lock >| Gemfile.lock
	sed $(SED_REPLACE) $(DIFF_PATH)/example.bower.json >| bower.json
	sed $(SED_REPLACE) $(DIFF_PATH)/example.package.json >| package.json
	sed $(SED_REPLACE) $(DIFF_PATH)/Gulpfile.js >| Gulpfile.js
	sed $(SED_REPLACE) $(DIFF_PATH)/Makefile.example >| Makefile
	sed $(SED_REPLACE) $(DIFF_PATH)/bowerrc >| .bowerrc
	sed $(SED_REPLACE) $(DIFF_PATH)/config/aliases.drushrc.php >| config/aliases.drushrc.php
	sed $(SED_REPLACE) $(DIFF_PATH)/config/drupal-vm.config.yml >| config/drupal-vm.config.yml
	sed $(SED_REPLACE) $(DIFF_PATH)/config/deploy.rb >| config/deploy.rb
	sed $(SED_REPLACE) $(DIFF_PATH)/config/deploy/staging.rb >| config/deploy/staging.rb
	sed $(SED_REPLACE) $(DIFF_PATH)/config/deploy/production.rb >| config/deploy/production.rb
