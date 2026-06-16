#
# Copyright (C) 2023 IOPSYS
#

include $(TOPDIR)/rules.mk

PKG_NAME:=timemngr
PKG_VERSION:=1.1.15

LOCAL_DEV:=0
ifneq ($(LOCAL_DEV),1)
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://dev.iopsys.eu/bbf/timemngr.git
PKG_SOURCE_VERSION:=d4c2d84c666a349196a12bb709111863766e2f3c
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.zst
PKG_MIRROR_HASH:=skip
endif

PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=LICENSE

# bbfdm.mk's BBFDM_REGISTER_SERVICES / BBFDM_INSTALL_MS_* macros shell out to `jq`
# at install time; provide it on the host PATH (the SDK container has none).
# See jqhost/Makefile.
PKG_BUILD_DEPENDS:=jqhost/host

PKG_CONFIG_DEPENDS:= \
	CONFIG_TIMEMNGR_VENDOR_PREFIX \
	CONFIG_BBF_VENDOR_PREFIX

include $(INCLUDE_DIR)/package.mk
# Flat feed layout: bbfdm is a sibling package dir (see obuspa/Makefile).
include ../bbfdm/bbfdm.mk

#RSTRIP:=:

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=TRx69
  TITLE:=Time manager daemon based on ntpd
  DEPENDS:=+ntpd +libuci +libubox +ubus +@BUSYBOX_CONFIG_PGREP
  DEPENDS+=+libbbfdm-api +libbbfdm-ubus +bbfdmd
  MENU:=1
endef

define Package/$(PKG_NAME)/config
	source "$(SOURCE)/Config.in"
endef

MAKE_PATH:=src

define Package/$(PKG_NAME)/description
	Manage device time with ntpd and provides Device.Time. datamodel object based on TR181-2.16
endef

ifeq ($(LOCAL_DEV),1)
define Build/Prepare
        $(CP) -rf ~/git/timemngr/* $(PKG_BUILD_DIR)/
endef
endif

ifeq ($(CONFIG_TIMEMNGR_VENDOR_PREFIX),"")
VENDOR_PREFIX = $(CONFIG_BBF_VENDOR_PREFIX)
else
VENDOR_PREFIX = $(CONFIG_TIMEMNGR_VENDOR_PREFIX)
endif

TARGET_CFLAGS += -DBBF_VENDOR_PREFIX=\\\"$(VENDOR_PREFIX)\\\"

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/timemngr/
	$(INSTALL_DIR) $(1)/etc/config/
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_DIR) $(1)/etc/hotplug.d/ntp
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/uci-defaults
ifeq ($(CONFIG_TIMEMNGR_LEGACY_DM),y)
	$(BBFDM_REGISTER_SERVICES) ./bbfdm_service_legacy.json $(1) $(PKG_NAME)
	$(BBFDM_INSTALL_MS_DM) $(PKG_BUILD_DIR)/src/dm_time_legacy.so $(1) $(PKG_NAME)
else
	$(BBFDM_REGISTER_SERVICES) ./bbfdm_service.json $(1) $(PKG_NAME)
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/timemngr $(1)/usr/sbin/timemngr
ifeq ($(CONFIG_TIMEMNGR_MIGRATE_SYSTEM),y)
	$(INSTALL_BIN) ./files/etc/uci-defaults/96-system-ntp-migrate $(1)/etc/uci-defaults/
endif
	# Hand ntp ownership to timemngr: disable base sysntpd so the two ntpd
	# instances don't fight over UDP/123 (see the script for details).
	$(INSTALL_BIN) ./files/etc/uci-defaults/97-disable-sysntpd-for-timemngr $(1)/etc/uci-defaults/
	$(INSTALL_BIN) ./files/etc/hotplug.d/iface/21-timemngr $(1)/etc/hotplug.d/iface/
	$(INSTALL_BIN) ./files/etc/hotplug.d/ntp/40-firstUseDate $(1)/etc/hotplug.d/ntp/
	$(INSTALL_BIN) ./files/etc/init.d/timemngr $(1)/etc/init.d/
	$(INSTALL_DATA) ./files/etc/config/time $(1)/etc/config/
ifeq ($(CONFIG_TIMEMNGR_NTPD),y)
	$(CP) ./files/etc/timemngr/ntpd_config.sh $(1)/etc/timemngr/time.sh
	$(CP) ./files/etc/timemngr/generate_supported_zones.sh $(1)/etc/timemngr/generate_supported_zones.sh
endif
endif

ifeq ($(CONFIG_TIMEMNGR_VENDOR_EXTENSIONS),y)
	$(BBFDM_INSTALL_MS_PLUGIN) $(PKG_BUILD_DIR)/src/libtimeext.so $(1) $(PKG_NAME)
endif
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
