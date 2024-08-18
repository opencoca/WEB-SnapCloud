FROM openco/snapcloud-develop:latest-prerequisites

ENV DEBIAN_FRONTEND=noninteractive

# Install rclone
# Add cron for scheduling backups
RUN apt-get update && apt-get install -y cron rclone

# Set default values for environment variables

ENV RCLONE_CONFIG_B2_TYPE=b2
ENV RCLONE_CONFIG_B2_ACCOUNT=000000000000000000000000
ENV RCLONE_CONFIG_B2_KEY=K000000000000000000000000
ENV RCLONE_CONFIG_B2_HARD_DELETE=true

ENV RCLONE_REMOTE=b2
ENV BACKUP_PATH=snapcloud-backups
# Optional: Rclone configuration for Google Drive
# RCLONE_REMOTE=gdrive
# RCLONE_CONFIG_TYPE=drive
# RCLONE_CONFIG_DRIVE_CLIENT_ID=YOUR_CLIENT_ID
# RCLONE_CONFIG_DRIVE_CLIENT_SECRET=YOUR_CLIENT_SECRET
# RCLONE_CONFIG_DRIVE_SCOPE=drive
# RCLONE_CONFIG_DRIVE_TOKEN='{"access_token":"YOUR_ACCESS_TOKEN","token_type":"bearer","expiry":"0001-01-01T00:00:00Z"}'
# Backup path and schedule

ENV BACKUP_PATH=snapcloud-backups
ENV BACKUP_CRON="0 2 * * *"  
# 2 AM EST (7 AM UTC)
ENV NOTIFY_URL=https://your-webhook-url.com/notify

# Document the environment variables
# RCLONE_REMOTE: The remote storage service to use (default: dropbox)
# RCLONE_CONFIG_TYPE: The type of remote storage service (default: dropbox)
# RCLONE_CONFIG_DROPBOX_TOKEN: The access token for Dropbox (default: {"access_token":"YOUR_ACCESS_TOKEN","token_type":"bearer","expiry":"0001-01-01T00:00:00Z"})
# RCLONE_REMOTE (Google Drive): The remote storage service to use (default: gdrive)
# RCLONE_CONFIG_TYPE (Google Drive): The type of remote storage service (default: drive)
# RCLONE_CONFIG_DRIVE_CLIENT_ID: The client ID for Google Drive
# RCLONE_CONFIG_DRIVE_CLIENT_SECRET: The client secret for Google Drive
# RCLONE_CONFIG_DRIVE_SCOPE: The scope for Google Drive (default: drive)
# RCLONE_CONFIG_DRIVE_TOKEN: The access token for Google Drive (default: {"access_token":"YOUR_ACCESS_TOKEN","token_type":"bearer","expiry":"0001-01-01T00:00:00Z"})
# BACKUP_PATH: The path where backups will be stored (default: snapcloud-backups)
# BACKUP_CRON: The cron schedule for backups (default: "0 2 * * *")
# NOTIFY_URL: The URL for notifications (default: https://your-webhook-url.com/notify)


# Add canonical snap store
COPY ./store /app/store
# Add canonical database
COPY snapcloud.sql /app/bin/snapcloud.sql

RUN service postgresql start \
  && su postgres -c "dropdb snapcloud" \
  && su postgres -c "createdb snapcloud" \
  && su postgres -c "psql -c \"ALTER USER cloud WITH SUPERUSER;\"" \
  && su postgres -c "psql -d snapcloud -f /app/bin/snapcloud.sql"
# env file for snap cloud
COPY env.sh /app/.env

COPY . /app

RUN chmod -R 777 /app/store

EXPOSE 80
ENV PORT=80

CMD ["/app/start.sh"]
