#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
#
# Stage the GWRT mesh/agent packages into an OpenWrt tree.
#
# port/scripts/build.sh calls this by default (TYFZA1_GWRT_MESH=0 disables it);
# calling it by hand only stages the packages, it does not touch .config.
#
#   sh port/scripts/sync-gwrt-mesh.sh /path/to/openwrt-checkout
#   APPLY_CONFIG=1 sh port/scripts/sync-gwrt-mesh.sh /path/to/openwrt-checkout
#
# APPLY_CONFIG=1 also appends port/configs/gwrt-mesh.config to <tree>/.config
# and runs `make defconfig`.  Without it the tree is only given the packages.
#
# Packages staged:
#   gwrt-agent          telemetry/CGI agent + mesh window helpers
#   gwrt-mesh-led       mesh status LED, WPS/BTN pairing front-end
#   gwrt-mesh-apmode    router <-> real-AP state machine
#   gwrt-wifiroam-v5    wifiroam v5 page/daemon overlay + wifiroam-dpi
#   gwrt-mesh-defaults  enabling only (this port; see the uci-defaults)
#
# NOT staged: the upstream wifiroam base package.  It is not in any OpenWrt
# feed; the AN7581 tree only carries a prebuilt apk for it.  Mesh therefore
# needs that base package (or an extracted copy of it) before it can run.
set -eu
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
umask 022
PORT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TREE=${1:?Usage: sync-gwrt-mesh.sh /path/to/openwrt-checkout}
APPLY_CONFIG=${APPLY_CONFIG:-0}

test -d "$TREE/package" || {
    echo "not an OpenWrt tree: $TREE" >&2
    exit 1
}

for package in gwrt-agent gwrt-mesh-led gwrt-mesh-apmode gwrt-wifiroam-v5 gwrt-mesh-defaults; do
    test -d "$PORT/packages/$package" || {
        echo "missing $PORT/packages/$package" >&2
        exit 1
    }
    mkdir -p "$TREE/package/$package"
    rsync -a --delete "$PORT/packages/$package/" "$TREE/package/$package/"
done

# gwrt-agent ships an IPv6 first-boot hook written for the AN7581/SS-01 trees
# (it rewrites gwrt.ipv6 auto/pd/relay and enables gwrt-ipv6-auto).  TYFZA1 is a
# PON board whose WAN6 setup belongs to the PON service, so that hook is dropped
# by default.  GWRT_MESH_PRUNE=0 keeps the package byte-identical to source.
# The package Makefile installs those three files explicitly, so dropping the
# files without dropping the install lines breaks the build (missing source).
GWRT_AGENT_MAKEFILE="$TREE/package/gwrt-agent/Makefile"
prune_agent_file() {
    rm -f "$TREE/package/gwrt-agent/files/$1"
    # drop the matching "$(INSTALL_BIN) ./files/<path> ..." line
    grep -v "\./files/$1 " "$GWRT_AGENT_MAKEFILE" >"$GWRT_AGENT_MAKEFILE.tmp"
    mv "$GWRT_AGENT_MAKEFILE.tmp" "$GWRT_AGENT_MAKEFILE"
}

if [ "${GWRT_MESH_PRUNE:-1}" = 1 ]; then
    prune_agent_file etc/uci-defaults/90_gwrt-agent-ipv6
    prune_agent_file etc/init.d/gwrt-ipv6-auto
    prune_agent_file usr/sbin/gwrt-ipv6-auto.sh
fi

# Guard: every file a staged Makefile installs must exist in the staged tree.
for package in gwrt-agent gwrt-mesh-led gwrt-mesh-apmode gwrt-wifiroam-v5 gwrt-mesh-defaults; do
    makefile="$TREE/package/$package/Makefile"
    test -f "$makefile" || continue
    for stage in $(grep -o '\./files/[A-Za-z0-9._/-]*' "$makefile" | sort -u); do
        file=${stage#./}
        test -e "$TREE/package/$package/$file" || {
            echo "$package: Makefile installs missing $file" >&2
            exit 1
        }
    done
done

if [ "$APPLY_CONFIG" = 1 ]; then
    test -f "$TREE/.config" || {
        echo "missing $TREE/.config; generate it first" >&2
        exit 1
    }
    cp "$TREE/.config" "$TREE/.config.bak-gwrt-mesh"
    {
        echo
        echo "# --- GWRT mesh + agent (port/configs/gwrt-mesh.config) ---"
        cat "$PORT/configs/gwrt-mesh.config"
    } >>"$TREE/.config"
    make -C "$TREE" defconfig
    echo "applied config to $TREE/.config (backup: .config.bak-gwrt-mesh)"
fi

echo "staged gwrt-agent + gwrt-mesh-led + gwrt-mesh-apmode + gwrt-wifiroam-v5 + gwrt-mesh-defaults into $TREE/package/ (prune=${GWRT_MESH_PRUNE:-1})"