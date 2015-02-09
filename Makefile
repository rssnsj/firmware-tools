
all: src/squashfs-tools/mksquashfs src/squashfs-tools/unsquashfs \
	src/padjffs2/padjffs2 src/opkg/src/opkg-cl

src/squashfs-tools/mksquashfs src/squashfs-tools/unsquashfs:
	make -C src/squashfs-tools
src/padjffs2/padjffs2:
	make -C src/padjffs2
src/opkg/src/opkg-cl:
	cd src/opkg; ./autogen.sh --disable-curl --disable-gpg --with-opkgetcdir=/etc --with-opkglockfile=/tmp/opkg.lock
	make -C src/opkg

clean:
	make clean -C src/squashfs-tools
	make clean -C src/padjffs2
	make clean -C src/opkg

install: all
	install -m755 src/squashfs-tools/mksquashfs src/squashfs-tools/unsquashfs /usr/bin/
	install -m755 src/padjffs2/padjffs2 /usr/bin/
	install -m755 src/opkg/src/opkg-cl /usr/bin/
	install -m755 src/opkg.sh /usr/bin/opkg
	install -m755 src/lua/src/luac /usr/bin/
	install -m755 hiwifi-repack.sh /usr/bin/
	mkdir -p /usr/share/firmware-merger
	cp -f *-oemparts.bin /usr/share/firmware-merger/
	install -m755 scripts/*.sh /usr/bin/

