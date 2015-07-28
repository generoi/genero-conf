<?php

// Custom aliases.
$options['shell-aliases']['offline'] = 'variable-set -y --always-set maintenance_mode 1';
$options['shell-aliases']['online'] = 'variable-delete -y --exact maintenance_mode';

/**
 * Prevent patched modules from being updated.
 * @todo as we should make a move towards drush make files it's not necesassary
 * anymore, but otherwise this should be moved to the genero drush module as a
 * policy.
 */
$root = drush_get_context('DRUSH_SELECTED_DRUPAL_ROOT');
if ($root && is_dir($root . '/sites/all/modules/patched')) {
  $locked = array();
  foreach (scandir($root . '/sites/all/modules/patched') as $module) {
    // Make sure it's a valid directory
    if (is_dir($root . '/sites/all/modules/patched/' . $module) && !in_array($module, array('.', '..'))) {
      $locked[] = $module;
    }
  }
  $command_specific['pm-update'] = array('lock' => implode(',', $locked));
}
