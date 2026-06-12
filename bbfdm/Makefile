#
# Copyright (C) 2023 IOPSYS
#

include $(TOPDIR)/rules.mk

PKG_NAME:=bbfdm
PKG_VERSION:=1.20.2

USE_LOCAL:=0
ifneq ($(USE_LOCAL),1)
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://dev.iopsys.eu/bbf/bbfdm.git
PKG_SOURCE_VERSION:=99e70ae4f465517accda5e50f0e5d9df4b1ab395
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.zst
PKG_MIRROR_HASH:=skip
endif

PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=LICENSE

PKG_CONFIG_DEPENDS:= \
	CONFIG_BBFDM_DM_SERVICE_RAM_OPTIMIZED \
	CONFIG_BBF_VENDOR_PREFIX \
	CONFIG_PACKAGE_tr104

RSTRIP:=true

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk
include bbfdm.mk

define Package/libbbfdm-api
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=TRx69
  TITLE:=BBF datamodel library, provides API to extend datamodel using DotSO plugins
  DEPENDS:=+libuci +libubox +libubus +libblobmsg-json +libjson-c +libcurl
  ABI_VERSION:=1.0
endef

define Package/libbbfdm-ubus
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=TRx69
  TITLE:=BBF datamodel ubus library, provides API to expose datamodel over ubus
  DEPENDS:=+libuci +libubox +libubus +libblobmsg-json +libjson-c +libbbfdm-api
endef

define Package/bbfdmd
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=TRx69
  TITLE:=Datamodel ubus backend to expose core tree
  DEPENDS:=+libuci +libubox +libubus +libblobmsg-json +libjson-c +libbbfdm-api +libopenssl +libbbfdm-ubus +bbf_configmngr
endef

define Package/dm-service
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=TRx69
  TITLE:=Datamodel ubus backend to expose micro-service tree
  DEPENDS:=+libuci +libubox +libubus +libblobmsg-json +libjson-c +libbbfdm-api +libbbfdm-ubus +bbf_configmngr +libeasy
endef

define Package/bbf_configmngr
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=TRx69
  TITLE:= BBF Config Manager
  DEPENDS:=+libuci +libubox +libubus +libblobmsg-json
endef

define Package/bbfdmd/config
	source "$(SOURCE)/Config_bbfdmd.in"
endef

# Below config is a hack to force-recompile dependent micro-services
define Package/libbbfdm-api/config
	if PACKAGE_bbfdmd
		config BBF_LIBBBFDM_VERSION
			string "Internal config variable to force recompile"
			default "v${PKG_VERSION}"
	endif
endef

define Package/libbbfdm-api/description
 Library contains the API(UCI, UBUS, JSON, CLI and Browse) of libbbfdm
endef

define Package/libbbfdm-ubus/description
 Library contains the APIs to expose data model over ubus
endef

define Package/bbfdmd/description
 Daemon to expose Datamodel core tree
endef

define Package/dm-service/description
 Daemon to expose Datamodel micro-service tree
endef

define Package/bbf_configmngr/description
 Daemon for handling bbf reload services via ubus bbf.config
endef

