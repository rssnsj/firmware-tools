#!/bin/sh

opkg_exec()
{
	local squashfs_root=`pwd`
	local major_arch

	# Check if we are working under OpenWrt root directory
	if [ ! -f "$squashfs_root"/etc/opkg.conf ]; then
		echo "*** You do not seem to be working under OpenWrt filesystem. Aborted."
		exit 1
	fi

	# Place a temporary copy of opkg.conf without unknown options
	mkdir -p "$squashfs_root"/tmp
	sed '/option \+ssl_ca_path/d' "$squashfs_root"/etc/opkg.conf > "$squashfs_root"/tmp/opkg.conf

	# Get system architecture on first execution
	if [ -z "$major_arch" ]; then
		major_arch=`cat "$squashfs_root"/usr/lib/opkg/status | awk -F': *' '/^Architecture:/&&$2!~/^all$/{print $2}' | sort -u | head -n1`
	fi

	IPKG_INSTROOT="$squashfs_root" IPKG_CONF_DIR="$squashfs_root"/etc IPKG_OFFLINE_ROOT="$squashfs_root" \
	exec opkg-cl --offline-root "$squashfs_root" --conf "$squashfs_root"/tmp/opkg.conf \
		--force-overwrite --force-maintainer \
		--add-arch all:100 --add-arch $major_arch:200 "$@"
	## --force-depends --add-dest root:/
}

opkg_exec "$@"

