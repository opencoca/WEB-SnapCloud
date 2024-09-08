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
  #and log to log file
  rclone copy /app/store/ "$RCLONE_REMOTE:/$BACKUP_PATH" >> /app/backup.log
  #log the backup status
  su postgres -c "pg_dump -d snapcloud" > /app/backup.snapcloud.sql
  rclone copy /app/backup.snapcloud.sql "$RCLONE_REMOTE:/$BACKUP_PATH" >> /app/backup.log
  echo "Backup completed."
}


# Function to perform restore
restore_backup() {
  if rclone lsf "$RCLONE_REMOTE:$BACKUP_PATH" > /dev/null 2>&1; then
    echo "Restoring backup from $RCLONE_REMOTE..."
    rclone copy "$RCLONE_REMOTE:$BACKUP_PATH" /app/store/ --exclude 'backup.snapcloud.sql' --exclude 'backup.log' >> /app/backup.log
    
    echo "Restoring PostgreSQL database..."
    if rclone cat "$RCLONE_REMOTE:$BACKUP_PATH/backup.snapcloud.sql" > /app/restore.snapcloud.sql >> /app/backup.log; then
      # Drop and recreate the database
      su postgres -c "psql -c 'DROP DATABASE IF EXISTS snapcloud;'"
      su postgres -c "psql -c 'CREATE DATABASE snapcloud;'"
      
      # Restore the database
      su postgres -c "psql -d snapcloud -f /app/restore.snapcloud.sql" >> /app/backup.log
      
      # Clean up
      rm /app/restore.snapcloud.sql
      echo "Database restored successfully."
    else
      echo "Failed to retrieve database backup file." >> /app/backup.log
    fi
    
    echo "Backup restored successfully." >> /app/backup.log
  else
    echo "No backup found at $RCLONE_REMOTE. Using existing files." >> /app/backup.log
  fi
}

# Function to start the application
start_app() {
  # Start PostgreSQL service
  service postgresql start
  # Wait for PostgreSQL to start
  sleep 2
  # if $AUTO_RESTORE is set to true, restore the backup
  if [ "$AUTO_RESTORE" = "true" ]; then
    restore_backup
  fi

  # Set permissions for store
  chmod -R 777 /app/store

  # Start the application
  cd /app/ \
    && . env.sh \
    && lapis server $LAPIS_ENVIRONMENT --trace &

  # Schedule backups
  if [ -z "$BACKUP_HOOK" ]; then
    BACKUP_CRON="${BACKUP_CRON:-'0 5 * * *'}"  # set BACKUP_CRON as environment variable or default to '0 5 * * *' 
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