ifeq ($(USE_LOCAL),1)
define Build/Prepare
	$(CP) ~/git/bbfdm/* $(PKG_BUILD_DIR)/
endef
endif

CMAKE_OPTIONS += \
	-DBBF_VENDOR_PREFIX:String="$(CONFIG_BBF_VENDOR_PREFIX)" \
	-DBBFDMD_MAX_MSG_LEN:Integer=20971520 \
	-DCMAKE_BUILD_TYPE:String="Debug" \

ifeq ($(CONFIG_BBFDM_DM_SERVICE_RAM_OPTIMIZED),y)
CMAKE_OPTIONS += -DBBFDM_DM_SERVICE_RAM_OPTIMIZED=TRUE
endif

ifneq ($(CONFIG_PACKAGE_tr104),)
CMAKE_OPTIONS += -DBBFDM_INCLUDE_SERVICE_OBJ=TRUE
endif

define Package/libbbfdm-api/install
	$(INSTALL_DIR) $(1)/lib
	$(CP) $(PKG_BUILD_DIR)/libbbfdm-api/legacy/libbbfdm-api.so $(1)/lib/
	$(CP) $(PKG_BUILD_DIR)/libbbfdm-api/version-2/libbbfdm-api-v2.so $(1)/lib/

	$(INSTALL_DIR) $(1)/usr/libexec/rpcd
	$(CP) $(PKG_BUILD_DIR)/utilities/files/usr/libexec/rpcd/bbf.secure $(1)/usr/libexec/rpcd/bbf.secure
	$(CP) $(PKG_BUILD_DIR)/utilities/files/usr/libexec/rpcd/bbf.diag $(1)/usr/libexec/rpcd/bbf.diag

	$(INSTALL_DIR) $(1)/usr/share/bbfdm/scripts/
	$(CP) $(PKG_BUILD_DIR)/utilities/files/usr/share/bbfdm/scripts/bbf_api $(1)/usr/share/bbfdm/scripts/

	$(INSTALL_DIR) $(1)/etc/bbfdm/certificates
	echo "$(CONFIG_BBF_OBFUSCATION_KEY)" > $(1)/etc/bbfdm/.secure_hash
endef

define Package/libbbfdm-ubus/install
	$(INSTALL_DIR) $(1)/lib
	$(CP) $(PKG_BUILD_DIR)/libbbfdm-ubus/libbbfdm-ubus.so $(1)/lib/
endef

define Package/bbfdmd/install
	$(INSTALL_DIR) $(1)/etc/bbfdm/dmmap
	$(INSTALL_DIR) $(1)/usr/share/bbfdm

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/etc/config/bbfdm $(1)/etc/config/bbfdm
	$(INSTALL_CONF) ./files/etc/config/schedules $(1)/etc/config/schedules

	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bbfdmd/ubus/bbfdmd $(1)/usr/sbin/
	$(STRIP) $(1)/usr/sbin/bbfdmd

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/bbfdmd $(1)/etc/init.d/bbfdmd

	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_BIN) ./files/etc/hotplug.d/iface/85-bbfdm-sysctl $(1)/etc/hotplug.d/iface/85-bbfdm-sysctl
	
	$(INSTALL_DIR) $(1)/lib/upgrade/keep.d
	$(INSTALL_DATA) ./files/lib/upgrade/keep.d/bbf $(1)/lib/upgrade/keep.d/bbf
	
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/etc/uci-defaults/91-fix-bbfdmd-enabled-option $(1)/etc/uci-defaults/
	$(INSTALL_BIN) ./files/etc/uci-defaults/ruleng.bbfdm $(1)/etc/uci-defaults

	$(INSTALL_DIR) $(1)/etc/ruleng
	$(INSTALL_BIN) ./files/etc/ruleng/bbfdm.json $(1)/etc/ruleng
endef

define Package/dm-service/install
	$(INSTALL_DIR) $(1)/etc/init.d

ifeq ($(CONFIG_BBFDM_DM_SERVICE_RAM_OPTIMIZED),y)
	$(INSTALL_BIN) ./files/etc/init.d/bbfdm.core $(1)/etc/init.d/bbfdm.services
else
	$(INSTALL_BIN) ./files/etc/init.d/bbfdm.services $(1)/etc/init.d/
endif

	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/dm-service/dm-service $(1)/usr/sbin/

	$(INSTALL_DIR) $(1)/etc/bbfdm
	$(INSTALL_DATA) ./files/etc/bbfdm/datamodel.json $(1)/etc/bbfdm/

	$(BBFDM_REGISTER_SERVICES) -v ${CONFIG_BBF_VENDOR_PREFIX} ./bbfdm_service.json $(1) core
	$(BBFDM_INSTALL_MS_DM) $(PKG_BUILD_DIR)/libbbfdm/libcore.so $(1) core
endef

define Package/bbf_configmngr/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/bbfdm/
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/usr/share/bbfdm/scripts

	$(INSTALL_BIN) $(PKG_BUILD_DIR)/utilities/bbf_configd $(1)/usr/sbin/
	$(STRIP) $(1)/usr/sbin/bbf_configd

	$(INSTALL_BIN) ./files/etc/init.d/bbf_configd $(1)/etc/init.d/bbf_configd
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/utilities/files/usr/share/bbfdm/scripts/bbf_config_notify.sh $(1)/usr/share/bbfdm/scripts/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/utilities/files/usr/share/bbfdm/scripts/bbf_default_reload.sh $(1)/etc/bbfdm/
	$(INSTALL_DATA) ./files/etc/bbfdm/critical_services.json $(1)/etc/bbfdm/
endef

define Package/bbfdmd/prerm
	#!/bin/sh
	rm -rf /etc/bbfdm/dmmap/*
	exit 0
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_DIR) $(1)/usr/include
	$(INSTALL_DIR) $(1)/usr/include/libbbfdm-api
	$(INSTALL_DIR) $(1)/usr/include/libbbfdm-api/legacy
	$(INSTALL_DIR) $(1)/usr/include/libbbfdm-api/legacy/plugin
	$(INSTALL_DIR) $(1)/usr/include/libbbfdm-api/version-2
	$(INSTALL_DIR) $(1)/usr/include/libbbfdm-ubus
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/libbbfdm-api/legacy/*.h $(1)/usr/include/libbbfdm-api/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/libbbfdm-api/legacy/*.h $(1)/usr/include/libbbfdm-api/legacy/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/libbbfdm-api/legacy/plugin/*.h $(1)/usr/include/libbbfdm-api/legacy/plugin/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/libbbfdm-api/version-2/*.h $(1)/usr/include/libbbfdm-api/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/libbbfdm-api/version-2/*.h $(1)/usr/include/libbbfdm-api/version-2/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/libbbfdm-ubus/bbfdm-ubus.h $(1)/usr/include/libbbfdm-ubus/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/libbbfdm-api/legacy/include/*.h $(1)/usr/include/
	$(CP) $(PKG_BUILD_DIR)/libbbfdm-api/legacy/libbbfdm-api.so $(1)/usr/lib
	$(CP) $(PKG_BUILD_DIR)/libbbfdm-api/version-2/libbbfdm-api-v2.so $(1)/usr/lib
	$(CP) $(PKG_BUILD_DIR)/libbbfdm-ubus/libbbfdm-ubus.so $(1)/usr/lib
endef

$(eval $(call BuildPackage,bbf_configmngr))
$(eval $(call BuildPackage,libbbfdm-api))
$(eval $(call BuildPackage,libbbfdm-ubus))
$(eval $(call BuildPackage,bbfdmd))
$(eval $(call BuildPackage,dm-service))
