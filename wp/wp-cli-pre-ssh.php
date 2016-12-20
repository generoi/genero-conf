<?php

/**
 * Add vendor binaries to $PATH so that wp-cli is available on the remote host
 * when it's a composer dependency.
 *
 * @see https://runcommand.io/to/wp-ssh-custom-path/
 */
WP_CLI::add_hook('before_ssh', function() {
  // Eg. /var/www/wordpress/web/wp
  $wp_path = WP_CLI\Utils\parse_ssh_url(WP_CLI::get_runner()->config['ssh'], PHP_URL_PATH);
  // Eg. /var/www/wordpress
  $project_root = dirname(dirname($wp_path));
  // Eg. /var/www/wordpress/vendor/bin
  $vendor_path = "$project_root/vendor/bin";
  // Additionally add the users globally installed composer binaries.
  $composer_path = '$HOME/.composer/vendor/bin';
  // Drupal VM installs global composer packages in a custom location, readable
  // by all the users.
  $source_profile = '[ -e /etc/profile.d/composer.sh ] && source /etc/profile.d/composer.sh';

  putenv('WP_CLI_SSH_PRE_CMD=' . $source_profile . ';export PATH=' . $vendor_path . ':' . $composer_path . ':$PATH');
});
