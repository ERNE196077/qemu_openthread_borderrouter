# qemu_openthread_borderrouter
Kernel image and instructions to deploy a virtual borderrouter test environment.

## Kernel Build Instructions
In case you want it you can build your own kernel and tweak it to add support to more devices/functions. In the steps below I will be using the .config file from this repo, apart of versatile-pb configuration it contains the below modules built-in:
* IPv6.
* USB Serial Support (For the very popular FT232 transceivers, tweak this option in case you use some other) .

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
```
For the next step I used the linux-arm-4.14.50.patch from dhruvvyas90, due changes in the files from the kernel tree the patch failed to be applied in my case so I opened the files and did the changes manually (Just 3 files...). 
Please refer to the patch file to apply the changes. It just be needed to be done just once. [linux-arm-4.14.50.patch](https://github.com/dhruvvyas90/qemu-rpi-kernel/blob/master/tools/linux-arm-4.14.50.patch)
```
nano linux/arch/arm/Kconfig
nano linux/arch/arm/mach-versatile/Kconfig
nano linux/drivers/mmc/host/Kconfig
```
```
```
```
```
```
```
```
```
