---
title: routing
description: MeshCore packet routing algorithm — hybrid flood and path-cached direct routing
published: true
date: 2026-02-19T00:00:00.000Z
tags: meshcore, technical, routing, protocol
---

# Routing Algorithm

MeshCore uses a hybrid routing scheme that combines initial flood discovery with path-cached direct routing for all subsequent messages. This design dramatically reduces airtime compared to pure flooding while maintaining resilience and self-healing capability.

---

## Overview: Three Phases

Every conversation between two nodes follows this lifecycle:

```
Phase 1: Discovery Flood    → packet traverses the mesh, building a path record
Phase 2: Path Return        → destination sends the reverse route back
Phase 3: Cached Direct      → all future messages use the known path directly
```

When a path fails (no ACK received), the firmware resets to Phase 1 automatically.

---

## Phase 1 — Discovery Flood

**Trigger**: sender has no cached path to destination (`out_path_len == -1`)

The sender transmits the message with route type `ROUTE_TYPE_FLOOD`. The path field starts **empty**.

At each intermediate repeater:
1. Node receives the flood packet
2. Node checks its duplicate suppression table — if seen before, drop it
3. Node checks `path_len < flood_max` (configurable per-repeater hop limit)
4. If eligible, node **appends its own 1-byte node hash** to the path field
5. Node schedules retransmission (with delay — see Flood Delay below)

When the destination receives the packet, the path field contains an ordered sequence of every intermediate hop's 1-byte identifier.

**Example** (3-hop path):
```
Sender → RepeaterA → RepeaterB → RepeaterC → Destination
                                              path = [A_hash, B_hash, C_hash]
```

---

## Phase 2 — Path Return

After receiving the flooded message, the destination node:
1. Reverses the accumulated path
2. Wraps it in a `PAYLOAD_TYPE_PATH` packet
3. Sends it back toward the originator (may flood again, or use the reversed path directly)

When the originator receives the PATH packet, it stores the route:
```
ContactInfo.out_path[]    = reversed path bytes
ContactInfo.out_path_len  = number of hop bytes
```

This path is now cached for all future messages to that contact.

---

## Phase 3 — Cached Direct Routing

All subsequent messages use route type `ROUTE_TYPE_DIRECT` with the stored path pre-populated in the path field.

At each hop along the path:
1. Forwarding node checks: does `path[0]` match my 1-byte node hash?
2. **Yes**: strip the first byte from path (shift remaining left), retransmit immediately (priority 0)
3. **No**: ignore the packet entirely

When `path_length == 0` after stripping, the packet has reached its destination.

This results in:
- No redundant retransmissions from nodes not on the path
- Minimal airtime consumption per message
- Deterministic delivery along the known best route

**Airtime savings**: Compared to perpetual flooding, cached direct routing can reduce airtime by ~95–98% for repeated messages on a stable topology.

---

## Path Failure and Reset

If the sender does not receive an ACK after a configurable number of attempts, it calls `resetPathTo()`:

```
ContactInfo.out_path_len = -1   // forces next send to flood again
```

The next message triggers a new discovery flood, re-learning the current best path. This provides self-healing behaviour when topology changes (node goes offline, new repeater added, etc.).

---

## Duplicate Suppression

The `SimpleMeshTables` class prevents loops and redundant processing:

**Two separate tables:**

| Table | Size | Entry | Purpose |
|-------|------|-------|---------|
| ACK table | 64 entries | `uint32_t` (4-byte ACK CRC) | Suppress duplicate ACKs |
| Packet hash table | 128 entries | 8-byte hash | Suppress duplicate data packets |

Both tables use **cyclic (ring buffer) replacement** — the oldest entry is overwritten when full. `hasSeen()` performs a linear scan. Separate counters track `_direct_dups` and `_flood_dups` for statistics.

When a node receives a packet it has already processed, it is silently dropped at this stage before any routing decision is made.

---

## Flood Delay Formula

To avoid simultaneous retransmissions from multiple nodes hearing the same flood packet, retransmission is staggered based on link quality:

```
delay = (10^(0.85 - score) - 1.0) × air_time
```

Where `score` ∈ [0, 1] is derived from the received SNR and packet length via `packetScoreInt()`. A stronger signal (better score) means a **shorter delay** — that node retransmits first, which is logical because closer/better-heard nodes make better relays.

