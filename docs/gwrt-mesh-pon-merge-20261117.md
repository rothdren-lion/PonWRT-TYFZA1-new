# GWRT mesh + agent 移植到 TYFZA1（2026-11-17）

目标：把 GWRT 的 agent 与 mesh 三件套接入本仓库的 TYFZA1（RTL9617C / PON）构建，
使 `build-release.yml` 产出的固件包含这些包。

## 接入方式

| 位置 | 作用 |
| --- | --- |
| `port/packages/gwrt-agent/` | 遥测 + APP 命令 agent，CGI、mesh 窗口、mesh 遥测载荷 |
| `port/packages/gwrt-mesh-led/` | mesh 状态灯、WPS/BTN 一键配对 |
| `port/packages/gwrt-mesh-apmode/` | 路由 ↔ 真 AP 状态机 |
| `port/packages/gwrt-wifiroam-v5/` | wifiroam v5 页面/守护进程覆盖层 + `wifiroam-dpi`（默认不启用） |
| `port/packages/gwrt-mesh-defaults/` | 本移植新增：只做启用，不动网络/无线/PON |
| `port/scripts/sync-gwrt-mesh.sh` | 把上述包拷进 OpenWrt 树 |
| `port/configs/gwrt-mesh.config` | 包选择片段，由 `build.sh` 追加进 `.config` |
| `port/scripts/build.sh` | `TYFZA1_GWRT_MESH=1`（默认）时同步包、追加配置、校验包存在 |

`TYFZA1_GWRT_MESH=0` 可退回不含 mesh 的构建。

## 与 AN7581 树的差异（安全相关）

1. **AP 模式默认关闭**：`gwrt.mesh_apmode.enabled='0'`。上游默认 `1` 会在检测到已组网后
   关闭本机 dnsmasq/odhcpd 并把 WAN 并进 br-lan；TYFZA1 是 PON 主路由，触发即断网。
   需要子节点行为时从 LuCI/APP 手动打开。
2. **移除 IPv6 首启钩子**：`90_gwrt-agent-ipv6`、`gwrt-ipv6-auto`（面向 AN7581/SS-01，
   会改 `gwrt.ipv6` 的 auto/pd/relay）。`GWRT_MESH_PRUNE=0` 可保留原始包。
3. **不引入 `gwrt-device-defaults`**：685K，含 MT7981 专属逻辑与预编译 aarch64 apk 预设。

## 未解决：wifiroam 基包

mesh 三包与 agent 运行时都调用上游 `wifiroam`（`/etc/init.d/wifiroam`、
`/usr/share/wifiroam/`、`/etc/config/wifiroam`、LuCI view 与 menu）。

该包不在 OpenWrt 官方 feeds，本仓库也没有其源码。AN7581 树只有预编译 apk
（`gwrt-device-defaults/files/apk/wifiroam-0.1.0-r1.apk`，apk-tools v3 格式，22588 字节）。

因此本固件里：

- `gwrt-agent` 上报与 APP 命令通道可用；
- `gwrt-mesh-led` 状态灯可用；
- **mesh 配对与 AP 模式不可用**，因为 `wifiroam` 的 cli/uci 界面不存在；
- `gwrt-wifiroam-v5` 默认不打包，覆盖层缺少基包时无意义。

补法（择一）：把 wifiroam 源码做成包加入 `port/packages/`；或提取预编译 apk 内容做成
`PKGARCH:=all` 的文件包（需要能解 apk-tools v3 的工具）。

## 验证

- `sh -n` 通过：`port/scripts/build.sh`、`port/scripts/sync-gwrt-mesh.sh`、
  `gwrt-mesh-defaults` 的 uci-defaults。
- 5 个包 Makefile 在假 `TOPDIR` 下 `make` 解析通过（无真机/树完整编译验证）。
- 真机未验证：未刷机、未连接设备。CI 编译结果见本轮 GitHub 运行。