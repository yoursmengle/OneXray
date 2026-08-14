## 1. Desktop typography

- [x] 1.1 Clamp desktop `MediaQuery.textScaler` in `GoRouteApp` (min 0.9, max 1.1); leave mobile unchanged
- [x] 1.2 Tighten desktop `AppTypography` semantic tokens and Material mapping; set explicit `height` so Windows CJK fallback cannot inflate dense rows
- [x] 1.3 Confirm list rows still ellipsize titles and keep delay/status on the same row; fix any remaining overflow without page-level numeric font sizes
- [x] 1.4 Add/extend theme tests for desktop clamp, token sizes/heights, and Windows fallback family

## 2. Node ping TUN bypass

- [x] 2.1 Add a ping-source helper that sets `streamSettings.sockopt.interface` from TUN `autoOutboundsInterface` on Windows/Linux outbounds (skip freedom/blackhole/dns)
- [x] 2.2 Apply the helper when building outbound, Full Config, and Raw `PingBatchSource` JSON
- [x] 2.3 Add unit tests that ping JSON includes the interface on Windows/Linux and is unchanged on other platforms
- [x] 2.4 Confirm Ping timeout range, probe URLs, and auto-ping preference are untouched

## 3. Validation

- [x] 3.1 Run `dart format` on changed Dart files and the ping/theme tests
- [ ] 3.2 Rebuild Windows x64 release and smoke Home list: text complete at 125–150% scale; ping while TUN is connected returns ms delays for working nodes
