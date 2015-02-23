#!/bin/sh -e

SOURCE_FIRMWARE=http://downloads.openwrt.org/snapshots/trunk/ramips/mt7620/openwrt-ramips-mt7620-xiaomi-miwifi-mini-squashfs-sysupgrade.bin
SOURCE_FIRMWARE=http://downloads.openwrt.org/snapshots/trunk/ar71xx/generic/openwrt-ar71xx-generic-hiwifi-hc6361-squashfs-sysupgrade.bin

opkg update
opkg install 6in4 6to4 curl ethtool fdisk iftop ip ip6tables-extra ip6tables-mod-nat iperf-mt ipset iptables-mod-conntrack-extra iptables-mod-extra iptables-mod-ipopt iptables-mod-lua iptables-mod-nat-extra kmod-crypto-des kmod-crypto-ecb kmod-crypto-hmac kmod-crypto-manager kmod-crypto-md4 kmod-crypto-md5 kmod-crypto-pcompress kmod-crypto-sha1 kmod-crypto-sha256 kmod-dnsresolver kmod-fs-autofs4 kmod-fs-cifs kmod-gre kmod-ip6-tunnel kmod-ip6tables-extra kmod-ipip kmod-ipt-conntrack-extra kmod-ipt-extra kmod-ipt-ipopt kmod-ipt-ipset kmod-ipt-nat-extra kmod-ipt-nat6 kmod-iptunnel kmod-iptunnel4 kmod-iptunnel6 kmod-leds-gpio kmod-ledtrig-default-on kmod-ledtrig-netdev kmod-ledtrig-timer kmod-ledtrig-usbdev kmod-lib-textsearch kmod-macvlan kmod-mppe kmod-nfnetlink kmod-pptp kmod-sit kmod-tun libblkid libcurl libdaemon libevent2 libjson liblzo libmnl libncurses libopenssl libpcap libpolarssl libpthread luci-app-samba luci-lib-json luci-proto-ipv6 luci-proto-relay openvpn-openssl relayd resolveip samba36-server tcpdump terminfo zlib
#opkg install ppp-mod-pppol2tp || :
opkg install ppp-mod-pptp || :
opkg install luci-i18n-base-zh-cn luci-i18n-commands-zh-cn luci-i18n-diag-core-zh-cn luci-i18n-firewall-zh-cn luci-i18n-qos-zh-cn luci-i18n-samba-zh-cn

H=w.rssn.cn

# Determine download URL by architecture name
[ -f etc/openwrt_release ] && . etc/openwrt_release
P=`echo "$DISTRIB_TARGET" | awk -F/ '{print $1}'`
U="http://$H/network-feeds/$P"
case "$P" in
	ar71xx)
		N=ar71xx
		K=http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/packages/oldpackages/pdnsd_1.2.9a-par-a8e46ccba7b0fa2230d6c42ab6dcd92926f6c21d_ar71xx.ipk
		;;
	ramips)
		N=ramips_24kec
		K=http://downloads.openwrt.org/barrier_breaker/14.07/ramips/mt7620a/packages/oldpackages/pdnsd_1.2.9a-par-a8e46ccba7b0fa2230d6c42ab6dcd92926f6c21d_ramips_24kec.ipk
		;;
esac

rm -rf /tmp/opkg-lists
opkg install $U/dnsmasq_2.71-4_${N}.ipk --force-overwrite ##--force-depends
opkg install $K
opkg install $U/ipset-lists_1-20150107_${N}.ipk
opkg install $U/shadowsocks-libev_1.6.2_${N}.ipk
opkg install $U/shadowsocks-tools_1-20150108_${N}.ipk
opkg install $U/p2pvtun_1-20150219_${N}.ipk
rm -f etc/pdnsd.conf

