#!/bin/sh

PATH=/opt/bin:/opt/sbin:/sbin:/bin:/usr/sbin:/usr/bin

CHROOT_DIR=$(readlink -f /opt/debian)
CHROOT_SERVICES_LIST=/opt/etc/chroot-services.list

if [ ! -e "$CHROOT_SERVICES_LIST" ]; then
  echo "Please, define Debian services to start in $CHROOT_SERVICES_LIST first!"
  echo "One service per line. Hint: this is a script names from Debian's /etc/init.d/"
  exit 1
fi

mount_ext() {
  for dir in /mnt/*; do
    dir=$(readlink -f $dir)/
    if ! echo "$CHROOT_DIR" | grep -q ^$dir; then
      target_dir=$CHROOT_DIR/mnt/$(echo "$dir" | sed 's!^.*mnt/!!')
      mkdir -p $target_dir
      if ! mountpoint -q $target_dir; then
        mount -o bind $dir $target_dir
      fi
    fi
  done
}

start() {
  if [ $(mount | grep $CHROOT_DIR | wc -l) -gt 0 ]; then
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
  if [ $(mount | grep $CHROOT_DIR | wc -l) -eq 0 ]; then
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
      mount -o bind /$dir $CHROOT_DIR/$dir
    fi
  done

  chroot $CHROOT_DIR /bin/bash
}

status() {
  if [ $(mount | grep $CHROOT_DIR | wc -l) -gt 0 ]; then
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
