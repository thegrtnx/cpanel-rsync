# Rsync File Sync Script

## Overview
This Bash script automates the secure and efficient synchronization of files between two remote servers using `rsync`. It employs a two-step approach:

1. **Pull** files from the source server to a local temporary directory.
2. **Push** files from the local temporary directory to the destination server.

The script also supports real-time file synchronization using `inotifywait`.

---

## Features
- Secure file transfer using SSH and `rsync`.
- Exclusion of sensitive and unnecessary files (e.g., `.sql`, `wp-config.php`, `.env`).
- Automatic retry mechanism with a configurable maximum retry limit.
- Logs all transfer activities to `rsync_transfer.log`.
- Supports real-time file change detection and synchronization.
- Closes existing SSH tunnels before initiating a new transfer.

---

## Configuration
Edit the script to provide necessary server credentials and settings:

### **Source Server Configuration**
```bash
SRC_USER="your_source_username"
SRC_HOST="your.source.server"
SRC_PORT="22"
SRC_PASSWORD="your_source_password"
SRC_PATH="/home1/$SRC_USER/"
```

### **Destination Server Configuration**
```bash
DEST_USER="your_destination_username"
DEST_HOST="your.destination.server"
DEST_PORT="22"
DEST_PASSWORD="your_destination_password"
DEST_PATH="/home/$DEST_USER/"
```

### **Local Temporary Directory**
```bash
LOCAL_TEMP_DIR="/tmp/rsync_temp"
LOG_FILE="rsync_transfer.log"
MAX_RETRIES=5
```

### **Exclude Rules**
The script excludes specific files and directories during transfer to ensure secure and efficient syncing:
```bash
EXCLUDE=(
    "--exclude=*.sql"
    "--exclude=wp-config.php"
    "--exclude=.env"
    "--exclude=cpanel"
    "--exclude=mail"
    "--exclude=logs"
    "--exclude=tmp"
    "--exclude=.*"
    "--include=.htaccess"
    "--exclude=backup_*"
    "--exclude=*.bak"
    "--exclude=*.tar"
    "--exclude=*.tar.gz"
    "--exclude=*.zip"
    "--exclude=*.gz"
)
```

---

## Usage
### 1. **Grant Execute Permission**
Before running the script, ensure it has execute permissions:
```bash
chmod +x sync_script.sh
```

### 2. **Run the Script**
Execute the script to start the synchronization process:
```bash
./sync_script.sh
```

### 3. **Real-time Syncing**
The script continuously monitors file changes and syncs them in real-time using `inotifywait`.

---

## Error Handling & Logs
- The script attempts **up to 5 retries** before giving up on a failed transfer.
- Logs are recorded in `rsync_transfer.log` for debugging.
- Failed attempts will trigger a 30-second delay before retrying.

---

## Dependencies
Ensure the following packages are installed on your system:
```bash
sudo apt update && sudo apt install rsync sshpass inotify-tools -y
```

---

## License
This script is open-source and free to use. Modify it as per your needs.
