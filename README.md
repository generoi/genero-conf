Development environment
-----------------------

> Located on your own machine but running inside a virtual machine. All the
> development is done on the host machine, while mysql, apache etc are on the
> guest machine.

#### Dependencies:

**These you must install by yourself.**

###### OSX

```
# Install some UNIX tools
brew tap homebrew/dupes
brew install coreutils
brew install gnupg
brew install gnu-sed --with-default-names
brew install rsync
brew install grep --with-default-names
brew install ssh-copy-id

# Install additional dependencies
brew install git
brew install homebrew/php/php56
brew install ansible
brew install Caskroom/cask/vagrant

# Configure git
git config --global github.user "<username>"
git config --global user.name "<Your Name>"
git config --global user.email "<youremail@domain.com>"

# Install Composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Install Drush
composer global require drush/drush:6.*

# Install some vagrant plugins
vagrant plugin install vagrant-gatling-rsync
vagrant plugin install vagrant-hostsupdater
```

###### LInux

```sh
# Git
sudo apt-get install git
git config --global github.user "<username>"
git config --global user.name "<Your Name>"
git config --global user.email "<youremail@domain.com>"

# Create a key that you can add to your GitHub account
ssh-keygen
cat ~/.ssh/id_rsa.pub

# PHP & Curl
sudo apt-get install php5 php5-cli curl libcurl3 libcurl3-dev php5-curl

# Ansible
sudo apt-get install software-properties-common
sudo apt-add-repository ppa:ansible/ansible
sudo apt-get update
sudo apt-get install ansible

# Vagrant & Virtualbox
# For Vagrant 1.7.4 or later and Virtualbox 5 or later, download the installation files
# from the linkes below and install with your systems package manager
# https://www.virtualbox.org/wiki/Linux_Downloads
# http://www.vagrantup.com/downloads.html
vagrant plugin install vagrant-gatling-rsync
vagrant plugin install vagrant-auto_network

# Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
# Add the following line to ~/.bashrc
export PATH="$HOME/.composer/vendor/bin:$PATH"
source ~/.bashrc

# Drush (using Composer)
composer global require drush/drush:6.*
```

#### Setup

Fetch the code from github, the files and the latest database from production.

_Note that all of these tasks should run on your local machine._

```sh
git clone --recursive git@github.com:generoi/<PROJECT>.git
cd <PROJECT>

# Setup git hooks
./lib/git-hooks/install.sh

# Install dependencies
bundle
npm install
bower install

# Add your key to the authorization agent for connecting to production.
eval $(ssh-agent -s)
ssh-add

# Authenticate the production servers key fingerprint locally.
# If you run this before `vagrant up` the fingerprint will be copied to the VM as well.
drush @production status

# Setup the local settings file (pre-configured for the VM)
cp sites/default/example.settings.local.php sites/default/settings.local.php

# Setup the VM folder
make vm

# Fetch ansible roles used by Drupal VM
sudo ansible-galaxy install -r lib/drupal-vm/provisioning/requirements.yml --force

# Build the VM
vagrant up --provision

# Import the database from the production environment.
# NOTE you cannot use @self here, as MySQL isn't installed on your local
# computer. Instead you need to reference the VM with @dev.
drush sql-sync @production @dev

# Import the files from the production environment.
# NOTE that you cannot use @dev here, as rsync requires one of the targets be
# local. Instead we first SSH into the @dev box and then issue it locally.
drush @dev ssh 'drush core-rsync @production:%files @self:%files'

# Begin watching with rsync (one-way and only if this command is running)
vagrant gatling-rsync-auto
```

#### Start coding

> All development should be done on your local machine.

1. Make sure your VM is running: `vagrant up`
2. Make sure files are being synced by running `vagrant gatling-rsync-auto`
3. Open the git project in your favorit editor (locally,
   the files will be synced to the VM automatically).
