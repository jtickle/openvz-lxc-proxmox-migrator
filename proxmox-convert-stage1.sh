#!/usr/bin/env bash

PRIVATE=/vz/private
WORKBASE=root@PROXMOX_HOST:/root/migrate/work

if [ $# -ne 1 ]; then
  echo "Usage: $0 <veid>"
  exit 1
fi

VEID=$1

WORK="$WORKBASE/$VEID"

if [ ! -d $PRIVATE/$1 ]; then
  echo "VEID $1 does not exist in $PRIVATE"
  exit 2
fi

# Copy everything except devices out so we can mess with it
rsync -av --delete --exclude=etc/udev/devices --exclude=dev "$PRIVATE/$1/" "$WORK/"

echo "Stage 1 complete in $WORK"
echo "Stop the container and run this again to get a clean snapshot"
echo "Then go to proxmox0 and run /root/migrate/proxmox-convert-stage2.sh $VEID"
