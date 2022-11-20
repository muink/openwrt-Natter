#
# Copyright (C) 2022 muink
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=natter
PKG_VERSION=0.9
PKG_RELEASE:=20221119

PKG_MAINTAINER:=muink <hukk1996@gmail.com>
PKG_LICENSE:=GPL-3
PKG_LICENSE_FILES:=LICENSE

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/MikeWang000000/Natter.git
PKG_SOURCE_VERSION:=42005887f95dcfdfd5ed995bf237003f2f80ccfd

PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Open Port under FullCone NAT (NAT 1)
	URL:=https://github.com/MikeWang000000/Natter
	DEPENDS:=+python3-light
	PKGARCH:=all
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/conffiles
/etc/$(PKG_NAME)/custom-script.sh
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ ! -f /etc/$(PKG_NAME)/custom-script.sh ]; then
	mkdir -p /etc/$(PKG_NAME) 2>/dev/null
	cat <<-EOF > /etc/$(PKG_NAME)/custom-script.sh
	#!/bin/sh
	#
	# Write your upload script below...
	EOF
	chmod 755 /etc/$(PKG_NAME)/custom-script.sh
fi
endef

define Package/$(PKG_NAME)/prerm
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/usr/share/$(PKG_NAME)
	$(SED) 's,# Write your upload script below...,exec /etc/$(PKG_NAME)/custom-script.sh "$$$$@",'    $(PKG_BUILD_DIR)/natter-hook.sh
	$(INSTALL_BIN) ./natter $(1)/usr/sbin/natter
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/natter-hook.sh $(1)/usr/share/$(PKG_NAME)/natter-hook.sh
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/natter.py $(1)/usr/share/$(PKG_NAME)/natter.py
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/natter-config.template.json $(1)/usr/share/$(PKG_NAME)/natter-config.template.json
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
