#!/bin/bash -e

LIBRARY_DIR=/usr/lib/hiwifi-repack

export MODEL_NAME=
export MAJOR_ARCH=
export SUBMODEL=
KERNEL_OFFSET_64K=
SQUASHFS_OFFSET_64K=
ENABLE_ROOT_LOGIN=N
UNLOCK_UBOOT=N
STRIP_UBOOT=N
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
 -s <sub_model>            specify a sub model name
 -r <package>              remove opkg package (can be multiple)
 -i <package>              install package with ipk file path or URL (can be multiple)
 -e                        enable root login
 -u                        unlock U-boot by replacing with an old version
 -U                        strip U-boot from firmware (plain 'sysupgrade' format)
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

	# Write sub model info
	if [ -n "$SUBMODEL" ]; then
		local __model="$MODEL_NAME-$SUBMODEL"
		print_red "WARNING: New firmware model will be '$__model'."
		echo "$SUBMODEL" > etc/.submodel
	fi

	# Root the firmware
	if [ "$ENABLE_ROOT_LOGIN" = Y ]; then
		if ! grep 'tty[SA]' etc/inittab &>/dev/null; then
			case "$MAJOR_ARCH" in
				ar71xx) echo 'ttyATH0::askfirst:/bin/ash --login' >> etc/inittab;;
				ralink) echo 'ttyS1::askfirst:/bin/ash --login' >> etc/inittab;;
			esac
		fi
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

	# Parse options and parameters
	local opt
	while [ $# -gt 0 ]; do
		case "$1" in
			-s)
				shift 1
				SUBMODEL="$1"
				;;
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
			-u)
				UNLOCK_UBOOT=Y
				;;
			-U)
				STRIP_UBOOT=Y
				;;
			-e)
				ENABLE_ROOT_LOGIN=Y
				UNLOCK_UBOOT=Y
				;;
			-x)
				shift 1
				ROOTFS_CMDS="$ROOTFS_CMDS$1
"
				;;
			-h|--help)
				print_help
				exit 0
				;;
			-*)
				echo "*** Unknown option '$1'."
				exit 1
				;;
			*)
				if [ -z "$MODEL_NAME" ]; then
					MODEL_NAME=`echo "$1" | tr '[a-z]' '[A-Z]'`
				elif [ -z "$old_romfile" ]; then
					old_romfile="$1"
				else
					echo "*** Useless parameter: $1".
					exit 1
				fi
				;;
		esac
		shift 1
	done

	case "$MODEL_NAME" in
		HC6361|HC6341)
			MAJOR_ARCH=ar71xx; KERNEL_OFFSET_64K=2
			;;
		HC5761|HC5661|HC5663)
			MAJOR_ARCH=ralink; KERNEL_OFFSET_64K=5
			;;
		"")
			print_help; exit 1
			;;
		*)
			echo "*** Unsupported model: $MODEL_NAME."; exit 1
			;;
	esac


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

	# Check if firmware is in "SquashFS" type
	local fw_magic=`cat "$old_romfile" | get_magic_word`
	if [ "$fw_magic" = "2705" ]; then
		echo ""
		echo "***************************************************"
		echo "*** WARNING: Firmware is SquashFS without u-boot."
		echo "***************************************************"
		echo ""
		#
		KERNEL_OFFSET_64K=0
		cp -f $LIBRARY_DIR/$MODEL_NAME-oemparts.bin $MODEL_NAME-oemparts.bin
	else
		if [ "$UNLOCK_UBOOT" = Y ]; then
			print_red "WARNING: Replacing U-boot with unlocked version."
			cp -f $LIBRARY_DIR/$MODEL_NAME-oemparts.bin $MODEL_NAME-oemparts.bin
		else
			dd if="$old_romfile" bs=64k count=$KERNEL_OFFSET_64K > $MODEL_NAME-oemparts.bin
		fi
	fi

	# Search for SquashFS offset
	local __offset_64k=`expr $KERNEL_OFFSET_64K + 8`
	while [ $__offset_64k -lt 32 ]; do
		local __magic=`dd if="$old_romfile" bs=64k skip=$__offset_64k count=1 2>/dev/null | get_magic_long`
		if [ "$__magic" = 68737173 ]; then
			SQUASHFS_OFFSET_64K=$__offset_64k
			echo "Found SquashFS at 64k * $__offset_64k."
			break
		fi
		__offset_64k=`expr $__offset_64k + 1`
	done
	if [ -z "$SQUASHFS_OFFSET_64K" ]; then
		echo "*** Cannot find SquashFS offset in firmware."
		exit 1
	fi

	print_green ">>> Extracting kernel, rootfs partitions ..."

	# Partition: kernel
	dd if="$old_romfile" bs=64k skip=$KERNEL_OFFSET_64K count=`expr $SQUASHFS_OFFSET_64K - $KERNEL_OFFSET_64K` > $MODEL_NAME-uImage.bin
	# Partition: rootfs
	dd if="$old_romfile" bs=64k skip=$SQUASHFS_OFFSET_64K > root.squashfs.orig

	print_green ">>> Extracting SquashFS into directory squashfs-root/ ..."
	# Extract the file system, to squashfs-root/
	rm -rf squashfs-root
	unsquashfs root.squashfs.orig
	local rootfs_root=squashfs-root

	#######################################################
	print_green ">>> Patching the firmware ..."
	rm -rf /tmp/opkg-lists
	( cd $rootfs_root; modify_rootfs )  # exits on error since 'bash -e' was used
	#######################################################

	# Rebuild SquashFS image
	print_green ">>> Repackaging the modified firmware ..."
	mksquashfs $rootfs_root root.squashfs -nopad -noappend -root-owned -comp xz -Xpreset 9 -Xe -Xlc 0 -Xlp 2 -Xpb 2 -b 256k -processors 1

	if [ "$STRIP_UBOOT" = Y ]; then
		print_red "WARNING: Firmware is being rebuilt without U-boot."
		cat $MODEL_NAME-uImage.bin root.squashfs > "$new_romfile"
	else
		cat $MODEL_NAME-oemparts.bin $MODEL_NAME-uImage.bin root.squashfs > "$new_romfile"
	fi

	padjffs2 "$new_romfile" 4 8 16 64 128 256

	print_green ">>> Done. New firmware: $new_romfile"

	# Copy files for rapid debugging
	[ -d /tftpboot ] && cp -vf "$new_romfile" /tftpboot/recovery.bin
	[ -L recovery.bin ] && ln -sf "$new_romfile" recovery.bin

	rm -f root.squashfs* *-uImage.bin *-oemparts.bin
	rm -rf $rootfs_root /tmp/opkg-lists

	exit 0
}

clean_env()
{
	rm -f recovery.bin *.out
	rm -f root.squashfs* *-uImage.bin *-oemparts.bin
	rm -rf $rootfs_root /tmp/opkg-lists
	rm -rf squashfs-root
}

case "$1" in
	-c) clean_env;;
	-h|--help) print_help;;
	*) do_firmware_repack "$@";;
esac

