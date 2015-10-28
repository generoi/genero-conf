# STAGING_HOST         ?=
# PRODUCTION_HOST      ?=

VM_URL               := https://github.com/geerlingguy/drupal-vm/archive/master.tar.gz

FINGERPRINTS         ?= github.com ${STAGING_HOST} ${PRODUCTION_HOST}

VAGRANT_IP   ?= $(shell awk '/vagrant_ip/ { print $$2; }' ${DRUPALVM_CONFIG})
VAGRANT_HOST ?= $(shell awk '/vagrant_hostname/ { print $$2; }' ${DRUPALVM_CONFIG})

SED-version:     ; @sed --version | grep "GNU sed" > /dev/null
ANSIBLE-exists:  ; @which ansible > /dev/null
VAGRANT-exists:  ; @which vagrant > /dev/null

# Virtual Machine
##############################################################################

vm-check: ANSIBLE-exists VAGRANT-exists SED-version LOCAL-env

vm-install: vm-check
	@echo -e "${CSTART} Restart services if vagrant is already running ${CEND}"
	vagrant status | grep -qe 'running' && (vagrant ssh -c 'sudo service mysql restart; sudo service apache2 restart') || true
	@echo -e "${CSTART} Start and provision the vagrant environment ${CEND}"
	vagrant up --provision && vagrant provision
	@echo -e "${CSTART} Configure settings.local.php ${CEND}"
	vagrant ssh -c '\
		chmod 775 ${DRUPAL_ROOT}/sites/default;\
		cd ${DRUPAL_ROOT}/sites/default;\
		dbinfo="$$(grep -A 14 "^\$$databases =" settings.php)";\
	  [ "$$dbinfo" != "" ] && (\
			echo -e "<?php\n" >| settings.local.php && \
			echo -e "$$dbinfo" >> settings.local.php && \
			sed -i "s/localhost/${VAGRANT_HOST}/" settings.local.php \
		) || true\
	'
	@echo -e "${CSTART} Fetch settings.local.php to localhost ${CEND}"
	vagrant ssh -c 'cat ${DRUPAL_ROOT}/sites/default/settings.local.php' >| ${DRUPAL_SITES_DIR}/default/settings.local.php
	@echo -e "${CSTART} Change swappiness ${CEND}"
	vagrant ssh -c 'sudo bash -c "sysctl vm.swappiness=0; grep -qe \"vm.swappiness\" /etc/sysctl.conf || echo \"vm.swappiness = 0\" >> /etc/sysctl.conf"'
	@echo -e "${CSTART} Make sure ~/.ssh/known_hosts exist ${CEND}"
	vagrant ssh -c 'mkdir -p ~/.ssh; chmod 0700 ~/.ssh; touch ~/.ssh/known_hosts; chmod 0600 ~/.ssh/known_hosts;'
	@echo -e "${CSTART} Add the fingerprint for some common servers: ${FINGERPRINTS} ${CEND}"
	vagrant ssh -c 'for s in ${FINGERPRINTS}; do key="$$(ssh-keyscan $$s)"; grep -qe "$$key" ~/.ssh/known_hosts || echo "$$key" >> ~/.ssh/known_hosts; done'
	make vm-hosts
	@echo
	@echo -e "\n-----------------------------------------------------------------------------------"
	@echo -e "NOTE: To push your public key to the production environment you can: make production-ssh-copy-id"
	@echo -e "-----------------------------------------------------------------------------------"

vm-hosts:
	@echo -e "${CSTART} Add /etc/host entries ${CEND}"
	@for host in $$(awk '/servername:/ { gsub("[\",]", ""); print $$4 }' ${DRUPALVM_CONFIG} | grep -v 'drupal_domain'); do \
		echo -e "${VAGRANT_IP}\t$$host"; grep -qe "${VAGRANT_IP}\s*$$host" /etc/hosts || sudo sh -c "echo \"${VAGRANT_IP}\t$$host\" >> /etc/hosts"; \
	done
	@echo -e "${VAGRANT_IP}\t${VAGRANT_HOST}"; grep -qe "${VAGRANT_IP}\s*${VAGRANT_HOST}" /etc/hosts || sudo sh -c "echo \"${VAGRANT_IP}\t${VAGRANT_HOST}\" >> /etc/hosts"
	@echo -e "${VAGRANT_IP}\twww.${VAGRANT_HOST}"; grep -qe "${VAGRANT_IP}\s*www.${VAGRANT_HOST}" /etc/hosts || sudo sh -c "echo \"${VAGRANT_IP}\twww.${VAGRANT_HOST}\" >> /etc/hosts"

