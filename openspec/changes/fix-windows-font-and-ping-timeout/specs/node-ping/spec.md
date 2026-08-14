## Purpose

Measures listed node latency through the node under test, including while Windows TUN is already connected and routing traffic.

## ADDED Requirements

### Requirement: Ping reports real delay when the node can route

When the user pings listed outbound, Full Config, or Raw nodes, the system MUST send the configured probe through that node’s outbound. If the probe succeeds within the saved timeout, the system MUST store a delay in milliseconds. Timeout (11000) and error (10000) MUST be used only for an actual probe timeout or failure.

#### Scenario: Reachable node while disconnected

- **WHEN** TUN is not running and the user pings a node that can later start and route
- **THEN** the list shows a millisecond delay, not timeout, for that node

#### Scenario: Reachable node while TUN is connected

- **WHEN** TUN is already connected and routing, and the user pings the same or other listed nodes
- **THEN** each successful probe shows a millisecond delay instead of timeout for every node

### Requirement: Ping bypasses the active TUN path

On Windows and Linux, ping probes MUST leave the machine on the same physical outbound interface used for TUN outbounds (`autoOutboundsInterface`, including `auto`). Probe sockets MUST NOT be captured by the active TUN default route or resolved only through tunnel FakeDNS.

#### Scenario: All nodes time out only while TUN is up

- **WHEN** listed nodes can start TUN and browse, but ping was going through the tunnel
- **THEN** after this change, pinging those nodes while TUN is up yields millisecond delays or a true per-node error, not a uniform timeout

### Requirement: Existing ping settings are unchanged

The system MUST keep the current ping timeout range (3–8 seconds, default 5), Cloudflare and Google probe URLs, and the auto-ping-new-configs flag. It MUST NOT add or remove persisted ping or TUN fields.

#### Scenario: Saved ping preferences

- **WHEN** the user has already saved a timeout and probe URL
- **THEN** ping continues to use those values after the fix
