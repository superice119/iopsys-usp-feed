# iopsys-feed — iopsys/bbfdm USP feed for OpenWrt

A self-contained OpenWrt feed that connects an OpenWrt gateway to an
[Oktopus](https://github.com/OktopUSP/oktopus) USP Controller using the
**iopsys** TR-369/USP stack — the alternative to the prpl Ambiorix path in
`../prpl-feed`.

```
Oktopus  --USP/WebSocket-->  obuspa (iopsys fork: USP Agent + WS MTP)
                                 |
                                 |  ubus
                                 v
                          bbfdmd  (broker, ubus object "bbfdm")
                                 |  routes Device.* to micro-services
        +------------------+-----+------------------+--------------+
        v                  v                        v              v
  dm-service -m core    obuspa.so              sysmngr        timemngr
  (thin "core" slice)  (LocalAgent/MQTT)    (DeviceInfo)      (Time)
```

> **Verified end-to-end** on Oolite V8.0 / MediaTek MT7621 (`mipsel_24kc`) /
> ImmortalWrt 24.10: build → install → WebSocket connect → Online in Oktopus →
> DeviceInfo/Time populated → full data-model discovery (`RootDataModelVersion
> 2.20`). CI builds the whole feed green on mt7621 + rk3308 (9/9 ipks).

## Architecture: the data model is split across managers

The single most important thing to know about this stack: **`bbfdm` + `obuspa`
do NOT contain the TR-181 data model.** `bbfdmd` is only a broker. The one
data-model micro-service these two repos ship is `core` (`dm-service -m core`,
`libcore.so`), and it registers just a thin slice — `LANConfigSecurity`,
`Schedules`, `Security`, `PacketCaptureDiagnostics`, `SelfTestDiagnostics`,
`{VENDOR}OpenVPN`, `RootDataModelVersion`, `Reboot()`, `FactoryReset()`.

Everything else (`DeviceInfo`, `Time`, `IP`, `Ethernet`, `WiFi`, `DHCP`, …)
lives in ~50 separate **manager daemons** in the iopsys feed, each registering
its own subtree. This feed vendors the two needed for parity with the prpl
device's tree:

- `sysmngr` → `Device.DeviceInfo`
- `timemngr` → `Device.Time`

(Proof the rest isn't there: `ubus call bbfdm.core get '{"path":"Device.DeviceInfo."}'`
returns fault 9005 "Invalid parameter name" until `sysmngr` is installed.)

## vs. the prpl feed

| | `prpl-feed` (Ambiorix) | `iopsys-feed` (bbfdm) |
|---|---|---|
| Data model source | one `tr181-*` daemon per area (amxrt + ODL) | `bbfdmd` broker + per-area manager micro-services |
| "Open-box" full tree | **yes** (pull in the plugins) | **no** — broker+agent ship only the thin core; add managers |
| Dependency weight | heavy (full Ambiorix: `libamx*`, `amxrt`) | light core (uci/ubus/json-c/openssl/curl/sqlite3/websockets/nl); managers add little |
| Config backend | Ambiorix-native | native UCI / ubus (`/etc/config`, `/etc/board-db/config`) |
| Adaptation cost | breadth — pin ~37 inter-`requires` packages | depth — host-jq build trap + platform glue (below) |

## Packages

Sources are pinned to upstream commits — nothing fabricated; the iopsys Makefiles
are vendored verbatim from [`feed/iopsys`](https://dev.iopsys.eu/feed/iopsys)
(branch `devel`). `PKG_MIRROR_HASH:=skip` is upstream's own value; the integrity
pin is `PKG_SOURCE_VERSION` (the git commit).

| dir | upstream | pin | builds / provides |
|---|---|---|---|
| `bbfdm/` | [bbf/bbfdm](https://dev.iopsys.eu/bbf/bbfdm) v1.20.2 | `99e70ae4` | `libbbfdm-api`, `libbbfdm-ubus`, `bbfdmd`, `dm-service`, `bbf_configmngr` |
| `obuspa/` | [bbf/obuspa](https://dev.iopsys.eu/bbf/obuspa) v11.0.3.1 | `92aabe98` | `obuspa` (USP Agent, WebSocket MTP) |
| `libeasy/` | [hal/libeasy](https://dev.iopsys.eu/hal/libeasy) v7.5.1 | `b981f7e1` | `libeasy` (required by `dm-service`) |
| `sysmngr/` | [system/sysmngr](https://dev.iopsys.eu/system/sysmngr) v1.3.0 | `a806420d` | `sysmngr` → `Device.DeviceInfo` |
| `timemngr/` | [bbf/timemngr](https://dev.iopsys.eu/bbf/timemngr) v1.1.15 | `d4c2d84c` | `timemngr` → `Device.Time` (ntpd-backed) |
| `jqhost/` | [jqlang/jq](https://github.com/jqlang/jq) v1.7.1 (release binary) | sha256 | build-host `jq` (see below) — `BUILDONLY`, no target ipk |

> Layout is **flat** (mirrors `feed/iopsys`) on purpose: `obuspa/`, `sysmngr/`
> and `timemngr/` Makefiles all `include ../bbfdm/bbfdm.mk`, so they must be
> siblings of `bbfdm/`.

### The host-`jq` build trap (why `jqhost/` exists)

`bbfdm/tools/bbfdm.sh` shells out to `jq` at **package-install** time (the
`BBFDM_REGISTER_SERVICES` / `BBFDM_INSTALL_MS_DM` macros validate & register the
micro-service JSON). The OpenWrt SDK container (`buildbot`, no apt, no jq) lacks
it, so `obuspa`/`dm-service`/`sysmngr`/`timemngr` install steps fail and are
**silently dropped** under `IGNORE_ERRORS` — a green build missing the key ipks.
`jqhost` puts a static `jq` on `STAGING_DIR_HOST/bin`; every package that
includes `bbfdm.mk` carries `PKG_BUILD_DEPENDS:=jqhost/host`. Verify success by
**ipk presence**, not build exit code.

## Platform glue for non-iopsys hardware

iopsys firmware ships an environment these components assume; on generic OpenWrt
(e.g. ImmortalWrt) it is absent. This feed bakes in the fixes:

| What | Why it's needed | Where it's handled |
|---|---|---|
| `assigned_role_name='full_access'` on the controller | `ws://` has no TLS client cert, so the controller otherwise falls back to the `Untrusted` role and **data-model discovery hangs** | documented example in `obuspa/files/etc/config/obuspa` |
| controller `EndpointID` = the controller's own id (e.g. `oktopusController`) | a mismatch makes obuspa drop every USP record with "inconsistent endpoint" → never connects | same example block |
| `/etc/board-db/config/device` (UCI `deviceinfo`) | `sysmngr` reads `Device.DeviceInfo.*` identity (SerialNumber/SoftwareVersion/…) from this UCI confdir, which iopsys provides via its board `db` backend | identity **template shipped** by `sysmngr` (`INSTALL_CONF`) — edit the values |
| disable base `sysntpd` | `timemngr` runs its own ntpd; the two fight over UDP/123 → procd crash-loops timemngr | uci-default `97-disable-sysntpd-for-timemngr` (shipped by `timemngr`) |
| `SYSMNGR_FWBANK_UBUS_SUPPORT=n` (default here) | the fwbank helper needs iopsys A/B dual-image glue (`/lib/functions/iopsys-fwbank.sh`); on single-image OpenWrt it spins 10 retries | default flipped in `sysmngr/Config.in` |

## Device-side onboarding (quickstart)

```sh
# 1. install (opkg resolves base deps; order doesn't matter with a feed)
opkg install libeasy_* bbf_configmngr_* libbbfdm-api1.0_* libbbfdm-ubus_* \
             bbfdmd_* dm-service_* sysmngr_* timemngr_* obuspa_*

# 2. set device identity (edit to taste; OUI must be 6 hex digits)
vi /etc/board-db/config/device          # template is shipped pre-populated

# 3. point obuspa at the controller — uncomment + edit the example block,
#    keeping EndpointID=<controller id> and assigned_role_name='full_access'
vi /etc/config/obuspa

# 4. (re)start; obuspa last so it reads a populated DeviceInfo
/etc/init.d/bbfdmd restart;  /etc/init.d/bbfdm.services restart
/etc/init.d/sysmngr restart; /etc/init.d/timemngr restart
/etc/init.d/obuspa  restart

# verify
ubus call bbfdm get '{"path":"Device.DeviceInfo.SerialNumber"}'   # non-empty
ubus call bbfdm get '{"path":"Device.Time.Status"}'               # Synchronized
```

If a stale `usp.db` blocks re-seeding the controller, force a clean seed:
`rm -f /etc/obuspa/.boot /etc/obuspa/usp.db* /tmp/obuspa/fw_defaults && /etc/init.d/obuspa restart`.

## Build

CI (`.github/workflows/build.yml`) builds the whole feed with the official
OpenWrt SDK (`openwrt/gh-action-sdk`) for two boards:

| board | OpenWrt target | package arch |
|---|---|---|
| mt7621 | `ramips/mt7621` | `mipsel_24kc` |
| rk3308 | `rockchip/armv8` | `aarch64_generic` |

Default OpenWrt release is `24.10.7` (override via `workflow_dispatch` input
`version`). The collect step asserts each key ipk is present by name — the
silently-dropped-package failure mode is caught, not hidden.

Locally against an OpenWrt SDK:

```sh
echo "src-link iopsys_usp $(pwd)" >> feeds.conf.default
./scripts/feeds update iopsys_usp
./scripts/feeds install -p iopsys_usp -a       # also pulls in jqhost/host
make package/obuspa/compile V=s
```
