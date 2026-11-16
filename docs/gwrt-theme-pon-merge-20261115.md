# GWRT theme + PON settings merge (2026-11-15)

Staged, not built. Nothing in the pinned TYFZA1 build pipeline calls the new
files, so `port/scripts/prepare.sh` and `port/scripts/build.sh` behave exactly
as before.

## What was copied

| Destination | Source | Size |
|---|---|---|
| `port/packages/luci-theme-gwrt/` | `gwrt-theme-V3/theme/luci-theme-gwrt/` (AN7581 series tree) | 5.5M |
| `port/packages/luci-app-pon-wan/` | `package/gwrt-luci-app-pon-wan/luci-app-pon-wan/` | 32K |
| `port/configs/gwrt-theme.config` | theme part of `gwrt-theme-V3/manifest/config.fragment.an7581` + PON WAN app | — |
| `port/configs/gwrt-pon-an7581.packages` | `gwrt-mk-an7581-config.sh` PON package loop (reference) | — |
| `port/scripts/sync-gwrt-theme.sh` | new, opt-in staging script | — |

Theme package identity: `luci-theme-gwrt`, `PKG_VERSION:=1.0`,
`PKG_RELEASE:=117`, license Apache-2.0, only dependency `+luci-base`.

## What was deliberately left out

- **Airoha kernel PON drivers** (`kmod-airoha-xpon`, `kmod-airoha-pon-frontend`,
  `kmod-airoha-en7572`, `kmod-airoha-paged-bosa`) and the airoha userspace
  (`airoha-ponctl`, `airoha-pond`, `luci-app-pon`, `luci-app-iptv`). They
  DEPEND on `TARGET_airoha`; TYFZA1 is Realtek RTL9617CVW, so they cannot
  build or run here. Listed for reference only in
  `port/configs/gwrt-pon-an7581.packages`.
- **OAF / appfilter / bandix / coremark / ttyd** — the AN7581 generator strips
  these too (≈50 MB volume budget), and the request was theme + PON settings.
- The `overlays/package/gwrt-luci-app-oaf/` compatibility files
  (`Makefile`, `luasrc/view/admin_network/app_filter.htm`) from
  `gwrt-theme-V3/manifest/overlay-files.txt`; they only matter for OAF.
- No change to `port/scripts/sync-overlay.sh`, `port/scripts/build.sh`,
  `configs/feeds.conf`, or `sources.lock.json`.

## Why the theme is safe to drop in as-is

`port/packages/luci-theme-gwrt/root` is self-contained: it carries its own
helper scripts (`gwrt-clients*`, `gwrt-conntrack`, `gwrt-dhcp-fp`,
`gwrt-ppe-stats`, `gwrt-socinfo`, `gwrt-lan-alias`, `gwrt-ota`,
`gwrt-coremark`, `gwrt-gecoosac-sync`, `gwrt-apk-autoinstall`), its own
`init.d/gwrt-theme` repair hook and an `admin_status` dispatcher that replaces
`luci-mod-status`'s stock `index.ut`. External tools are optional at runtime:
`jsonfilter` is required by the OTA card, `curl`/`wget`/`uclient-fetch` are
probed. That is why `gwrt-theme.config` adds `jsonfilter`, `curl`,
`ca-bundle`.

The repair hook is why `PKG_RELEASE` must stay above 111 (the last field
package) — a lower release makes apk/opkg keep the old package and lets a
`luci-mod-status` upgrade restore the stock dashboard.

## Using it later

```sh
# stage packages only
sh port/scripts/sync-gwrt-theme.sh /path/to/openwrt

# stage packages and enable them in .config
APPLY_CONFIG=1 sh port/scripts/sync-gwrt-theme.sh /path/to/openwrt
```

To make the theme part of the normal image, add the two `rsync` lines from
that script to `port/scripts/sync-overlay.sh` and merge
`port/configs/gwrt-theme.config` into `port/configs/tyfza1-compat.config`.

## PON app adapted to this board (2026-11-15, second pass)

`luci-app-pon-wan` no longer ships the Airoha flavour. It is now written for the
single target of this repo, TYFZA1 / RTL9617CVW, and `PKG_RELEASE` is 2.

| Area | Change |
|---|---|
| `view/ponwan/config.js` | Chinese UI matching the bundled app; reads `/etc/config/pon` to show `enabled` and `mode` (GPON / XGS-PON / EPON) in the map description; warns when no `pon*` device exists; lists the current `network.wan.device` |
| `menu.d` | node moved to `admin/onu/pon-wan` ("PON WAN 与 VLAN", order 45, next to 上网配置 40), alias `admin/network/ponwan` kept |
| `acl.d` | added read access to `pon` for the mode display |
| `/etc/config/pon_wan` | Chinese comments; defaults unchanged (`enabled 0`, `uplink pon0`, `iface wan`, `proto dhcp`) |
| `pon-wan-apply` | disable path only restores the plain uplink when the WAN interface really points at the VLAN device this page created (`managed` check against `network.pon_wan_vlan.name`, falling back to `<uplink>.<vid>`), so a hand-made `pon0.100` survives |
| `Makefile` | `LUCI_TITLE` names RTL9617CVW/TYFZA1; license header corrected from Apache-2.0 to GPL-2.0-only to match `PKG_LICENSE` |

