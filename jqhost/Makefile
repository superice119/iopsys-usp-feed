#
# Host jq for the OpenWrt build machine.
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
# A BUILDONLY target Package/ is declared *only* so the package is indexed and
# `feeds install -a` symlinks it into the build tree (a pure HostBuild produces
# no package entry, so the `jqhost/host` build-dep would be unresolvable). It
# builds no target ipk.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=jqhost
PKG_VERSION:=1.7.1
PKG_RELEASE:=1

# Remote asset is named exactly `jq-linux-amd64` (no version infix); PKG_SOURCE
# must match the remote filename since the download is PKG_SOURCE_URL/PKG_SOURCE.
PKG_SOURCE:=jq-linux-amd64
PKG_SOURCE_URL:=https://github.com/jqlang/jq/releases/download/jq-$(PKG_VERSION)
PKG_HASH:=5942c9b0934e510ee61eb3e30273f1b3fe2590df93933a93d7c58b81d19c8ff5

PKG_LICENSE:=MIT
PKG_MAINTAINER:=iopsys-usp-feed

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/host-build.mk

define Package/jqhost
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=TRx69
  TITLE:=jq on the build host (build helper for bbfdm install tooling)
  # BUILDONLY: indexed so feeds install symlinks it; produces no target ipk.
  BUILDONLY:=1
endef

define Package/jqhost/description
 Installs a static jq onto the build host PATH so bbfdm/tools/bbfdm.sh can
 validate and register the micro-service datamodel JSON during obuspa and
 dm-service install. Not an on-device package.
endef

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

# Target side is a no-op (BUILDONLY). Override the defaults so nothing tries to
# untar the bare binary if the target package is ever visited.
define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/jqhost/install
endef

$(eval $(call HostBuild))
$(eval $(call BuildPackage,jqhost))
