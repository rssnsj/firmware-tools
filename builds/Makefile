
SDK_AR71XX_BB ?= OpenWrt-SDK-ar71xx-for-linux-x86_64-gcc-4.8-linaro_uClibc-0.9.33.2
SDK_AR71XX_CC ?= OpenWrt-SDK-ar71xx-generic_gcc-4.8-linaro_uClibc-0.9.33.2.Linux-x86_64
ifneq ($(SDK),)
	SDK_AR71XX_BB := $(SDK)
endif

PACKAGES_FULL_BB := 6in4 6to4 blkid curl ethtool ip ip6tables-extra ip6tables-mod-nat ipset \
	iptables-mod-conntrack-extra iptables-mod-extra iptables-mod-filter iptables-mod-ipopt \
	iptables-mod-nat-extra iwinfo kmod-crypto-deflate kmod-crypto-des kmod-crypto-ecb \
	kmod-crypto-hmac kmod-crypto-manager kmod-crypto-md4 kmod-crypto-md5 kmod-crypto-pcompress \
	kmod-crypto-sha1 kmod-crypto-sha256 kmod-dnsresolver kmod-fs-cifs kmod-fs-ext4 kmod-fs-hfs \
	kmod-fs-nfs kmod-fs-nfs-common kmod-fs-ntfs kmod-fs-vfat kmod-fuse kmod-gre kmod-ifb \
	kmod-ip6-tunnel kmod-ip6tables-extra kmod-ipip kmod-ipt-conntrack-extra kmod-ipt-extra \
	kmod-ipt-filter kmod-ipt-ipopt kmod-ipt-ipset kmod-ipt-nat-extra kmod-ipt-nat6 \
	kmod-ipt-nathelper-extra kmod-iptunnel kmod-iptunnel4 kmod-iptunnel6 kmod-l2tp \
	kmod-ledtrig-gpio kmod-lib-textsearch kmod-lib-zlib kmod-macvlan kmod-mppe kmod-nfnetlink \
	kmod-nls-cp437 kmod-nls-iso8859-1 kmod-nls-utf8 kmod-pppol2tp kmod-pptp kmod-sched-connmark \
	kmod-sched-core kmod-sit kmod-tun kmod-usb-ohci kmod-usb-printer kmod-usb-storage libcurl \
	libdaemon libevent2 libiwinfo libiwinfo-lua libjson liblua liblzo libmnl libncurses \
	libopenssl libpolarssl libpthread librt libubus-lua libuci-lua lua luci luci-app-firewall \
	luci-app-qos luci-app-samba luci-base luci-i18n-chinese luci-i18n-english luci-lib-json \
	luci-lib-nixio luci-mod-admin-full luci-proto-ipv6 luci-proto-ppp luci-proto-relay \
	luci-theme-bootstrap ntfs-3g openvpn-openssl ppp-mod-pppol2tp ppp-mod-pptp qos-scripts \
	resolveip samba36-server tc terminfo zlib pdnsd pptpd xl2tpd

PACKAGES_MEDIUM_BB := kmod-usb-storage kmod-fs-ext4 kmod-fs-vfat kmod-sit kmod-ipip kmod-gre \
	kmod-nls-cp437 kmod-nls-iso8859-1 libevent2 pptpd xl2tpd ntfs-3g ntfs-3g-utils luci \
	luci-app-samba luci-proto-ipv6 openvpn-openssl ipset

PACKAGES_FULL_CC := 6in4 6to4 blkid curl ethtool fdisk ip ip6tables-extra ip6tables-mod-nat \
	ipset iptables-mod-conntrack-extra iptables-mod-extra iptables-mod-ipopt iwinfo \
	iptables-mod-nat-extra kmod-crypto-des kmod-crypto-ecb kmod-crypto-hmac kmod-crypto-manager \
	kmod-crypto-md4 kmod-crypto-md5 kmod-crypto-pcompress kmod-crypto-sha1 kmod-crypto-sha256 \
	kmod-dnsresolver kmod-fs-ext4 kmod-fs-vfat kmod-fs-cifs kmod-fuse kmod-gre kmod-ipt-filter\
	kmod-ip6-tunnel kmod-ip6tables-extra kmod-ipip kmod-ipt-conntrack-extra kmod-ipt-extra \
	kmod-ipt-ipopt kmod-ipt-ipset kmod-ipt-nat-extra kmod-ipt-nat6 kmod-iptunnel kmod-iptunnel4 \
	kmod-iptunnel6 kmod-leds-gpio kmod-ledtrig-default-on kmod-ledtrig-netdev kmod-lib-zlib \
	kmod-ledtrig-timer kmod-ledtrig-usbdev kmod-lib-textsearch kmod-macvlan kmod-mppe \
	kmod-nfnetlink kmod-pptp kmod-sit kmod-tun kmod-usb-storage libblkid libcurl libdaemon \
	libevent2 liblzo libmnl libncurses libopenssl libpolarssl libpthread luci-app-samba \
	luci-lib-json luci-proto-ipv6 luci-proto-relay ntfs-3g openvpn-openssl resolveip \
	samba36-server terminfo zlib luci-i18n-base-zh-cn luci-i18n-commands-zh-cn \
	luci-i18n-diag-core-zh-cn luci-i18n-firewall-zh-cn luci-i18n-qos-zh-cn luci-i18n-samba-zh-cn \
	ppp-mod-pptp ppp-mod-pppol2tp kmod-nls-cp437 kmod-nls-iso8859-1 kmod-nls-utf8 \
	kmod-crypto-deflate kmod-usb-ohci kmod-usb-printer kmod-nf-nathelper kmod-nf-nathelper-extra
