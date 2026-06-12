# iopsys-feed — iopsys/bbfdm USP feed for OpenWrt

A self-contained OpenWrt feed that connects an OpenWrt gateway to an
[Oktopus](https://github.com/OktopUSP/oktopus) USP Controller using the
**iopsys** TR-369/USP stack — the alternative to the prpl Ambiorix path in
`../prpl-feed`.

```
Oktopus  --USP/WebSocket-->  obuspa (iopsys fork: Agent + Broker)
                                 |
                                 |  ubus / micro-service DM
                                 v
                       bbfdm (bbfdmd + dm-service)  --UCI/ubus-->  system
```

## Why this exists (vs. the prpl feed)

| | `prpl-feed` (Ambiorix) | `iopsys-feed` (bbfdm) |
|---|---|---|
| Data model source | one `tr181-*` daemon per area (amxrt + ODL) | one engine — `bbfdmd` + `dm-service` (`libcore.so`) |
| Dependency stack | full Ambiorix (`libamx*`, `mod-dmext`, `amxrt`) | **only OpenWrt base** (uci/ubus/json-c/openssl/curl/sqlite3/websockets/nl) |
| Config backend | Ambiorix-native | native UCI / ubus (`/etc/config`) |
| Startup blocking | ODL `requires "X."` chains (had to be patched out) | none — no ODL |

The iopsys path has **no Ambiorix layer at all**, so the entire class of
`requires "..."`/crash-loop fixes from the prpl feed is not needed here.

## Packages

All sources are pinned to upstream commits — nothing is fabricated; the Makefiles
are vendored verbatim from [`feed/iopsys`](https://dev.iopsys.eu/feed/iopsys)
(branch `devel`). `PKG_MIRROR_HASH:=skip` is upstream's own value; the integrity
pin is `PKG_SOURCE_VERSION` (the git commit).

| dir | upstream | pin | builds |
|---|---|---|---|
| `bbfdm/` | [bbf/bbfdm](https://dev.iopsys.eu/bbf/bbfdm) v1.20.2 | `99e70ae4` | `libbbfdm-api`, `libbbfdm-ubus`, `bbfdmd`, `dm-service`, `bbf_configmngr` |
| `obuspa/` | [bbf/obuspa](https://dev.iopsys.eu/bbf/obuspa) v11.0.3.1 | `92aabe98` | `obuspa` (USP Agent + Broker, WebSocket MTP) |
| `libeasy/` | [hal/libeasy](https://dev.iopsys.eu/hal/libeasy) v7.5.1 | `b981f7e1` | `libeasy` (helper lib, required by `dm-service`) |

Runtime set that feeds the Device.* tree to Oktopus:
`obuspa` → `dm-service` (runs `libcore.so`) → `libbbfdm-api` + `libbbfdm-ubus` +
`bbf_configmngr` + `libeasy`.

> Layout is **flat** (mirrors `feed/iopsys`) on purpose: `obuspa/Makefile` does
> `include ../bbfdm/bbfdm.mk`, so `obuspa/` and `bbfdm/` must be siblings.

## Build

CI (`.github/workflows/build.yml`) builds the whole feed with the official
OpenWrt SDK (`openwrt/gh-action-sdk`) for two boards:

| board | OpenWrt target | package arch |
|---|---|---|
| mt7621 | `ramips/mt7621` | `mipsel_24kc` |
| rk3308 | `rockchip/armv8` | `aarch64_generic` |

Default OpenWrt release is `24.10.7` (override via `workflow_dispatch` input
`version`). All dependencies resolve from the SDK's base + packages feeds.

Locally against an OpenWrt SDK:

```sh
echo "src-link iopsys_usp $(pwd)" >> feeds.conf.default
./scripts/feeds update iopsys_usp
./scripts/feeds install -p iopsys_usp -a
make package/obuspa/compile V=s
```
