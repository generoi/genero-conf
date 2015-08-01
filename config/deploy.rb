set :application,   '<project>'
set :repo_url,      'git@github.com:generoi/<project>.git'
set :branch,        'master'

set :user,          'deploy'
set :group,         'deploy'

# Root directory where backups will be placed.
set :backup_dir,    -> { "#{fetch(:deploy_to)}/backup" }
# Backup directories, currently only DB is suppored by drush.rake
set :backup_dirs,   %w[db]
set :log_level,     :info
set :pty,           true

# @NOTE this is not used anymore as development is done on local machines.
# Location where shared files reside on the development machine.
# This will be appended to :shared_settings and :shared_uploads
# set :shared_local_dir,  "/var/www/shared/#{fetch(:application)}"
set :shared_settings,   "sites/default/settings.local.php"
# set :shared_uploads,    "sites/default/files"

# Symlink these paths.
set :linked_files,      ["sites/default/settings.local.php", ".htaccess"]
set :linked_dirs,       ["sites/default/files"]

# Flags used by logs-tasks
set :tail_options,            "-n 100 -f"
set :rsync_options,           "--recursive --times --compress --human-readable --progress"

set :drush_cmd,               "drush"

# Cache tables should be set as structure tables in drushrc.php so that their
# data will be skipped from dumps.
# $options['structure-tables']['common'] = array('cache', 'cache_*', 'history', 'search_*', 'sessions', 'watchdog');
set :drush_sql_dump_options,  "--structure-tables-list=cache,cache_*,history,search_*,sessions,watchdog --gzip"

set :varnish_cmd,             "/usr/bin/varnishadm -S /etc/varnish/secret"
set :varnish_address,         "127.0.0.1:6082"
set :varnish_ban_pattern,     "req.url ~ ^/"

set :assets_compile,          "gulp build --production"
set :assets_output,           %w[sites/all/themes/<theme>/css sites/all/themes/<theme>/bower_components]

namespace :deploy do
  after :restart, :cache_clear do end

  after :finishing, :drupal_online do
    invoke "drush:site_offline"
    invoke "assets:push"
    invoke "drush:backupdb" if fetch(:stage) == :production
    invoke "cache:apc" if fetch(:stage) == :production
    invoke "cache:all"
    invoke "drush:updatedb"
    invoke "drush:site_online"
    # invoke "cache:varnish" if fetch(:stage) == :production
  end

  after :rollback, 'cache'
  before :starting, 'deploy:check:pushed'
  before :starting, 'deploy:check:assets'
  before :starting, 'deploy:check:sshagent'
end
