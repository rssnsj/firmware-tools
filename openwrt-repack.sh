#!/bin/bash -e

export SQUASHFS_ROOT=`pwd`/squashfs-root
ENABLE_ROOT_LOGIN=Y
ENABLE_WIRELESS=N
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
 $arg0 <major_model> <ROM_file> ...  patch firmware <ROM_file> and repackage
 $arg0 -c                            clean temporary and target files

Options:
 -o <output_file>          filename of newly built firmware
 -r <package>              remove opkg package, can be multiple
 -i <ipk_file>             install package with ipk file path or URL, can be multiple
 -e                        enable root login
 -w                        enable wireless by default
 -x <commands>             execute commands after all other operations
EOF
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

	# Run custom commands
	sh -c "$ROOTFS_CMDS" || __rc=101

	# Fix auto-start symlinks for /etc/init.d scripts
	print_green "Checking init.d scripts for newly installed services ..."
	local initsc
	for initsc in etc/init.d/*; do
		local initname=`basename "$initsc"`
		local start_no=`awk -F= '/^START=/{print $2; exit}' "$initsc"`
		local stop_no=`awk -F= '/^STOP=/{print $2; exit}' "$initsc"`
		if [ -n "$start_no" -o -n "$stop_no" ] && ! ls -d etc/rc.d/*$initname >/dev/null 2>&1; then
			echo "Setting auto-startup for '$initname' ..."
			[ -n "$start_no" ] && ln -sf ../init.d/$initname etc/rc.d/S$start_no$initname || :
			[ -n "$stop_no" ] && ln -sf ../init.d/$initname etc/rc.d/K$stop_no$initname || :
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
			-x)
				shift 1
				ROOTFS_CMDS="$1"
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
		exit 1
	fi
	[ -z "$new_romfile" ] && new_romfile="$old_romfile.out" || :

	print_green ">>> Analysing source firmware: $old_romfile ..."

	# Check if firmware is in "SquashFS" type
	local fw_magic=`cat "$old_romfile" | get_magic_word`
	if [ "$fw_magic" != "2705" ]; then
		echo "*** Not a valid sysupgrade firmware file."
		exit 1
	fi

	# Search for SquashFS offset
	local squashfs_offset=`hexof 68737173 "$old_romfile"`
	if [ -n "$squashfs_offset" ]; then
		echo "Found SquashFS at $squashfs_offset."
	else
		echo "*** Cannot find SquashFS magic in firmware."
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
	rm -rf $SQUASHFS_ROOT
	unsquashfs root.squashfs.orig

	#######################################################
	print_green ">>> Patching the firmware ..."
	( cd $SQUASHFS_ROOT; modify_rootfs )
	# NOTICE: Ignore errors for "opkg install"
	if [ $? -eq 104 ]; then
		__rc=104
	elif [ $? -ne 0 ]; then
		exit 1
	fi
	#######################################################

	# Rebuild SquashFS image
	print_green ">>> Repackaging the modified firmware ..."
	mksquashfs $SQUASHFS_ROOT root.squashfs -nopad -noappend -root-owned -comp xz -Xpreset 9 -Xe -Xlc 0 -Xlp 2 -Xpb 2 -b 256k -p '/dev d 755 0 0' -p '/dev/console c 600 0 0 5 1' -processors 1
	cat uImage.bin root.squashfs > "$new_romfile"
	padjffs2 "$new_romfile" 4 8 16 64 128 256

	print_green ">>> Done. New firmware: $new_romfile"

	# Copy files for rapid debugging
	[ -d /tftpboot ] && cp -vf "$new_romfile" /tftpboot/recovery.bin
	[ -L recovery.bin ] && ln -sf "$new_romfile" recovery.bin

	rm -f root.squashfs* uImage.bin

	exit $__rc
}

clean_env()
{
	rm -f recovery.bin *.out
	rm -f root.squashfs* uImage.bin
	rm -rf squashfs-root
}

case "$1" in
	-c) clean_env;;
	-h|--help) print_help;;
	*) do_firmware_repack "$@";;
esac

