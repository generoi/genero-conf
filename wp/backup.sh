#!/usr/bin/env bash

# backup.sh \
#   --wp /home/www/foo/deploy/current/web/wp \
#   --customer foo \
#   --remote minasithil.genero.fi \
#   --dir /home/www/foo/deploy/shared/web/app/uploads
#   --dir /home/www/foo/deploy/shared/web/app/uploads2

TIME="$(date +%Y%m%d_%H%M%S)"
WP_BIN="${WPCLI_BIN:-/usr/local/bin/wp}"
RSYNC_BIN="${RSYNC_BIN:-/usr/bin/rsync}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/backups}"

args=()
wp_path=
customer=
remote=
dirs=()

# Process and remove all flags.
while (($#)); do
  case $1 in
    --wp=*) wp_path="${1#*=}" ;;
    --wp) shift; wp_path="$1" ;;

    --customer=*) customer="${1#*=}" ;;
    --customer) shift; customer="$1" ;;

    --remote=*) remote="${1#*=}" ;;
    --remote) shift; remote="$1" ;;

    --dir=*) shift; dirs+=("$1") ;;
    --dir) shift; dirs+=("$1") ;;

    -*) echo "invalid option: $1" >&2; exit 1 ;;
    *) args+=("$1") ;;
  esac
  shift
done

# Restore the arguments without flags.
set -- "${args[@]}"

if [ -z "$customer" ]; then
  echo "--customer is required." >&2;
  exit 1
fi

if [ -z "$remote" ]; then
  echo "--remote is required." >&2;
  exit 1
fi

if [ -z "$wp_path" ]; then
  wp_path="/home/www/${customer}/deploy/current/web/wp"
fi

if [ ! -d "$wp_path" ]; then
  echo "could not find wp installation path." >&2;
  exit 1
fi

if [ ! -d "$BACKUP_DIR" ]; then
  mkdir -p $BACKUP_DIR || exit 1
fi

backup_db_file="$BACKUP_DIR/$customer-db-$TIME.sql.gz"

# Export database
$WP_BIN --path="$wp_path" db export - | gzip -f -6 >| $backup_db_file

# Create directory tree.
ssh "$remote" mkdir -p ~/backups/$customer/db

# Backup database
$RSYNC_BIN -aqz -e 'ssh' "$backup_db_file" "$remote:~/backups/$customer/db/"

# Delete files older than 30 days.
ssh "$remote" find ~/backups/$customer/db/ -mtime +30 -delete

# Remove local database dump.
rm -f $BACKUP_DB_FILE

# Backup directories.
for dir in "${dirs[@]}"; do
  $RSYNC_BIN -aqz -e 'ssh' --delete "$dir" "$remote:~/backups/$customer"
done
