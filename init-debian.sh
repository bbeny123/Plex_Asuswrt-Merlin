#!/bin/sh

PATH=/opt/bin:/opt/sbin:/sbin:/bin:/usr/sbin:/usr/bin

CHROOT_DIR=/opt/debian
CHROOT_SERVICES_LIST=/opt/etc/chroot-services.list

EXT_DIR1=/tmp/mnt/Beny/
EXT_DIR1_TARGET=$CHROOT_DIR/mnt/Beny/
EXT_DIR2=/tmp/mnt/Beny-Kingston/
EXT_DIR2_TARGET=$CHROOT_DIR/mnt/Beny-Kingston/

if [ ! -e "$CHROOT_SERVICES_LIST" ]; then
	echo "Please, define Debian services to start in $CHROOT_SERVICES_LIST first!"
	echo "One service per line. Hint: this is a script names from Debian's /etc/init.d/"
	exit 1
fi

MountedDirCount="$(mount | grep $CHROOT_DIR | wc -l)"

mount_ext() {
	if [ ! -z "$EXT_DIR1" ] && [ ! -z "$EXT_DIR1_TARGET" ]; then
		mkdir -p $EXT_DIR1_TARGET
		if ! mountpoint -q $EXT_DIR1_TARGET; then
			mount -Br $EXT_DIR1 $EXT_DIR1_TARGET
		fi
	fi

	if [ ! -z "$EXT_DIR2" ] && [ ! -z "$EXT_DIR2_TARGET" ]; then
		mkdir -p $EXT_DIR2_TARGET
		if ! mountpoint -q $EXT_DIR2_TARGET; then
			mount -Br $EXT_DIR2_TARGET
		fi
	fi
}

start() {
	if [ $MountedDirCount -gt 0 ]; then
		echo "Chroot'ed services seems to be already started, exiting..."
		exit 1
	fi

	echo "Starting chroot'ed Debian services..."

	for dir in dev proc sys; do
		mount -B /$dir $CHROOT_DIR/$dir
	done

	mount_ext

	for item in $(cat $CHROOT_SERVICES_LIST); do
		chroot $CHROOT_DIR /etc/init.d/$item start
	done
}

stop() {
	if [ $MountedDirCount -eq 0 ]; then
		echo "Chroot'ed services seems to be already stopped, exiting..."
		exit 1
	fi

	echo "Stopping chroot'ed Debian services..."

	for item in $(cat $CHROOT_SERVICES_LIST); do
		chroot $CHROOT_DIR /etc/init.d/$item stop
		sleep 2
	done

	if mountpoint -q $CHROOT_DIR/dev/pts; then
		umount $CHROOT_DIR/dev/pts
	fi

	mount | grep $CHROOT_DIR | awk '{print $3}' | xargs umount -l
}

restart() {
	stop
	start
}

enter() {
	mount_ext

	for dir in dev dev/pts proc sys; do
		if ! mountpoint -q $CHROOT_DIR/$dir; then
			mount -B /$dir $CHROOT_DIR/$dir
		fi
	done

	chroot $CHROOT_DIR /bin/bash
}

status() {
	if [ $MountedDirCount -gt 0 ]; then
		echo "Chroot'ed services running..."
	else
		echo "Chroot'ed services not running!"
	fi
}

case "$1" in
start)
	start
	;;
stop)
	stop
	;;
restart)
	restart
	;;
enter)
	enter
	;;
status)
	status
	;;
*)
	echo "Usage: (start|stop|restart|enter|status)"
	exit 1
	;;
esac

echo Done.
exit 0
