apt-get install bzip2 git vim make gcc libncurses-dev flex bison bc cpio libelf-dev libssl-dev syslinux dosfstools
git clone --depth 1 https://github.com/torvalds/linux.git
cd linux
make -j $(nproc)
mkdir ~/dfs-distro
cp -r arch/x86/boot/bzImage ~/dfs-distro
git clone --depth 1 https://git.busybox.net/busybox
cd busybox
echo "While in the menu select 'Build static binary (no shared libs) (NEW)' "
sleep 5
make menuconfig
make -j $(nproc)
mkdir ~/dfs-distro/initramfs
cd ~/dfs-distro/initramfs
ls
touch init
echo "#!/bin/sh

/bin/sh" >> init
rm linuxrc
chmod +x init
find . | cpio -o -H newc ../init.cpio
cd ..
dd if=/dev/zero of=boot.img bs=1M count=50
ls
mkfs.vfat boot.img
syslinux boot.img
mkdir BOOTLOADER
mount boot BOOTLOADER
cp bzImage init.cpio BOOTLOADER
umount BOOTLOADER
apt-get install xorriso genisoimage
mkdir -p ~/dfs-iso/iso/{boot,rootfs}
cp ~/dfs-distro/BOOTLOADER/bzImage ~/dfs-iso/boot/
cp ~/dfs-distro/BOOTLOADER/init.cpio ~/dfs-iso/boot/
cp ~/dfs-distro/boot.img ~/dfs-iso/boot/
touch ~/mnt/boot/boot/syslinux.cfg
echo 'DEFAULT linux
LABEL linux
    KERNEL bzImage
    INITRD initramfs.cpio
    APPEND root=/dev/ram0' | sudo tee ~/mnt/boot/syslinux.cfg
    sudo umount ~/mnt/boot
    xorriso -as mkisofs \
    -r -V "DFS_Linux" \
    -b boot.syslinux \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -o ~/dfs-iso/dfs-linux.iso \
    ~/dfs-iso
echo "CLI Image Completed"