**Limits:**
- Maximum delay: `MAX_RX_DELAY_MILLIS = 32000 ms`
- Minimum delay: if computed < 50 ms, packet is processed immediately without queuing

**Practical effect**: Nodes that heard the packet well (short distance, good SNR) retransmit first. Nodes with marginal reception retransmit later, and may find the packet already forwarded by a better node — causing them to see the dup and cancel their own retransmission.

---

## Hop Limit

Each repeater has a configurable `flood_max` value (default typically 4–8, max 64):

```
CLI: set flood.max <0–64>
```

A repeater drops any flood packet where `path_len >= flood_max`. This prevents unbounded propagation across a large network.

For direct packets, the effective hop limit is the length of the stored path (max 64 bytes = 64 hops).

---

## Priority Scheme

The `Dispatcher` uses a numeric priority queue (0 = highest priority):

| Packet Type | Priority | Notes |
|-------------|----------|-------|
| Direct-routed messages | 0 | Immediate, pre-emptive |
| Flood packets (close source) | Low number | Score-dependent, earlier = better link |
| Trace packets | 5 | Diagnostic, low priority |

---

## Airtime Budget and Duty Cycle

The firmware enforces an airtime budget to respect duty cycle limits:

```
getAirtimeBudgetFactor() = 2.0
effective_duty_cycle = 100 / (airtime_factor + 1) = 33.3%
```

The radio must be silent for at least **2× the last transmission duration** before the next transmission. This is enforced by the `Dispatcher` before any queued transmission fires.

For regions with strict duty cycle requirements (e.g., EU 869.525 MHz sub-band at 10% max), operators should configure `af = 9.0`.

---

## Channel Activity Detection (CAD)

Before every transmission, the Dispatcher performs LoRa Channel Activity Detection:

- `CAD_FAIL_MAX_DURATION = 4000 ms` — if channel stays busy for 4 seconds, declare timeout error
- `STARTRX_TIMEOUT = 8000 ms` — watchdog for radio stuck in TX state
- `NOISE_FLOOR_CALIB_INTERVAL = 2000 ms` — RSSI sampling interval

The noise floor baseline is calculated from 64 RSSI samples below threshold, clamped at −120 dBm minimum.

---

## Neighbour Table (Repeaters)

Repeaters maintain a neighbour table of nearby repeater-type nodes they have directly heard:

```
NeighbourInfo {
    mesh::Identity id
    uint32_t advert_timestamp
    uint32_t heard_timestamp
    int8_t snr               // stored as SNR × 4, divide by 4 for dBm
}
```

Up to `MAX_NEIGHBOURS` entries (typically 50). Only populated from zero-hop ADVERT packets from other repeaters. Used for local mesh topology awareness and path selection heuristics.

---

## Rate Limiting

Repeaters apply rate limiting to protect against abuse:

- **`discover_limiter`**: throttles path-discovery flood requests — prevents a compromised or misbehaving node from saturating the mesh with discovery floods
- **`anon_limiter`**: throttles anonymous requests (room server login) — prevents DoS via repeated anonymous login attempts

---

## Transport Codes and Region Scoping

`ROUTE_TYPE_TRANSPORT_FLOOD` packets include a 4-byte region code. Repeaters check this against their regional configuration. Flags:

- `REGION_DENY_FLOOD`: repeater will not forward flood packets tagged with this region
- `REGION_DENY_DIRECT`: repeater will not forward direct packets tagged with this region

This enables geographic/administrative boundaries within a larger network — for example, separating state-level mesh regions while allowing selective cross-region forwarding for gateway-type nodes.

---

## Routing State Summary

| Condition | `out_path_len` | Next Action |
|-----------|---------------|-------------|
| New contact / path unknown | `-1` | Send as FLOOD, accumulate path |
| Path known and valid | `> 0` | Send as DIRECT with cached path |
| ACK timeout / path failure | reset to `-1` | Trigger new FLOOD discovery |
| Contact out of range | stays `-1` | Message queued, retry on next advert heard |

---

## Related Pages

- [Packet Structure](./packet-structure)
- [Node Roles](./node-roles)
- [Radio Layer](./radio-layer)
- [Firmware Internals](./firmware/overview)
