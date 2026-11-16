#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
#
# Stage the GWRT theme and the PON WAN settings app into an OpenWrt tree.
#
# port/scripts/build.sh calls this by default (TYFZA1_GWRT_THEME=0 disables it);
# calling it by hand only stages the packages, it does not touch .config.
#
#   sh port/scripts/sync-gwrt-theme.sh /path/to/openwrt-checkout
#   APPLY_CONFIG=1 sh port/scripts/sync-gwrt-theme.sh /path/to/openwrt-checkout
#
# APPLY_CONFIG=1 also appends port/configs/gwrt-theme.config to <tree>/.config
# and runs `make defconfig`.  Without it the tree is only given the packages.
set -eu
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
umask 022
PORT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TREE=${1:?Usage: sync-gwrt-theme.sh /path/to/openwrt-checkout}
APPLY_CONFIG=${APPLY_CONFIG:-0}

test -d "$TREE/package" || {
    echo "not an OpenWrt tree: $TREE" >&2
    exit 1
}

mkdir -p "$TREE/package/luci-theme-gwrt"
rsync -a --delete "$PORT/packages/luci-theme-gwrt/" "$TREE/package/luci-theme-gwrt/"
mkdir -p "$TREE/package/luci-app-pon-wan"
rsync -a --delete "$PORT/packages/luci-app-pon-wan/" "$TREE/package/luci-app-pon-wan/"

# The theme package was lifted from the AN7581 GWRT suite, so its first-boot
# scripts also configure services this board does not have (OTA feed, gecoosac
# accelerator, storage/aria2/samba/nfs, hostname, apk autoinstall, dual-theme
# port).  Keep only the scripts the dashboard needs and drop the rest, so a
# TYFZA1 image is not reconfigured by a theme package.  GWRT_THEME_PRUNE=0 keeps
# the package byte-identical to the AN7581 source tree.
if [ "${GWRT_THEME_PRUNE:-1}" = 1 ]; then
    for script in \
        32_gwrt-ota-github-hosts \
        33_gwrt-dual-theme-port \
        33_gwrt-gecoosac \
        34_gwrt-autostart-policy \
        35_gwrt-apk-autoinstall \
        37_gwrt-dhcp-fp \
        40_gwrt-storage-setup \
        41_gwrt-aria2-setup \
        42_gwrt-samba-setup \
        43_gwrt-nfs-setup \
        44_gwrt-hostname; do
        rm -f "$TREE/package/luci-theme-gwrt/root/etc/uci-defaults/$script"
    done
fi

if [ "$APPLY_CONFIG" = 1 ]; then
    test -f "$TREE/.config" || {
        echo "missing $TREE/.config; generate it first" >&2
        exit 1
    }
    cp "$TREE/.config" "$TREE/.config.bak-gwrt-theme"
    {
        echo
        echo "# --- GWRT theme + PON WAN (port/configs/gwrt-theme.config) ---"
        cat "$PORT/configs/gwrt-theme.config"
    } >>"$TREE/.config"
    make -C "$TREE" defconfig
    echo "applied config to $TREE/.config (backup: .config.bak-gwrt-theme)"
fi

echo "staged luci-theme-gwrt + luci-app-pon-wan into $TREE/package/"