#!/bin/bash

# Source environment variables
if [ -f /app/.env ]; then
  echo "Sourcing /app/.env..."
  . /app/.env
else
  echo "No /app/.env found. Using environment and env.sh variables."
fi

# function to setup rclone config
setup_rclone() {
    # Create rclone config directory
    config_dir="${HOME}/.config/rclone"
    mkdir -p "$config_dir" || { echo "Failed to create config directory"; return 1; }

    # Find all unique remotes by scanning environment variables that start with RCLONE_CONFIG_
    remotes=$(env | grep -E '^RCLONE_CONFIG_[^_]+_TYPE=' | sed 's/RCLONE_CONFIG_\([^_]*\)_TYPE=.*/\1/' | sort -u)

    if [ -z "$remotes" ]; then
        echo "No remotes found"
        return 0
    fi

    echo "Found remotes: $remotes"
    echo "Generating rclone configuration for all remotes..."

    # Generate rclone config file
    for REMOTE in $remotes; do
        echo "Generating configuration for $REMOTE..."
        {
            echo "[$REMOTE]"
            echo "type = $(eval echo \$RCLONE_CONFIG_${REMOTE}_TYPE)"
            env | grep "^RCLONE_CONFIG_${REMOTE}_" | sed "s/^RCLONE_CONFIG_${REMOTE}_//" | 
                sed 's/=/ = /' | awk -F' = ' '{print tolower($1)" = "$2}' | grep -v '^type = '
        } >> "$config_dir/rclone.conf" || { echo "Failed to write config for $REMOTE"; return 1; }
    done

    echo "Rclone configuration generated."
    echo ""
    echo "*********"
    cat "$config_dir/rclone.conf"
    echo "*********"
}


# Function to perform backup
backup() {
  echo "Performing backup to $RCLONE_REMOTE..."
  echo "rclone copy /app/store/ $RCLONE_REMOTE:/$BACKUP_PATH"
  rclone copy /app/store/ "$RCLONE_REMOTE:/$BACKUP_PATH"
  #TODO: Test Postgres backup
  su postgres -c "pg_dump -d snapcloud" > /app/backup.snapcloud.sql
  rclone copy /app/backup.snapcloud.sql "$RCLONE_REMOTE:/$BACKUP_PATH"
  echo "Backup completed."
}


# Function to perform restore
restore_backup() {
  if rclone lsf "$RCLONE_REMOTE:$BACKUP_PATH" > /dev/null 2>&1; then
    echo "Restoring backup from $RCLONE_REMOTE..."
    rclone copy "$RCLONE_REMOTE:$BACKUP_PATH" /app/store/
    #TODO: Add Postgres restore
    echo "Backup restored successfully."
  else
    echo "No backup found at $RCLONE_REMOTE. Using existing files."
  fi
}

# Function to start the application
start_app() {
  # Start PostgreSQL service
  service postgresql start

  # Set permissions for store
  chmod -R 777 /app/store

  # Start the application
  cd /app/ \
    && . env.sh \
    && lapis server $LAPIS_ENVIRONMENT --trace &

  # Schedule backups
  if [ -z "$BACKUP_HOOK" ]; then
    # Set default backup time to 2am EST
    BACKUP_CRON="${BACKUP_CRON:-'0 7 * * *'}"  # 7 AM UTC is 2 AM EST
    echo "$BACKUP_CRON root /app/start.sh backup" > /etc/cron.d/backup
    chmod 0644 /etc/cron.d/backup
    crontab /etc/cron.d/backup
    service cron start
  else
    # Run custom backup hook if provided
    eval "$BACKUP_HOOK"
  fi

  # Infinite sleep to keep the container running
  sleep infinity
}

# Main execution logic
case "$1" in
  backup)
    backup
    ;;
  restore)
    restore_backup
    ;;
  setup_rclone)
    setup_rclone
    ;;
  server)
    setup_rclone 
    start_app
    ;;
  *)
    echo "Usage: $0 {backup|restore|setup_rclone|server}"
    # TODO instead can we parse our case to see the useage options?
    exit 1
    ;;
esac

# Exit with status of process that exited first
wait -n
exit $?