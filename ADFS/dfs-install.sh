#!/bin/sh
echo "This is an installer for DFS Based distros"

# Variables
DISK="/dev/sda"
BOOT_PARTITION="${DISK}1"
ROOT_PARTITION="${DISK}2"
MOUNT_POINT="/mnt"
ROOTFS_TARBALL="/rootfs.tar.gz"
KERNEL_IMAGE="/boot/init.cpio"     # If you are creating an ARM DFS distro please replace bzImage with zImage
INITRD_IMAGE="/boot/init.cpio"  # Adjust this if you have an initrd image

echo "Partitioning the disk..."
fdisk $DISK <<EOF
o      # Create a new DOS partition table
n      # Add a new partition
p      # Primary partition
1      # Partition number
        # Default - start at beginning of disk 
+500M  # Boot partition size
n      # Add a new partition
p      # Primary partition
2      # Partition number
        # Default - start immediately after the previous partition
        # Default - extend to the end of the disk
a      # Make a partition bootable
1      # Mark the boot partition
w      # Write the changes to disk
EOF

echo "Formatting the partitions..."
/usr/sbin/mkfs.ext4 $BOOT_PARTITION
/usr/sbin/mkfs.ext4 $ROOT_PARTITION

echo "Mounting the partitions..."
mkdir -p $MOUNT_POINT
mount $ROOT_PARTITION $MOUNT_POINT
mkdir -p $MOUNT_POINT/boot
mount $BOOT_PARTITION $MOUNT_POINT/boot

echo "Extracting the root filesystem..."
/usr/sbin/tar -xzf $ROOTFS_TARBALL -C $MOUNT_POINT

echo "Entering the new root environment with chroot..."
/usr/bin/chroot $MOUNT_POINT /bin/sh <<EOF_CHROOT

echo "Installing GRUB..."
/usr/sbin/grub-install --target=i386-pc --boot-directory=/boot $DISK

echo "Generating GRUB configuration..."
/usr/sbin/grub-mkconfig -o /boot/grub/grub.cfg

echo '
set default=0
set timeout=5

insmod ext2

set root=(hd0,msdos1)

menuentry "DFS-Based OS" {
    linux /bzImage root=/dev/sda1

    initrd /initrd.img
}
' >> /boot/grub/grub.cfg

echo "Configuring fstab..."
cat <<EOF > /etc/fstab
$ROOT_PARTITION  /               ext4    defaults        1 1
$BOOT_PARTITION  /boot           ext4    defaults        1 2
EOF

EOF_CHROOT

echo "Installation complete. Unmounting and rebooting..."
umount $MOUNT_POINT/boot
umount $MOUNT_POINT
reboot
