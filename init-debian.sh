#!/bin/sh

PATH=/opt/bin:/opt/sbin:/sbin:/bin:/usr/sbin:/usr/bin

# Folder with Debian

CHROOT_DIR=##CHROOT_DIR##

##EXT_DIR1##
##EXT_DIR1_TARGET##
##EXT_DIR2##
##EXT_DIR2_TARGET##

CHROOT_SERVICES_LIST=/opt/etc/chroot-services.list

if [ ! -e "$CHROOT_SERVICES_LIST" ]; then
    echo "Please, define Debian services to start in $CHROOT_SERVICES_LIST first!"
    echo "One service per line. Hint: this is a script names from Debian's /etc/init.d/"
    exit 1
fi

MountedDirCount="$(mount | grep $CHROOT_DIR | wc -l)"

start() {
    if [ $MountedDirCount -gt 0 ]; then
        echo "Chroot'ed services seems to be already started, exiting..."
        exit 1
    fi

    echo "Starting chroot'ed Debian services..."

    for dir in dev proc sys; do
        mount -o bind /$dir $CHROOT_DIR/$dir
    done
	
	if [ ! -z "$EXT_DIR1" ] && [ ! -z "$EXT_DIR1_TARGET" ]; then
		mkdir -p $CHROOT_DIR/$EXT_DIR1_TARGET		
		mount -o bind $EXT_DIR1 $CHROOT_DIR/$EXT_DIR1_TARGET
	fi
	
	if [ ! -z "$EXT_DIR2" ] && [ ! -z "$EXT_DIR2_TARGET" ]; then
		mkdir -p $CHROOT_DIR/$EXT_DIR2_TARGET		
		mount -o bind $EXT_DIR2 $CHROOT_DIR/$EXT_DIR2_TARGET
	fi

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

    umount /opt/debian/dev/pts

    mount | grep $CHROOT_DIR | awk '{print $3}' | xargs umount -l
}

restart() {
    if [ $MountedDirCount -eq 0 ]; then
        echo "Chroot'ed services seems to be already stopped"
        start
    else
        echo "Stopping chroot'ed Debian services..."

        for item in $(cat $CHROOT_SERVICES_LIST); do
            chroot $CHROOT_DIR /etc/init.d/$item stop
            sleep 2
        done

        mount | grep $CHROOT_DIR | awk '{print $3}' | xargs umount -l

        echo "Restarting chroot'ed Debian services..."

        for dir in dev proc sys; do
            mount -o bind /$dir $CHROOT_DIR/$dir
        done
	
		if [ ! -z "$EXT_DIR1" ] && [ ! -z "$EXT_DIR1_TARGET" ]; then
			mkdir -p $CHROOT_DIR/$EXT_DIR1_TARGET		
			mount -o bind $EXT_DIR1 $CHROOT_DIR/$EXT_DIR1_TARGET
		fi
		
		if [ ! -z "$EXT_DIR2" ] && [ ! -z "$EXT_DIR2_TARGET" ]; then
			mkdir -p $CHROOT_DIR/$EXT_DIR2_TARGET		
			mount -o bind $EXT_DIR2 $CHROOT_DIR/$EXT_DIR2_TARGET
		fi

        for item in $(cat $CHROOT_SERVICES_LIST); do
            chroot $CHROOT_DIR /etc/init.d/$item start
        done
    fi
}

enter() {	
	if [ ! -z "$EXT_DIR1" ] && [ ! -z "$EXT_DIR1_TARGET" ]; then
		mkdir -p $CHROOT_DIR/$EXT_DIR1_TARGET		
		mount -o bind $EXT_DIR1 $CHROOT_DIR/$EXT_DIR1_TARGET
	fi
	
	if [ ! -z "$EXT_DIR2" ] && [ ! -z "$EXT_DIR2_TARGET" ]; then
		mkdir -p $CHROOT_DIR/$EXT_DIR2_TARGET		
		mount -o bind $EXT_DIR2 $CHROOT_DIR/$EXT_DIR2_TARGET
	fi

    mount -o bind /dev/ /opt/debian/dev/
    mount -o bind /dev/pts /opt/debian/dev/pts
    mount -o bind /proc/ /opt/debian/proc/
    mount -o bind /sys/ /opt/debian/sys/

    chroot /opt/debian /bin/bash
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
