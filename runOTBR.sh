#!/bin/bash

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

# USB DETAILS
USB_VENDORID=0x0403
USB_PRODUCTID=0x6001



sudo tee /etc/dnsmasq.conf <<EOF
interface=virbr0 
dhcp-range=${IPV4_NETWORK}.2,${IPV4_NETWORK}.150,24h
dhcp-range=${IPV6_NETWORK}::10, ${IPV6_NETWORK}::12,24h
bind-interfaces
dhcp-host=aa:bb:cc:dd:ee:ff,${IPV6_RASPI_IP}
server=8.8.8.8
server=2001:4860:4860::8888
enable-ra
EOF

[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

sudo sysctl net.ipv4.ip_forward=1
sudo sysctl net.ipv6.conf.default.forwarding=1
sudo sysctl net.ipv6.conf.all.forwarding=1

sudo ip tuntap add dev vnet0 mode tap user $USER_NAME
sudo ip link add name virbr0 type bridge
sudo ip link set virbr0 up
sudo ip link set vnet0 up promisc on
sudo ip link set vnet0 master virbr0
sudo ip -6 addr add ${IPV6_NETWORK}::1/64 dev virbr0 
sudo ip addr add ${IPV4_NETWORK}.1/24 dev virbr0 
sudo systemctl start dnsmasq.service

sudo iptables -t nat -A POSTROUTING -o ${INET_INTERFACE} -j MASQUERADE
sudo ip -6 route add ${IPV6_THREAD_MESHPREFIX}::/64 via ${IPV6_RASPI_IP}

sudo qemu-system-arm -kernel ${KERNEL_FILE} \
		-append "root=/dev/sda2 panic=1 rootfstype=ext4 rw" \
		-hda ${RASPBIAN_IMAGE_FILE} \
		-cpu arm1176 \
		-m 256 \
		-M versatilepb \
		-no-reboot \
		-device virtio-net,netdev=eth0,mac=aa:bb:cc:dd:ee:ff \
		-netdev tap,id=eth0,ifname=vnet0,script=no,downscript=no \
		-serial stdio \
		-dtb ${VERSATILEPB_FILE} \
		-device nec-usb-xhci,id=xhci \
		-device usb-host,bus=xhci.0,vendorid=${USB_VENDORID},productid=${USB_PRODUCTID}
		

sudo systemctl stop dnsmasq.service
sudo iptables -t nat -D POSTROUTING -o ${INET_INTERFACE} -j MASQUERADE

sudo ip addr flush dev virbr0
sudo ip -6 addr flush dev virbr0
sudo ip -6 route del ${IPV6_THREAD_MESHPREFIX}::/64 via ${IPV6_RASPI_IP}

sudo killall dnsmasq
sudo ip link set vnet0 nomaster
sudo ip link set vnet0 down
sudo ip link set virbr0 down
sudo ip link delete virbr0 type bridge
sudo ip link delete vnet0

sudo sed -i '/^interface=virbr0/d' /etc/dnsmasq.conf
sudo sed -i '/^dhcp-range/d' /etc/dnsmasq.conf
sudo sed -i '/^dhcp-host/d' /etc/dnsmasq.conf
sudo sed -i '/^bind-interfaces/d' /etc/dnsmasq.conf
sudo sed -i '/^server=8.8.8.8/d' /etc/dnsmasq.conf
sudo sed -i '/^server=2001:4860:4860::8888/d' /etc/dnsmasq.conf
sudo sed -i '/^enable-ra/d' /etc/dnsmasq.conf
