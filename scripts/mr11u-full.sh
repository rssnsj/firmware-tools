#!/bin/sh

openwrt-repack.sh http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/openwrt-ar71xx-generic-tl-mr11u-v2-squashfs-sysupgrade.bin -w -x '
set -e
opkg update
opkg install kmod-usb-storage kmod-fs-ext4 kmod-fs-vfat kmod-sit kmod-ipip kmod-gre kmod-nls-cp437 kmod-nls-iso8859-1
opkg install libevent2 pptpd xl2tpd ntfs-3g ntfs-3g-utils luci-app-samba luci-proto-ipv6
opkg install tcpdump iftop
'

