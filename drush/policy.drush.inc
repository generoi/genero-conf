<?php

/**
 * @file
 *   Example policy commandfile. Modify as desired.
 *
 *   Validates commands as they are issued and returns an error
 *   or changes options when policy is violated.
 *
 *   You can copy this file to any of the following
 *     1. A .drush folder in your HOME folder.
 *     2. Anywhere in a folder tree below an active module on your site.
 *     3. /usr/share/drush/commands (configurable)
 *     4. In an arbitrary folder specified with the --include option.
 *     5. Drupal's sites/all/drush folder (note: sql-sync validation won't work here).
 */

/**
 * Implement of drush_hook_COMMAND_validate().
 *
 * Prevent catastrophic braino. Note that this file has to be local to the machine
 * that intitiates sql-sync command.
 */
function drush_policy_sql_sync_validate($source = NULL, $destination = NULL) {
  if (preg_match("/[@.](prod|production|live)$/", $destination)) {
    return drush_set_error(dt('Per genero/policy.drush.inc, you may never overwrite the production database.'));
  }
}


/**
 ** Implements drush_hook_COMMAND_validate().
 *
 * We can also limit rsync operations to production sites.
 */
function drush_policy_core_rsync_validate($source = NULL, $destination = NULL) {
  if (preg_match("/[@.](prod|production|live)$/", $destination)) {
    return drush_set_error('POLICY_DENY', dt('Per genero/policy.drush.inc, you may never rsync to the production site.'));
  }
}
