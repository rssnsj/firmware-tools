#!/bin/sh

if [ -z "$1" ]; then
	echo "*** No firmware download URL specified."
	exit 1
fi

U="$1"
F=`basename "$U"`

[ -f "$F" ] || wget "$U" -O "$F"

openwrt-repack.sh "$F" -x '
set -e

opkg update
opkg install kmod-usb-storage kmod-fs-ext4 kmod-fs-vfat kmod-sit kmod-ipip kmod-gre kmod-nls-cp437 kmod-nls-iso8859-1
opkg install libevent2 pptpd xl2tpd ntfs-3g ntfs-3g-utils luci-app-samba luci-proto-ipv6 openvpn-openssl ipset
opkg install tcpdump iftop iperf-mt
'

