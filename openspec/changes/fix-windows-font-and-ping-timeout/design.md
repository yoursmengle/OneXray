## Context

See proposal.md for motivation.

Typography today is Shadcn Geist via `AppTypography` (`lib/pages/theme/font.dart`). Semantic styles map from Geist’s web scale (`h4` / `large` / `p` / `muted` / `small`). Windows adds `Microsoft YaHei UI` as fallback only. `GoRouteApp` does not clamp `MediaQuery.textScaler`. List rows already ellipsize titles (`data_list.dart`), so the remaining failure is type that is too large for the row budget, plus CJK metric mismatch.

Ping today builds a JSON body that contains only `outbounds` and calls libXray `pingBatch` in-process (`lib/service/ping/`). libXray ignores other root fields. Windows TUN installs `0.0.0.0/0` plus TUN DNS / FakeDNS (`198.18.0.1/15`). The running core binds outbounds with `autoOutboundsInterface`. The temporary ping instance does not, so its dials follow the default route into TUN. System DNS while TUN is up also answers FakeDNS addresses that only work inside the tunnel. Result: every probe times out even though the selected node routes.

Constraints: no new persisted fields; pages must keep using `AppTypography` / `ThemeData.textTheme`; no page-level numeric font sizes.

## Goals / Non-Goals

**Goals:**

- Desktop type scale and text scaler that keep current layouts complete on Windows 100%–150% scale.
- Ping probes that bind to the TUN physical interface (or `auto`) so they do not enter the tunnel.
- Tests that lock typography clamp/scale and ping source sockopt behavior.

**Non-Goals:**

- A user-facing font-size setting.
- Changing probe URLs, timeout range, or auto-ping persistence.
- Replacing `pingBatch` with HTTP through `pingIn`.
- Android / Apple Network Extension ping paths.

## Decisions

### 1. Clamp desktop text scaler in `GoRouteApp`, do not add a setting

- **Choice:** In `GoRouteApp`’s `builder`, wrap the child with `MediaQuery` that clamps `textScaler` on desktop (Windows / Linux / macOS), e.g. `clamp(min: 0.9, max: 1.1)`.
- **Why:** Windows “make text bigger” multiplies Geist’s already-large scale. Clamping is one place, no new preference, and matches “do not add fields.”
- **Alternative:** Ignore OS scale entirely (`TextScaler.noScaling`) — worse for mild accessibility needs.
- **Alternative:** Per-page font overrides — forbidden by typography rules.

### 2. Tighten desktop `AppTypography` from Geist defaults; keep semantic tokens

- **Choice:** On desktop, copy Geist styles then reduce size/height for `pageTitle`, `panelTitle`, `rowTitle`, `rowValue`, `supporting`, `badge`, `control`, and the Material `textTheme` mapping. Keep the same token names. Set an explicit `height` so YaHei fallback cannot blow line-height.
- **Why:** Overflow is from token sizes, not missing ellipsis. Changing tokens fixes Home, lists, and settings together.
- **Alternative:** Shrink only Home tiles — leaves settings and Core lists broken.

### 3. Apply TUN outbound interface to ping outbounds only

- **Choice:** When building `PingBatchSource` JSON, clone the target outbound(s) and set `streamSettings.sockopt.interface` from current TUN settings (`autoOutboundsInterface`, default `auto`) on Windows and Linux. Do this for outbound, Full Config, and Raw sources (Raw: parse JSON, patch matching outbound(s), re-encode). Leave macOS / mobile ping JSON unchanged.
- **Why:** libXray `pingBatch` only reads `outbounds`. The same `interface` value already used by TUN is the supported way to skip Wintun / `0.0.0.0/0`.
- **Alternative:** Stop TUN, ping, restart — disruptive and races the user’s session.
- **Alternative:** Ping through `pingIn` on the running core — different code path, does not test unselected nodes, larger behavior change.
- **Alternative:** Add DNS to ping JSON — ignored by libXray.

### 4. Always attach the interface on Windows/Linux ping, not only when TUN is up

- **Choice:** Always set `sockopt.interface` on desktop ping outbounds. When TUN is down, `auto` still selects a valid NIC; when TUN is up, it avoids the tunnel.
- **Why:** Avoids a “VPN running?” race and matches “all pings time out” whether or not the user pinged while connected.
- **Alternative:** Only patch when `VpnService.vpnRunning` is true — misses the first batch after connect and is harder to test.

## Risks / Trade-offs

- [Geist + YaHei still look slightly uneven] → Mitigation: explicit `height` on dense tokens; do not replace Geist.
- [Some NICs reject `interface: auto`] → Mitigation: reuse the exact TUN setting the core already starts with; if a user set a named interface for TUN, ping uses that name.
- [Raw / Full Config with several outbounds] → Mitigation: apply interface to every outbound in the ping payload except `freedom` / `blackhole` / `dns` tags if present; libXray still picks `outboundTag`, `proxy`, or the first outbound.
- [Probe URL blocked in some regions even through a working node] → Mitigation: out of scope; keep existing URL setting. Uniform timeout on every node is the TUN-capture bug, not a single blocked URL.

## Migration Plan

- No data migration. Existing ping and TUN preferences stay valid.
- Rollback: revert typography/scaler and ping source patch; no schema rollback.
