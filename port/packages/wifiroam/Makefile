#
# wifiroam 基包（自预置 apk 还原）
#
# 上游 wifiroam 0.1.0-r1 只有预编译 apk，本仓以源码形式重建同一份内容：
#   /usr/share/wifiroam/wifiroamd.uc   procd 守护进程（ucode）
#   /etc/init.d/wifiroam               START=99 / STOP=10，respawn 3600 5 5
#   /etc/config/wifiroam               globals/roam/backhaul/alias_sync
#   /lib/upgrade/keep.d/wifiroam       保留 /etc/wifiroam/aliases.json
#
include $(TOPDIR)/rules.mk

PKG_NAME:=wifiroam
PKG_VERSION:=0.1.0
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0-or-later

include $(INCLUDE_DIR)/package.mk

define Package/wifiroam
  SECTION:=net
  CATEGORY:=Network
  PKGARCH:=all
  TITLE:=wifiroam multi-AP topology and 802.11k/v/r roaming daemon
  DEPENDS:=+ucode +ucode-mod-ubus +ucode-mod-uloop +ucode-mod-socket \
	+ucode-mod-fs +ucode-mod-uci +ucode-mod-digest
endef

define Package/wifiroam/description
  wifiroam daemon with cap/sap/unconfigured roles, UDP 50607 discovery,
  and roaming helpers. Restored from the vendored 0.1.0-r1 apk.
endef

define Package/wifiroam/conffiles
/etc/config/wifiroam
endef

define Build/Compile
endef

define Package/wifiroam/install
	$(INSTALL_DIR) $(1)/etc/init.d $(1)/etc/config
	$(INSTALL_BIN) ./files/etc/init.d/wifiroam $(1)/etc/init.d/wifiroam
	$(INSTALL_CONF) ./files/etc/config/wifiroam $(1)/etc/config/wifiroam
	$(INSTALL_DIR) $(1)/usr/share/wifiroam
	$(INSTALL_DATA) ./files/usr/share/wifiroam/wifiroamd.uc $(1)/usr/share/wifiroam/wifiroamd.uc
	$(INSTALL_DIR) $(1)/lib/upgrade/keep.d
	$(INSTALL_DATA) ./files/lib/upgrade/keep.d/wifiroam $(1)/lib/upgrade/keep.d/wifiroam
endef

$(eval $(call BuildPackage,wifiroam))