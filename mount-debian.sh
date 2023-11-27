#!/bin/sh

CHROOT_DIR=$(readlink -f /opt/debian)

if [ $(mount | grep $CHROOT_DIR | wc -l) -gt 0 ]; then
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
fi
