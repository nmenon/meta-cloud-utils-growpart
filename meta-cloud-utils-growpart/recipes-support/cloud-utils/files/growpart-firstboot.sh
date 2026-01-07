#!/bin/bash
set -euo pipefail

DONE_FILE="/var/lib/growpart-firstboot.done"

log() {
  echo "growpart-firstboot: $*" >&2
}

trim_ws() {
  tr -d '[:space:]'
}

# Find root device
ROOT_SRC="$(findmnt -n -o SOURCE / 2>/dev/null || true)"
if [ -z "$ROOT_SRC" ]; then
  log "ERROR: cannot determine root source device"
  exit 0
fi

# Check if root is a partition
ROOT_TYPE="$(lsblk -no TYPE "$ROOT_SRC" 2>/dev/null | head -n1 | trim_ws || true)"
if [ "$ROOT_TYPE" != "part" ]; then
  log "root is not a partition (type=$ROOT_TYPE); skipping resize"
  mkdir -p "$(dirname "$DONE_FILE")" && : > "$DONE_FILE"
  exit 0
fi

# Get parent disk and partition number
DISK_BASENAME="$(lsblk -no PKNAME "$ROOT_SRC" 2>/dev/null | head -n1 | trim_ws || true)"
if [ -z "$DISK_BASENAME" ]; then
  log "ERROR: cannot determine parent disk for $ROOT_SRC"
  exit 0
fi
DISK="/dev/$DISK_BASENAME"

PARTNUM="$(lsblk -no PARTN "$ROOT_SRC" 2>/dev/null | head -n1 | trim_ws || true)"
if [ -z "$PARTNUM" ] || ! [[ "$PARTNUM" =~ ^[0-9]+$ ]]; then
  log "ERROR: invalid partition number '$PARTNUM' for $ROOT_SRC"
  exit 0
fi

log "detected: disk=$DISK partition=$PARTNUM device=$ROOT_SRC"

# 1. Grow Partition
GROWPART_SUCCESS=0
log "running: growpart $DISK $PARTNUM"
if growpart "$DISK" "$PARTNUM"; then
  GROWPART_SUCCESS=1
  log "growpart succeeded"
else
  GROWPART_RC=$?
  if [ "$GROWPART_RC" -eq 1 ]; then
    GROWPART_SUCCESS=1
    log "growpart: no change needed (already at max size)"
  else
    log "ERROR: growpart failed with exit code $GROWPART_RC"
  fi
fi

# 2. Resize Filesystem (only if partition step was okay)
FS_SUCCESS=0
if [ "$GROWPART_SUCCESS" -eq 1 ]; then
  partprobe "$DISK" 2>/dev/null || true
  [ -x /sbin/udevadm ] && udevadm settle 2>/dev/null || true
  sleep 1

  FSTYPE="$(findmnt -n -o FSTYPE / 2>/dev/null | head -n1 | trim_ws || true)"
  if [[ "$FSTYPE" =~ ^ext[234]$ ]]; then
    log "resizing $FSTYPE filesystem on $ROOT_SRC"
    if resize2fs "$ROOT_SRC"; then
      log "resize2fs succeeded"
      FS_SUCCESS=1
    else
      log "ERROR: resize2fs failed"
    fi
  else
    log "fstype=$FSTYPE is not ext2/3/4; skipping filesystem resize"
    FS_SUCCESS=1
  fi
fi

# 3. Finalize
if [ "$GROWPART_SUCCESS" -eq 1 ] && [ "$FS_SUCCESS" -eq 1 ]; then
  log "all steps completed successfully; marking as done"
  mkdir -p "$(dirname "$DONE_FILE")" && : > "$DONE_FILE"
  exit 0
else
  log "ERROR: one or more steps failed; will retry on next boot"
  exit 1
fi
