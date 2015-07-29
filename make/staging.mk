SHELL := /bin/bash

# STAGING_DB_NAME ?=
# STAGING_DB_USER ?=
# STAGING_DB_PASS ?=

# Staging environment
##############################################################################

staging-check: LOCAL-env SSHAGENT-exists

staging-install: staging-check staging-ssh-copy-id
	@echo -e "${CSTART} Scaffold and setup the staging environmnet ${CEND}"
	cap staging setup
	@echo -e "${CSTART} Make an initial deployment (will partly fail) ${CEND}"
	-cap staging deploy
	@echo
	@echo -e "\n-----------------------------------------------------------------------------------"
	@echo -e "NOTE: To import a database you can use: drush sql-sync @production @staging"
	@echo -e "NOTE: To import the files you can use:  drush @staging ssh 'drush core-rsync @production:%files @self:%files'"
	@echo -e "-----------------------------------------------------------------------------------"

staging-ssh-copy-id: staging-check
	@echo -e "${CSTART} Copy your public key to the deploy user on the staging environment: ${STAGING_HOST} ${CEND}"
	@access=$$(ssh -o PasswordAuthentication=no -o ConnectTimeout=15 deploy@${STAGING_HOST} echo ok 2>&1); \
	if [[ ! "$$access" =~ "ok" ]]; then \
		u=$$(read -p "User login for ${STAGING_HOST} (the password prompted is for sudo on ${STAGING_HOST}): " usr; echo $$usr); \
		k="$$(cat ~/.ssh/id_rsa.pub)"; \
		ssh -t $$u@${STAGING_HOST} " \
			sudo su - deploy -c \" \
				k=\\\"$$k\\\"; \
				if ! grep -qe \\\"\\\$$k\\\" /home/deploy/.ssh/authorized_keys; then \
					echo \\\"\\\$$k\\\" >> /home/deploy/.ssh/authorized_keys; \
					echo \\\"Your key was added\\\"; \
				else \
					echo \\\"Your key already exists\\\"; \
				fi \
			\" \
		"; \
	else \
		echo "Your key is already present."; \
	fi

staging-mysql-settings: staging-check
	@echo -e "${CSTART} Scaffold the remote database settings for: ${STAGING_HOST} ${CEND}"
	@grep -qe "\$$databases\['staging'\]\['default'\]" sites/default/settings.local.php && \
	echo "settings already exist" \
	|| (echo -e "\n\
	\$$databases['staging']['default'] = array(\n\
	'database' => '${STAGING_DB_NAME}',\n\
	'username' => '${STAGING_DB_USER}',\n\
	'password' => '${STAGING_DB_PASS}',\n\
	'host' => '127.0.0.1',\n\
	'port' => '3307',\n\
	'driver' => 'mysql',\n\
	);" >> sites/default/settings.local.php;\
	vagrant rsync;\
	echo "settings added.")

staging-mysql-tunnel: staging-mysql-settings
	@echo -e "${CSTART} Open a tunnel on VM for port 3306 -> 3307: ${STAGING_HOST} ${CEND}"
	vagrant ssh -c "\
		cd ${DRUPAL_ROOT};\
		echo \"\\\$$databases['default'] = \\\$$databases['staging'];\" >> sites/default/settings.local.php;\
		function fin { sed -i '$$ d' sites/default/settings.local.php; echo \"cleanup\"; };\
		trap fin EXIT;\
		ssh -x -T -c arcfour -m hmac-md5-96 -o Compression=no -L 3307:127.0.0.1:3306 deploy@${STAGING_HOST} -N\
	"
