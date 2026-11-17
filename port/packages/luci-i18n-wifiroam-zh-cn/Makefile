#
# wifiroam 简体中文翻译（自预置 apk 还原）
#
include $(TOPDIR)/rules.mk

PKG_NAME:=luci-i18n-wifiroam-zh-cn
PKG_VERSION:=0.261025
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0-or-later
PKGARCH:=all

include $(INCLUDE_DIR)/package.mk

define Package/luci-i18n-wifiroam-zh-cn
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=Chinese (simplified) translation for luci-app-wifiroam
  DEPENDS:=+luci-app-wifiroam
endef

define Package/luci-i18n-wifiroam-zh-cn/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/i18n/wifiroam.zh-cn.lmo \
		$(1)/usr/lib/lua/luci/i18n/wifiroam.zh-cn.lmo
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/etc/uci-defaults/luci-i18n-wifiroam-zh-cn \
		$(1)/etc/uci-defaults/luci-i18n-wifiroam-zh-cn
endef

$(eval $(call BuildPackage,luci-i18n-wifiroam-zh-cn))