# Changelog
## 2.4.2
- Prints archived file to log for visibility

## 2.4.1
- Add pigz for faster compression on multicore systems

## 2.4
- Add immediate gzip compression (no more tar archival)
- Add DB_INCLUDE_SYSTEM option to backup system databases
- Add DB_SEPARATE_FILES option to control single vs multiple files when including system DBs
- Add DB_USE_FOLDERS toggle for archive folder structure
- Add DB_ARCHIVEDIR parameter for custom archive folder name
- Add DB_NORMAL_RETENTION_DAYS for two-tier retention
- Add DB_FILENAME_FORMAT for custom timestamp format
- Add input validation for backup directory, write permissions, and date format
- Add --single-transaction --quick --events --routines --triggers for complete consistent dumps
- Remove inefficient tar archival logic

## 2.3
- add more maps

## 2.2
- add retention days as var

## 2.1
- readme fixes

## 2.0
- Add variable for dump location

## 1.9
- housekeeping

## 1.0
- Initial release
