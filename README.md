# DFS Project
Create your own Distro From Scratch with DFS a Free-to-use guide on how to get started building your Linux Distro

# Chapter 1.0 : Installing Required Dependencies
* we will require a few dependencies to configure , build and use the kernel here are a few packages we may need
```bash
apt-get install bzip2 git vim make gcc libncurses-dev flex bison bc cpio libelf-dev libssl-dev syslinux dosfstools
```
if you get an error such as
```bash
xaruc@dfs-guide:~$ apt-get install bzip2 git vim make gcc libncurses-dev flex bison bc cpio libelf-dev libssl-dev syslinux dosfstools
E: Could not open lock file /var/lib/dpkg/lock-frontend - open (13: Permission denied)
E: Unable to acquire the dpkg frontend lock (/var/lib/dpkg/lock-frontend), are you root?
xaruc@dfs-guide:~$
```
you may need to run it with `sudo`
# Chapter 1.1 : Configuring The Kernel
* we first have to configure and compile the kernel this is (chapter 1.0-1.9) the simplest part of the entire book
* first you need to  fetch the latest kernel at the time writing it is `6.10.7`
* you need to clone the repository using `git` and enter the directory using `cd` here is how
```bash
git clone --depth 1 https://github.com/torvalds/linux.git
cd linux
```
* now you need to configure the kernel the simplest way is to run
```bash
make menuconfig
```

* the best things I recommend are adding Drivers to your distro and make sure they are selected as `*` not `M` `M` means module, After you have finished run the `make` command to build the kernel
```bash
make -j $(nproc)
```
* after the kernel finsihed building you will see a message looking similar to this
```bash
Kernel: arch/x86/boot/bzImage is ready (#1)
```
* this means the kernel has compiled, `bzImage` is the compiled kernel binary we will use it later to boot to the system lets create a directory lets call it for example `dfs-distro` and we will copy the `bzImage`/Kernel to the directory
```
mkdir ~/dfs-distro
cp -r arch/x86/boot/bzImage ~/dfs-distro
```
# Chapter 1.2 : The User Space
* we will use busybox as the user space, linux will be the kernel but we need some kind of user-space, we will use git for this operation
```bash
git clone --depth 1 https://git.busybox.net/busybox
cd busybox
```
* we are going to the same thing we did with the kernel by configuring `busybox`
```bash
make menuconfig
```
* first we are going to change a few settings in busybox you need to go to to `Settings` then you need to select `Build static binary (no shared libs) (NEW)` after that run hit `ESC` x2 times and hit `YES` to save the config
* now compile the kernel
```
make -j $(nproc)
```
* after busybox finsihed compiling we will create a new directory in the `~/dfs-distro` directory and we will call it `initramfs`
```
mkdir ~/dfs-distro/initramfs
```
* now we need to install it to the `initramfs` directory
```
make CONFIG_PREFIX=/home/$USER/dfs-distro/initramfs install
```
* `initramfs` is the initial file system the kernel loads after booting we will put `busybox` over there
* now enter that directory
```
cd ~/dfs-distro/initramfs
ls
```
* you will find 1 file and 3 directories
```
bin linuxrc sbin usr
```
* we will create another file called `init` which will load the shell proccess in the kernel, it will use the shell to use the shell its a little bit funny but thats what its going to do
```
touch init
echo "#!/bin/sh

/bin/sh" >> init
```
* also we can remove `linuxrc` no need for that file
```
rm linuxrc
```
* also add exec perms for `init`
```
chmod +x init
```
* we will use the find command to pack this into a `cpio` archive, we will pass find as `cpio` and pass it as a file called `init.cpio` which will be used in the above directory
```
find . | cpio -o -H newc ../init.cpio
```
* if you go one directory back you will find the `init.cpio` file, we will use the syslinux bootloader

# Chapter 1.3 : The Bootloader
* we will usea utility called `dd` which will allow us to create the bootloader
```
dd if=/dev/zero of=boot.img bs=1M count=50
ls
```
* you will find the bootloader has been created as the file called `boot`, now set the `boot` file to be a `fat` format
```
mkfs.vfat boot.img
```
* after running it will create a `fat` fs on the `boot` file now we need to enable `syslinux` on the `boot` file
```
syslinux boot.img
```
* we still need to copy the `init.cpio` and `bzImage` to the `syslinux` bootloader, we will create a new directory we will call it as `BOOTLOADER` so we will copy those files to the `BOOTLOADER` directory
```
mkdir BOOTLOADER
mount boot BOOTLOADER
cp bzImage init.cpio BOOTLOADER
```
* now you can unmount it
```
umount BOOTLOADER
```
you could finish here but if you want to create an ISO continue

# Chapter 2.0 : Creating the ISO
* Install the Necassary Packages we will need `xorriso` to create a new ISO format for our Image
```
sudo apt-get install xorriso genisoimage
```
* create a new directory for example `~/dfs-iso` and create these directories 
```
mkdir -p ~/dfs-iso/iso/{boot,rootfs}
```
* now copy Kernel and Initramfs and Syslinux:
```
cp ~/dfs-distro/BOOTLOADER/bzImage ~/dfs-iso/boot/
cp ~/dfs-distro/BOOTLOADER/init.cpio ~/dfs-iso/boot/
cp ~/dfs-distro/boot.img ~/dfs-iso/boot/
```
* Mount the FAT Image and copy Kernel and Initramfs to the Image:
```
mkdir ~/mnt/boot
sudo mount -o loop boot.img ~/mnt/boot
cp ~/dfs-iso/boot/bzImage ~/mnt/boot/
cp ~/dfs-iso/boot/initramfs.cpio ~/mnt/boot/
```
* Create Syslinux Configuration
```
touch ~/mnt/boot/boot/syslinux.cfg
echo 'DEFAULT linux
LABEL linux
    KERNEL bzImage
    INITRD initramfs.cpio
    APPEND root=/dev/ram0' | sudo tee ~/mnt/boot/syslinux.cfg
```
* Unmount
```
sudo umount ~/mnt/boot
```
* Create the ISO Image Using `xorriso`:
```
xorriso -as mkisofs \
    -r -V "DFS_Linux" \
    -b boot.syslinux \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -o ~/dfs-iso/dfs-linux.iso \
    ~/dfs-iso
```