PACKAGES_URLS_CC := http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/packages/oldpackages/pdnsd_1.2.9a-par-a8e46ccba7b0fa2230d6c42ab6dcd92926f6c21d_ar71xx.ipk

PACKAGES_FEEDS := ipset-lists minivtun shadowsocks-libev shadowsocks-tools file-storage \
	kmod-proto-bridge kmod-yavlan

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

# Generic method of creating firmware with the built components
# $1: Firmware download URL
# $2: Packages to install
# $3: Package URLs to install
define DownloadRepackGeneric
	[ -f `basename $(1)` ] || wget -4 $(1)
	openwrt-repack.sh `basename $(1)` -x \
"set -e; \
mkdir -p etc/opkg; cp $(shell pwd)/rssnsj.conf etc/opkg/; \
opkg update; opkg install $(2); \
opkg install dnsmasq-full --force-overwrite; \
for p in $(3); do opkg install \$$p; done; \
echo '#!/bin/sh' > etc/uci-defaults/disable-pdnsd; \
echo '[ -x /etc/init.d/pdnsd ] && /etc/init.d/pdnsd disable' >> etc/uci-defaults/disable-pdnsd; \
chmod 755 etc/uci-defaults/disable-pdnsd; \
rm -vf etc/opkg/rssnsj.conf; rmdir etc/opkg 2>/dev/null || :; \
exit 0; \
"
endef

# Qihoo-C301 only
# $1: Firmware download URL
# $2: Packages to install
# $3: Package URLs to install
define DownloadRepackQihooC301
	[ -f `basename $(1)` ] || wget -4 $(1)
	openwrt-repack.sh `basename $(1)` -x \
"set -e; \
mkdir -p etc/opkg; cp $(shell pwd)/rssnsj.conf etc/opkg/; \
opkg update; opkg install $(2); \
opkg install dnsmasq-full --force-overwrite; \
opkg install kmod-ath10k; \
rm -vf lib/firmware/ath10k/QCA988X/hw2.0/firmware-4.bin; \
cp -vf $(shell pwd)/files/ath10k/firmware-2.bin lib/firmware/ath10k/QCA988X/hw2.0/firmware-2.bin; \
for p in $(3); do opkg install \$$p; done; \
echo '#!/bin/sh' > etc/uci-defaults/disable-pdnsd; \
echo '[ -x /etc/init.d/pdnsd ] && /etc/init.d/pdnsd disable' >> etc/uci-defaults/disable-pdnsd; \
chmod 755 etc/uci-defaults/disable-pdnsd; \
rm -vf etc/opkg/rssnsj.conf; rmdir etc/opkg 2>/dev/null || :; \
exit 0; \
"
endef

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
help:
	@echo "Usage:"
	@echo "  make <model> [SDK=...]"

all:
	make hiwifi-hc6361
	make qihoo-c301
	make tl-wr703n

hiwifi-hc6361: .feeds_ar71xx_bb
	$(call DownloadRepackGeneric, http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/openwrt-ar71xx-generic-hiwifi-hc6361-squashfs-sysupgrade.bin, $(PACKAGES_FULL_BB) $(PACKAGES_FEEDS))

tl-wr703n: .feeds_ar71xx_bb
	$(call DownloadRepackGeneric, http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/openwrt-ar71xx-generic-tl-wr703n-v1-squashfs-sysupgrade.bin, $(PACKAGES_MEDIUM_BB) $(PACKAGES_FEEDS))

qihoo-c301: .feeds_ar71xx_cc
	$(call DownloadRepackQihooC301, http://downloads.openwrt.org/snapshots/trunk/ar71xx/generic/openwrt-ar71xx-generic-qihoo-c301-squashfs-sysupgrade.bin, $(PACKAGES_FULL_CC) $(PACKAGES_FEEDS), $(PACKAGES_URLS_CC))

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
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
	make package/file-storage/compile V=s -C "$(1)"
	make package/dnspod-utils/compile V=s -C "$(1)"
	make package/proto-bridge/compile V=s -C "$(1)"
	cd "$(1)/bin/ar71xx/packages" && ../../../scripts/ipkg-make-index.sh . > Packages && gzip -9c Packages > Packages.gz
	echo "src rssnsj file:$(shell cd $(1) 2>/dev/null && pwd)/bin/ar71xx/packages" > rssnsj.conf
endef

.feeds_ar71xx_bb:
	$(call BuildFeedsWithSDK,$(SDK_AR71XX_BB))
.feeds_ar71xx_cc:
	$(call BuildFeedsWithSDK,$(SDK_AR71XX_CC))

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
extract:
	tar jxvf /var/dl/$(SDK_AR71XX_BB).tar.bz2
	tar jxvf /var/dl/$(SDK_AR71XX_CC).tar.bz2

clean:
	openwrt-repack.sh -c
	rm -vf rssnsj.conf .feeds_* openwrt-*.bin openwrt-*.bin.out

