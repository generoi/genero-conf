DOTFILES_URL ?= https://github.com/generoi/dotfiles.git
GEMS         ?= capistrano compass bundler
NODE_VERSION ?= stable
NPM_PACKAGES ?= grunt-cli gulp bower ngrok weinre@latest

RVM_GPG_KEY  := 409B6B1796C275462A1703113804BB82D39DC0E3
RVM_URL      := https://get.rvm.io
NVM_URL      := https://raw.githubusercontent.com/creationix/nvm/v0.25.4/install.sh

# Used to scaffold an initial ~/.bash/local.sh
GIT_USER     ?= $(shell git config --global user.name)
GIT_EMAIL    ?= $(shell git config --global user.email)
GITHUB_USER  ?= $(shell git config --global github.user)

GNUPG-exists:    ; @which gpg > /dev/null
COMPOSER-exists: ; @which composer > /dev/null
DRUSH-exists:    ; @which drush > /dev/null
DRUSH-version:   ; @drush --version | grep ':\s*6' > /dev/null

# Development (vm)
##############################################################################

dev-check: VAGRANT-exists COMPOSER-exists DRUSH-exists DRUSH-version

dev-install: dev-dependencies-install dev-check
	@echo -e "${CSTART} Install git hooks ${CEND}"
	[ -f lib/git-hooks/install.sh ] && lib/git-hooks/install.sh || true
	vagrant ssh -c 'cd ${DRUPAL_ROOT}; make dev-dependencies-install'
	@echo -e "${CSTART} Install dotfiles ${CEND}"
	vagrant ssh -c '[ ! -d dotfiles ] && git clone ${DOTFILES_URL} dotfiles; cd dotfiles; ./bootstrap.sh'
	@echo -e "${CSTART} Create git config ${CEND}"
	vagrant ssh -c 'echo -e "export GIT_USER_NAME=\"${GIT_USER}\"\nexport GIT_USER_EMAIL=\"${GIT_EMAIL}\"\nexport GITHUB_USER=\"${GITHUB_USER}\"" >| /home/vagrant/.bash/local.sh'
	@echo -e "${CSTART} Install the repository npm packages ${CEND}"
	[ -f package.json ] && $(NPM) install
	@echo -e "${CSTART} Install the repository bower packages ${CEND}"
	[ -f bower.json ] && $(BOWER) install
	@echo -e "${CSTART} Install the gem bundles ${CEND}"
	[ -f Gemfile ] && $(BUNDLE) install
	@echo
	@echo -e "\n-----------------------------------------------------------------------------------"
	@echo -e "NOTE: Your local git config information (${GIT_USER} <${GIT_EMAIL}>) was added to ~/.bash/local.sh"
	@echo -e "NOTE: To import a database you can use: drush sql-sync @production @dev"
	@echo -e "Note: To import the files:  drush @dev ssh 'drush core-rsync @production:%files @self:%files'"
	@echo -e "-----------------------------------------------------------------------------------"

# This task is issued both on your local computer and on the virtual machine.
dev-dependencies-install: GNUPG-exists
	@echo -e "${CSTART} Install RVM and gems: ${GEMS} ${CEND}"
	which rvm > /dev/null || (gpg --keyserver hkp://keys.gnupg.net --recv-keys ${RVM_GPG_KEY}; curl -sSL ${RVM_URL} | bash -s stable --gems="${GEMS}")
	@echo -e "${CSTART} Install NVM ${CEND}"
	source ~/.nvm/nvm.sh; command -v nvm > /dev/null 2>&1 || (wget -qO- ${NVM_URL} | bash)
	@echo -e "${CSTART} Install Node and NPM: ${NODE_VERSION} ${CEND}"
	source ~/.nvm/nvm.sh; nvm install ${NODE_VERSION}; nvm alias default ${NODE_VERSION}
	@echo -e "${CSTART} Install NPM packages: ${NPM_PACKAGES} ${CEND}"
	source ~/.nvm/nvm.sh; $(NPM) install -g ${NPM_PACKAGES}
