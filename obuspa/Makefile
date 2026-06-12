#
# Copyright (C) 2019 IOPSYS
#

include $(TOPDIR)/rules.mk

PKG_NAME:=obuspa
PKG_VERSION:=11.0.3.1
PKG_RELEASE:=1

LOCAL_DEV:=0
ifneq ($(LOCAL_DEV),1)
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://dev.iopsys.eu/bbf/obuspa.git
PKG_SOURCE_VERSION:=92aabe989d3f105478462ae1c6a0d62824908b0d
PKG_MAINTAINER:=Vivek Dutta <vivek.dutta@iopsys.eu>
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.zst
PKG_MIRROR_HASH:=skip
endif

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=LICENSE

PKG_CONFIG_DEPENDS:= \
	CONFIG_OBUSPA_VENDOR_PREFIX \
	CONFIG_BBF_VENDOR_PREFIX \
	CONFIG_OBUSPA_CONTROLLER_MTP_VERIFY \
	CONFIG_OBUSPA_MTP_ENABLE_STOMP \
	CONFIG_OBUSPA_MTP_ENABLE_MQTT \
	CONFIG_OBUSPA_MTP_ENABLE_COAP \
	CONFIG_OBUSPA_MTP_ENABLE_WEBSOCKETS \
	CONFIG_OBUSPA_DOWNLOAD_EXTENSION \
	CONFIG_OBUSPA_UPLOAD_EXTENSION \
	CONFIG_OBUSPA_SESSION_EXTENSION \
	CONFIG_OBUSPA_MAX_CONTROLLERS_NUM \
	CONFIG_OBUSPA_VC_POLL_PERIOD

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk
include ../bbfdm/bbfdm.mk

define Package/obuspa
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=TRx69
  TITLE:=USP agent
  MENU:=1
  DEPENDS:=+libopenssl +libcurl +libsqlite3 +libmosquitto-ssl +libwebsockets-openssl
  DEPENDS+=+libjson-c +libubox +libubus +libuci +libblobmsg-json
  DEPENDS+=+ca-certificates +OBUSPA_LOCAL_MQTT_LISTENER:mosquitto-ssl
  DEPENDS+=+libbbfdm-api +libbbfdm-ubus +dm-service
endef

define Package/obuspa/description
 OB-USP-AGENT is a system daemon providing a User Services Platform (USP) Agent.
endef

define Package/obuspa/config
	source "$(SOURCE)/Config.in"
endef

TARGET_CFLAGS += \
	-D_GNU_SOURCE \
	-DHAVE_STRERROR_R \
	-Wall \
	-Werror

ifeq ($(CONFIG_OBUSPA_VENDOR_PREFIX),"")
VENDOR_PREFIX = $(CONFIG_BBF_VENDOR_PREFIX)
else
VENDOR_PREFIX = $(CONFIG_OBUSPA_VENDOR_PREFIX)
endif

TARGET_CFLAGS += -D_DM_VENDOR_PREFIX=$(VENDOR_PREFIX)

CMAKE_OPTIONS += -DCMAKE_INSTALL_PREFIX=/tmp
CMAKE_OPTIONS += -DCMAKE_INSTALL_SYSCONFDIR="/etc"

ifneq ($(CONFIG_OBUSPA_CONTROLLER_MTP_VERIFY),)
  TARGET_CFLAGS += -DOBUSPA_CONTROLLER_MTP_VERIFY
endif

ifeq ($(CONFIG_OBUSPA_MTP_ENABLE_STOMP),y)
CMAKE_OPTIONS += -DENABLE_STOMP=ON
else
CMAKE_OPTIONS += -DENABLE_STOMP=OFF
endif

ifeq ($(CONFIG_OBUSPA_MTP_ENABLE_MQTT),y)
CMAKE_OPTIONS += -DENABLE_MQTT=ON
else
CMAKE_OPTIONS += -DENABLE_MQTT=OFF
endif

ifeq ($(CONFIG_OBUSPA_MTP_ENABLE_COAP),y)
CMAKE_OPTIONS += -DENABLE_COAP=ON
else
CMAKE_OPTIONS += -DENABLE_COAP=OFF
endif

ifeq ($(CONFIG_OBUSPA_MTP_ENABLE_WEBSOCKETS),y)
CMAKE_OPTIONS += -DENABLE_WEBSOCKETS=ON
else
CMAKE_OPTIONS += -DENABLE_WEBSOCKETS=OFF
endif

