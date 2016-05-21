#!/bin/bash

ROOT_PATH=/var/www/drupal/web

FILES_USER=vagrant
FILES_GROUP=www-data
FILES_PATH=${ROOT_PATH}/sites/default/files

# Ensure the files directory has the correct permissions.
sudo mkdir -p $FILES_PATH
sudo chmod 775 $FILES_PATH
sudo chown -R $FILES_USER:$FILES_GROUP $FILES_PATH
sudo chmod g+s $FILES_PATH
unset FILES_PATH FILES_USER FILES_GROUP

# Generate a unique hash salt.
HASH_SALT_FILE=${ROOT_PATH}/../config/salt.txt
if [ ! -e "$HASH_SALT_FILE" ]; then
  SALT="$(openssl rand -base64 32)"
  echo "$SALT" > "$HASH_SALT_FILE"
fi
unset HASH_SALT_FILE SALT
