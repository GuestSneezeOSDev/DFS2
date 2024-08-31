# DFS Project
Create your own Distro From Scratch with DFS a Free-to-use guide on how to get started building your Linux Distro

# Chapter 1.0 : Installing Required Dependencies
![newbie](https://img.shields.io/badge/Level%20Newbie-green)
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
* we first have to configure and compile the kernel this is (chapter 1.0-1.3) the simplest part of the entire book
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
![newbie](https://img.shields.io/badge/Level%20Newbie-green)
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

# Chapter 2.1 Further Beyond DFS: GUI
![Medium](https://img.shields.io/badge/Level%20Medium-yellow)
* We will discard the previous code since it will be useless, we need to install a few dependencies
```
apt install wget
apt install bzip2 libncurses-dev flex bison bc libelf-dev libssl-dev xz-utils autoconf gcc make libtool git vim libpng-dev libfreetype-dev g++ extlinux
```
* now download the kernel
```
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.10.tar.xz
tar xf linux-6.10.tar.xz
```
* now go to the kernel's folder and configure it
```
cd linux-6.10
make menuconfig
```
* Now we need to enable a few things find all of them
```
Device Drivers > Graphic Support > Cirrus drivers
Device Drivers > Graphic Support > Frame buffer devices > support for frame buffer devices
Device Drivers > Graphic Support > Bootup logo
```
* then hit `/` and type `mousedev` enable it, now we need to compile it so hit `ESC` x2 times hit `YES` then type
```
make -j $(nproc)
```
* now lets make a new directory we will call it `dfs-gui`
```
mkdir ~/dfs-gui
```
* we will copy the kernel to the Directory
```
cp arch/x86/boot/bzImage ~/dfs-gui
```
## Chapter 2.2 Further Beyond DFS: User-space
This is the simplest part of Further Beyond DFS
* we will now use a user-space called Busybox again
```
wget https://busybox.net/downloads/busybox-1.36.1.tar.bz2
tar xf busybox-1.36.1.tar.bz2
cd busybox-1.36.1
```
* Now configure busybox
```
make menuconfig
```
* Now select `Settings > build static library (No shared libs) (NEW) ` then hit `ESC` x2 times and select exit then compile it using
```
make -j$(nproc)
```
* Create a Config Prefix on where to install `busybox`
```
make CONFIG_PREFIX=/home/$USER/dfs-gui install
```
# Chapter 2.3 Further Beyond DFS : The Desktop Enviorment
we will use a Window Manager called Nano-X
```
git clone https://github.com/ghaerr/microwindows.git
cd microwindows
```
* Navigate to the `src/` folder and build The Microwindows/Nano-X Enviorment with the Linux Hardware buffer config
```
cd src/
cp Configs/config.linux-fb config
```
* Modify the Makefile to avoid issues
```
nano config # Change NX11 from N to Y
nano nx11/Makefile # Comment X11_INCULDE=$(X11HDRLOCATION) and Uncomment X11_INCLUDE=./x11-local
```
* Then run
```
make
make install
```

* Port an app : This is required so here is a demo
```
/* 
 
  hellox -- Hello world with Xlib.
 
  $(CC) -o hellox hellox.c -lX11 -L/usr/X11/lib
 
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
 
 
int main(argc,argv)
     int argc;
     char **argv;
{
  char hello[] = "Hello World!";
  char hi[] = "hi!";
 
  Display *mydisplay;
  Window  mywindow;
 
  GC      mygc;
  
  XEvent myevent;
  KeySym mykey;
  
  XSizeHints myhint;
  
  int myscreen;
  unsigned long myforeground, mybackground;
  int i;
  char text[10];
  int done;
 
  /* setup display/screen */
  mydisplay = XOpenDisplay("");
  
  myscreen = DefaultScreen(mydisplay);
 
  /* drawing contexts for an window */
  myforeground = BlackPixel(mydisplay, myscreen);
  mybackground = WhitePixel(mydisplay, myscreen);
  myhint.x = 200;
  myhint.y = 300;
  myhint.width = 350;
  myhint.height = 250;
  myhint.flags = PPosition|PSize;
 
  /* create window */
  mywindow = XCreateSimpleWindow(mydisplay, DefaultRootWindow(mydisplay),
                                 myhint.x, myhint.y,
                                 myhint.width, myhint.height,
                                 5, myforeground, mybackground);
 
  /* window manager properties (yes, use of StdProp is obsolete) */
  XSetStandardProperties(mydisplay, mywindow, hello, hello,
                         None, argv, argc, &myhint);
 
  /* graphics context */
  mygc = XCreateGC(mydisplay, mywindow, 0, 0);
  XSetBackground(mydisplay, mygc, mybackground);
  XSetForeground(mydisplay, mygc, myforeground);
 
  /* allow receiving mouse events */
  XSelectInput(mydisplay,mywindow,
               ButtonPressMask|KeyPressMask|ExposureMask);
 
  /* show up window */
  XMapRaised(mydisplay, mywindow);
 
  /* event loop */
  done = 0;
  while(done==0){
 
    /* fetch event */
    XNextEvent(mydisplay, &myevent);
 
    switch(myevent.type){
      
    case Expose:
      /* Window was showed. */
      if(myevent.xexpose.count==0)
        XDrawImageString(myevent.xexpose.display,
                         myevent.xexpose.window,
                         mygc, 
                         50, 50, 
                         hello, strlen(hello));
      break;
    case MappingNotify:
      /* Modifier key was up/down. */
      XRefreshKeyboardMapping(&myevent);
      break;
    case ButtonPress:
      /* Mouse button was pressed. */
      XDrawImageString(myevent.xbutton.display,
                       myevent.xbutton.window,
                       mygc, 
                       myevent.xbutton.x, myevent.xbutton.y,
                       hi, strlen(hi));
      break;
    case KeyPress:
      /* Key input. */
      i = XLookupString(&myevent, text, 10, &mykey, 0);
      if(i==1 && text[0]=='q') done = 1;
      break;
    }
  }
  
  /* finalization */
  XFreeGC(mydisplay,mygc);
  XDestroyWindow(mydisplay, mywindow);
  XCloseDisplay(mydisplay);
 
  exit(0);
}
```
* Then run `gcc gui.c -lNX11 -lnano-x && gcc gui.c -lNX11 -lnano-x -I /microwindows/src/nx11/X11-local/` to compile now move it to the `~/dfs-gui` dir by running
```
mv a.out ~/dfs-gui/x11app
```
* Now enter `bin` directory
```
cd microwindows/src/bin
# or cd bin/
``` 
* Run the LDD program to see the comipled libraries and create new directorys
```
ldd nano-X
mkdir -p /distro/lib/x86_64-linux-gnu/
mkdir /distro/lib64
```
* copy the neccassry files
```
cp /lib/x86_64-linux-gnu/libpng16.so.16 ~/dfs-gui/lib/x86_64-linux-gnu/libpng16.so.16
cp /lib/x86_64-linux-gnu/libz.so.1 ~/dfs-gui/lib/x86_64-linux-gnu/libz.so.1
cp /lib/x86_64-linux-gnu/libc.so.6 ~/dfs-gui/lib/x86_64-linux-gnu/libc.so.6
cp /lib/x86_64-linux-gnu/libm.so.6 ~/dfs-gui/lib/x86_64-linux-gnu/libm.so.6
cp /lib/x86_64-linux-gnu/libbrotlidec.so.1 ~/dfs-gui/lib/x86_64-linux-gnu/libbrotlidec.so.1
cp /lib64/ld-linux-x86-64.so.2 ~/dfs-gui/lib64/ld-linux-x86-64.so.2
```
* Now run those copy commands , copy the biniaries by copying the whole folder
```
cd ..
cp -r bin ~/dfs-gui/nanox
cd ..
cp runapp ~/dfs-gui/nanox
```
# Chapter 2.4 Further Beyond DFS : Bootloader & ISO
* Create the ISO Directory
```
mkdir -p ~/dfs-iso/{boot,grub}
```
* Copy linux kernel and other files:
```
cp ~/dfs-gui/bzImage ~/dfs-iso/boot/
cp -r ~/dfs-gui/{bin,lib,lib64,nanox,x11app,linuxrc,usr} ~/dfs-iso/
```
* Install GRUB
```
grub-mkrescue -o ~/dfs-iso/boot/grub/grub.cfg ~/dfs-iso
```
* Add the following to the `grub.cfg`
```
set default=0
set timeout=5

menuentry "DFS Distro with GUI" {
    linux /boot/bzImage root=/dev/sda rw
}
```
* Create the ISO Image
```
xorriso -as mkisofs -o ~/dfs-iso/dfs-gui.iso -b boot/grub/grub.cfg -no-emul-boot -boot-load-size 4 -boot-info-table -R -J -l ~/dfs-iso
```
* Test the ISO
```
qemu-system-x86_64 -cdrom ~/dfs-iso/dfs-gui.iso
```
If you get any issues create a new issue

# Chapter 3 Further Beyond DFS: How to port `xorg`
> ![IMPORTANT]
> Do not use this part yet since it is not ready and is in heavy development changes may occur

![Hard](https://img.shields.io/badge/Level%Hard-red) 
This is hard and we do not recommend this to beginners please make sure you have a good understanding of Unix , Linux and The Previous Chapters so you can get a better understanding of how you can do this

* Make sure you have the source code of the GUI ISO so you can continue

* First `wget` the source code and extract the src
```
wget https://www.x.org/releases/individual/xserver/xorg-server-21.1.2.tar.xz
tar -xzf https://www.x.org/releases/individual/xserver/xorg-server-21.1.2.tar.xz
```
* now install dependencies
```
sudo apt-get install build-essential libx11-dev libxext-dev libxau-dev libxdmcp-dev xorg-dev libdrm-intel1
```
* Configure and Build Xorg
```
./configure --prefix=/home/$USER/dfs-gui/usr --sysconfdir=home/$USER/dfs-gui/etc --localstatedir=/var
```
* Compile: Build the Xorg server:
```
make
make CONFIG_PREFIX=/home/$USER/dfs-gui/ install
```

* Download Intel Driver
```
wget https://www.x.org/releases/individual/driver/xf86-video-intel-2.4.1.tar.bz2
tar -xjf xf86-video-intel-2.4.1.tar.bz2
cd xf86-video-intel-2.4.1
```
* Configure and Build Intel Driver
```
./configure --prefix=/home/$USER/dfs-gui/usr --sysconfdir=home/$USER/dfs-gui/etc
make
sudo make install
```
* Configure Xorg for Intel Devices
```
sudo mkdir -p /home/$USER/dfs-gui/etc/X11/xorg.conf.d/
sudo nano /home$USER/dfs-gui/etc/X11/xorg.conf.d/20-intel.conf
```
