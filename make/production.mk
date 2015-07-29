SHELL := /bin/bash

# PRODUCTION_HOST ?=
# STAGING_HOST    ?=

# Production environment
##############################################################################

production-check: LOCAL-env SSHAGENT-exists

production-install: production-check
	@echo -e "\n@TODO"

production-ssh-copy-id: production-check
	@echo -e "${CSTART} Copy your public key to the deploy user on the production environment: ${PRODUCTION_HOST} ${CEND}"
	@echo -e "${CSTART} This assumes you have access to the host from the staging environment. ${CEND}"
	@u=$$(read -p "Your personal user login for ${STAGING_HOST}: " usr; echo $$usr); \
	access="$$(ssh -o PasswordAuthentication=no -o ConnectTimeout=15 -o "ProxyCommand ssh $$u@${STAGING_HOST} nc %h %p" deploy@${PRODUCTION_HOST} echo ok 2>&1)"; \
	if [[ ! "$$access" =~ "ok" ]]; then \
		k="$$(cat ~/.ssh/id_rsa.pub)"; \
		ssh -t $$u@${STAGING_HOST} " \
			ssh -t deploy@${PRODUCTION_HOST} \" \
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
	fi; \
	echo -e "${CSTART} Make sure we get the RSA fingerprint on the VM (type yes) ${CEND}"; \
	vagrant ssh -c "ssh-add -l && ssh -o \"ProxyCommand ssh $$u@${STAGING_HOST} nc %h %p\" deploy@${PRODUCTION_HOST} echo ok 2>&1"