ifeq ($(CONFIG_OBUSPA_DOWNLOAD_EXTENSION),y)
TARGET_CFLAGS += -DOBUSPA_ENABLE_DOWNLOAD_EXT
endif

ifeq ($(CONFIG_OBUSPA_UPLOAD_EXTENSION),y)
TARGET_CFLAGS += -DOBUSPA_ENABLE_UPLOAD_EXT
endif

ifeq ($(CONFIG_OBUSPA_SESSION_EXTENSION),y)
TARGET_CFLAGS += -DOBUSPA_ENABLE_SESSION_EXT
endif

ifneq ($(CONFIG_OBUSPA_MAX_CONTROLLERS_NUM),)
TARGET_CFLAGS += -DOBUSPA_MAX_CONTROLLERS_NUM=$(CONFIG_OBUSPA_MAX_CONTROLLERS_NUM)
endif

ifneq ($(CONFIG_OBUSPA_VC_POLL_PERIOD),)
TARGET_CFLAGS += -DOBUSPA_VC_POLL_PERIOD=$(CONFIG_OBUSPA_VC_POLL_PERIOD)
endif

ifeq ($(LOCAL_DEV),1)
define Build/Prepare
	$(CP) -rf ~/git/obuspa/* $(PKG_BUILD_DIR)/
	$(Build/Patch)
endef
endif

define Package/obuspa/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/obuspa
	$(INSTALL_DIR) $(1)/etc/users/roles
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_DIR) $(1)/etc/udhcpc.user.d
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/obuspa $(1)/usr/sbin/
	$(INSTALL_BIN) ./files/etc/init.d/obuspa $(1)/etc/init.d/
	$(INSTALL_DATA) ./files/etc/config/obuspa $(1)/etc/config/
	$(INSTALL_DATA) ./files/etc/users/roles/*.json $(1)/etc/users/roles/
	$(INSTALL_DATA) ./files/etc/obuspa/usp_utils.sh $(1)/etc/obuspa/
	$(INSTALL_DATA) ./files/etc/obuspa/search_query_params.json $(1)/etc/obuspa/
	echo "$(VENDOR_PREFIX)" > $(1)/etc/obuspa/vendor_prefix
	$(INSTALL_DATA) ./files/etc/uci-defaults/01-fix-upgrade-uci $(1)/etc/uci-defaults/
	$(INSTALL_DATA) ./files/etc/uci-defaults/60-generate-ctrust-defaults $(1)/etc/uci-defaults/
	$(INSTALL_DATA) ./files/etc/uci-defaults/obuspa-set-dhcp-option $(1)/etc/uci-defaults/
	$(INSTALL_DATA) ./files/etc/uci-defaults/92-obuspa_firewall $(1)/etc/uci-defaults/
	$(INSTALL_DATA) ./files/etc/uci-defaults/93-obuspa_mdns_adv $(1)/etc/uci-defaults/
	$(INSTALL_DATA) ./files/etc/uci-defaults/94-obuspa_set_credential $(1)/etc/uci-defaults/
	$(INSTALL_BIN) ./files/etc/hotplug.d/iface/90-obuspa $(1)/etc/hotplug.d/iface/
	$(INSTALL_BIN) ./files/etc/udhcpc.user.d/udhcpc_obuspa_opt125.user $(1)/etc/udhcpc.user.d/
ifeq ($(CONFIG_OBUSPA_CWMP_DATAMODEL_SUPPORT),y)
	$(BBFDM_REGISTER_SERVICES) ./bbfdm_service.json $(1) $(PKG_NAME)
	$(BBFDM_INSTALL_MS_DM) $(PKG_BUILD_DIR)/libuspagentdm.so $(1) $(PKG_NAME)
endif
ifeq ($(CONFIG_OBUSPA_LOCAL_MQTT_LISTENER),y)
	$(INSTALL_DATA) ./files/etc/uci-defaults/55-obuspa-local-mqtt-usp-connection $(1)/etc/uci-defaults/
endif
ifeq ($(CONFIG_OBUSPA_OVERRIDE_CT_ROLE),y)
	$(INSTALL_DATA) ./files/etc/uci-defaults/61-override-ct-roles $(1)/etc/uci-defaults/
endif
endef

$(eval $(call BuildPackage,obuspa))
