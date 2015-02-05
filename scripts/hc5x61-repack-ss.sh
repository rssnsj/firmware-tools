#!/bin/sh

get_ss_firmware_name()
{
	local orig_name="$1"
	echo `echo "$orig_name" | sed 's/\.bin$//'`-Shadowsocks.bin
}

# --------------------------------------------------

[ -z "$U" ] && U="http://v.rssn.cn/ralink/packages/"
case "$U" in
	*/) : ;;
	*) U="$U/" ;;
esac

M=""
F=""
case "$1" in
	HC5?6?) M="$1"; shift 1; F="$1"; shift 1;;
	HC5?6?-*) F="$1"; M=`echo "$F" | awk -F- '{print $1}'`; shift 1;;
	*) echo "*** Unable to determine model type of this firmware. Please specify model name in arguments before file name."; exit 1;;
esac

hiwifi-repack.sh -e -x "
set -e
opkg install '${U}autossh_1.4b-20140307.1_ralink.ipk'
opkg install '${U}dnsmasq-salist_2.71-1_ralink.ipk'
opkg install '${U}openssh-redir-client_6.1p1-20150202_ralink.ipk'
opkg install '${U}vanillass-libev_1.6.2_ralink.ipk'
opkg install '${U}shadowsocks-tools_1-20150108_ralink.ipk' --force-overwrite --force-depends
" $M "$F" -o `get_ss_firmware_name "$F"` "$@"

exit 0

