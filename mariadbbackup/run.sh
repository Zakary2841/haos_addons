#!/usr/bin/env bash
set -e

CONFIG_PATH="/data/options.json"

echo "[INFO] Loading configuration..."

DB_HOST=$(jq --raw-output '.DB_HOST // "core-mariadb"' "$CONFIG_PATH")
DB_USER=$(jq --raw-output '.DB_USER // "homeassistant"' "$CONFIG_PATH")
DB_PASS=$(jq --raw-output '.DB_PASS // empty' "$CONFIG_PATH")
DB_BACKUPDIR=$(jq --raw-output '.DB_BACKUPDIR // "/share"' "$CONFIG_PATH")
DB_RETENTION_DAYS=$(jq --raw-output '.DB_RETENTION_DAYS // 60' "$CONFIG_PATH")
DB_NORMAL_RETENTION_DAYS=$(jq --raw-output '.DB_NORMAL_RETENTION_DAYS // 7' "$CONFIG_PATH")
DB_ARCHIVEDIR=$(jq --raw-output '.DB_ARCHIVEDIR // "Archive"' "$CONFIG_PATH")
DB_USE_FOLDERS=$(jq --raw-output '.DB_USE_FOLDERS // true' "$CONFIG_PATH")
DB_FILENAME_FORMAT=$(jq --raw-output '.DB_FILENAME_FORMAT // "%Y%m%d_%H%M%S"' "$CONFIG_PATH")
DB_INCLUDE_SYSTEM=$(jq --raw-output '.DB_INCLUDE_SYSTEM // false' "$CONFIG_PATH")
DB_SEPARATE_FILES=$(jq --raw-output '.DB_SEPARATE_FILES // false' "$CONFIG_PATH")

OUTPUT_FOLDER="$DB_BACKUPDIR"
ARCHIVE_FOLDER="$OUTPUT_FOLDER/$DB_ARCHIVEDIR"

TIMESTP_LOG=$(date +"%Y%m%d%H%M")

echo "$TIMESTP_LOG [INFO] Starting MariaDB dump process..."

# Detect compression tool
if command -v pigz >/dev/null 2>&1; then
    COMPRESS_CMD="pigz"
    echo "$TIMESTP_LOG [INFO] Using pigz for parallel compression"
else
    COMPRESS_CMD="gzip"
    echo "$TIMESTP_LOG [INFO] Using gzip (install pigz in Dockerfile for faster compression)"
fi

# Validate backup directory exists
if [ ! -d "$OUTPUT_FOLDER" ]; then
  echo "$TIMESTP_LOG [ERROR] Backup directory does not exist: $OUTPUT_FOLDER"
  echo "$TIMESTP_LOG [ERROR] Ensure the path is correct and the mount is connected."
  exit 1
fi

# Validate backup directory is writable
if [ ! -w "$OUTPUT_FOLDER" ]; then
  echo "$TIMESTP_LOG [ERROR] Backup directory is not writable: $OUTPUT_FOLDER"
  exit 1
fi

# Validate filename format
TIMESTAMP=$(date +"$DB_FILENAME_FORMAT" 2>&1)
if [ $? -ne 0 ]; then
  echo "$TIMESTP_LOG [ERROR] Invalid filename format: $DB_FILENAME_FORMAT"
  echo "$TIMESTP_LOG [ERROR] Format error: $TIMESTAMP"
  exit 1
fi

# Create archive folder if using folders
if [ "$DB_USE_FOLDERS" = "true" ]; then
  if [ ! -d "$ARCHIVE_FOLDER" ]; then
    echo "$TIMESTP_LOG [INFO] Creating archive directory: $ARCHIVE_FOLDER"
    mkdir -p "$ARCHIVE_FOLDER"
  fi
fi

# Get the list of databases
DATABASES=$(mariadb --skip-ssl -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "SHOW DATABASES;" 2>/dev/null | tail -n +2)

if [ -z "$DATABASES" ]; then
  echo "$TIMESTP_LOG [ERROR] Could not retrieve database list. Check credentials and connection."
  exit 1
fi

