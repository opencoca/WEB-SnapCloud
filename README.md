# Startr Snap!Cloud v0.4.1 - The Snap! Cloud

## Upgrading Snap to 10.4.6

[![Build Status](https://travis-ci.org/opencoca/WEB-SnapCloud.svg?branch=master)](https://travis-ci.org/opencoca/WEB-SnapCloud)
[![License](https://img.shields.io/badge/license-GPL-purple.svg)](https://opensource.org/licenses/GPL-3.0)
[![GitHub stars](https://img.shields.io/github/stars/opencoca/WEB-SnapCloud.svg)](https://github.com/opencoca/WEB-SnapCloud/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/opencoca/WEB-SnapCloud.svg)](https://github.com/opencoca/WEB-SnapCloud/issues)

## Now with RClone Support! (v1.0.1)

Snap! Cloud is the behind-the-scenes engine for Snap!. It stores important info in a database for faster searches and saves all the actual content on your disk. With our latest update, it now supports `rclone` to back up your data to different cloud services, ensuring your information is safe and easy to recover.


## Table of Contents

- [Codezy Snap!Cloud v1.0.1 - The Snap! Cloud](#codezy-snapcloud-v101---the-snap-cloud)
  - [Upgrading Snap to 10.2.5](#upgrading-snap-to-1025)
  - [Now with RClone Support! (v1.0.1)](#now-with-rclone-support-v101)
  - [Table of Contents](#table-of-contents)
  - [Getting Started](#getting-started)
    - [Clone the Repository](#clone-the-repository)
    - [Installation with Makefile](#installation-with-makefile)
    - [Docker Installation](#docker-installation)
      - [Building the Docker Image](#building-the-docker-image)
      - [Running the Docker Container](#running-the-docker-container)
  - [Configuration](#configuration)
    - [Environment Variables](#environment-variables)
    - [.env File](#env-file)
  - [Rclone Configuration](#rclone-configuration)
    - [Example Configuration for Google Drive](#example-configuration-for-google-drive)
  - [Backup and Restore](#backup-and-restore)
    - [Performing a Backup](#performing-a-backup)
    - [Restoring from a Backup](#restoring-from-a-backup)
  - [Scheduling Backups](#scheduling-backups)
    - [Example Cron Expressions](#example-cron-expressions)
  - [Starting the Application](#starting-the-application)
    - [Using Makefile](#using-makefile)
    - [Using Docker](#using-docker)
  - [Custom Backup Hooks](#custom-backup-hooks)
    - [Example](#example)
  - [Third-party Dependencies](#third-party-dependencies)
    - [Frameworks and Tools](#frameworks-and-tools)
    - [Lua Rocks](#lua-rocks)
    - [JS Libraries](#js-libraries)
    - [Did We Forget to Mention Your Stuff?](#did-we-forget-to-mention-your-stuff)
  - [Live Instance](#live-instance)
  - [Contributing](#contributing)
  - [Troubleshooting](#troubleshooting)
  - [License](#license)

## Getting Started

To get the latest version of the code, clone our repository:

### Clone the Repository

Using HTTPS:

```bash
git clone --filter=tree:0 https://github.com/opencoca/WEB-SnapCloud
```

Or using SSH:

```bash
git clone --filter=tree:0 git@github.com:opencoca/WEB-SnapCloud.git
```

### Installation with Makefile

Navigate to the project directory and get started with our Makefile:

```bash
cd WEB-SnapCloud
make
```

This will show you the available commands. Make sure to install the submodules and the dependencies before running the server using `make this_dev_env`.

Then you can run the server using `make it_run` and access it at `http://localhost`.

### Docker Installation

For easier deployment and management, you can use Docker to run the Snap! Cloud server. The following instructions outline how to build and run the Docker container.

#### Building the Docker Image

First, build the Docker image:

```bash
docker build -t snapcloud-server .
```

#### Running the Docker Container

Run the Docker container with necessary volume mounts and environment variables:

```bash
docker run -d --name snapcloud-server \
  -v "$(pwd)/:/app/" \
  -v "$(pwd)/.env:/app/.env" \
  -e BACKUP_CRON="0 5 *" \
  -p 80:80 \
  snapcloud-server
```

Replace `/path/to/app` and `/path/to/env` with your actual paths.

## Configuration

### Environment Variables

SnapCloud Server relies on several environment variables for its configuration. These can be set in a `.env` file or passed directly to the Docker container.

| Variable             | Description                                                                 | Example                                         |
|----------------------|-----------------------------------------------------------------------------|-------------------------------------------------|
| `RCLONE_CONFIG_*`    | Configuration for each rclone remote. Replace `*` with the remote name.     | `RCLONE_CONFIG_DRIVE_TYPE=drive`                |
| `RCLONE_REMOTE`      | The name of the rclone remote to use for backups.                           | `DRIVE`                                         |
| `BACKUP_PATH`        | The path in the remote storage where backups will be stored.                | `backups/snapcloud`                             |
| `BACKUP_CRON`        | Cron expression for scheduling backups. Defaults to `0 5 *` (5:00 AM daily).| `30 2 *` (2:30 AM daily)                        |
| `AUTO_RESTORE`       | If set to `true`, the server will attempt to restore from a backup on startup.| `true`                                        |
| `LAPIS_ENVIRONMENT`  | Environment setting for the Lapis server.                                   | `production`                                    |
| `BACKUP_HOOK`        | Custom command or script to execute for backups instead of the default.     | `./custom_backup.sh`                            |

### .env File

Create a `.env` file in the `/app` directory to store your environment variables:

```env
# Rclone Configuration for Google Drive
RCLONE_CONFIG_DRIVE_TYPE=drive
RCLONE_CONFIG_DRIVE_CLIENT_ID=your_client_id
RCLONE_CONFIG_DRIVE_CLIENT_SECRET=your_client_secret
RCLONE_CONFIG_DRIVE_SCOPE=drive
RCLONE_CONFIG_DRIVE_TOKEN={"access_token":"your_access_token","token_type":"Bearer","refresh_token":"your_refresh_token","expiry":"2024-12-31T23:59:59.000Z"}

# Backup Settings
RCLONE_REMOTE=DRIVE
BACKUP_PATH=backups/snapcloud
BACKUP_CRON=0 5 *
AUTO_RESTORE=true
LAPIS_ENVIRONMENT=production
# BACKUP_HOOK can be defined if you have a custom backup script
# BACKUP_HOOK="./custom_backup.sh"
```

## Rclone Configuration

The `setup_rclone` function in `start.sh` automatically generates the `rclone.conf` file based on environment variables prefixed with `RCLONE_CONFIG_`. Ensure that you define all necessary configuration variables for each remote you intend to use.

### Example Configuration for Google Drive

```env
RCLONE_CONFIG_DRIVE_TYPE=drive
RCLONE_CONFIG_DRIVE_CLIENT_ID=your_client_id
RCLONE_CONFIG_DRIVE_CLIENT_SECRET=your_client_secret
RCLONE_CONFIG_DRIVE_SCOPE=drive
RCLONE_CONFIG_DRIVE_TOKEN={"access_token":"your_access_token","token_type":"Bearer","refresh_token":"your_refresh_token","expiry":"2024-12-31T23:59:59.000Z"}
```

You can define multiple remotes by adding additional `RCLONE_CONFIG_*` variables with different remote names.

## Backup and Restore

### Performing a Backup

To manually trigger a backup, execute the following command inside the Docker container:

```bash
docker exec snapcloud-server backup
```

This will:

1. Copy the contents of `/app/store/` to the specified `RCLONE_REMOTE` and `BACKUP_PATH`.
2. Dump the PostgreSQL database `snapcloud` to `/app/backup.snapcloud.sql`.
3. Upload the database dump to the remote storage.
4. Clean up the local database dump file.

### Restoring from a Backup

To manually restore from a backup, execute:

```bash
docker exec snap-cloud /app/start.sh restore
```

Where `e24` is the name/hash of the Docker container.

This will:

1. Check for existing backups in the specified `RCLONE_REMOTE` and `BACKUP_PATH`.
2. Download the backup files excluding `backup.snapcloud.sql` and `backup.log` to `/app/store/`.
3. Download the database dump `backup.snapcloud.sql`.
4. Drop and recreate the PostgreSQL database `snapcloud`.
5. Restore the database from the downloaded dump.

## Scheduling Backups

Backups are scheduled based on the `BACKUP_CRON` environment variable, which follows a simplified cron expression format: `MINUTE HOUR DAY`. The default is `0 5 *`, which schedules backups at 5:00 AM every day.

### Example Cron Expressions

- `30 2 *` - Executes backup daily at 2:30 AM.
- `0 * *` - Executes backup at the start of every hour.
- `* * *` - Executes backup every minute (use with caution).

The `schedule_backups` function continuously checks the current time against the `BACKUP_CRON` schedule and triggers backups accordingly.

## Starting the Application

The `start.sh` script manages the startup process of the application, including setting up rclone, starting PostgreSQL, optionally restoring from backups, starting the Lapis server, and scheduling backups.

### Using Makefile

If you prefer using the Makefile, ensure that you have configured the necessary environment variables and run:

```bash
make it_run
```

### Using Docker

When running via Docker, use the `server` command to initiate all necessary services:

```bash
docker run -d --name snapcloud-server \
  -v /path/to/app:/app \
  -v /path/to/env:/app/.env \
  snapcloud-server server
```

This command will:

1. **Setup Rclone Configuration**: Generates the `rclone.conf` based on environment variables.
2. **Start PostgreSQL Service**: Initializes the PostgreSQL database.
3. **Auto Restore (Optional)**: If `AUTO_RESTORE` is set to `true`, restores data from the latest backup.
4. **Set Permissions**: Ensures `/app/store` has the necessary permissions.
5. **Start Lapis Server**: Launches the Lapis application in the background.
6. **Schedule Backups**: Initiates the backup scheduler based on `BACKUP_CRON` or executes a custom `BACKUP_HOOK` if provided.
7. **Keep Container Running**: Uses an infinite sleep to keep the Docker container alive.

## Custom Backup Hooks

If you prefer to use a custom backup script instead of the default backup mechanism, define the `BACKUP_HOOK` environment variable with your custom command or script.

### Example

```env
BACKUP_HOOK="./custom_backup.sh"
```

Ensure that your custom script handles all necessary backup steps, such as data synchronization and database dumps.

## Third-party Dependencies

### Frameworks and Tools

* [Leafo](http://leafo.net/)'s [Lapis](http://leafo.net/lapis/) is the lightweight, fast, powerful, and versatile [Lua](http://lua.org) web framework that powers the Snap Cloud - [[ MIT ](https://opensource.org/licenses/MIT)]
* The [PostgreSQL](https://www.postgresql.org/) database holds almost all the data, while the rest is stored to disk. - [[ PostgreSQL license ](https://www.postgresql.org/about/licence/)]

### Lua Rocks

* [Lubyk](https://github.com/lubyk)'s [XML](https://luarocks.org/modules/luarocks/xml) module is used to parse thumbnails and notes out of projects. - [[ MIT ](https://opensource.org/licenses/MIT)]
* [Michal Kottman](https://github.com/mkottman)'s [LuaCrypto](https://luarocks.org/modules/luarocks/luacrypto) module is the Lua frontend to the OpenSSL library. - [[ MIT ](https://opensource.org/licenses/MIT)]
* [Leafo](http://leafo.net/)'s [PgMoon](https://luarocks.org/modules/leafo/pgmoon) module is used to connect to the PostgreSQL database for migrations - [[ MIT ](https://opensource.org/licenses/MIT)]

### JS Libraries

* [Matt Holt](https://github.com/mholt)'s [Papaparse](https://www.papaparse.com) library is used to parse CSV files for bulk account creation. - [[ MIT ](https://opensource.org/licenses/MIT)]
* [Eli Grey](https://github.com/eligrey)'s [FileSaver.js](https://github.com/eligrey/FileSaver.js/) library is used to save project files from the project page, and maybe elsewhere - [[ MIT ](https://opensource.org/licenses/MIT)]

### Did We Forget to Mention Your Stuff?

Sorry about that! Please file an issue stating what we forgot, or just send us a pull request modifying this [README](https://github.com/opencoca/WEB-SnapCloud/edit/master/README.md).

## Live Instance

The Snap!Cloud backend is currently live at [https://cloud.snap.berkeley.edu](https://cloud.snap.berkeley.edu). See the API description page at [https://cloud.snap.berkeley.edu/static/API](https://cloud.snap.berkeley.edu/static/API).

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) before sending us any pull requests. Thank you!

## Troubleshooting

- **Rclone Configuration Issues**: Ensure all `RCLONE_CONFIG_*` environment variables are correctly set. Check the generated `rclone.conf` for accuracy.
- **Backup Failures**: Review the logs for any errors during the backup process. Ensure that the remote storage is accessible and that credentials are correct.
- **Database Issues**: If the PostgreSQL service fails to start or the database fails to restore, verify PostgreSQL logs and ensure that the `pg_dump` and `psql` commands are functioning correctly.
- **Permission Errors**: Ensure that the `/app/store` directory has appropriate permissions. The script sets permissions to `777` by default, but adjust as necessary for your security requirements.

## License

This project is licensed under the [GPL-3.0](https://opensource.org/licenses/GPL-3.0).

---

For any issues or feature requests, please open an issue on the [GitHub repository](https://github.com/opencoca/WEB-SnapCloud/issues).
