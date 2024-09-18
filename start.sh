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
  # and log to log file
  rclone -vv copy /app/store/ "$RCLONE_REMOTE:/$BACKUP_PATH" 
  # log the backup status
  su postgres -c "pg_dump -d snapcloud" > /app/backup.snapcloud.sql
  rclone -vv copy /app/backup.snapcloud.sql "$RCLONE_REMOTE:/$BACKUP_PATH" 
  rm /app/backup.snapcloud.sql
  echo "Backup completed."
}


# Function to perform restore
restore_backup() {
  echo "Checking for backup at $RCLONE_REMOTE..."
  if rclone -vv lsf "$RCLONE_REMOTE:$BACKUP_PATH" > /dev/null 2>&1; then
    # Echo the date & time at which the backup was found
    echo "Backup found at $RCLONE_REMOTE on $(date)."
    rclone -vv copy "$RCLONE_REMOTE:$BACKUP_PATH" /app/store/ --exclude 'backup.snapcloud.sql' --exclude 'backup.log'
    
    echo "Restoring PostgreSQL database..."
    if rclone -vv cat "$RCLONE_REMOTE:$BACKUP_PATH/backup.snapcloud.sql" > /app/restore.snapcloud.sql; then
      # Drop and recreate the database
      su postgres -c "psql -c 'DROP DATABASE IF EXISTS snapcloud;'"
      su postgres -c "psql -c 'CREATE DATABASE snapcloud;'"
      
      # Restore the database
      su postgres -c "psql -d snapcloud -f /app/restore.snapcloud.sql" 
      
      # Clean up
      rm /app/restore.snapcloud.sql
      echo "Database restored successfully."
    else
      echo "Failed to retrieve database backup file." 
    fi
    
    echo "Backup restored successfully."
  else
    echo "No backup found at $RCLONE_REMOTE. Using existing files."
  fi
}

# Function to schedule backups
schedule_backups() {
  local MINUTE HOUR DAY
  IFS=' ' read -r MINUTE HOUR DAY <<< "$BACKUP_CRON"

  echo "Scheduling backups with cron expression: $BACKUP_CRON"

  while true; do
    CURRENT_MINUTE=$(date +%-M)
    CURRENT_HOUR=$(date +%-H)
    CURRENT_DAY=$(date +%-d)

    MATCHED=true

    # Check minute
    if [ "$MINUTE" != "*" ]; then
      if [ "$MINUTE" != "$CURRENT_MINUTE" ]; then
        MATCHED=false
      fi
    fi

    # Check hour
    if [ "$HOUR" != "*" ]; then
      if [ "$HOUR" != "$CURRENT_HOUR" ]; then
        MATCHED=false
      fi
    fi

    # Check day
    if [ "$DAY" != "*" ]; then
      if [ "$DAY" != "$CURRENT_DAY" ]; then
        MATCHED=false
      fi
    fi

    if [ "$MATCHED" = true ]; then
      echo "Time matches the backup schedule, running backup..."
      backup
      # Sleep for 60 seconds to avoid running backup multiple times in the same minute
      sleep 60
    else
      # Sleep until the start of the next minute
      sleep $((60 - $(date +%S)))
    fi
  done
}

# Function to start the application
start_app() {
  # Start PostgreSQL service
  service postgresql start
  # Wait for PostgreSQL to start
  sleep 2
  # if $AUTO_RESTORE is set to true, restore the backup
  if [ "$AUTO_RESTORE" = "true" ]; then
    echo "AUTO_RESTORE is set to true. Restoring backup..."
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
    BACKUP_CRON="${BACKUP_CRON:-0 5 *}"  # Default to '0 5 *' (5:00 AM every day)
    schedule_backups &
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
    # Dynamically generate usage options by parsing the case statement
    options=$(awk '/case "\$1" in/,/\*)/' "$0" | grep -E '^\s+[^\|\)]+' | sed 's/)//;s/)//;s/^\s*//')
    echo "Usage: $0 {$(echo $options | tr '\n' '|')}"
    exit 1
    ;;
esac

# Exit with status of process that exited first
wait -n
exit $?
