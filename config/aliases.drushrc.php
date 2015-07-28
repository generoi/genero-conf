<?php

define('CONF_DEV_URI', '<project>.dev');
define('CONF_DEV_ROOT', '/var/www/drupal');
define('CONF_DEV_USER', 'vagrant');

define('CONF_STAGING_URI', '<project>.staging.<company>.fi');
define('CONF_STAGING_ROOT', '/var/www/staging/<project>/current');
define('CONF_STAGING_HOST', '<company>');
define('CONF_STAGING_USER', 'deploy');

define('CONF_PRODUCTION_URI', '<project>.fi');
define('CONF_PRODUCTION_ROOT', '/home/www/<project>/deploy/current');
define('CONF_PRODUCTION_HOST', '<project>.fi');
define('CONF_PRODUCTION_USER', 'deploy');
define('CONF_ADMIN_PASSWORD', 'admin');

exec("hostname", $output);
$is_staging = ($output[0] == '<company>');
exec("whoami", $output);
$is_vagrant = ($output[0] == 'vagrant');

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
$rsync_exclude = array('styles', 'js', 'css', 'xmlsitemap', 'ctools', 'languages', 'advagg_css', 'advagg_js');

$dev_enable = array('devel', 'admin_devel', 'update');
$dev_disable = array('apc', 'cache_control', 'varnish');

$dev_variables = array(
  'cache' => '0',
  'preprocess_css' => '0',
  'preprocess_js' => '0',
  'error_level' => '2',
);
$dev_permissions = array(
  'access devel information',
  'access rules debug',
  'access environment indicator',
);

$staging_variables = $dev_variables;
$staging_enable = array();
$staging_disable = $dev_enable + $dev_disable;

// Include the shared aliases logic.
include_once __DIR__ . '/../lib/genero-conf/drush/aliases.drushrc.php';
