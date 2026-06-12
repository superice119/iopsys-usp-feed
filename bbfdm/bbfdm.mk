#
# Copyright (C) 2023 IOPSYS
#

BBFDM_BASE_DM_PATH=/usr/share/bbfdm
BBFDM_INPUT_PATH=/etc/bbfdm/micro_services
BBFDM_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

PKG_CONFIG_DEPENDS += CONFIG_BBF_LIBBBFDM_VERSION
#BBFDM_VERSION:=$(shell grep -oP '(?<=^PKG_VERSION:=).*' ${BBFDM_DIR}/Makefile)
#BBFDM_TOOLS:=$(BUILD_DIR)/bbfdm-$(BBFDM_VERSION)/tools

# Utility to install the plugin in bbfdm core path with priority.
# Its now possible to overwrite/remove core datamodel with plugin, so, if some
# datamodel objects/parameters are present in more than one plugin, order in
# which they loaded into memory becomes crucial, this Utility help to configure
# a priority order in which they gets loaded in memory.
#
# ARGS:
#  $1 => Plugin artifact
#  $2 => package install directory
#  $3 => Priority of the installed plugin (Optional)
#
# Note:
# - Last loaded plugin gets the highest priority
#
# Example:
#  BBFDM_INSTALL_CORE_PLUGIN ./files/etc/bbfdm/json/CWMPManagementServer.json $(1)
#
# Example to install plugin with priority:
#  BBFDM_INSTALL_CORE_PLUGIN ./files/etc/bbfdm/json/CWMPManagementServer.json $(1) 01
#
BBFDM_INSTALL_CORE_PLUGIN:=$(BBFDM_DIR)/tools/bbfdm.sh -p


# Utility to install the micro-service datamodel
# Use Case:
# user wants to run a datamodel micro-service, it required to install the
# DotSO/JSON plugin into a bbf shared directory, this utility helps in
# installing the DotSO/JSON plugin in bbfdm shared directory, and auto-generate
# input file for the micro-service
#
# ARGS:
#  $1 => DotSo or Json plugin with complete path
#  $2 => package install directory
#  $3 => service name
#
# Note:
# - There could be only one main plugin file, so its bind to PKG_NAME
# - Micro-service input.json will be auto generated with this call
#
# Example:
#  BBFDM_INSTALL_MS_DM $(PKG_BUILD_DIR)/libcwmp.so $(1) $(PKG_NAME)
#
BBFDM_INSTALL_MS_DM:=$(BBFDM_DIR)/tools/bbfdm.sh -m


# Utility to install a plugins in datamodel micro-service
#
# ARGS:
#  $1 => DotSo or Json plugin with complete path
#  $2 => package install directory
#  $3 => service name
#
# Note:
# - Use the service_name/PKG_NAME of the service in which this has to run
#
# Example:
#  BBFDM_INSTALL_MS_PLUGIN $(PKG_BUILD_DIR)/libxmpp.so $(1) icwmp
#
BBFDM_INSTALL_MS_PLUGIN:=$(BBFDM_DIR)/tools/bbfdm.sh -m -p

# Utility to install the helper scripts in default bbfdm script path
#
# Use Case:
# User want to install some script for running diagnostics
#
# ARGS:
#  $1 => Script with complete path
#  $2 => package install directory
#
# Note:
# - Use with -d option to install script in bbf.diag directory
#
# Example:
#  BBFDM_INSTALL_SCRIPT $(PKG_BUILD_DIR)/download $(1)
#  BBFDM_INSTALL_SCRIPT -d $(PKG_BUILD_DIR)/ipping $(1)
#
BBFDM_INSTALL_SCRIPT:=$(BBFDM_DIR)/tools/bbfdm.sh -s


BBFDM_REGISTER_SERVICES:=$(BBFDM_DIR)/tools/bbfdm.sh -t
