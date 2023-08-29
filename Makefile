#
# Copyright (C) 2022-2023 muink
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=natter
PKG_VERSION=0.9
PKG_RELEASE:=20230828

PKG_MAINTAINER:=muink <hukk1996@gmail.com>
PKG_LICENSE:=GPL-3
PKG_LICENSE_FILES:=LICENSE

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/MikeWang000000/Natter.git
PKG_SOURCE_VERSION:=b84622e39ea9a5247e772078a8aaaf3be0e667d7

PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Open Port under FullCone NAT (NAT 1)
	URL:=https://github.com/MikeWang000000/Natter
	DEPENDS:=+python3-light +bash +coreutils-base64 +curl +jsonfilter \
		+$(PKG_NAME)-notify-script-telegram \
		+$(PKG_NAME)-ddns-script-cloudflare
	PKGARCH:=all
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/$(PKG_NAME)
/etc/config/$(PKG_NAME)-plugins
/etc/$(PKG_NAME)/custom-script.sh
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -n "$${IPKG_INSTROOT}" ]; then
[ -f "$${IPKG_INSTROOT}/usr/sbin/nft" ] && FW='fw4' || FW='fw3'
sed -i "\$$a\\\n\
config include '$(PKG_NAME)'\n\
\toption type 'script'\n\
\toption path '/usr/share/$(PKG_NAME)/$$FW.include'\
" "$${IPKG_INSTROOT}/etc/config/firewall"
if [ "$$FW" == "fw3" ]; then
sed -i "\$$a\\
\toption family 'any'\n\
\toption reload '1'\
" "$${IPKG_INSTROOT}/etc/config/firewall"
fi
else
	[ -x "$$(command -v nft)" ] && FW='fw4' || FW='fw3'
	uci -q batch <<-EOF
		delete firewall.$(PKG_NAME)
		set firewall.$(PKG_NAME)=include
		set firewall.$(PKG_NAME).type=script
		set firewall.$(PKG_NAME).path=/usr/share/$(PKG_NAME)/$$FW.include
		commit firewall
	EOF
	if [ "$$FW" == "fw3" ]; then
	uci -q batch <<-EOF
		set firewall.$(PKG_NAME).family=any
		set firewall.$(PKG_NAME).reload=1
		commit firewall
	EOF
	fi
fi
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
uci delete firewall.$(PKG_NAME)
uci commit firewall
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./natter $(1)/usr/sbin/natter

	$(INSTALL_DIR) $(1)/usr/share/$(PKG_NAME)
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/natter-hook.sh $(1)/usr/share/$(PKG_NAME)/natter-hook.sh
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/natter.py $(1)/usr/share/$(PKG_NAME)/natter.py
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/natter-config.template.json $(1)/usr/share/$(PKG_NAME)/natter-config.template.json

	$(INSTALL_DATA) ./files/fw3.include $(1)/usr/share/$(PKG_NAME)/fw3.include
	$(INSTALL_DATA) ./files/fw4.include $(1)/usr/share/$(PKG_NAME)/fw4.include
	$(INSTALL_BIN) ./files/plugins.sh $(1)/usr/share/$(PKG_NAME)/plugins.sh

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/natter.init $(1)/etc/init.d/$(PKG_NAME)

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/natter.config $(1)/etc/config/$(PKG_NAME)
	$(INSTALL_CONF) ./files/natter-plugins.config $(1)/etc/config/$(PKG_NAME)-plugins

	$(INSTALL_DIR) $(1)/usr/libexec/$(PKG_NAME)
	$(INSTALL_BIN) ./files/natcheck.sh $(1)/usr/libexec/$(PKG_NAME)/natcheck.sh

	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_DATA) ./files/natter.hotplug $(1)/etc/hotplug.d/iface/70-$(PKG_NAME)

	$(INSTALL_DIR) $(1)/usr/share/nftables.d
	$(CP) ./files/nftables.d/* $(1)/usr/share/nftables.d/

	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/uci-defaults $(1)/etc/uci-defaults/70_$(PKG_NAME)
endef

define Package/$(PKG_NAME)-scripts/Default
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Natter $(1) scripts ($(2))
	DEPENDS:=+natter
	PROVIDES:=natter-$(1)-scripts
	PKGARCH:=all
endef

define Package/$(PKG_NAME)-notify-script-telegram
	$(call Package/$(PKG_NAME)-scripts/Default,notify,telegram)
	DEPENDS+:=
endef

define Package/$(PKG_NAME)-notify-script-pushbullet
	$(call Package/$(PKG_NAME)-scripts/Default,notify,pushbullet)
	DEPENDS+:=
endef

define Package/$(PKG_NAME)-ddns-script-cloudflare
	$(call Package/$(PKG_NAME)-scripts/Default,ddns,cloudflare)
	DEPENDS+:=
endef

define Package/$(PKG_NAME)-scripts/install/Default
	$(INSTALL_DIR) $(1)/etc/$(PKG_NAME)/$(2)
	$(INSTALL_BIN) ./files/$(2)/$(3).sh $(1)/etc/$(PKG_NAME)/$(2)/
endef

define Package/$(PKG_NAME)-notify-script-telegram/install
	$(call Package/$(PKG_NAME)-scripts/install/Default,$(1),notify,telegram)
endef

define Package/$(PKG_NAME)-notify-script-pushbullet/install
	$(call Package/$(PKG_NAME)-scripts/install/Default,$(1),notify,pushbullet)
endef

define Package/$(PKG_NAME)-ddns-script-cloudflare/install
	$(call Package/$(PKG_NAME)-scripts/install/Default,$(1),ddns,cloudflare)
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
$(eval $(call BuildPackage,$(PKG_NAME)-notify-script-telegram))
$(eval $(call BuildPackage,$(PKG_NAME)-notify-script-pushbullet))
$(eval $(call BuildPackage,$(PKG_NAME)-ddns-script-cloudflare))
