# qemu_openthread_borderrouter
Kernel image and instructions to deploy a virtual borderrouter test environment.
## Requirements
Install the needed dependencies
### ArchLinux
GNU EABI compiler will probably need few other dependencies, install accordingly:
```
sudo pacman -S base-devel qemu qemu-arch-extra
trizen -S aqemu
trizen -S arm-linux-gnueabihf-gcc
trizen -S ncurses5-compat-libs
```
### Ubuntu
```
sudo apt-get install bison flex build-essential qemu-system-arm gcc-arm-linux-gnueabihf
```
## Kernel Build Instructions
In case you want it you can build your own kernel and tweak it to add support to more devices/functions. I always prefer to build it by my own as:

* Contain the latest changes.
* Is compatible with the last raspbian image available.

In the steps below I will be using the .config file from this repo, In addition to the versatile-pb configuration it contains the below modules built-in:

* IPv6.
* USB Serial Support (For the very popular FT232 transceivers, tweak this option in case you use some other) .
* VirtIO drivers
* iptables (netfilter)

Clone the Raspberry kernel tree:
```
git clone git://github.com/raspberrypi/linux.git
cd linux/
```
For the next step I used the linux-arm.patch (As of May 2019) from dhruvvyas90, due changes in the files from the kernel tree the patch failed to be applied in my case so I opened the files and did the changes manually (Just 3 files...). 
Please refer to the patch file to apply the changes. It just be needed to be done just once. [Linux tools from dhruvvyas90](https://github.com/dhruvvyas90/qemu-rpi-kernel/blob/master/tools).
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
In case you want to use the same .config file I used copy it into your location (The .config file I provided has all the IPv6, USB, etc stuff needed by OpenThread to work, modify for your own needs):
```
cp ../.config .
```
Start menuconfig and modify the kernel options to your taste, remember to save the .config file:
```
make -j 4 -k ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig
```
Compile the kernel and generate the device tree files:
```
make -j 4 -k ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bzImage dtbs
```
Once done copy the kernel and versatile-pb.dtb files where the runOTBR.sh script resides. (In case you want to use it).
```
cp arch/arm/boot/zImage ../
cp arch/arm/boot/dts/versatile-pb.dtb ../
```

## Border Router Setup
To get a working test environment with a Raspbian we need some setup in the host computer:

* Bridge configuration to permit the virtual Raspbian reach the internet
* iptables rules to allow the traffic
* An IPv6 and IPv4 free network segments to deploy the virtual Raspbian networking.

The steps below will use the runOTBR.sh script which takes care of the 2 first points above. You will need to choose a network segment for IPv4 and 2 for IPv6 and set it in the variables of the script. In my case I used: 

* 2001:dead:beef:cafe::/64    -    Additional Local Mesh for the Thread network 
* 2001:db8:dead:beef:fe::/96    -    IPv6 network between the virtual BR and your computer.
* 192.168.40.0/24    -    IPv4 network for Internet access.

If you need more information about iptables, network routing in Linux I recommend you to read the below topics which I used while writting the runOTBR.sh script.

* [bridge configuration](https://wiki.archlinux.org/index.php/Network_bridge) - ArchLinux network bridge Wiki.
* [port forwarding](https://aboullaite.me/kvm-qemo-forward-ports-with-iptables/) - iptables configuration for bridged connections (Thanks Mohammed)
* [QEMU tap interface](https://backreference.org/2010/03/26/tuntap-interface-tutorial/) - TUN/TAP interface creation.
* [QEMU kernel building](https://web.archive.org/web/20131210001638/http://xecdesign.com/compiling-a-kernel/) - Web archive with the original instructions.

### Raspbian image preparation
Download the raspbian image of your taste, my personal preference is the lite version. Then use qemu-image to add some necessary space.
```
sudo qemu-img resize 2018-10-09-raspbian-stretch-lite.img +10G
```
Modify the script variables to match your kernel files, network details and USB OpenThread NCP device:
```  
# YOUR LINUX USER NAME
USER_NAME=myusername

# QEMU VARIABLES
RASPBIAN_IMAGE_FILE=2018-10-09-raspbian-stretch-lite.img
VERSATILEPB_FILE=versatile-pb.dtb
KERNEL_FILE=zImage

# NETWORKING VARIABLES
IPV6_NETWORK=2001:db8:dead:beef
IPV6_RASPI_IP=2001:db8:dead:beef::11
IPV6_THREAD_MESHPREFIX=2001:dead:beef:cafe
IPV4_NETWORK=192.168.40
INET_INTERFACE=wlp2s0

# USB DETAILS - In this case is 
USB_VENDORID=0x0403   
USB_PRODUCTID=0x6001

```
Run the script:
```
sudo ./runOTBR.sh
```
After this first boot lets configure and resize the filesystem to occupy the new size:
```
# Configure timezone, keyboard, password, etc.
sudo raspi-config 
# Work with the root filesystem.
sudo fdisk /dev/sda
# Print the partitions and take note of boot start of partition sda2 (e.g. 98304)
Type p
# Delete the second partition:
Type d
Type 2
# Create a new partition using the same start position as the partition erased:
Type n 
Type p : for Primary partition
Type 2 : for the partition number
Type 98304 : From the previous steps
Type N : Just if you are asked to remove the signature (NO).
# Write the changes
Type w
# Shutdown raspbian to reboot and the changes take effect.
sudo shutdown -h now
```
Once Raspbian is shutdown it will close the script. Even if you type sudo reboot the Raspbian will shutdown (Due the script is using -no-reboot flag. At this point the filesystem was modified but it is needed to run the below command to modify the usable space. Run again the script to boot up Raspbian and then:
```
sudo resize2fs /dev/sda2
```
Make sure the following rules are uncommented and set to 1 in the file /etc/sysctl.conf
```
net.ipv4.ip_forward
net.ipv6.conf.all.forwarding
```
Finally test the networking and update the OS (dnsmasq DHCP negotiation should do the routing job to reach internet):
```
sudo dhcpcd eth0
ping www.google.com
sudo apt-get update
```
You should have a working Raspbian ready to install OpenThread Border Router. Additionally upgrade and install git.
```
sudo apt-get upgrade
sudo apt-get install git
```
### Install OpenThread Border Router
Clone the OTBR git in a local folder
```
git clone https://github.com/openthread/ot-br-posix.git
cd ot-br-posix
```
In this case we will avoid the installation of NAT64, DNS64 and the AP (Due the fact that this Raspbian is lack of wifi interface (wlan0). Set the below variables to 0 from the file examples/platforms/raspbian/default.
```
NAT64=0
DNS64=0
DHCPV6_PD=0
NETWORK_MANAGER=0
```
Before building we need more RAM... the 256 MB assigned are not enough, for this reason we setup a SWAP file:
```
sudo su -c 'echo "CONF_SWAPSIZE=512" > /etc/dphys-swapfile'
sudo dphys-swapfile setup
```
Build and run wpantund and otbr-agent/web as mentioned in the OT guide:
```
cd ot-br-posix
./script/bootstrap
./script/setup
```
Sit back and relax. The proces will take quite long time.
After finishing the OT Border Router Build and Configuration guide you should have a working OpenThread networking we just need something else...
### Connectivity from host to OT devices 
Using the guest Raspbian with the NCP connected, form a Thread network and add your devices. In this case I'm using a custom board with a cc2538... chip that at this time has problems with commissioning (11/2018) but I made it to get a formed network of some devices just for testing purposes.

Guest NCP status
```
pi@raspivirtual:~$ sudo wpanctl status
wpan0 => [
        "NCP:State" => "associated"
        "Daemon:Enabled" => true
        "NCP:Version" => "OPENTHREAD/20170716-01079-g08747cf7-dirty; CC2538; Nov 13 2018 20:16:15"
        "Daemon:Version" => "0.08.00d (/47f3212; Nov  7 2018 16:10:04)"
        "Config:NCP:DriverName" => "spinel"
        "NCP:HardwareAddress" => [00124B0011F47F13]
        "NCP:Channel" => 11
        "Network:NodeType" => "router"
        "Network:Name" => "OpenThread"
        "Network:XPANID" => 0xDEAD00BEEF00CAFE
        "Network:PANID" => 0x0102
        "IPv6:LinkLocalAddress" => "fe80::30ac:123:29b9:74e8"
        "IPv6:MeshLocalAddress" => "fdde:ad00:beef:0:b8d4:da1a:5652:2239"
        "IPv6:MeshLocalPrefix" => "fdde:ad00:beef::/64"
        "com.nestlabs.internal:Network:AllowingJoin" => false
]
```
OT child device (
```
sudo screen /dev/ttyUSB0 115200,cs8

> state
leader
Done
> ipaddr
fdde:ad00:beef:0:0:ff:fe00:fc00
fdde:ad00:beef:0:0:ff:fe00:5800
fe80:0:0:0:945d:51a1:5201:40f4
fdde:ad00:beef:0:4bf4:d389:a832:8f78
Done
> neighbor table
| Role | RLOC16 | Age | Avg RSSI | Last RSSI |R|S|D|N| Extended MAC     |
+------+--------+-----+----------+-----------+-+-+-+-+------------------+
|   R  | 0xbc00 |  41 |      -22 |       -23 |1|0|1|1| 32ac012329b974e8 |
```
We need to add a gateway and a route to advise the OT network of a route to outside the Thread network:
```
# Configure the gateway. Use a different network prefix from apart of the one from the Raspbian configuration In my case (2001:dead:beef:cafe::/64).
sudo wpanctl -I wpan0 config-gateway 2001:dead:beef:cafe:: -d
```
In this moment you will see that the OT devices and Border Router's wpan will configure a new IP:
```
Raspbian Border Router:
pi@raspivirtual:~$ ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 52:54:00:12:34:56 brd ff:ff:ff:ff:ff:ff
    inet 192.168.40.145/24 brd 192.168.40.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 2001:db8:dead:beef::7f/128 scope global 
       valid_lft forever preferred_lft forever
    inet6 fe80::5054:ff:fe12:3456/64 scope link 
       valid_lft forever preferred_lft forever
3: tunl0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN group default qlen 1000
    link/ipip 0.0.0.0 brd 0.0.0.0
4: wpan0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1280 qdisc pfifo_fast state UNKNOWN group default qlen 500
    link/none 
    inet6 2001:dead:beef:cafe:30ac:123:29b9:74e8/64 scope global 
       valid_lft forever preferred_lft forever
    inet6 fdde:ad00:beef:0:b8d4:da1a:5652:2239/64 scope global 
       valid_lft forever preferred_lft forever
    inet6 fe80::30ac:123:29b9:74e8/64 scope link 
       valid_lft forever preferred_lft forever
    inet6 fe80::30bc:8ea9:5584:c802/64 scope link flags 800 
       valid_lft forever preferred_lft forever

OT Child device:
> ipaddr
2001:dead:beef:cafe:9a0d:50:91ad:230
fdde:ad00:beef:0:0:ff:fe00:fc00
fdde:ad00:beef:0:0:ff:fe00:5800
fe80:0:0:0:945d:51a1:5201:40f4
fdde:ad00:beef:0:4bf4:d389:a832:8f78
Done
```
Add now a route to let the OT devices know what other networks are behind the Border Router:
```
sudo wpanctl -I wpan0 add-route 2001:db8:dead:beef::
```
You should be able to do ping from your host computer to your OT devices and viceversa:
```
From OT child to Host computer:
> ping 2001:db8:dead:beef::1
> 16 bytes from 2001:db8:dead:beef:0:0:0:1: icmp_seq=25 hlim=63 time=61ms

From Host computer to OT child
[ernestrc@homedell qemu_raspbian]$ ping -6 2001:dead:beef:cafe:9a0d:50:91ad:230
PING 2001:dead:beef:cafe:9a0d:50:91ad:230(2001:dead:beef:cafe:9a0d:50:91ad:230) 56 data bytes
64 bytes from 2001:dead:beef:cafe:9a0d:50:91ad:230: icmp_seq=1 ttl=63 time=73.5 ms
64 bytes from 2001:dead:beef:cafe:9a0d:50:91ad:230: icmp_seq=2 ttl=63 time=86.5 ms
64 bytes from 2001:dead:beef:cafe:9a0d:50:91ad:230: icmp_seq=3 ttl=63 time=94.10 ms
64 bytes from 2001:dead:beef:cafe:9a0d:50:91ad:230: icmp_seq=4 ttl=63 time=101 ms
```
## Some troubleshooting
### Refresh IP
The script is configured to provide the virtual Raspbian with the fixed IP you provide in the variables via dnsmasq. This same IP is configured as route via to reach the Thread network. If you have problems reaching the Thread network from your Host computer try the below in the virtual Raspbian:
```
# Remove the IPv6 from the ethernet interface
sudo ip -6 addr flush dev eth0
# Request again an IP (This hopefully will give the IP you provided to your Raspbian eth0 interface)
sudo dhcpcd eth0
```
Then check if you can reach now the Thread network.
### Docker
If you are using Docker, you will probably have problems connecting the virtual raspbian to the network. This is due the fact hat Docker set several iptables rules for the containers. It is possible to 
### Memory constraints
If you run into problems while running the **bootstrap** or **setup** scripts and the error message stands for out of memory, reboot the virtual machine and retry the script. This is due the fact that the swap configured (512M) is not enough to handle the compilation process (As of May 2019, the build process works ok without hitting this issue).
## Final thought
Despite is funny to have a virtual Raspbian with wpantund and OTBR recent achievements are being made with Docker [OTBR Docker](https://openthread.io/guides/border-router/docker/run). Please check that solution and use the one of your taste.