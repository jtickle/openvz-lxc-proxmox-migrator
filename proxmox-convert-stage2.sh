#!/usr/bin/env bash

MIGRATE=/var/lib/vz/template/cache
WORKBASE=/root/migrate/work
FILES=/root/migrate/files

if [ $# -ne 1 ]; then
  echo "Usage: $0 <veid>"
  exit 1
fi

VEID=$1

WORK=$WORKBASE/$VEID

# Remove mount for dev/shm
cp $WORK/etc/fstab $WORK/etc/fstab-vzbak
grep -v 'dev/shm' $WORK/etc/fstab-vzbak > $WORK/etc/fstab

# Remove start_udev
cp $WORK/etc/rc.sysinit $WORK/etc/rc.sysinit-vzbak
grep -v '/sbin/start_udev' $WORK/etc/rc.sysinit-vzbak > $WORK/etc/rc.sysinit

# Fix tty for consoles
cp $WORK/etc/securetty $WORK/etc/securetty-vzbak
cp $FILES/securetty $WORK/etc/securetty
for i in $(ls $WORK/etc/init/tty*.conf); do mv $WORK/etc/init/$i $WORK/root/$i-vzbak; done
cp $FILES/tty.conf $WORK/etc/init/tty.conf

# Add some LXC-related Init stuff
cp $FILES/lxc-halt $WORK/etc/init.d/lxc-halt
chmod +x $WORK/etc/init.d/lxc-halt
mkdir -p $WORK/etc/init
cp $FILES/lxc-sysinit.conf $WORK/etc/init/lxc-sysinit.conf
cp $FILES/power-status-changed.conf $WORK/etc/init/power-status-changed.conf
ln -sf ../init.d/lxc-halt $WORK/etc/rc.d/rc0.d/S00lxc-halt
ln -sf ../init.d/lxc-halt $WORK/etc/rc.d/rc6.d/S00lxc-reboot

# Fix default gateway
cp $WORK/etc/sysconfig/network $WORK/etc/sysconfig/network-vzbak
grep -v 'GATEWAYDEV' $WORK/etc/sysconfig/network-vzbak > $WORK/etc/sysconfig/network

# Backup SSH keys since proxmox will just overwrite them
mkdir -p $WORK/root/ssh_keys
for i in $(ls $WORK/etc/ssh/*key*); do mv "$i" "$WORK/root/ssh_keys/$(basename $i)"; done

tar cJvf $MIGRATE/$VEID.tar.xz -C $WORK .

echo "Stage 2 is  complete, $MIGRATE/$VEID.tar.xz ready to migrate"
