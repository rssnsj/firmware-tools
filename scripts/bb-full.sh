#!/bin/sh

SOURCE_FIRMWARE=http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/openwrt-ar71xx-generic-hiwifi-hc6361-squashfs-sysupgrade.bin
SOURCE_FIRMWARE=http://downloads.openwrt.org/barrier_breaker/14.07/ramips/mt7620a/openwrt-ramips-mt7620a-Lenovo-y1s-squashfs-sysupgrade.bin

set -e
opkg update
opkg install 6in4 6to4 curl ethtool fdisk iftop ip ip6tables-extra ip6tables-mod-nat iperf-mt ipset iptables-mod-conntrack-extra iptables-mod-extra iptables-mod-ipopt iptables-mod-lua iptables-mod-nat-extra kmod-crypto-des kmod-crypto-ecb kmod-crypto-hmac kmod-crypto-manager kmod-crypto-md4 kmod-crypto-md5 kmod-crypto-pcompress kmod-crypto-sha1 kmod-crypto-sha256 kmod-dnsresolver kmod-fs-autofs4 kmod-fs-cifs kmod-gre kmod-ip6-tunnel kmod-ip6tables-extra kmod-ipip kmod-ipt-conntrack-extra kmod-ipt-extra kmod-ipt-ipopt kmod-ipt-ipset kmod-ipt-nat-extra kmod-ipt-nat6 kmod-iptunnel kmod-iptunnel4 kmod-iptunnel6 kmod-l2tp kmod-leds-gpio kmod-ledtrig-default-on kmod-ledtrig-netdev kmod-ledtrig-timer kmod-ledtrig-usbdev kmod-lib-textsearch kmod-macvlan kmod-mppe kmod-nfnetlink kmod-pppol2tp kmod-pptp kmod-sit kmod-tun libblkid libcurl libdaemon libevent2 libjson liblzo libmnl libncurses libopenssl libpcap libpolarssl libpthread luci-app-samba luci-i18n-chinese luci-i18n-english luci-lib-json luci-proto-ipv6 luci-proto-relay openvpn-openssl pdnsd ppp-mod-pppol2tp ppp-mod-pptp pptpd relayd resolveip samba36-server tcpdump terminfo xl2tpd zlib
rm -f etc/pdnsd.conf

