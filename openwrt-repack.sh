#!/bin/bash -e

LIBRARY_DIR=/usr/lib/openwrt-repack

ENABLE_ROOT_LOGIN=N
ENABLE_WIRELESS=N
IGNORE_MODIFY_ERRORS=N
OPKG_REMOVE_LIST=
OPKG_INSTALL_LIST=
ROOTFS_CMDS=

print_green()
{
	if tty -s 2>/dev/null; then
		echo -ne "\033[32m"
		echo -n "$@"
		echo -e "\033[0m"
	else
		echo "$@"
	fi
}

print_red()
{
	if tty -s 2>/dev/null; then
		echo -ne "\033[31m"
		echo -n "$@"
		echo -e "\033[0m"
	else
		echo "$@"
	fi
}

get_magic_long()
{
	dd bs=4 count=1 2>/dev/null 2>/dev/null | hexdump -v -n 4 -e '1/1 "%02x"'
}

get_magic_word()
{
	dd bs=2 count=1 2>/dev/null 2>/dev/null | hexdump -v -n 4 -e '1/1 "%02x"'
}


print_help()
{
	local arg0=`basename "$0"`
cat <<EOF
Usage:
 $arg0 <ROM_file> [options] ...    patch firmware <ROM_file> and repackage
 $arg0 -c                          clean temporary and target files

Options:
 -o <output_file>          filename of newly built firmware
 -r <package>              remove opkg package (can be multiple)
 -i <package>              install package with ipk file path or URL (can be multiple)
 -e                        enable root login
 -w                        enable wireless by default
 -x <commands>             execute commands after all other operations
 -F                        ignore errors during modification

Predefined commands:

EOF

	local sc
	for sc in $LIBRARY_DIR/*.sh; do
		[ -f "$sc" ] || continue
		cat <<EOF
$arg0 -w -x $sc <file_or_url>

EOF
		local romfile
		cat $sc | awk -F= '/^SOURCE_FIRMWARE[^=]*=/{print $2}' | sed "s/^[\"']//;s/[\"']\$//" |
		while read romfile; do
			cat <<EOF
$arg0 -w -x $sc '$romfile'

EOF
		done
	done
}

modify_rootfs()
{
	local __rc=0

	# Uninstall old packages
	local ipkg
	for ipkg in $OPKG_REMOVE_LIST; do
		opkg remove "$ipkg"
	done
	# Install extra ipk packages
	for ipkg in ipk.$MAJOR_ARCH/*.ipk ipk.$MODEL_NAME/*.ipk; do
		[ -f "$ipkg" ] || continue
		opkg install "$ipkg" || __rc=104
	done
	if [ -n "$OPKG_INSTALL_LIST" ]; then
		opkg update || :
		opkg install $OPKG_INSTALL_LIST || __rc=104
	fi

	# Enable wireless on first startup
	if [ "$ENABLE_WIRELESS" = Y ]; then
		sed -i '/option \+disabled \+1/d;/# *REMOVE THIS LINE/d' lib/wifi/mac80211.sh
	fi

	# Root the firmware (only for the HCxxxx ROMs)
	if [ "$ENABLE_ROOT_LOGIN" = Y ]; then
		# Hack this line: 'sed -i "/login/d" /etc/inittab'
		[ -f lib/functions/system.sh ] && sed -i '/sed.*\/login\/d.*inittab/d' lib/functions/system.sh || :
		if ! ls etc/rc.d/S*dropbear &>/dev/null; then
			ln -sv ../init.d/dropbear etc/rc.d/S50dropbear
		fi
		print_red "WARNING: Enabled root login permanently for the firmware."
	fi

	# Run custom commands
	if [ -n "$ROOTFS_CMDS" ]; then
		print_green ">>> Executing custom commands ..."
		sh -c "$ROOTFS_CMDS" || __rc=101
	fi

	# Fix rc.d symbolic links for /etc/init.d scripts
	print_green "Checking rc.d links for changed services ..."
	local initsc
	for initsc in etc/init.d/*; do
		local initname=`basename "$initsc"`
		local start_no=`awk -F= '/^START=/{print $2; exit}' "$initsc"`
		local stop_no=`awk -F= '/^STOP=/{print $2; exit}' "$initsc"`
		if [ -n "$start_no" -o -n "$stop_no" ] && ! ls -d etc/rc.d/*$initname >/dev/null 2>&1; then
			echo "Creating rc.d links for '/$initsc' ..."
			[ -n "$start_no" ] && ln -sf ../init.d/$initname etc/rc.d/S$start_no$initname || :
			[ -n "$stop_no" ] && ln -sf ../init.d/$initname etc/rc.d/K$stop_no$initname || :
		fi
	done
	local rcdsc
	for rcdsc in etc/rc.d/S* etc/rc.d/K*; do
		local initsc=`readlink "$rcdsc"`
		local initname=`basename "$initsc"`
		if [ ! -f etc/init.d/"$initname" ]; then
			echo "Deleting stale rc.d link '/$rcdsc' ..."
			rm -f "$rcdsc"
		fi
	done

	rm -rf tmp/*

	return $__rc
}

do_firmware_repack()
{
	local old_romfile=
	local new_romfile=
	local __rc=0

	# Parse options and parameters
	local opt
	while [ $# -gt 0 ]; do
		case "$1" in
			-o)
				shift 1
				new_romfile="$1"
				;;
			-r)
				shift 1
				OPKG_REMOVE_LIST="$OPKG_REMOVE_LIST$1 "
				;;
			-i)
				shift 1
				OPKG_INSTALL_LIST="$OPKG_INSTALL_LIST$1 "
				;;
			-e)
				ENABLE_ROOT_LOGIN=Y
				;;
			-w)
				ENABLE_WIRELESS=Y
				;;
			-F)
				IGNORE_MODIFY_ERRORS=Y
				;;
			-x)
				shift 1
				ROOTFS_CMDS="$ROOTFS_CMDS$1
"
				;;
			-*)
				echo "*** Unknown option '$1'."
				exit 1
				;;
			*)
				if [ -z "$old_romfile" ]; then
					old_romfile="$1"
				else
					echo "*** Useless parameter: $1".
					exit 1
				fi
				;;
		esac
		shift 1
	done


	# Download file if the filename starts with "http*://"
	case "$old_romfile" in
		http*://*)
			local romfile_url="$old_romfile"
			old_romfile=`basename "$old_romfile"`
			if [ -f "$old_romfile" ]; then
				print_red "WARNING: File exists, not downloading original file."
			else
				print_green ">>> Downloading file $romfile_url ..."
				wget -4 "$romfile_url" -O "$old_romfile"
			fi
			;;
	esac

	if [ -z "$old_romfile" -o ! -f "$old_romfile" ]; then
		echo "*** Invalid source firmware file '$old_romfile'"
		print_help
		exit 1
	fi
	[ -z "$new_romfile" ] && new_romfile="$old_romfile.out" || :

	print_green ">>> Analysing source firmware: $old_romfile ..."

	#### FIXME: Do not verify SquashFS before we can cover all formats
	#local fw_magic=`cat "$old_romfile" | get_magic_word`
	#if [ "$fw_magic" != "2705" ]; then
	#	echo "*** Not a valid sysupgrade firmware file."
	#	exit 1
	#fi

	# Search for SquashFS offset
	local squashfs_offset=`hexof 68737173 "$old_romfile"`
	if [ -n "$squashfs_offset" ]; then
		echo "Found SquashFS at $squashfs_offset."
	else
		echo "*** Cannot find SquashFS magic in firmware. Not a valid sysupgrade image?"
		exit 1
	fi

	print_green ">>> Extracting kernel, rootfs partitions ..."

	# Partition: kernel
	# dd if="$old_romfile" bs=1 count=$squashfs_offset > uImage.bin
	head "$old_romfile" -c$squashfs_offset > uImage.bin
	# Partition: rootfs
	# dd if="$old_romfile" bs=1 skip=$squashfs_offset > root.squashfs.orig
	tail "$old_romfile" -c+`expr $squashfs_offset + 1` > root.squashfs.orig

	print_green ">>> Extracting SquashFS into directory squashfs-root/ ..."
	# Extract the file system, to squashfs-root/
	rm -rf squashfs-root
	unsquashfs root.squashfs.orig
	local rootfs_root=squashfs-root
	#mv squashfs-root $rootfs_root

	#######################################################
	print_green ">>> Patching the firmware ..."
	rm -rf /tmp/opkg-lists
	if ( cd $rootfs_root; modify_rootfs ); then
		__rc=0
	else
		__rc=$?
		if [ "$IGNORE_MODIFY_ERRORS" = Y ]; then
			__rc=0
		elif [ $__rc -ne 0 ]; then
			exit $__rc
		fi
	fi
	#######################################################

	# Rebuild SquashFS image
	print_green ">>> Repackaging the modified firmware ..."
	mksquashfs $rootfs_root root.squashfs -nopad -noappend -root-owned -comp xz -Xpreset 9 -Xe -Xlc 0 -Xlp 2 -Xpb 2 -b 256k -p '/dev d 755 0 0' -p '/dev/console c 600 0 0 5 1' -processors 1
	cat uImage.bin root.squashfs > "$new_romfile"
	padjffs2 "$new_romfile" 4 8 16 64 128 256

	print_green ">>> Done. New firmware: $new_romfile"

	# Copy files for rapid debugging
	[ -d /tftpboot ] && cp -vf "$new_romfile" /tftpboot/recovery.bin
	[ -L recovery.bin ] && ln -sf "$new_romfile" recovery.bin

	rm -f root.squashfs* uImage.bin
	rm -rf $rootfs_root /tmp/opkg-lists

	exit $__rc
}

clean_env()
{
	rm -f recovery.bin *.out
	rm -f root.squashfs* uImage.bin
	rm -rf $rootfs_root /tmp/opkg-lists
	rm -rf squashfs-root
}

case "$1" in
	-c) clean_env;;
	-h|--help) print_help;;
	*) do_firmware_repack "$@";;
esac

