#!/bin/bash

FILES_USER=vagrant
FILES_GROUP=www-data
ROOT_PATH=/var/www/drupal/web
FILES_PATH=${ROOT_PATH}/sites/default/files

# Ensure the files directory has the correct permissions.
sudo mkdir -p $FILES_PATH
sudo chmod 775 $FILES_PATH
sudo chown -R $FILES_USER:$FILES_GROUP $FILES_PATH
sudo chmod g+s $FILES_PATH