Why `pon0` stays the default: `board.d/02_network` on this target runs
`ucidef_set_interfaces_lan_wan "$lan_ports" "pon0"`, so `pon0` is the actual WAN
netdev. The app turns it into a netifd `8021q` device named `pon0.<vid>`,
exactly the shape netifd produces for a non-DSA uplink.

### Checks run (no compile)

- `sh -n` on `pon-wan-apply`, `node --check` on `config.js`, `python3 -m json.tool`
  on both `menu.d` and `acl.d` JSON.
- Stub harness (`/tmp/ponwan-t`, fake `uci`/`ubus`/`logger`) over the apply
  script: enable `vlan=41` writes the `8021q` device and binds `wan` to
  `pon0.41`, creating the wan firewall zone when it is missing; disable restores
  `pon0`; a hand-made `pon0.100` plus a stale `pon_wan_vlan` section is left
  untouched; `vlan=99999` is rejected before any write.

### Still unverified

- Whether the Realtek PON driver passes tagged frames and whether `pon0.<vid>`
  comes up: needs the real board with an OLT that tags the service VLAN.
- The bundled `admin/onu` app remains the place for VLAN/bridge/IPTV on that
  board; this app only owns the service-VLAN binding, so the two must not both
  rewrite `network.wan`.

## Theme wiring and uniform port tiles (2026-11-15, later)

### Uniform 网络接口 tiles

The AN7581 dashboard drew the WAN/PON row deliberately wider than the LAN row.
On TYFZA1 the PON port plus four LAN ports made that asymmetry look wrong, so
every tile now uses one width:

- `root/usr/share/ucode/luci/template/admin_status/index_gwrt.ut:2785`:
  `portGroup('wan', …, 1.12)` → weight `1`. The weight feeds
  `--gwrt-group-weight`, which `cascade.css:742` consumes as
  `.gwrt-port-group{flex:var(--gwrt-group-weight,1) 1 0%!important}`.
- `htdocs/luci-static/gwrt/css/cascade.css`: removed the two
  `.gwrt-port.wan` overrides (`156px` under 1240px, `148px` under 720px),
  changed the 901px+ rule from `.group-lan .gwrt-port{flex:0 0 155px}` to
  `.gwrt-port-group .gwrt-port{flex:0 0 150px}`, and dropped the container-query
  WAN basis from `164px` to `146px` per tile.

### build.sh integration

`port/scripts/build.sh` now stages and enables the theme by default:

- stages `luci-theme-gwrt` + `luci-app-pon-wan` through
  `port/scripts/sync-gwrt-theme.sh`,
- appends `port/configs/gwrt-theme.config` to `<tree>/.config` before
  `make defconfig`,
- requires `luci-theme-gwrt` and `luci-app-pon-wan` in the defconfig result,
- `TYFZA1_GWRT_THEME=0` restores the previous argon-only build.

Argon stays installed and keeps `CONFIG_PACKAGE_luci-theme-argon=y`
(`scripts/prepare_luci_feeds.sh` re-adds it), so the GWRT theme becomes active
through `luci.main.mediaurlbase`, which its own `31_luci-theme-gwrt` first-boot
script sets.

Because the package came from the AN7581 suite, `sync-gwrt-theme.sh` prunes
first-boot scripts for services this board does not have (OTA feed hosts,
gecoosac, dual-theme port, autostart policy, apk autoinstall, DHCP
fingerprinting, storage/aria2/samba/nfs/hostname). It keeps
`30_gwrt-banner`, `31_luci-theme-gwrt`, `33_gwrt-dashboard` and
`36_gwrt-clients-init`. `GWRT_THEME_PRUNE=0` stages the package unmodified.

### Build blocked

`port/scripts/build.sh <tree> <jobs>` stops before anything is downloaded:

```
PON runtime preparation failed: Missing mandatory PON input:
…/analysis/private/live-files/etc/serdes/pon_serdes_epon.txt
```

`tools/prepare_pon_runtime.py` needs the six stock SerDes tables
(`pon_serdes_{epon,epon_d10g,epon_bi10g,gpon,xgpon,xgspon}.txt`), which are
deliberately not in the repository; `analysis/private/live-files` is absent from
this clone, and no copy exists under `/home/godsun` or on the NAS download
share. Disk is the second blocker: `/home` has 20G free, too little for a full
RTL9617C world build.

Unblock options: point `TYFZA1_STOCK_INPUTS` at the stock `live-files` dump, set
`TYFZA1_RUNTIME_INPUTS` to an already-prepared PON runtime, or build on a host
with both the inputs and the disk.

### Push blocked

The three port commits (`4195b95`, `a5ce30c`, `7b8b6f6`) are committed locally but
not on GitHub. Every outbound 443 request from this host is refused
(`curl: (7) Failed to connect to github.com port 443 after 6 ms`), for github.com,
raw.githubusercontent.com and gitee.com alike, so `git push origin main` cannot
reach the remote. `origin/main` still points at upstream `f74af17`.
