<?php

$base_options = array(
  'path-aliases' => array(
    '%dump-dir' => '/tmp',
    '%dump' => '/tmp/dump.sql',
    '%files' => 'sites/default/files',
  ),
  'command-specific' => array(
    'sql-dump' => array(
      'no-ordered-dump' => TRUE,
      'structure-tables-list' => implode(',', $structure_tables),
    ),
    'core-rsync' => array(
      'verbose' => TRUE,
      'mode' => 'rlpzO',
      'no-perms' => TRUE,
      'exclude-paths' => implode(':', $rsync_exclude),
    ),
  ),
);


// The locally installed virtual machine.
$aliases['dev'] = $base_options + array(
  'uri' => CONF_DEV_URI,
  'root' => CONF_DEV_ROOT,

  'target-command-specific' => array(
    'sql-sync' => array(
      # Do not cache the sql-dump file.
      'no-cache' => TRUE,
      # Leverage multiple value inserts to sql 4x faster.
      # @see http://knackforge.com/blog/sivaji/how-make-drush-sql-sync-faster
      'no-ordered-dump' => TRUE,
      'structure-tables-list' => implode(',', $structure_tables),
      # Enable development modules.
      'enable' => $dev_enable,
      # Disable some caching modules.
      'disable' => $dev_disable,
      # Reset the admin users password.
      'reset-admin-password' => CONF_ADMIN_PASSWORD,
      # Obscure user email addresses and reset passwords.
      'sanitize' => TRUE,
      'confirm-sanitizations' => TRUE,
      # Allow all users to see devel information.
      'permission' => array(
        'authenticated user' => array(
          'add' => array() + $dev_permissions,
          'remove' => array('change own password'),
        ),
        'anonymous user' => array(
          'add' => array() + $dev_permissions,
        ),
      ),
      'variables' => $dev_variables,
    ),
  ),
);
// Add the vagrant ssh connection information as long as we're not within the
// vagrant VM.
if (!$is_vagrant) {
  $aliases['dev'] += array(
    'remote-host' => CONF_DEV_URI,
    'remote-user' => CONF_DEV_USER,
    // rsync doesn't understand ~/
    'ssh-options' => '-o ForwardAgent=yes -o PasswordAuthentication=no -i ' . $_SERVER['HOME'] . '/.vagrant.d/insecure_private_key',
  );
}


// The staging enviornment available on minasanor.
$aliases['staging'] = $base_options + array(
  'uri' => CONF_STAGING_URI,
  'root' => CONF_STAGING_ROOT,
  'remote-host' => CONF_STAGING_HOST,
  'remote-user' => CONF_STAGING_USER,
  'ssh-options' => '-o ForwardAgent=yes',

  'target-command-specific' => array(
    'sql-sync' => array(
      'no-cache' => TRUE,
      'no-ordered-dump' => TRUE,
      'structure-tables-list' => implode(',', $structure_tables),
      'enable' => $staging_enable,
      'disable' => $staging_disable,
      'variables' => $staging_variables,
    ),
  ),
);

// The production environment.
$aliases['production'] = $base_options + array(
  'uri' => CONF_PRODUCTION_URI,
  'root' => CONF_PRODUCTION_ROOT,
  'remote-host' => CONF_PRODUCTION_HOST,
  'remote-user' => CONF_PRODUCTION_USER,
  // Prevent accidental writes to production environment.
  'target-command-specific' => array(
    'sql-sync' => array('simulate' => TRUE),
    'core-rsync' => array('simulate' => TRUE),
  ),
  'source-command-specific' => array(
    'sql-sync' => array(
      # Do not cache the sql-dump file.
      'no-cache' => TRUE,
      # Leverage multiple value inserts to sql 4x faster.
      # @see http://knackforge.com/blog/sivaji/how-make-drush-sql-sync-faster
      'no-ordered-dump' => TRUE,
      'structure-tables-list' => implode(',', $structure_tables),
    ),
  ),
);

// Only the staging environment has access to the production environment, if
// we're running drush from somewhere else, use the staging environment as a
// proxy.
if (!$is_staging) {
  $aliases['production']['ssh-options'] = '-o "ProxyCommand '
    . 'ssh ' . $aliases['staging']['remote-user']. '@' . $aliases['staging']['remote-host']
    . ' nc %h %p 2> /dev/null"';
}
