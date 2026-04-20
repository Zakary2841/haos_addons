# 🧩 Home Assistant OS Add-ons by @dx edited by @Zakary2841

This repository contains custom add-ons for [Home Assistant OS](https://www.home-assistant.io/installation/). These tools extend the capabilities of your HA instance by integrating with cloud services, managing backups, and offering useful system utilities.

📦 All add-ons are built for **Home Assistant OS** and designed to run in lightweight Alpine or Debian-based containers.

---

## 📁 Add-ons Included

### 🔹 [MariaDB Backup](./mariadbbackup)

Create manual or scheduled `.sql` dumps of your MariaDB `homeassistant` database. Useful for maintaining regular backups.

- Dumps stored in in your config
- Reads DB credentials from configuration
- Output: `mariadb_backup_<date>.sql` - Configurable

🔗 [README](./mariadbbackup/README.md)

---

### 🔹 [Azure CLI (azcli)](./azcli)

Run Azure CLI (`az`) commands from within Home Assistant.

- Authenticate with a service principal or device login
- Schedule scripts or call via automations
- Based on official `mcr.microsoft.com/azure-cli`

🔗 [README](./azcli/README.md)

---

### 🔹 [Azure REST CLI (azrestcli)](./azrestcli)

Low-level add-on to execute raw Azure CLI requests using Rest Commands `curl`. 

- Uses `curl` + token file
- Works with ARM, MS Graph, AVD, etc.
- Easy automation integration

🔗 [README](./azrestcli/README.md)

---

### 🔹 [yt-dlp YouTube Downloader/Streamer](./ytdlp)

Download or stream YouTube videos or audio files via Home Assistant:

- `video` or `audio` -> download to `/media`
- `stream` -> play directly on a `media_player` (e.g., Nest Mini)
- Controlled via `rest_command` and `shell_command`

🔗 [README](./ytdlp/README.md)

---
