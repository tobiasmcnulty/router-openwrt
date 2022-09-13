#!/bin/bash

set -ex

MOUNT_POINT=$(mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir')

unmount () {
    sudo umount $MOUNT_POINT || true
    [[ -z $DEV ]] || (sudo losetup -d $DEV || true)
}
# always umount & detach loopback device in case of error
trap unmount ERR

shopt -s nullglob
for image in "$@"; do
    gunzip --force --keep $image || true

    filename=$(basename -- "$image")
    filename_no_gz="${filename%.*}" # remove '.gz'
    extension="${filename_no_gz##*.}" # get '.img'
    filename_no_img="${filename_no_gz%.*}" # remove '.img'

    new_image="$(dirname $image)/$filename_no_img-no-serial.$extension"
    mv $(dirname $image)/$filename_no_gz $new_image

    DEV=$(sudo losetup --find)

    sudo losetup --partscan $DEV $new_image
    sudo mount ${DEV}p1 $MOUNT_POINT

    cat $MOUNT_POINT/boot/grub/grub.cfg
    sudo sed -i 's/console=ttyS0,115200n8//' $MOUNT_POINT/boot/grub/grub.cfg
    cat $MOUNT_POINT/boot/grub/grub.cfg

    unmount

    gzip --force $new_image
done
