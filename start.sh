#!/bin/bash
source /app/.env

# Create rclone config directory
mkdir -p /root/.config/rclone

# Generate rclone config file
cat > /root/.config/rclone/rclone.conf <<EOL
[$RCLONE_REMOTE]
type = $RCLONE_CONFIG_TYPE
$(env | grep ^RCLONE_CONFIG_ | sed 's/^RCLONE_CONFIG_//' | sed 's/=/ = /')
EOL

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
  && . .env \
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
