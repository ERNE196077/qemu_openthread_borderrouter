# qemu_openthread_borderrouter
Kernel image and instructions to deploy a virtual borderrouter test environment.

## Kernel Build Instructions
In case you want it you can build your own kernel and tweak it to add support to more devices/functions. I always prefer to build it by my own as:
* Contain the latest changes.
* Is compatible with the last raspbian image available.
In the steps below I will be using the .config file from this repo, In addition to the versatile-pb configuration it contains the below modules built-in:
* IPv6.
* USB Serial Support (For the very popular FT232 transceivers, tweak this option in case you use some other) .
* VirtIO drivers
* iptables (netfilter)
Adjust the below commands to the OS you are using. In this case I'm using Arch Linux with trizen as AUR package manager.
Install some dependencies:
```
sudo pacman -Syy
trizen -S ncurses5-compat-libs
```
I installed these AUR packages but I'm almost sure that arm-linux-gnueabihf-gcc should be enough:
```
trizen -S arm-linux-gnueabihf-binutils
trizen -S arm-linux-gnueabihf-gcc
trizen -S arm-linux-gnueabihf-glibc
trizen -S arm-linux-gnueabihf-linux-api-headers
```
Clone the Raspberry kernel tree:
```
git clone git://github.com/raspberrypi/linux.git
cd linux/
```
For the next step I used the linux-arm-4.14.50.patch from dhruvvyas90, due changes in the files from the kernel tree the patch failed to be applied in my case so I opened the files and did the changes manually (Just 3 files...). 
Please refer to the patch file to apply the changes. It just be needed to be done just once. [linux-arm-4.14.50.patch](https://github.com/dhruvvyas90/qemu-rpi-kernel/blob/master/tools/linux-arm-4.14.50.patch).
Don't forget to thanks dhruvvyas90 for his help.
```
nano arch/arm/Kconfig
nano arch/arm/mach-versatile/Kconfig
nano drivers/mmc/host/Kconfig
```
Prepare the initial configuration for versatile:
```
make ARCH=arm versatile_defconfig 
```
In case you want to use the same .config file I used copy it into your location:
```
cp ../.config .
```
Start menuconfig and modify the kernel options to your taste, remember to save the .config file:
```
make -j 4 -k ARCH=arm menuconfig
```
Compile the kernel and generate the device tree files:
```
make -j 4 ARCH=arm -k bzImage dtbs
```
Once done copy the kernel and versatile-pb.dtb files where the runborderrouter.sh script resides. (In case you want to use it).
```
cp arch/arm/boot/zImage ../
cp arch/arm/boot/dts/versatile-pb.dtb ../
```
## Border Router Setup
To get a working test environment with a Raspbian we need some setup in the host computer:
* Bridge configuration to permit the virtual Raspbian reach the internet
* iptables rules to allow the traffic
* An IPv6 and IPv4 free network segments to deploy with the virtual Raspbian.

The steps below will use the runborderrouter.sh script which takes care of the 2 first points above. You will need to choose a network segment for IPv4 and IPv6 and set it in the variables of the script. In my case I will use: 
* 2001:db8:dead:beef:fe::/96
* 192.168.40.0/24

If you need more information about iptables, network routing in Linux I recommend you to read the below topics which I used while writting the runborderrouter.sh script. 
* [bridge configuration](https://wiki.archlinux.org/index.php/Network_bridge) - ArchLinux network bridge Wiki.
* [port forwarding](https://aboullaite.me/kvm-qemo-forward-ports-with-iptables/) - iptables configuration for bridged connections (Thanks Mohammed)
* [QEMU tap interface](https://backreference.org/2010/03/26/tuntap-interface-tutorial/) - TUN/TAP interface creation.
* [QEMU kernel buil]

The rest of the guide assume you will be using that script instead of manual work:
```
```
```
```
```
```
```
```
```
```
```
```
```

```
