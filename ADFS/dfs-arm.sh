wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.10.7.tar.xz
tar -xf linux-6.10.7.tar.xz
cd linux-6.10.7
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- dtbs
sudo apt-get install gcc-arm-linux-gnueabihf
make ARCH=arm defconfig
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- dtbs
mkdir ~/dfs-arm
mv zImage ~/dfs-arm
wget https://busybox.net/downloads/busybox-1.36.1.tar.bz2
tar xjf busybox-1.36.1.tar.bz2
cd busybox-1.36.1
echo "Select Build static binary (no shared libs) (NEW)"
make menuconfig
make -j$(nproc)
mkdir ~/dfs-gui/initramfs
make CONFIG_PREFIX=/home/$USER/dfs-arm/initramfs install
cd ~/dfs-arm/initramfs
touch init
echo "#!/bin/sh

/bin/sh" >> init
cd ~/
wget https://raw.githubusercontent.com/spartrekus/links2/master/links-1.03.tar.gz
tar xzf links-1.03
cd links-1.03
./configure
make
sudo make install
find . -name 'links*' -type f
mkdir -p ~/dfs-arm/usr/bin/links/
mv links ~/dfs-arm/usr/bin/links/links
cd ~/dfs-arm/usr/bin/links/
chmod +x link
find . | cpio -o -H newc ../init.cpio
cd ..
dd if=/dev/zero of=boot.img bs=1M count=50
mkfs.vfat boot.img
mkdir BOOT-DFS
mount boot.img BOOT-DFS
cp zImage init.cpio BOOT-DFS
umount BOOT-DFS
cd ~/
mkdir -p ~/dfs-iso/iso/{boot,rootfs}
cp ~/dfs-arm/BOOT-DFS/zImage ~/dfs-iso/boot/
cp ~/dfs-arm/BOOT-DFS/init.cpio ~/dfs-iso/boot/
cp ~/dfs-arm/boot.img ~/dfs-iso/boot/
sudo apt-get install xorriso genisoimage
xorriso -as mkisofs \
    -r -V "DFS_Linux" \
    -b boot.syslinux \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -o ~/dfs-iso/dfs-linux.iso \
    ~/dfs-iso
