#
# wifiroam LuCI 页面（自预置 apk 还原）
#
# 四个视图：topology / clients / settings / pairing，
# 静态资源含 oui.js、common.js、wifiroam.css 与打赏二维码图。
#
include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-wifiroam
PKG_VERSION:=0.261025
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0-or-later
PKGARCH:=all

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-wifiroam
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=LuCI support for wifiroam seamless roaming
  DEPENDS:=+luci-base +wifiroam
endef

define Package/luci-app-wifiroam/description
  LuCI views, menu, and ACL for the wifiroam daemon.
endef

define Package/luci-app-wifiroam/install
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/wifiroam
	$(INSTALL_DATA) ./files/www/luci-static/resources/view/wifiroam/*.js \
		$(1)/www/luci-static/resources/view/wifiroam/
	$(INSTALL_DIR) $(1)/www/luci-static/resources/wifiroam
	$(INSTALL_DATA) ./files/www/luci-static/resources/wifiroam/wifiroam.css \
		$(1)/www/luci-static/resources/wifiroam/
	$(INSTALL_DATA) ./files/www/luci-static/resources/wifiroam/oui.js \
		$(1)/www/luci-static/resources/wifiroam/
	$(INSTALL_DATA) ./files/www/luci-static/resources/wifiroam/common.js \
		$(1)/www/luci-static/resources/wifiroam/
	$(INSTALL_DATA) ./files/www/luci-static/resources/wifiroam/donate-qr.png \
		$(1)/www/luci-static/resources/wifiroam/
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) ./files/usr/share/luci/menu.d/luci-app-wifiroam.json \
		$(1)/usr/share/luci/menu.d/luci-app-wifiroam.json
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./files/usr/share/rpcd/acl.d/luci-app-wifiroam.json \
		$(1)/usr/share/rpcd/acl.d/luci-app-wifiroam.json
endef

$(eval $(call BuildPackage,luci-app-wifiroam))