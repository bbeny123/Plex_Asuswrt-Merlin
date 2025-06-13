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
  mount | grep -q "$CHROOT_DIR"
}

mount_ext() {
  for dir in /mnt/*; do
    { [ -d "$dir" ] && mountpoint -q "$dir"; } || continue

    dir=$(readlink -f "$dir")
    [ "${CHROOT_DIR#"$dir/"}" != "$CHROOT_DIR" ] && continue

    target_dir="$CHROOT_DIR/mnt/$(basename "$dir")"
    mountpoint -q "$target_dir" && continue

    mkdir -p "$target_dir" && mount -o bind "$dir" "$target_dir"
  done
}

start() {
  if running; then
    echo "Chroot'ed services seems to be already started, exiting..."
    return 0
  fi

  logger "Starting Debian..."

  rm -rf "$CHROOT_DIR/opt/tmp/" "$CHROOT_DIR/tmp/" 2>/dev/null
  mkdir -p "$CHROOT_DIR/opt/tmp" "$CHROOT_DIR/tmp"

  for dir in dev proc sys; do
    target_dir="$CHROOT_DIR/$dir"
    mountpoint -q "$target_dir" && continue
    mkdir -p "$target_dir" && mount -o bind "/$dir" "$target_dir"
  done

  mount_ext

  echo "Starting chroot'ed Debian services..."

  grep -Ev '^\s*($|#)' "$CHROOT_SERVICES_LIST" | while IFS= read -r service; do
    chroot "$CHROOT_DIR" "/etc/init.d/$service" start
  done

  echo "Debian started" && logger "Debian started"
}

stop() {
  if ! running; then
    echo "Chroot'ed services already stopped"
    return 0
  fi

  logger "Stopping Debian..."

  echo "Stopping chroot'ed Debian services..."

  grep -Ev '^\s*($|#)' "$CHROOT_SERVICES_LIST" | while IFS= read -r service; do
    chroot "$CHROOT_DIR" "/etc/init.d/$service" stop
    sleep 1
  done

  awk -v dir="$CHROOT_DIR" '$2 ~ dir { print $2 }' /proc/mounts | sort -r | xargs -d '\n' -r umount -l

  echo "Debian stopped" && logger "Debian stopped"
}

restart() {
  stop
  start
}

enter() {
  running || start

  if ! mountpoint -q "$CHROOT_DIR/dev/pts"; then
    mount -o bind "/dev/pts" "$CHROOT_DIR/dev/pts"
  fi

  chroot "$CHROOT_DIR" "/bin/bash"

  if mountpoint -q "$CHROOT_DIR/dev/pts"; then
    umount "$CHROOT_DIR/dev/pts"
  fi
}

postmount() {
  if [ -n "$1" ] && [ "${CHROOT_DIR#"$1/"}" != "$CHROOT_DIR" ]; then
    start
  else
    mount_ext
    logger "Debian - missing external drives mounted"
  fi
}

unmount() {
  if [ -n "$1" ] && [ "${CHROOT_DIR#"$1/"}" != "$CHROOT_DIR" ]; then
    stop
  fi
}

status() {
  running && echo "Chroot'ed services: RUNNING" || echo "Chroot'ed services: STOPPED"
}

case "$1" in
start | stop | restart | enter | status)
  "$1"
  ;;
postmount | unmount)
  "$1" "$2"
  ;;
*)
  echo "Usage: (start|stop|restart|enter|status)"
  exit 1
  ;;
esac

exit 0
