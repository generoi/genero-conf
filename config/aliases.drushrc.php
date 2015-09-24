<?php

define('CONF_DEV_URI', '<project>.dev');
define('CONF_DEV_ROOT', '/var/www/drupal');
define('CONF_DEV_USER', 'vagrant');

define('CONF_STAGING_URI', '<project>.staging.minasanor.genero.fi');
define('CONF_STAGING_ROOT', '/var/www/staging/<project>/current');
define('CONF_STAGING_HOST', 'minasanor.genero.fi');
define('CONF_STAGING_USER', 'deploy');

define('CONF_PRODUCTION_URI', '<host>');
define('CONF_PRODUCTION_ROOT', '/var/www/<project>/current');
define('CONF_PRODUCTION_HOST', '<host>');
define('CONF_PRODUCTION_USER', 'deploy');
define('CONF_ADMIN_PASSWORD', 'admin');

exec("hostname", $output);
$is_staging = ($output[0] == 'minasanor');
exec("whoami", $output);
$is_vagrant = ($output[0] == 'vagrant');
$is_production = ($output[0] == 'deploy');
$is_local = !$is_staging && !$is_vagrant && !$is_production;

# Tables to exclude data from during sql sync/dump
$structure_tables = array(
  'advagg_*',
  'cache',
  'cache_*',
  'history',
  'search_*',
  'sessions',
  'watchdog',
  'webform_submitted_data',
);

# Directories to exclude during rsync
$rsync_exclude = array('styles', 'js', 'css', 'xmlsitemap', 'ctools', 'languages', 'advagg_css', 'advagg_js', '*.mp3', '*.mp4', '*.wmv', '*.mov', '*.zip', '*.gz');

$dev_enable = array('devel', 'admin_devel', 'update');
$dev_disable = array('apc', 'cache_control', 'varnish');

$dev_variables = array(
  'advagg_enabled' => '0',
  'cache' => '0',
  'error_level' => '2',
  'preprocess_css' => '0',
  'preprocess_js' => '0',
);
$dev_permissions = array(
  'access devel information',
  'access rules debug',
  'access environment indicator',
);

$staging_variables = $dev_variables;
$staging_enable = array();
$staging_disable = $dev_enable + $dev_disable + array('memcache', 'memcache_storage', 'memcache_admin');

// Include the shared aliases logic.
include __DIR__ . '/../lib/genero-conf/drush/aliases.drushrc.php';
