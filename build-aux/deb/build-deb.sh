#!/bin/sh
# Builds a .deb. The point of the native package is that it installs the udev
# rule itself, as root, at install time — so the dongle simply works afterwards
# and the user is never asked to copy anything.
#
# Written against dpkg-deb rather than debhelper so it runs with nothing beyond
# dpkg-dev and meson installed.
set -eu

cd "$(dirname "$0")/../.."
VERSION=$(sed -n "s/^  version: '\(.*\)',$/\1/p" meson.build | head -1)
ARCH=$(dpkg --print-architecture)
STAGE=$(pwd)/build-deb/stage
OUT=$(pwd)/build-deb

rm -rf "$OUT"
mkdir -p "$STAGE/DEBIAN"

meson setup build-deb/meson \
    --prefix=/usr \
    --buildtype=release \
    -Dudev_rules_dir=/usr/lib/udev/rules.d >/dev/null
meson install -C build-deb/meson --destdir "$STAGE" >/dev/null

# Ask dpkg what the binary actually needs rather than guessing. dpkg-shlibdeps
# reads debian/control relative to the working directory, so it has to be run
# from inside the staging tree with the stub placed there.
mkdir -p "$STAGE/debian"
printf 'Source: appairee\n' > "$STAGE/debian/control"
DEPENDS=$( cd "$STAGE" && dpkg-shlibdeps -O usr/bin/appairee 2>/dev/null \
    | sed 's/^shlibs:Depends=//' )
rm -rf "$STAGE/debian"

# An empty Depends would install cleanly on a machine with no GTK and then fail
# to start, so treat it as a build failure rather than shipping it.
if [ -z "$DEPENDS" ]; then
    echo "dpkg-shlibdeps produced no dependencies; refusing to build" >&2
    exit 1
fi

cat > "$STAGE/DEBIAN/control" <<CONTROL
Package: appairee
Version: $VERSION
Section: sound
Priority: optional
Architecture: $ARCH
Depends: $DEPENDS
Maintainer: Benjamin Bellamy <benjamin@castopod.org>
Description: Settings for the Sennheiser BTD 700 Bluetooth dongle
 Appairée changes the settings stored inside a Sennheiser BTD 700 USB
 Bluetooth dongle: audio mode, Bluetooth codec, and the meaning of its
 status light. Those settings live in the dongle's own firmware and
 Sennheiser exposes them only through its Windows and macOS application.
 .
 The dongle protocol is btd700ctl by sobalap, built in.
CONTROL

cat > "$STAGE/DEBIAN/postinst" <<'POSTINST'
#!/bin/sh
set -e
# The rule is already on disk; udev only needs to be told, and existing devices
# re-evaluated, so that a dongle plugged in before the install also works.
if [ "$1" = "configure" ]; then
    udevadm control --reload-rules || true
    udevadm trigger --subsystem-match=usb --subsystem-match=hidraw || true
fi
POSTINST
chmod 755 "$STAGE/DEBIAN/postinst"

DEB="$OUT/appairee_${VERSION}_${ARCH}.deb"
dpkg-deb --root-owner-group --build "$STAGE" "$DEB" >/dev/null
echo "$DEB"
