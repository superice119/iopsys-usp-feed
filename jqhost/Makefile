#
# Host-only jq for the OpenWrt build machine.
#
# bbfdm ships tools/bbfdm.sh, which shells out to `jq` (and optionally
# python3-jsonschema) at *package-install* time to validate/compact the
# micro-service datamodel JSON and to register services. The official OpenWrt
# SDK container runs as user `buildbot` with no apt access and ships no `jq`, so
# obuspa and dm-service silently fail their install step ("Invalid datamodel
# json input file") and drop out of the build.
#
# This package puts a `jq` on the host PATH (STAGING_DIR_HOST/bin) so any package
# that does `PKG_BUILD_DEPENDS:=jqhost/host` can use it. The artifact is the
# official jqlang release: a fully-static x86_64 Linux binary (no glibc dep),
# which is what every OpenWrt SDK/CI host is.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=jqhost
PKG_VERSION:=1.7.1
PKG_RELEASE:=1

PKG_SOURCE:=jq-$(PKG_VERSION)-linux-amd64
PKG_SOURCE_URL:=https://github.com/jqlang/jq/releases/download/jq-$(PKG_VERSION)
PKG_HASH:=5942c9b0934e510ee61eb3e30273f1b3fe2590df93933a93d7c58b81d19c8ff5

PKG_LICENSE:=MIT
PKG_MAINTAINER:=prpl-usp-feed

include $(INCLUDE_DIR)/host-build.mk

# The download is a bare ELF binary, not an archive — replace the default
# unpack with a plain copy so the build system does not try to untar it.
define Host/Prepare
	mkdir -p $(HOST_BUILD_DIR)
	$(CP) $(DL_DIR)/$(PKG_SOURCE) $(HOST_BUILD_DIR)/jq
	chmod +x $(HOST_BUILD_DIR)/jq
endef

define Host/Configure
endef

define Host/Compile
endef

define Host/Install
	$(INSTALL_DIR) $(STAGING_DIR_HOST)/bin
	$(INSTALL_BIN) $(HOST_BUILD_DIR)/jq $(STAGING_DIR_HOST)/bin/jq
endef

define Host/Clean
	rm -f $(STAGING_DIR_HOST)/bin/jq
endef

$(eval $(call HostBuild))
