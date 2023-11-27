#!/bin/sh

DEBIAN_CHROOT_DIR=/opt/debian

DEBIAN_EXT_DIR1=/tmp/mnt/Beny/
DEBIAN_EXT_DIR1_TARGET=$DEBIAN_CHROOT_DIR/mnt/Beny/
DEBIAN_EXT_DIR2=/tmp/mnt/Beny-Kingston/
DEBIAN_EXT_DIR2_TARGET=$DEBIAN_CHROOT_DIR/mnt/Beny-Kingston/

DEBIAN_MOUNTED_DIR_COUNT="$(mount | grep $DEBIAN_CHROOT_DIR | wc -l)"

if [ $DEBIAN_MOUNTED_DIR_COUNT -gt 0 ]; then
	mkdir -p $DEBIAN_EXT_DIR1_TARGET
	if ! mountpoint -q $DEBIAN_EXT_DIR1_TARGET ; then
		mount -Br $DEBIAN_EXT_DIR1 $DEBIAN_EXT_DIR1_TARGET
	fi

	mkdir -p $DEBIAN_EXT_DIR2_TARGET
	if ! mountpoint -q $DEBIAN_EXT_DIR2_TARGET ; then
		mount -Br $DEBIAN_EXT_DIR2 $DEBIAN_EXT_DIR2_TARGET
	fi
fi
