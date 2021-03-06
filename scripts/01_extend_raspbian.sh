#!/bin/bash -e
# Extends raspbian root partition

if [[ -z $1 ]]; then
    echo "Usage: $0 [SIZE_MB]"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo "This script should be run as root"
    exit 1
fi

IMG=raspbian_lite.img
EXTEND_MB=$1

echo "Extending raspbian root partition by ${EXTEND_MB}MB"

# Add zeros to image file
dd if=/dev/zero bs=1M count=${EXTEND_MB} >> image/${IMG}

# Attach loopback device
LOOP_DEV=`losetup -f --show -P image/${IMG}`
if [[ $? != 0 ]]; then
    echo "Error attaching loopback device"
    exit 1
else
    echo "Attached base loopback at: $LOOP_DEV"
fi

# Extend root partition
parted $LOOP_DEV resizepart 2 100%

# Resize ext file system
e2fsck -f -y ${LOOP_DEV}p2
resize2fs ${LOOP_DEV}p2

# Close loopback device
losetup -d $LOOP_DEV
echo "Closed loopback $LOOP_DEV"