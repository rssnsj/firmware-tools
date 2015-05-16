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

mkdir -p etc/opkg
echo "src/gz rssnsj http://rssn.cn/network-feeds/ar71xx" > etc/opkg/rssnsj.conf

opkg update
opkg install 6in4 6to4 curl ethtool fdisk iftop ip ip6tables-extra ip6tables-mod-nat iperf-mt ipset iptables-mod-conntrack-extra iptables-mod-extra iptables-mod-ipopt iptables-mod-lua iptables-mod-nat-extra kmod-crypto-des kmod-crypto-ecb kmod-crypto-hmac kmod-crypto-manager kmod-crypto-md4 kmod-crypto-md5 kmod-crypto-pcompress kmod-crypto-sha1 kmod-crypto-sha256 kmod-dnsresolver kmod-fs-autofs4 kmod-fs-cifs kmod-gre kmod-ip6-tunnel kmod-ip6tables-extra kmod-ipip kmod-ipt-conntrack-extra kmod-ipt-extra kmod-ipt-ipopt kmod-ipt-ipset kmod-ipt-nat-extra kmod-ipt-nat6 kmod-iptunnel kmod-iptunnel4 kmod-iptunnel6 kmod-leds-gpio kmod-ledtrig-default-on kmod-ledtrig-netdev kmod-ledtrig-timer kmod-ledtrig-usbdev kmod-lib-textsearch kmod-macvlan kmod-mppe kmod-nfnetlink kmod-pptp kmod-sit kmod-tun libblkid libcurl libdaemon libevent2 liblzo libmnl libncurses libopenssl libpcap libpolarssl libpthread luci-app-samba luci-lib-json luci-proto-ipv6 luci-proto-relay openvpn-openssl relayd resolveip samba36-server tcpdump terminfo zlib
opkg install ppp-mod-pptp ppp-mod-pppol2tp || :
opkg install luci-i18n-base-zh-cn luci-i18n-commands-zh-cn luci-i18n-diag-core-zh-cn luci-i18n-firewall-zh-cn luci-i18n-qos-zh-cn luci-i18n-samba-zh-cn

opkg install http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/packages/oldpackages/pdnsd_1.2.9a-par-a8e46ccba7b0fa2230d6c42ab6dcd92926f6c21d_ar71xx.ipk
opkg install ipset-lists minivtun shadowsocks-libev shadowsocks-tools
opkg install dnsmasq-full --force-overwrite

cat >> etc/uci-defaults/disable-pdnsd <<EOF
#!/bin/sh
[ -x /etc/init.d/pdnsd ] && /etc/init.d/pdnsd disable
EOF
chmod 755 etc/uci-defaults/disable-pdnsd

rm -vf etc/opkg/rssnsj.conf
rmdir etc/opkg 2>/dev/null || :

'

