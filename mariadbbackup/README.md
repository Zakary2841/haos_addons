# 🗄️ MariaDB Backup Add-on for Home Assistant OS

This is a Home Assistant OS-compatible add-on that creates scheduled and manual backups of Home Assistant MariaDB database.

It uses `mariadb-dump` to export the database and stores the result as a timestamped `.sql` file in selected directory.

The add-on doesn’t need to stay running or launch at boot. It acts as a boot-triggered task—starts, performs the backup, then stops.

---

## 🔧 How It Works

The `run.sh` script:

1. Connects to the running MariaDB container used by Home Assistant.
2. Runs a `mariadb-dump` of all databases using credentials stored in `/data/secrets.txt`.
3. Saves the `.sql` backup file to custom location.

---

## 📍 Backup Location

Allowed locations:

  - addons
  - all_addon_configs
  - backup
  - homeassistant_config
  - media
  - share
  - any network path

---

## 🔐 Credentials

You must provide database credentials and backup location in the add-on configuration:

## ⚙️ Comfiguration 

| Option | Description | Default |
|--------|-------------|---------|
| `DB_HOST` | MariaDB hostname | `core-mariadb` |
| `DB_USER` | Database username | `homeassistant` |
| `DB_PASS` | Database password | (required) |
| `DB_BACKUPDIR` | Backup output directory | `/share` |
| `DB_RETENTION_DAYS` | Days to keep archived backups | `60` |
| `DB_NORMAL_RETENTION_DAYS` | Days before moving to archive | `7` |
| `DB_ARCHIVEDIR` | Archive folder name | `Archive` |
| `DB_FILENAME_FORMAT` | strftime format for timestamps | `%Y%m%d_%H%M%S` |
| `DB_TIMEZONE` | Timezone for timestamps | `UTC` |
| `DB_USE_FOLDERS` | Use archive folder structure | `true` |
| `DB_INCLUDE_SYSTEM` | Include system databases | `false` |
| `DB_SEPARATE_FILES` | Separate file per database (when including system) | `false` |


### DB_TIMEZONE

Select from common timezones. For other zones, fork and modify `config.yaml`.

🚀 Manual Backup

You can trigger a manual backup by starting the add-on.


📅 Scheduled Backups using HA Automation


```
alias: MariaDBBackup
description: ""
triggers:
  - at: "23:00:00"
    enabled: true
    trigger: time
conditions:
  - condition: time
    weekday:
      - sun
actions:
  - action: hassio.addon_start
    data:
      addon: 00000XX_mariadb-backup-zakary # name of mariadbbackup 
mode: single
```

📦 Output
Backups are saved under:

```
$DB_BACKUPDIR/mariadb_backup_YYYY-MM-DD_HH-MM-SS.sql
```

🛠️ Dependencies
- core-mariadb add-on must be running and accessible
- creds
- backup location
- retention period



✍️ Author
Made with 💙 by @dimx <br>
Edited with 🩵 by @Zakary2841
