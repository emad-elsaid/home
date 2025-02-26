#!/bin/bash

DEST_DIR="/sync"
MOUNT_POINT="/mnt/camera"
PROCESSED_DEVICES="/app/processed_devices.txt"

echo "Starting camera sync service for USB Mass Storage mode..."

# Create mount point and processed devices file
mkdir -p $MOUNT_POINT
touch $PROCESSED_DEVICES


# Function for logging
log() {
  echo "$(date): $1"
}

while true; do
  # Find removable devices using proper formatting options
  # This gives us just the device names of removable partitions
  removable_partitions=$(lsblk -ln -o NAME,RM,TYPE | awk '$2 == 1 && $3 == "part" {print $1}')

  for partition in $removable_partitions; do
    device="/dev/$partition"

    # Check if we've already processed this device in this session
    if ! grep -q "$device" $PROCESSED_DEVICES; then
      log "New USB storage device detected: $device"

      # Try to mount the partition
      if mount -t auto $device $MOUNT_POINT; then
        log "Storage device mounted at $MOUNT_POINT, checking for camera content..."

        # Check if this looks like a camera (has DCIM directory)
        if [ -d "$MOUNT_POINT/DCIM" ]; then
          log "Camera storage detected, starting sync..."

          # Directly sync to destination directory
          rsync -avP --progress "$MOUNT_POINT/DCIM/" "$DEST_DIR/"

          log "Sync complete"

          # Ensure all writes are complete
          sync

          # Add to processed devices list
          echo "$device" >> $PROCESSED_DEVICES
        else
          log "Not a camera storage device. Unmounting..."
        fi

        umount $MOUNT_POINT
      fi
    fi
  done

  sleep 5
done
