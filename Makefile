#
# Copyright (C) 2022 muink
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=natter
PKG_VERSION=0.9
PKG_RELEASE:=20230121

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
	DEPENDS:=+python3-light +bash +coreutils-base64
	PKGARCH:=all
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/$(PKG_NAME)
/etc/$(PKG_NAME)/custom-script.sh
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
[ -x "$$(which nft)" ] && FW='fw4' || FW='fw3'
white_script() {
	cat <<-EOF > /etc/$(PKG_NAME)/custom-script.sh
	#!/bin/sh
	#
	EOF
	sed -n '1,/^echo /{s|^echo .*|# Write your upload script below...|;p}' /usr/share/$(PKG_NAME)/natter-hook.sh >> /etc/$(PKG_NAME)/custom-script.sh
}
if [ ! -f /etc/$(PKG_NAME)/custom-script.sh ]; then
	mkdir -p /etc/$(PKG_NAME) 2>/dev/null
	white_script
else
	mv -f /etc/$(PKG_NAME)/custom-script.sh /etc/$(PKG_NAME)/custom-script.sh.bak
	sed -Ei "1,/^#+ Write your upload script below.../{s|^|#|g}" /etc/$(PKG_NAME)/custom-script.sh.bak
	white_script
	cat /etc/$(PKG_NAME)/custom-script.sh.bak >> /etc/$(PKG_NAME)/custom-script.sh
fi
chmod 755 /etc/$(PKG_NAME)/custom-script.sh
uci show firewall | grep -E "firewall.@rule\[.+\.name='NatTypeTest'" >/dev/null
if [ "$$?" == "1" ]; then
	. /lib/functions/network.sh
	network_find_wan wan_iface
	for ext_iface in $$wan_iface; do
		network_get_device ext_device $$ext_iface
		srczone=$$($$FW -q device "$$ext_device")
	done
	section=$$(uci add firewall rule)
	uci -q batch <<-EOF >/dev/null
		set firewall.$$section.name='NatTypeTest'
		set firewall.$$section.src="$$srczone"
		set firewall.$$section.dest_port='3456'
		set firewall.$$section.target='ACCEPT'
		commit firewall
	EOF
fi
uci show luci | grep "name='Test Natter'" >/dev/null
if [ "$$?" == "1" ]; then
	section=$$(uci add luci command)
	uci -q batch <<-EOF >/dev/null
		set luci.$$section.name='Test Natter'
		set luci.$$section.command='natter --check-nat 3456'
		commit luci
	EOF
fi
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
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
uci delete firewall.$(PKG_NAME)
uci commit firewall
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/usr/share/$(PKG_NAME)
	$(SED) 's,# Write your upload script below...,exec /etc/$(PKG_NAME)/custom-script.sh "$$$$@",'    $(PKG_BUILD_DIR)/natter-hook.sh
	$(INSTALL_BIN) ./natter $(1)/usr/sbin/natter
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/natter-hook.sh $(1)/usr/share/$(PKG_NAME)/natter-hook.sh
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/natter.py $(1)/usr/share/$(PKG_NAME)/natter.py
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/natter-config.template.json $(1)/usr/share/$(PKG_NAME)/natter-config.template.json
	$(INSTALL_DATA) ./files/fw3.include $(1)/usr/share/$(PKG_NAME)/fw3.include
	$(INSTALL_DATA) ./files/fw4.include $(1)/usr/share/$(PKG_NAME)/fw4.include
	$(INSTALL_DIR) $(1)/usr/libexec/$(PKG_NAME)
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_BIN) ./files/natcheck.sh $(1)/usr/libexec/$(PKG_NAME)/natcheck.sh
	$(INSTALL_BIN) ./files/natter.init $(1)/etc/init.d/$(PKG_NAME)
	$(INSTALL_CONF) ./files/natter.config $(1)/etc/config/$(PKG_NAME)
	$(INSTALL_DATA) ./files/natter.hotplug $(1)/etc/hotplug.d/iface/70-$(PKG_NAME)
	$(INSTALL_DIR) $(1)/usr/share/nftables.d
	$(CP) ./files/nftables.d/* $(1)/usr/share/nftables.d/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
