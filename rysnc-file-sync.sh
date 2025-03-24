#!/bin/bash

# CONFIGURATION
SRC_USER=""
SRC_HOST=""
SRC_PORT="22"
SRC_PASSWORD=""
SRC_PATH="/home1/$SRC_USER/"

DEST_USER=""
DEST_HOST=""
DEST_PORT="22"
DEST_PASSWORD=""
DEST_PATH="/home/$DEST_USER/"

LOCAL_TEMP_DIR="/home/thegrtnx/Documents/"
LOG_FILE="rsync_transfer.log"
MAX_RETRIES=5

# Exclude rules
EXCLUDE=(
    "--exclude=*.sql"
    "--exclude=wp-config.php"
    "--exclude=cpanel"
    "--exclude=mail"
    "--exclude=logs"
    "--exclude=tmp"
    "--exclude=.*"
    "--include=.htaccess"
    "--include=.env"
    "--exclude=backup_*"
    "--exclude=*.bak"
    "--exclude=*.tar"
    "--exclude=*.tar.gz"
    "--exclude=*.zip"
    "--exclude=*.gz"
     "--exclude=*/node_modules/"  # Exclude any node_modules folder in any directory
    "--exclude=*/images/"  # Exclude any images folder in any directory
    "--exclude=*/id_images/"  # Exclude any id_images folder in any directory
    "--exclude=*/upload/"  # Exclude any upload folder in any directory
    "--exclude=*/uploads/"  # Exclude any uploads folder in any directory
    "--exclude=*/activation_images/"  # Exclude any activation_images folder in any directory
    "--exclude=*/images/faces/"  # Exclude any images/faces folder in any directory
    "--exclude=*/images/idcard/" # Exclude any images/idcard folder in any directory
    "--exclude=*.mp4"         # Exclude mp4 files
    "--exclude=*.pdf"         # Exclude pdf files
    "--exclude=*.pptx"        # Exclude pptx files
    "--exclude=*.exe"         # Exclude exe files
    "--exclude=*.dmg"         # Exclude dmg files
)

# Function to close all existing SSH tunnels
close_existing_tunnels() {
    echo "🔻 Closing any existing SSH tunnels..."
    pkill -f "ssh -N -L"  # Close any existing SSH tunnels
    sleep 2
    echo "✅ All SSH tunnels closed."
}

# Function to sync files using a two-step approach (Local Pull → Remote Push)
sync_files() {
    local attempt=1

    # Ensure the local temporary directory exists
    mkdir -p "$LOCAL_TEMP_DIR"

    while [ $attempt -le $MAX_RETRIES ]; do
        echo "Attempt $attempt: Pulling files from source..." | tee -a "$LOG_FILE"

        sshpass -p "$SRC_PASSWORD" rsync -avzP --protocol=31 --partial --append-verify --ignore-existing \
            -e "ssh -p $SRC_PORT" \
            "${EXCLUDE[@]}" \
            --ignore-existing \
            "$SRC_USER@$SRC_HOST:$SRC_PATH" "$LOCAL_TEMP_DIR/" \
            | tee -a "$LOG_FILE"

        if [ $? -eq 0 ]; then
            echo "✅ Files successfully pulled from source!" | tee -a "$LOG_FILE"

            echo "🚀 Attempt $attempt: Pushing files to destination..." | tee -a "$LOG_FILE"
            sshpass -p "$DEST_PASSWORD" rsync -avzP --protocol=31 --partial --append-verify --ignore-existing \
                -e "ssh -p $DEST_PORT" \
                "${EXCLUDE[@]}" \
                --ignore-existing \
                "$LOCAL_TEMP_DIR/" "$DEST_USER@$DEST_HOST:$DEST_PATH" \
                | tee -a "$LOG_FILE"

            if [ $? -eq 0 ]; then
                echo "✅ Rsync completed successfully!" | tee -a "$LOG_FILE"
                return 0
            else
                echo "❌ Rsync to destination failed! Retrying in 30 seconds..." | tee -a "$LOG_FILE"
            fi
        else
            echo "❌ Rsync from source failed! Retrying in 30 seconds..." | tee -a "$LOG_FILE"
        fi

        sleep 30
        attempt=$((attempt + 1))
    done

    echo "❌ Maximum retry limit reached. Rsync failed." | tee -a "$LOG_FILE"
    return 1
}

# Start real-time sync
echo "🚀 Starting real-time file sync from $SRC_HOST to $DEST_HOST..." | tee -a "$LOG_FILE"

# Close any open tunnels before running rsync
close_existing_tunnels

# Ensure destination directory exists
sshpass -p "$DEST_PASSWORD" ssh -p "$DEST_PORT" "$DEST_USER@$DEST_HOST" "mkdir -p $DEST_PATH"

sync_files

# Watch for file changes
echo "🔄 Watching for file changes in real-time..."
while inotifywait -r -e modify,create,delete,move "$LOCAL_TEMP_DIR"; do
    sync_files
done