# Determine backup mode
# Mode 1: DB_INCLUDE_SYSTEM=false -> dump each non-system DB separately
# Mode 2: DB_INCLUDE_SYSTEM=true AND DB_SEPARATE_FILES=false -> one file with all DBs
# Mode 3: DB_INCLUDE_SYSTEM=true AND DB_SEPARATE_FILES=true -> dump each DB separately (including system)

if [ "$DB_INCLUDE_SYSTEM" = "true" ] && [ "$DB_SEPARATE_FILES" != "true" ]; then
  # Mode 2: Single file with all databases
  OUTPUT_FILE="$OUTPUT_FOLDER/all_databases_backup_${TIMESTAMP}.sql.gz"
  echo "$TIMESTP_LOG [INFO] Backing up ALL databases to single file -> $OUTPUT_FILE"

  if mariadb-dump --skip-ssl --single-transaction --quick --events --routines --triggers \
    -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" --all-databases 2>/dev/null | $COMPRESS_CMD > "$OUTPUT_FILE"; then
    echo "$TIMESTP_LOG [SUCCESS] Full database backup completed."
  else
    echo "$TIMESTP_LOG [ERROR] Failed to back up databases."
    rm -f "$OUTPUT_FILE"
    exit 1
  fi
else
  # Mode 1 or 3: Individual database files
  for DB in $DATABASES; do
    # Skip system databases if DB_INCLUDE_SYSTEM is false
    if [ "$DB_INCLUDE_SYSTEM" != "true" ]; then
      if [[ "$DB" == "information_schema" || "$DB" == "performance_schema" || "$DB" == "mysql" || "$DB" == "sys" ]]; then
        echo "$TIMESTP_LOG [INFO] Skipping system database: $DB"
        continue
      fi
    fi

    OUTPUT_FILE="$OUTPUT_FOLDER/${DB}_backup_${TIMESTAMP}.sql.gz"
    echo "$TIMESTP_LOG [INFO] Backing up database: $DB -> $OUTPUT_FILE"

    if mariadb-dump --skip-ssl --single-transaction --quick --events --routines --triggers \
      -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB" 2>/dev/null | $COMPRESS_CMD > "$OUTPUT_FILE"; then
      echo "$TIMESTP_LOG [SUCCESS] Database $DB backed up successfully."
    else
      echo "$TIMESTP_LOG [ERROR] Failed to back up database $DB."
      rm -f "$OUTPUT_FILE"
    fi
  done
fi

# Housekeeping based on folder mode
if [ "$DB_USE_FOLDERS" = "true" ]; then
  # Move files older than DB_NORMAL_RETENTION_DAYS to archive
  echo "$TIMESTP_LOG [INFO] Moving old backups to $DB_ARCHIVEDIR..."
  find "$OUTPUT_FOLDER" -maxdepth 1 -type f -name '*.sql.gz' -mtime +$DB_NORMAL_RETENTION_DAYS -print -exec mv {} "$ARCHIVE_FOLDER/" \; | while read -r file; do
    echo "$TIMESTP_LOG [MOVED] $file -> $DB_ARCHIVEDIR/"
  done

  # Delete files in archive older than DB_RETENTION_DAYS
  echo "$TIMESTP_LOG [INFO] Cleaning $DB_ARCHIVEDIR (files older than $DB_RETENTION_DAYS days)..."
  find "$ARCHIVE_FOLDER" -type f -name '*.sql.gz' -mtime +$DB_RETENTION_DAYS -print -delete | while read -r file; do
    echo "$TIMESTP_LOG [DELETED] $file"
  done
else
  # Flat mode: just delete everything older than DB_RETENTION_DAYS
  echo "$TIMESTP_LOG [INFO] Cleaning old backups (files older than $DB_RETENTION_DAYS days)..."
  find "$OUTPUT_FOLDER" -maxdepth 1 -type f -name '*.sql.gz' -mtime +$DB_RETENTION_DAYS -print -delete | while read -r file; do
    echo "$TIMESTP_LOG [DELETED] $file"
  done
fi


# Remove empty directories
find "$OUTPUT_FOLDER" -mindepth 1 -maxdepth 1 -type d -empty -delete 2>/dev/null || true

echo "$TIMESTP_LOG [INFO] Backup process completed."
