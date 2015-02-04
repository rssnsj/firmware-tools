#!/bin/sh

[ -z "$U" ] && U="http://v.rssn.cn/HC6361/packages/"

case "$U" in
	*/) : ;;
	*) U="$U/" ;;
esac

case "$1" in
	HC6361) shift 1:;;
esac

hiwifi-repack.sh -e -x "
set -e
opkg install '${U}autossh_1.4b-20140307.1_ar71xx.ipk'
opkg install '${U}dnsmasq-salist_2.71-1_ar71xx.ipk'
opkg install '${U}openssh-redir-client_6.1p1-20150202_ar71xx.ipk'
opkg install '${U}vanillass-libev_1.6.2_ar71xx.ipk'
opkg install '${U}shadowsocks-tools_1-20150108_ar71xx.ipk' --force-overwrite --force-depends
" HC6361 "$@"

exit 0

