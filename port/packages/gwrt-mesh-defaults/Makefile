#
# GWRT mesh defaults for the TYFZA1 (RTL9617C) port
#
# Upstream GWRT packages only enable their services through the SS-01 first-boot
# script (gwrt-device-defaults), which is MT7981 specific and is not shipped
# here.  This package does the enabling part and nothing else: it never touches
# network, wireless or PON configuration.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=gwrt-mesh-defaults
PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0

include $(INCLUDE_DIR)/package.mk

define Package/gwrt-mesh-defaults
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=GWRT mesh first-boot enabling defaults
  DEPENDS:=+gwrt-agent +gwrt-mesh-led +gwrt-mesh-apmode
  PKGARCH:=all
endef

define Package/gwrt-mesh-defaults/description
  Enables the GWRT agent and mesh status LED on first boot and records the mesh
  UCI defaults.  AP mode (auto Wi-Fi backhaul via relayd) stays disabled until
  it is switched on from LuCI or the APP, so a PON board keeps its own routing.
endef

define Build/Compile
endef

define Package/gwrt-mesh-defaults/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/etc/uci-defaults/95_gwrt-mesh-defaults $(1)/etc/uci-defaults/95_gwrt-mesh-defaults
endef

$(eval $(call BuildPackage,gwrt-mesh-defaults))