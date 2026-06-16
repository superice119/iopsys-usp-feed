#
# Copyright (C) 2024 IOPSYS
#

include $(TOPDIR)/rules.mk

PKG_NAME:=sysmngr
PKG_VERSION:=1.3.0

LOCAL_DEV:=0
ifneq ($(LOCAL_DEV),1)
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://dev.iopsys.eu/system/sysmngr.git
PKG_SOURCE_VERSION:=a806420db9cc745738acebfa0e73240a3004df56
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.zst
PKG_MIRROR_HASH:=skip
endif

PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=LICENSE

# bbfdm.mk's BBFDM_REGISTER_SERVICES macro shells out to `jq` at install time;
# provide it on the host PATH (the SDK container has none). See jqhost/Makefile.
PKG_BUILD_DEPENDS:=jqhost/host

PKG_CONFIG_DEPENDS:= \
	CONFIG_SYSMNGR_VENDOR_CONFIG_FILE \
	CONFIG_SYSMNGR_MEMORY_STATUS \
	CONFIG_SYSMNGR_PROCESS_STATUS \
	CONFIG_SYSMNGR_SUPPORTED_DATA_MODEL \
	CONFIG_SYSMNGR_FIRMWARE_IMAGE \
	CONFIG_SYSMNGR_REBOOTS \
	CONFIG_SYSMNGR_NETWORK_PROPERTIES \
	CONFIG_SYSMNGR_VENDOR_EXTENSIONS \
	CONFIG_SYSMNGR_VENDOR_PREFIX \
	CONFIG_SYSMNGR_FWBANK_UBUS_SUPPORT \
	CONFIG_SYSMNGR_TEMPERATURE_STATUS

include $(INCLUDE_DIR)/package.mk
# Flat feed layout: bbfdm is a sibling package dir (see obuspa/Makefile).
include ../bbfdm/bbfdm.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=TRx69
  TITLE:=System manager daemon
  DEPENDS:=+libuci +libubox +libubus +libblobmsg-json +libjson-c +libopenssl
  DEPENDS+=+libbbfdm-api +libbbfdm-ubus +dm-service
  MENU:=1
endef

define Package/$(PKG_NAME)/config
	source "$(SOURCE)/Config.in"
endef

MAKE_PATH:=src

define Package/$(PKG_NAME)/description
	Manage device info and provides Device.DeviceInfo. datamodel object based on TR181-2.18
endef

ifeq ($(LOCAL_DEV),1)
define Build/Prepare
	$(CP) -rf ~/git/sysmngr/* $(PKG_BUILD_DIR)/
endef
endif

ifeq ($(CONFIG_SYSMNGR_VENDOR_CONFIG_FILE),y)
MAKE_FLAGS += SYSMNGR_VENDOR_CONFIG_FILE=y
endif

ifeq ($(CONFIG_SYSMNGR_MEMORY_STATUS),y)
MAKE_FLAGS += SYSMNGR_MEMORY_STATUS=y
endif

ifeq ($(CONFIG_SYSMNGR_PROCESS_STATUS),y)
MAKE_FLAGS += SYSMNGR_PROCESS_STATUS=y
endif

ifeq ($(CONFIG_SYSMNGR_SUPPORTED_DATA_MODEL),y)
MAKE_FLAGS += SYSMNGR_SUPPORTED_DATA_MODEL=y
endif

ifeq ($(CONFIG_SYSMNGR_FIRMWARE_IMAGE),y)
MAKE_FLAGS += SYSMNGR_FIRMWARE_IMAGE=y
endif

ifeq ($(CONFIG_SYSMNGR_REBOOTS),y)
MAKE_FLAGS += SYSMNGR_REBOOTS=y
endif

ifeq ($(CONFIG_SYSMNGR_NETWORK_PROPERTIES),y)
MAKE_FLAGS += SYSMNGR_NETWORK_PROPERTIES=y
endif

ifeq ($(CONFIG_SYSMNGR_VENDOR_EXTENSIONS),y)
MAKE_FLAGS += SYSMNGR_VENDOR_EXTENSIONS=y
ifeq ($(CONFIG_SYSMNGR_VENDOR_PREFIX),"")
TARGET_CFLAGS += -DCUSTOM_PREFIX=\\\"$(CONFIG_BBF_VENDOR_PREFIX)\\\"
else
TARGET_CFLAGS += -DCUSTOM_PREFIX=\\\"$(CONFIG_SYSMNGR_VENDOR_PREFIX)\\\"
endif
endif

ifeq ($(CONFIG_SYSMNGR_FWBANK_UBUS_SUPPORT),y)
MAKE_FLAGS += SYSMNGR_FWBANK_UBUS_SUPPORT=y
endif

ifeq ($(CONFIG_SYSMNGR_TEMPERATURE_STATUS),y)
MAKE_FLAGS += SYSMNGR_TEMPERATURE_STATUS=y
endif

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/etc/config/sysmngr $(1)/etc/config/sysmngr

	# DeviceInfo identity backend (UCI confdir /etc/board-db/config). iopsys HW
	# ships this from its board db; generic OpenWrt needs it or DeviceInfo.* read
	# back empty. INSTALL_CONF so user edits survive upgrades.
	$(INSTALL_DIR) $(1)/etc/board-db/config
	$(INSTALL_CONF) ./files/etc/board-db/config/device $(1)/etc/board-db/config/device

	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/sysmngr $(1)/usr/sbin/sysmngr

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/sysmngr $(1)/etc/init.d/sysmngr
	
	$(INSTALL_DIR) $(1)/etc/sysmngr
	$(INSTALL_BIN) ./files/etc/sysmngr/critical_state_logger.sh $(1)/etc/sysmngr/critical_state_logger.sh
	
	$(INSTALL_DIR) $(1)/usr/share/bbfdm/scripts
	$(CP) $(PKG_BUILD_DIR)/src/files/usr/share/bbfdm/scripts/bbf_activate_handler.sh $(1)/usr/share/bbfdm/scripts/
	$(CP) $(PKG_BUILD_DIR)/src/files/usr/share/bbfdm/scripts/bbf_check_idle.sh $(1)/usr/share/bbfdm/scripts/
	$(BBFDM_REGISTER_SERVICES) ./bbfdm_service.json $(1) $(PKG_NAME)
	
	$(INSTALL_BIN) ./files/etc/sysmngr/fwbank $(1)/etc/sysmngr/fwbank
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
