#!/bin/sh
# Builds a single-file .flatpak bundle, the kind you can download and install
# directly. Exports to a local repository first, because that is what
# flatpak build-bundle reads from. Nothing is installed.
set -eu

cd "$(dirname "$0")/../.."
VERSION=$(sed -n "s/^  version: '\(.*\)',$/\1/p" meson.build | head -1)
MANIFEST=build-aux/flatpak/fr.benjaminbellamy.Appairee.yml
REPO=build-flatpak-repo
OUT="appairee-$VERSION.flatpak"

rm -rf "$REPO" build-flatpak
flatpak-builder --force-clean --repo="$REPO" build-flatpak "$MANIFEST" >/dev/null
# --runtime-repo matters for a bundle people download: without it, installing
# on a machine that has no GNOME runtime and no Flathub remote simply fails.
flatpak build-bundle \
    --runtime-repo=https://flathub.org/repo/flathub.flatpakrepo \
    "$REPO" "$OUT" fr.benjaminbellamy.Appairee >/dev/null
echo "$OUT"