4. Install a [livereload extension](http://livereload.com/extensions/).
5. Run `grunt watch` or `gulp watch` to automatically compile assets and
   refresh your browser when a file changes.
   This task also takes care of rsyncing the changed files to the guest machine
   (much faster than vagrants rsync).
6. Start coding by opening http://`<PROJECT>.dev` in your browser.

_All git, cap, and drush commands should ideally run on your own machine. Most
tasks do work on the virtual machine, but not all of them. Note that drush
commands should use @dev as a target (eg. drush @dev status)._

##### XDebug with Sublime Text 3

1. Make sure you have [Package Control](https://packagecontrol.io/installation) installed.
2. Install `xdebug client` by going to `tools > command palette > install package > xdebug client`.
3. Configure xdebug in sublime for the project with the following `*.sublime-project` settings.

    ```json
    {
      "folders": [
        {
          "follow_symlinks": true,
          "path": "."
        }
      ],
      "settings": {
        "xdebug": {
          "url": "http://<PROJECT>.dev/",
          "path_mapping": {
            "/var/www/drupal": "/Users/oxy/Projects/Genero/<PROJECT>"
          }
        }
      }
    }
    ```

4. Add a breakpoint and start debugging.

##### XHProf

1. Visit `/admin/config/development/` and enable XHProf.
2. Visit any page you want to profile and look for the XHProf link at the bottom of the page.

XHProf results are at: `http://xhprof.<project>.dev`.

##### LiveReload

1. Install the [browser extension](http://go.livereload.com/extensions).
2. Enable the extension on said page.
3. Run `grunt watch` or `gulp watch` to trigger livereload when css/js/images changes.

In case you want to use live reloading on mobile devices, look into using the
[LiveReload Drupal module](https://www.drupal.org/project/livereload).

##### Share your local webserver on the internet

Maybe you want to test out the site on your mobile, or have someo PM take a
look at how everything is coming along.

Simply ssh into the VM (`vagrant ssh`) and run `ngrok 80`. You will be given a
unique address which you can share to anyone you want.

##### Remote mobile debugging

You can access your mobiles chrome windows through developers tools on your
desktop using the [following tutorial](https://developer.chrome.com/devtools/docs/remote-debugging).

1. Connect your phone to your computer
2. Enable USB debugging in settings on your phone
3. Go to `chrome://inspect#devices` on your desktop browser, and select your phone
4. Allow the connection on your phone
5. Choose inspect and start debugging.

##### Update/Install Drupal modules.

As `drush pm-update` and `drush pm-install` run within the VM and rsync is
one-way, the files created will be one the host only. So you have two options:

1. Fetch the modules locally with `drush dl foobar`
2. Let them be resynced to the VM.
3. Run the updates on the VM using `drush @dev updatedb`

Alternatively

1. Exit the `vagrant gatling-rsync-auto` process if you have it running, this
might override the new code before you can act.
2. Run the `drush` commands.
3. Run `make rsync-pull` to fetch the files from the guest VM to your host machine
4. Commit the code and restart `vagrant gatling-rsync-auto`.

##### Using Browserstack Live

[Browserstack](https://www.browserstack.com/local-testing)
allows for local testing so you can easily access the VM through their service.

1. Open the page on browserstack live.
2. Click the settings wheel and tick the box for resolving all network URLs.
3. Profit

##### Remote mobile debugging using weinre

[Weinre](http://people.apache.org/~pmuellr/weinre/docs/1.x/1.5.0/Home.html) is
a remote web inspector, allowing you to inspect a remote
client such as a browserstack session.

1. Run `vagrant ssh -c 'weinre --boundHost -all- --httpPort 80'` and keep it running.
2. Open the page you want to inspect and add `?debug` at the end of the URL.
3. Go to `http://<project>.dev:9090` in your own browser and start inspecting

_Unfortunately weinre does not display the CSS of media queries._

##### VM services

```
Adminer    http://adminer.{{ vagrant_hostname }}
MailHog    http://{{ vagrant_hostname }}:8025/
PimpMyLog  http://pimpmylog.{{ vagrant_hostname }}/
Solr       http://{{ vagrant_hostname  }}:8983/solr/
XHProf     http://xhprof.{{ vagrant_hostname }}/
```

#### Deploy

```sh
# Deploy to the production environment
cap production deploy

# Deploy to our staging environment
cap staging deploy

# Simply sync our compiled assets (these might be overriden on next deploy)
cap staging assets:push

# Push our local files to staging environment, overriding older files, but
# leaving untouched/unexisting files.
cap staging files:push

# Push git staged files to staging environment. This is simply rsynced and will
# be removed with the next proper deploy. It only exists for you to stop making
# repetitive fix commits. LEARN NOT TO NEED THIS!
cap staging deploy:temporary
```

#### Drupal

```sh
# Maintenance mode
cap production drush:offline
cap production drush:online

# Backup database (on the remote host)
cap production drush:backupdb

# Interactively import database (on the remote host)
cap production drush:importdb

# Run database updates
cap production drush:updatedb
```

#### Drush

```sh
# Check the status of the production site.
drush @production status

# Set the production site into maintenance mode.
drush @production offline
drush @production online

# Import the production database into the virtualmachine.
drush sql-sync @production @dev

# Import the production environment files into the staging environment.
# NOTE: Drush rsync requires that one of the target be local, which is why we
# ssh into staging first (production wouldn't have access to the staging
# environment).
drush @staging ssh 'drush core-rsync @production:%files @self:%files'

# Save a dump of the production database to the local machine.
drush sql-dump @production >| dump.sql
```

#### Clear caches

```sh
# Clear all caches on production.
cap production cache

# Clear all Drupal caches on production.
cap production cache:all

# Clear the varnish cache on production.
cap production cache:varnish

# Clear the APC cache on production (some weird php bugs).
cap production cache:apc

# Clear the asset caches on production.
cap production cache:cssjs
```

#### Logs and services

```sh
# Tail some logs
cap production logs:apache_access
cap production logs:apache_error
cap production logs:varnish
cap production logs:htop

# Display summary of running services (if monit is setup)
cap production monit:summary
cap production monit:status

# Control services
cap staging service:apache:graceful
cap staging service:mysql:start
cap staging service:varnish:restart

# Open a SSH connectino to production.
cap production ssh
```

Staging environment
-------------------

> Located on _minasanor.genero.fi_, within /var/www/staging/`<PROJECT>` as a
> capistrano target (setup using `current`, `release`, etc folders).

#### Setup

1. Configure the capistrano settings for staging in `config/deploy/staging.rb`
2. Todo have a look at this outdated [make task](https://github.com/generoi/genero-conf/blob/4f1bd8bc9da56847e691238b3b5c8228e14617b3/make/staging.mk#L10:L26).

Production
----------

> Located on the live server.

#### Setup

1. Setup the environment (apache, php, apc/opcache, varnish, squid, memcached, etc.)
2. Setup the deploy user according to [Capistrano's guides](http://capistranorb.com/documentation/getting-started/authentication-and-authorisation/)
3. Configure the capistrano settings for production: `config/deploy/production.rb`
4. Scaffold the capistrano folder structure by running the following from **your own development machine**.

    ```sh
    cap production setup
    ```

5. Probably not done, you should probably update this readme with whatever
   issues you found :)

Common issues
-------------

- If you're trying to communicate with production, make sure you have an SSH
  agent running with your key.

- If drush can't find an alias, check `drush site-alias`, if it's not there it
  most likely means you don't have the `sites/all/drush/aliases.drushrc.php`
  file.

- > Vagrant cannot forward the specified ports on this VM, since they
  > would collide with some other application that is already listening
  > on these ports. The forwarded port to 2222 is already in use
  > on the host machine.

  This is a Vagrant issue that will occur when you have a suspended VM that used
  a port that a now-running VM is using. Simply run `vagrant halt` followed by
  `vagrant up`.

- > Host key verification failed when staging is trying to communicate with production.

  `ssh deploy@minasanor 'ssh-keygen -R <production>'`

- > Keep getting random `Error: Call to undefined function ctools_include()` etc.

  Is memcached used, it might have failed somehow, restart it with:
  `drush @dev ssh 'sudo service memcached restart`