# Fetch and configure the latest drupal-vm
vm-update: vm-check
	@echo -e "${CSTART} Fetch all submodules ${CEND}"
	-git submodule update --init
	@mkdir -p ${DRUPALVM_DIR}
	@echo -e "${CSTART} Fetch the latest drupal-vm and extract it into ${DRUPALVM_DIR} ${CEND}"
	wget -qO- ${VM_URL} | tar xvz --strip 1 -C ${DRUPALVM_DIR} --exclude='.gitignore'
	@echo -e "${CSTART} Symlink the configuration file to: ${DRUPALVM_DIR}/config.yml ${CEND}"
	ln -sf ${DRUPALVM_DIR_DIFF}${DRUPALVM_CONFIG} ${DRUPALVM_DIR}/config.yml
	@echo -e "${CSTART} Symlink the modified Vagrantfile to: ${DRUPALVM_DIR}/Vagrantfile ${CEND}"
	ln -sf ${DRUPALVM_DIR_DIFF}${DRUPALVM_VAGRANTFILE} ${DRUPALVM_DIR}/Vagrantfile
	@echo -e "${CSTART} Fetch required ansible roles ${CEND}"
	cd ${DRUPALVM_DIR}; sudo ansible-galaxy install -r provisioning/requirements.yml --force

vm-ssh-copy-id: vm-check
	@echo -e "${CSTART} Authorize the ${VAGRANT_HOST} RSA fingerprint ${CEND}"
	ssh-keygen -R ${VAGRANT_HOST}

vm-destroy:
	vagrant destroy -f

vm-rebuild: vm-check clean-settings vm-destroy
	@echo -e "${CSTART} Update vagrant box ${CEND}"
	make vm-update
	vagrant box update
	make vm-install vm-ssh-copy-id info

# Clean
##############################################################################

clean: clean-settings clean-vm clean-keys clean-knownhosts clean-hosts

clean-vm:
	@echo -e "${CSTART} Destroy the vagrant machine completely ${CEND}"
	vagrant destroy
	[ -d ".vagrant" ] && rm -r .vagrant
	[ -d "${DRUPALVM_DIR}/.vagrant" ] && rm -r ${DRUPALVM_DIR}/.vagrant || true
	[ -d "~/VirtualBox\ VMs/${VAGRANT_HOST}" ] && rm -r ~/VirtualBox\ VMs/${VAGRANT_HOST} || true

clean-db:
	-vagrant ssh -c "mysql -u root -p'root' -e 'DROP DATABASE IF EXISTS drupal; DROP USER drupal;'"

clean-settings:
	@echo -e "${CSTART} Remove the settings.local.php file ${CEND}"
	[ -e "sites/default/settings.local.php" ] && rm sites/default/settings.local.php || true
	vagrant ssh -c 'cd ${DRUPAL_ROOT}; [ -e "sites/default/settings.local.php" ] && rm sites/default/settings.local.php || true'

clean-knownhosts:
	@echo -e "${CSTART} Remove the known hosts from your local computer ${CEND}"
	for host in ${FINGERPRINTS} ${VAGRANT_HOST}; do \
		sed -i "/^$$host/d" ~/.ssh/known_hosts;\
	done

clean-hosts:
	@echo -e "${CSTART} Remove the hosts entries from your local computer ${CEND}"
	sudo sed -i '/^${VAGRANT_IP}/d' /etc/hosts

clean-keys:
	@echo -e "${CSTART} Remove your public key from: ${STAGING_HOST} and ${PRODUCTION_HOST} ${CEND}"
	-u=$$(read -p "User login for ${STAGING_HOST}: " usr; echo $$usr);\
		key="$$(cat ~/.ssh/id_rsa.pub)";\
		cmd="grep -v \"$$key\" ~/.ssh/authorized_keys >| /tmp/authorized_keys; cp /tmp/authorized_keys ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys";\
		[ "$$key" != "" ] && (\
			ssh -o PasswordAuthentication=no -o ConnectTimeout=15 -o "ProxyCommand ssh $$u@${STAGING_HOST} nc %h %p" deploy@${PRODUCTION_HOST} "$$cmd";\
			ssh -o PasswordAuthentication=no -o ConnectTimeout=15 deploy@${STAGING_HOST} "$$cmd";\
		)
