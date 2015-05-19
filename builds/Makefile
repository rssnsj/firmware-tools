
SDK_AR71XX_BB ?= OpenWrt-SDK-ar71xx-for-linux-x86_64-gcc-4.8-linaro_uClibc-0.9.33.2
ifneq ($(SDK),)
	SDK_AR71XX_BB := $(SDK)
endif

PACKAGES_FULL_BB := 6in4 6to4 blkid curl ethtool iftop ip ip6tables-extra ip6tables-mod-nat iperf-mt ipset \
	iptables-mod-conntrack-extra iptables-mod-extra iptables-mod-filter iptables-mod-ipopt iptables-mod-nat-extra \
	iwinfo kmod-crypto-deflate kmod-crypto-des kmod-crypto-ecb kmod-crypto-hmac kmod-crypto-manager \
	kmod-crypto-md4 kmod-crypto-md5 kmod-crypto-pcompress kmod-crypto-sha1 kmod-crypto-sha256 kmod-dnsresolver \
	kmod-fs-cifs kmod-fs-hfs kmod-fs-nfs kmod-fs-nfs-common kmod-fs-ntfs kmod-fs-vfat kmod-fuse kmod-gre kmod-ifb \
	kmod-ip6-tunnel kmod-ip6tables-extra kmod-ipip kmod-ipt-conntrack-extra kmod-ipt-extra kmod-ipt-filter \
	kmod-ipt-ipopt kmod-ipt-ipset kmod-ipt-nat-extra kmod-ipt-nat6 kmod-ipt-nathelper-extra kmod-iptunnel \
	kmod-iptunnel4 kmod-iptunnel6 kmod-l2tp kmod-ledtrig-gpio kmod-lib-textsearch kmod-lib-zlib kmod-macvlan \
	kmod-mppe kmod-nfnetlink kmod-nls-cp437 kmod-nls-iso8859-1 kmod-nls-utf8 kmod-pppol2tp kmod-pptp \
	kmod-sched-connmark kmod-sched-core kmod-sit kmod-tun kmod-usb-ohci kmod-usb-printer libcurl libdaemon \
	libevent2 libiwinfo libiwinfo-lua libjson liblua liblzo libmnl libncurses libopenssl libpcap libpolarssl \
	libpthread librt libubus-lua libuci-lua lua luci luci-app-firewall luci-app-qos luci-app-samba luci-base \
	luci-i18n-chinese luci-i18n-english luci-lib-json luci-lib-nixio luci-mod-admin-full luci-proto-ipv6 \
	luci-proto-ppp luci-proto-relay luci-theme-bootstrap ntfs-3g openvpn-openssl ppp-mod-pppol2tp ppp-mod-pptp \
	qos-scripts relayd resolveip samba36-server tc tcpdump terminfo uclibcxx uhttpd uhttpd-mod-ubus zlib \
	pdnsd pptpd xl2tpd

PACKAGES_MEDIUM_BB := kmod-usb-storage kmod-fs-ext4 kmod-fs-vfat kmod-sit kmod-ipip kmod-gre kmod-nls-cp437 \
	kmod-nls-iso8859-1 libevent2 pptpd xl2tpd ntfs-3g ntfs-3g-utils luci luci-app-samba luci-proto-ipv6 \
	openvpn-openssl ipset tcpdump iftop iperf-mt

PACKAGES_FEEDS := ipset-lists minivtun shadowsocks-libev shadowsocks-tools kmod-proto-bridge kmod-yavlan


define BuildFeedsWithSDK
	@if ! [ -n "$(1)" -a -d "$(1)/package" ]; then \
		echo "Please specify a valid OpenWrt SDK directory by adding \"SDK=...\"."; \
		echo "Type \"make help\" for more details."; \
		exit 1; \
	fi
	@cd $(1); [ ! -L dl -a -d /var/dl ] && { rmdir dl && ln -s /var/dl; } || :
	cd $(1)/package; [ -d network-feeds ] && { cd network-feeds; git pull; } || git clone https://github.com/rssnsj/network-feeds.git -b master
	make package/ipset-lists/compile V=s -C "$(1)"
	make package/shadowsocks-libev/compile V=s -C "$(1)"
	make package/shadowsocks-tools/compile V=s -C "$(1)"
	make package/minivtun-tools/compile V=s -C "$(1)"
	make package/proto-bridge/compile V=s -C "$(1)"
	cd "$(1)/bin/ar71xx/packages" && ../../../scripts/ipkg-make-index.sh . > Packages && gzip -9c Packages > Packages.gz
	echo "src rssnsj file:$(shell cd $(1) 2>/dev/null && pwd)/bin/ar71xx/packages" > rssnsj.conf
endef

#
# $1: Firmware download URL
# $2: Packages to install
#
define DownloadRepackBB
	[ -f `basename $(1)` ] || wget -4 $(1)
	openwrt-repack.sh `basename $(1)` -x \
"set -e; \
mkdir -p etc/opkg; cp $(shell pwd)/rssnsj.conf etc/opkg/; \
opkg update; opkg install $(2); \
opkg install dnsmasq-full --force-overwrite; \
echo '#!/bin/sh' > etc/uci-defaults/disable-pdnsd; \
echo '[ -x /etc/init.d/pdnsd ] && /etc/init.d/pdnsd disable' >> etc/uci-defaults/disable-pdnsd; \
chmod 755 etc/uci-defaults/disable-pdnsd; \
rm -vf etc/opkg/rssnsj.conf; rmdir etc/opkg 2>/dev/null || :; \
exit 0; \
"
endef


help:
	@echo "Usage:"
	@echo "  make <model> [SDK=...]"

hiwifi-hc6361: .feeds_ar71xx_bb
	$(call DownloadRepackBB, http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/openwrt-ar71xx-generic-hiwifi-hc6361-squashfs-sysupgrade.bin, $(PACKAGES_FULL_BB) $(PACKAGES_FEEDS))

tl-wr703n:
	$(call DownloadRepackBB, http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/openwrt-ar71xx-generic-tl-wr703n-v1-squashfs-sysupgrade.bin, $(PACKAGES_MEDIUM_BB) $(PACKAGES_FEEDS))

.feeds_ar71xx_bb:
	$(call BuildFeedsWithSDK,$(SDK_AR71XX_BB))
	touch $@

extract:
	tar jxvf /var/dl/OpenWrt-SDK-ar71xx-for-linux-x86_64-gcc-4.8-linaro_uClibc-0.9.33.2.tar.bz2

clean:
	openwrt-repack.sh -c
	rm -vf rssnsj.conf .feeds_* openwrt-*.bin openwrt-*.bin.out

