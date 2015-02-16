#!/bin/sh

if [ $# -lt 1 ]; then
	arg0=`basename "$0"`
	cat <<EOF
wget http://ur.ikcd.net//HC5661-sysupgrade-20141231-805e39dd.bin -O HC5661-0.9008.2.8061s-sysupgrade-20141231-805e39dd.bin
wget http://ur.ikcd.net//HC5661-sysupgrade-20141105-3abb3bf3.bin -O HC5661-0.9007.1.7117s-sysupgrade-20141105-3abb3bf3.bin

wget http://ur.ikcd.net//HC5761-sysupgrade-20141231-48642891.bin -O HC5761-0.9008.2.8061s-sysupgrade-20141231-48642891.bin
wget http://ur.ikcd.net//HC5761-sysupgrade-20141105-18eea212.bin -O HC5761-0.9007.1.7117s-sysupgrade-20141105-18eea212.bin

wget http://ur.ikcd.net//tw150v1-sysupgrade-20141231-4322bdfe.bin -O HC6361-0.9008.2.8061s-sysupgrade-20141231-4322bdfe.bin
wget http://ur.ikcd.net//tw150v1-sysupgrade-20141105-5810b4fb.bin -O HC6361-0.9007.1.7117s-sysupgrade-20141105-5810b4fb.bin

$arg0 <model> <rom_file>

EOF
	exit 1
fi

M=""
F=""
case "$1" in
	HC5?6?) M="$1"; shift 1; F="$1"; shift 1;;
	HC5?6?-*) F="$1"; M=`echo "$F" | awk -F- '{print $1}'`; shift 1;;
	*) echo "*** Unable to determine model type of this firmware. Please specify model name in arguments before file name."; exit 1;;
esac

hiwifi-repack.sh -e -u -x '
opkg remove inet_chk hidaemon rsyslog  pppoe-sniffer-server pppoe-obtain-account smartqos libhichannel kmod-smartqos kproxy-tools kmod-kproxy kmod-hwf-core miniupnpd special-dial pppoe-term
sed -i "/hidaemon/d" etc/inittab
echo KK > etc/.submodel
' $M "$F" "$@"

