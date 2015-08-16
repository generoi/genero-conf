WEINRE_HOST ?= -all-
WEINRE_PORT ?= 9090
NGROK_PORT ?= 80

PERMISSIONS_USER      ?= vagrant
PERMISSIONS_GROUP     ?= vagrant
PERMISSIONS_WEBSERVER ?= www-data

BREW-exists:     ; @which brew > /dev/null

weinre:
	vagrant ssh -c 'weinre --boundHost ${WEINRE_HOST} --httpPort ${WEINRE_PORT}'

ngrok:
	vagrant ssh -c 'ngrok ${NGROK_PORT}'

drupal-permissions:
	@echo -e "${CSTART} Make sure the file permissions are correct ${CEND}"
	[ -f ${DRUPAL_DIR}/sites/default/settings.php ]
	sudo chmod --changes 755 ${DRUPAL_DIR}
	sudo chown --changes ${PERMISSIONS_USER}:${PERMISSIONS_GROUP} ${DRUPAL_DIR}
	find ${DRUPAL_DIR} \( -not -user ${PERMISSIONS_USER} -o -not -group ${PERMISSIONS_USER} \) -not -path "${DRUPAL_DIR}/sites/default/files*" -exec sudo chown -v ${PERMISSIONS_USER}:${PERMISSIONS_GROUP} "{}" \;
	find ${DRUPAL_DIR} -type f -not -path "${DRUPAL_DIR}/sites/default/files*" -not -perm 644 -exec sudo chmod -v 644 "{}" \;
	find ${DRUPAL_DIR} -type d -not -path "${DRUPAL_DIR}/sites/default/files*" -not -perm 755 -exec sudo chmod -v 755 "{}" \;
	mkdir -pv ${DRUPAL_DIR}/sites/default/files
	sudo chown --changes ${PERMISSIONS_USER}:${PERMISSIONS_WEBSERVER} ${DRUPAL_DIR}/sites/default/files
	sudo chmod 2775 --changes ${DRUPAL_DIR}/sites/default/files
	sudo chown --changes ${PERMISSIONS_USER}:${PERMISSIONS_GROUP} ${DRUPAL_DIR}/sites/default/settings.*php
	sudo chmod 644 --changes ${DRUPAL_DIR}/sites/default/settings.*php
	find ${DRUPAL_DIR}/sites/default/files/ \( -not -user ${PERMISSIONS_USER} -o -not -group ${PERMISSIONS_WEBSERVER} \) -exec sudo chown ${PERMISSIONS_USER}:${PERMISSIONS_WEBSERVER} "{}" \;
	find ${DRUPAL_DIR}/sites/default/files/ -not -name '.htaccess' -type f -not -perm 0664 -exec sudo chmod -v 0664 "{}" \;
	find ${DRUPAL_DIR}/sites/default/files/ -type d -not -perm 2775 -exec sudo chmod -v 2775 "{}" \;
	find ${DRUPAL_DIR}/sites/default/files/ -name '.htaccess' -type f -not -perm 0444 -exec sudo chmod -v 0444 "{}" \;

drupal-permissions-cap:
	PERMISSIONS_USER=deploy PERMISSIONS_GROUP=deploy PERMISSIONS_WEBSERVER=www-data make drupal-permissions

# If you want to install the dependencies.
install-dep-osx: BREW-exists
	@echo -e "${CSTART} Install dependencies ${CEND}"
	$(BREW) install gnu-sed --with-default-names
	$(BREW) install home$(BREW)/dupes/rsync
	$(BREW) install home$(BREW)/dupes/grep
	which php > /dev/null || $(BREW) install homebrew/php/php56
	which gpg > /dev/null || $(BREW) install gnupg
	which ansible > /dev/null || $(BREW) install ansible
	which vagrant > /dev/null || $(BREW) install Caskroom/cask/vagrant Caskroom/cask/virtualbox
	which composer > /dev/null || (curl -sS https://getcomposer.org/installer | $(PHP); mv composer.phar /usr/local/bin/composer)
	which drush > /dev/null || $(COMPOSER) global require drush/drush:6.*
	vagrant plugin list | grep "vagrant-gatling-rsync" > /dev/null || vagrant plugin install vagrant-gatling-rsync
	vagrant plugin list | grep "vagrant-auto_network" > /dev/null || vagrant plugin install vagrant-auto_network
	vagrant plugin list | grep "vagrant-hostsupdater" > /dev/null || vagrant plugin install vagrant-hostsupdater

info:
	@echo
	@echo -e "\n-----------------------------------------------------------------------------------"
	@echo -e "                                  README"
	@echo -e " The Virtual Machine is using rsynced folders to get the best performance, this means:"
	@echo -e " - You need to keep the following command running to rsync: vagrant rsync gatling-rsync-auto"
	@echo -e " - The sync is one way, if you change the files on the VM, they will disappear with the VM."
	@echo -e " - You should run git, capistrano and drush on the host machine (your machine), even if"
	@echo -e "   some of the commands are available on the VM."
	@echo -e " - Some of the remote connections require SSH agenting forwarding so you should run: eval \$$(ssh-agent -s); ssh-add"
	@echo -e ""
	@echo -e "                               THIS WAS DONE:"
	@echo -e " - RVM, NVM (node and ruby version managers) have been installed on both hosts."
	@echo -e " - Capistrano, Bundler, Compass, Gulp, Grunt and Bower were also installed on both hosts."
	@echo -e " - Your local git config information was been added to ~/.bash/local.sh on the VM"
	@echo -e " - RVM and NVM might have modified your local dotfiles undesirably."
	@echo -e " - An entry for each VM host was added to your /etc/hosts"
	@echo -e ""
	@echo -e "                               YOU MIGHT WANT TO:"
	@echo -e " - Push your public key to the production environment you can run: make production-ssh-copy-id"
	@echo -e " - Import a database: drush sql-sync @production @dev (NOTE @dev, as that's where mysql is installed)"
	@echo -e " - Import the files:  drush @dev ssh 'drush core-rsync @production:%files @self:%files'"
	@echo -e " - Read the documentation: https://github.com/generoi/capistrano-tasks"
	@echo -e " - Read the VM documentation: https://github.com/geerlingguy/drupal-vm"
	@echo -e "-----------------------------------------------------------------------------------"
