echo "  
  ______          _   _                 ____                             _   _____  ______ _____ 
 |  ____|        | | | |               |  _ \                           | | |  __ \|  ____/ ____|
 | |__ _   _ _ __| |_| |__   ___ _ __  | |_) | ___ _   _  ___  _ __   __| | | |  | | |__ | (___  
 |  __| | | | '__| __| '_ \ / _ \ '__| |  _ < / _ \ | | |/ _ \| '_ \ / _` | | |  | |  __| \___ \ 
 | |  | |_| | |  | |_| | | |  __/ |    | |_) |  __/ |_| | (_) | | | | (_| | | |__| | |    ____) |
 |_|   \__,_|_|   \__|_| |_|\___|_|    |____/ \___|\__, |\___/|_| |_|\__,_| |_____/|_|   |_____/ 
                                                    __/ |                                        
                                                   |___/                                
"
apt install wget
apt install bzip2 libncurses-dev flex bison bc libelf-dev libssl-dev xz-utils autoconf gcc make libtool git vim libpng-dev libfreetype-dev g++ extlinux
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.10.tar.xz
tar xf linux-6.10.tar.xz
cd linux-6.10
echo " select these things inside the kernel 
Device Drivers > Graphic Support > Cirrus drivers
Device Drivers > Graphic Support > Frame buffer devices > support for frame buffer devices
Device Drivers > Graphic Support > Bootup logo"
sleep 5
make menuconfig
make -j $(nproc)
mkdir ~/dfs-gui
cp arch/x86/boot/bzImage ~/dfs-gui
echo "Select 
Settings > build static library (No shared libs) (NEW)"
make menuconfig
make -j$(nproc)
make CONFIG_PREFIX=/home/$USER/dfs-gui install
git clone https://github.com/ghaerr/microwindows.git
cd microwindows
cd src/
cp Configs/config.linux-fb config
echo "Change NX11 from N to Y"
nano config
echo "Comment X11_INCULDE=$(X11HDRLOCATION) and Uncomment X11_INCLUDE=./x11-local"
nano nx11/Makefile
make
make install
touch gui.c
echo "/* 
 
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
" >> gui.c
gcc gui.c -lNX11 -lnano-x && gcc gui.c -lNX11 -lnano-x -I /microwindows/src/nx11/X11-local/
mv a.out ~/dfs-gui/x11app
cd bin/
ldd nano-X
mkdir -p /distro/lib/x86_64-linux-gnu/
mkdir /distro/lib64

# Beta
cp /lib/x86_64-linux-gnu/libpng16.so.16 ~/dfs-gui/lib/x86_64-linux-gnu/libpng16.so.16
cp /lib/x86_64-linux-gnu/libz.so.1 ~/dfs-gui/lib/x86_64-linux-gnu/libz.so.1
cp /lib/x86_64-linux-gnu/libc.so.6 ~/dfs-gui/lib/x86_64-linux-gnu/libc.so.6
cp /lib/x86_64-linux-gnu/libm.so.6 ~/dfs-gui/lib/x86_64-linux-gnu/libm.so.6
cp /lib/x86_64-linux-gnu/libbrotlidec.so.1 ~/dfs-gui/lib/x86_64-linux-gnu/libbrotlidec.so.1
cp /lib64/ld-linux-x86-64.so.2 ~/dfs-gui/lib64/ld-linux-x86-64.so.2

cd ..
cp -r bin ~/dfs-gui/nanox
cd ..
cp runapp ~/dfs-gui/nanox
mkdir -p ~/dfs-iso/{boot,grub}
cp ~/dfs-gui/bzImage ~/dfs-iso/boot/
cp -r ~/dfs-gui/{bin,lib,lib64,nanox,x11app,linuxrc,usr} ~/dfs-iso/
grub-mkrescue -o ~/dfs-iso/boot/grub/grub.cfg ~/dfs-iso
echo 'set default=0
set timeout=5

menuentry "DFS Distro with GUI" {
    linux /boot/bzImage root=/dev/sda rw
}' >> ~/dfs-iso/boot/grub/grub.cfg
cd ~/
xorriso -as mkisofs -o ~/dfs-iso/dfs-gui.iso -b boot/grub/grub.cfg -no-emul-boot -boot-load-size 4 -boot-info-table -R -J -l ~/dfs-iso
echo "built successfully"
qemu-system-x86_64 -cdrom ~/dfs-iso/dfs-gui.iso

