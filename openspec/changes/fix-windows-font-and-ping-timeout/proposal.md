## Why

On the current Windows host, Home and list text is too large, so node names, delays, and side-panel details clip or wrap out of view. The same list can start TUN and route traffic, but every ping result is timeout. Both issues make the Windows client unusable for choosing a node.

## What Changes

- Tighten desktop typography and clamp Windows text scale so existing labels, list rows, and badges stay readable without adding a font-size setting.
- Keep Geist as the primary family; Windows CJK fallback must not inflate line height or overflow dense rows.
- Make list/Home ping measure latency through the node under test even when TUN is already capturing system traffic (the current “connect works, ping all times out” case).
- Apply the same physical outbound interface used by Windows TUN (`autoOutboundsInterface`) to ping outbounds so `pingBatch` does not send probes into the tunnel or FakeDNS range.
- Preserve existing Ping settings (timeout 3–8s, Cloudflare/Google probe URLs, auto-ping). Do not add or remove persisted fields.

## Capabilities

### New Capabilities

- `desktop-typography`: Desktop (especially Windows) text scale, fallback metrics, and overflow so UI copy remains complete.
- `node-ping`: Batch ping of listed outbound / Full Config / Raw nodes reports real delay or a true error, including while TUN is connected.

### Modified Capabilities

- None. `openspec/specs/` has no existing capability specs.

## Impact

- UI: `lib/pages/theme/font.dart`, `lib/pages/theme/theme.dart`, `lib/pages/main/router.dart`, dense list/row widgets that already use `AppTypography`.
- Ping: `lib/service/ping/` (source JSON, batch runner), possibly `lib/service/xray/outbound/` sockopt helpers and `lib/service/tun_settings/`.
- Tests: theme/typography tests; ping batch / source construction tests for Windows TUN bypass.
- No Pigeon, Drift, or l10n field changes. No new user-facing settings.
