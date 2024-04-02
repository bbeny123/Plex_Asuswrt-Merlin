#!/bin/sh

PATH=/opt/bin:/opt/sbin:/sbin:/bin:/usr/sbin:/usr/bin

CHROOT_DIR=$(readlink -f /opt/debian)
CHROOT_SERVICES_LIST=/opt/etc/chroot-services.list

if [ ! -e "$CHROOT_SERVICES_LIST" ]; then
  echo "Please, define Debian services to start in $CHROOT_SERVICES_LIST first!"
  echo "One service per line. Hint: this is a script names from Debian's /etc/init.d/"
  exit 1
fi

running() {
  if [ $(mount | grep $CHROOT_DIR | wc -l) -gt 0 ]; then 
    return 0
  fi

  return 1  
}

mount_int() {
  mkdir -p $CHROOT_DIR/opt/tmp

  for dir in dev proc sys opt/tmp; do
    if ! mountpoint -q $CHROOT_DIR/$dir; then
      mount -o bind /$dir $CHROOT_DIR/$dir
    fi
  done
}

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
  if running; then
    echo "Chroot'ed services seems to be already started, exiting..."
    exit 1
  fi
  
  mount_int
  mount_ext

  echo "Starting chroot'ed Debian services..."

  for item in $(cat $CHROOT_SERVICES_LIST); do
    chroot $CHROOT_DIR /etc/init.d/$item start
  done
}

stop() {
  if ! running; then
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
  if ! running; then
    start
  fi

  if ! mountpoint -q $CHROOT_DIR/dev/pts; then
    mount -o bind /dev/pts $CHROOT_DIR/dev/pts
  fi

  chroot $CHROOT_DIR /bin/bash

  if mountpoint -q $CHROOT_DIR/dev/pts; then
    umount $CHROOT_DIR/dev/pts
  fi
}

status() {
  if running; then
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
