#!/bin/sh

get_ss_firmware_name()
{
	local orig_name="$1"
	echo `echo "$orig_name" | sed 's/\.bin$//'`-Shadowsocks.bin
}

# --------------------------------------------------

[ -z "$U" ] && U="http://rssn.cn/network-feeds/hc6361/"

case "$U" in
	*/) : ;;
	*) U="$U/" ;;
esac

M=""
F=""
case "$1" in
	HC6361) M="$1"; shift 1; F="$1"; shift 1;;
	HC6361-*) F="$1"; M=`echo "$F" | awk -F- '{print $1}'`; shift 1;;
	*) echo "*** Unable to determine model type of this firmware. Please specify model name in arguments before file name."; exit 1;;
esac
case "$1" in
	-K*) shift 1; cmd2="opkg remove inet_chk hidaemon rsyslog  pppoe-sniffer-server pppoe-obtain-account smartqos libhichannel kmod-smartqos kproxy-tools kmod-kproxy kmod-hwf-core miniupnpd special-dial pppoe-term; sed -i '/hidaemon/d' etc/inittab; echo KK > etc/.submodel";;
esac

hiwifi-repack.sh -e -x "
set -e
opkg install '${U}autossh_1.4b-20140307.1_ar71xx.ipk'
opkg install '${U}dnsmasq-salist_2.71-1_ar71xx.ipk'
opkg install '${U}openssh-redir-client_6.1p1-20150202_ar71xx.ipk'
opkg install '${U}vanillass-libev_1.6.2_ar71xx.ipk'
opkg install '${U}shadowsocks-tools_1-20150108_ar71xx.ipk' --force-overwrite
" -x "$cmd2" $M "$F" -o `get_ss_firmware_name "$F"` "$@"

exit 0

