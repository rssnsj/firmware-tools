firmware-tools
==============

OpenWrt firmware patching and repackaging tools

### Installation

    git clone https://github.com/rssnsj/firmware-tools.git firmware-tools
    cd firmware-tools
    make install

### Usage

     openwrt-repack.sh <major_model> <ROM_file> ...  patch firmware <ROM_file> and repackage
     openwrt-repack.sh -c                            clean temporary and target files
     
    Options:
    -o <output_file>          filename of newly built firmware
    -r <package>              remove opkg package, can be multiple
    -i <ipk_file>             install package with ipk file path or URL, can be multiple
    -e                        enable root login
    -w                        enable wireless by default
    -x <commands>             execute commands after all other operations

### Example

    rssnsj@precise-vmx:~/roms$ openwrt-repack.sh openwrt-ramips-mt7620a-hiwifi-hc5761-squashfs-sysupgrade.bin -w -e -i tcpdump
    >>> Analysing source firmware: openwrt-ramips-mt7620a-hiwifi-hc5761-squashfs-sysupgrade.bin ...
    Found SquashFS at 1077084.
    >>> Extracting kernel, rootfs partitions ...
    >>> Extracting SquashFS into directory squashfs-root/ ...
    Parallel unsquashfs: Using 4 processors
    1488 inodes (1502 blocks) to write
    
    [====|                                                                                                                                                     ]   49/1502   3%
    create_inode: could not create character device squashfs-root/dev/console, because you're not superuser!
    [========================================================================================================================================================/ ] 1501/1502  99%
    created 1259 files
    created 104 directories
    created 228 symlinks
    created 0 devices
    created 0 fifos
    >>> Patching the firmware ...
    Downloading http://downloads.openwrt.org/barrier_breaker/14.07/ramips/mt7620a/packages/base/Packages.gz.
    Inflating http://downloads.openwrt.org/barrier_breaker/14.07/ramips/mt7620a/packages/base/Packages.gz.
    Updated list of available packages in /home/rssnsj/roms/squashfs-root//var/opkg-lists/barrier_breaker_base.
    Downloading http://downloads.openwrt.org/barrier_breaker/14.07/ramips/mt7620a/packages/luci/Packages.gz.
    Inflating http://downloads.openwrt.org/barrier_breaker/14.07/ramips/mt7620a/packages/luci/Packages.gz.
    Updated list of available packages in /home/rssnsj/roms/squashfs-root//var/opkg-lists/barrier_breaker_luci.
    Downloading http://downloads.openwrt.org/barrier_breaker/14.07/ramips/mt7620a/packages/oldpackages/Packages.gz.
    Inflating http://downloads.openwrt.org/barrier_breaker/14.07/ramips/mt7620a/packages/oldpackages/Packages.gz.
    Updated list of available packages in /home/rssnsj/roms/squashfs-root//var/opkg-lists/barrier_breaker_oldpackages.
    Downloading http://downloads.openwrt.org/barrier_breaker/14.07/ramips/mt7620a/packages/packages/Packages.gz.
    Inflating http://downloads.openwrt.org/barrier_breaker/14.07/ramips/mt7620a/packages/packages/Packages.gz.
    Updated list of available packages in /home/rssnsj/roms/squashfs-root//var/opkg-lists/barrier_breaker_packages.
    Downloading http://downloads.openwrt.org/barrier_breaker/14.07/ramips/mt7620a/packages/routing/Packages.gz.
    Inflating http://downloads.openwrt.org/barrier_breaker/14.07/ramips/mt7620a/packages/routing/Packages.gz.
    Updated list of available packages in /home/rssnsj/roms/squashfs-root//var/opkg-lists/barrier_breaker_routing.
    Downloading http://downloads.openwrt.org/barrier_breaker/14.07/ramips/mt7620a/packages/telephony/Packages.gz.
    Inflating http://downloads.openwrt.org/barrier_breaker/14.07/ramips/mt7620a/packages/telephony/Packages.gz.
    Updated list of available packages in /home/rssnsj/roms/squashfs-root//var/opkg-lists/barrier_breaker_telephony.
    Installing tcpdump (4.5.1-4) to root...
    Downloading http://downloads.openwrt.org/barrier_breaker/14.07/ramips/mt7620a/packages/base/tcpdump_4.5.1-4_ramips_24kec.ipk.
    Installing libpcap (1.5.3-1) to root...
    Downloading http://downloads.openwrt.org/barrier_breaker/14.07/ramips/mt7620a/packages/base/libpcap_1.5.3-1_ramips_24kec.ipk.
    Configuring libpcap.
    Configuring tcpdump.
    Checking init.d scripts for newly installed services ...
    >>> Repackaging the modified firmware ...
    Parallel mksquashfs: Using 1 processor
    Creating 4.0 filesystem on root.squashfs, block size 262144.
    Pseudo file "/dev" exists in source filesystem "/home/rssnsj/roms/squashfs-root/dev".
    Ignoring, exclude it (-e/-ef) to override.
    [=========================================================================================================================================================|] 1281/1281 100%
    Exportable Squashfs 4.0 filesystem, xz compressed, data block size 262144
            compressed data, compressed metadata, compressed fragments, compressed xattrs
            duplicates are removed
    Filesystem size 5765.15 Kbytes (5.63 Mbytes)
            31.05% of uncompressed filesystem size (18567.38 Kbytes)
    Inode table size 12810 bytes (12.51 Kbytes)
            24.24% of uncompressed inode table size (52840 bytes)
    Directory table size 15678 bytes (15.31 Kbytes)
            46.62% of uncompressed directory table size (33629 bytes)
    Number of duplicate files found 9
    Number of inodes 1600
    Number of files 1265
    Number of fragments 52
    Number of symbolic links  230
    Number of device nodes 1
    Number of fifo nodes 0
    Number of socket nodes 0
    Number of directories 104
    Number of ids (unique uids + gids) 1
    Number of uids 1
            root (0)
    Number of gids 1
            root (0)
    padding image to 006a9000
    padding image to 006aa000
    padding image to 006ac000
    padding image to 006b0000
    padding image to 006c0000
    >>> Done. New firmware: openwrt-ramips-mt7620a-hiwifi-hc5761-squashfs-sysupgrade.bin.out
    rssnsj@precise-vmx:~/roms$
