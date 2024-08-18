#!/bin/bash
if [ -f /app/.env ]; then
  echo "Sourcing /app/.env..."
  . /app/.env
  echo "RCLONE_CONFIG_DROPBOX_TYPE: $RCLONE_CONFIG_DROPBOX_TYPE"
  echo "RCLONE_CONFIG_DROPBOX_TOKEN: $RCLONE_CONFIG_DROPBOX_TOKEN"
  echo "RCLONE_REMOTE: $RCLONE_REMOTE"
  echo "BACKUP_PATH: $BACKUP_PATH"
else
  echo "No /app/.env found. Using environment and env.sh variables."
fi


# Create rclone config directory
mkdir -p /root/.config/rclone

# Find all unique remotes by scanning environment variables that start with RCLONE_CONFIG_
remotes=$(env | grep -oP '^RCLONE_CONFIG_\K\w+(?=_TYPE)' | sort -u)

# Generate rclone config file
for REMOTE in $remotes; do
  echo "Generating configuration for $REMOTE..."
  cat >> /root/.config/rclone/rclone.conf <<EOL
[$REMOTE]
type = $(eval echo \$RCLONE_CONFIG_${REMOTE}_TYPE)
$(env | grep ^RCLONE_CONFIG_${REMOTE}_ | sed "s/^RCLONE_CONFIG_${REMOTE}_//" | sed 's/=/ = /' | awk -F' = ' '{print tolower($1)" = "$2}' | grep -v '^type = ')
EOL
done




echo "Rclone configuration generated."

# Start PostgreSQL service
service postgresql start &

# Set permissions for store
chmod -R 777 /app/store

# Function to perform restore
restore_backup() {
  if rclone lsf "$RCLONE_REMOTE:$BACKUP_PATH" > /dev/null 2>&1; then
    echo "Restoring backup from $RCLONE_REMOTE..."
    rclone copy "$RCLONE_REMOTE:$BACKUP_PATH" /app/store/
    echo "Backup restored successfully."
    # Send notification (you can use a tool like curl to send a webhook notification)
  else
    echo "No backup found at $RCLONE_REMOTE. Using existing files."
  fi
}

# Function to perform backup
backup() {
  echo "Performing backup to $RCLONE_REMOTE..."
  rclone copy /app/store/ "$RCLONE_REMOTE:$BACKUP_PATH"
  echo "Backup completed."
}

# Restore if a backup exists
restore_backup

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

# Exit with status of process that exited first
wait -n
exit $?
