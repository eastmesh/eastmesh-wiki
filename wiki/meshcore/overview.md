---
title: overview
description: MeshCore protocol overview — core concepts, architecture, and how it works
published: true
date: 2026-02-19T00:00:00.000Z
tags: meshcore, overview, protocol
---

# MeshCore Overview

MeshCore is a LoRa-based mesh networking protocol designed for resilient, off-grid messaging over radio. This page covers the core concepts, how traffic flows, and the key design decisions.

---

## Core Concepts

| Concept | Description |
|---------|-------------|
| **Companion** | An endpoint device used for sending and receiving messages. Carried by users. Does not forward others' traffic. |
| **Repeater** | Infrastructure node that extends coverage by forwarding packets. The backbone of any deployment. |
| **Room Server** | Store-and-forward message board. Holds messages for offline recipients. |
| **Channel** | A shared group communication namespace, defined by a 32-byte shared secret. Not tied to radio frequency. |
| **Contact** | A known node — stored with public key, cached route, and shared secret. |
| **Advertisement (ADVERT)** | Signed broadcast that announces a node's identity, type, name, and optionally GPS location. |
| **Link quality** | Measured via RSSI (signal strength) and SNR (signal-to-noise ratio). Drives routing decisions. |

Mesh networks succeed when many moderately good links overlap, not when one node tries to reach everything directly.

---

## How Traffic Flows

### Peer-to-Peer Message (First Send)

When no cached path exists to the destination:

```
1. Sender transmits a FLOOD packet (path field empty)
2. Each repeater that receives it appends its 1-byte ID to the path field and retransmits
3. Destination receives the packet — path field now contains every hop traversed
4. Destination reverses the path and sends it back in a PATH packet
5. Sender receives the PATH packet, stores the route
```

### Peer-to-Peer Message (Subsequent Sends)

```
1. Sender transmits a DIRECT packet with the stored path pre-loaded
2. Each hop in the path strips its own ID and forwards to the next
3. Final hop delivers to destination
4. Destination sends ACK back (may flood or use reverse path)
```

DIRECT routing uses ~95–98% less airtime than perpetual flooding for repeated messages.

### Group Channel Message

```
1. Sender encrypts message with the channel's shared secret (AES-128-ECB + HMAC)
2. Transmits as FLOOD (channel messages always flood — no per-contact path caching)
3. All nodes with the channel secret can decrypt and read the message
4. Nodes without the secret see only the 1-byte channel hash in the header
```

---

## Protocol Layers

```
Application:    Message composition, contact management, channels
Crypto:         Ed25519 identity, ECDH key exchange, AES-128-ECB, HMAC-SHA256
Routing:        Hybrid flood discovery + cached direct delivery
MAC:            Channel Activity Detection, airtime budget, priority queuing
Radio:          LoRa (SX1262/SX1276/etc.) via RadioLib
Physical:       915 MHz ISM band (Australia/NZ), 62.5 kHz BW
```

---

## Design Priorities

**Resilience over performance**: The flood+path-cache approach means any new node can be reached without pre-configuration, and paths re-discover automatically if topology changes.

**Airtime efficiency**: Cached direct routing minimises on-air time after initial discovery. Important for regulatory duty cycle compliance and network capacity.

**Constrained hardware**: No dynamic memory allocation. Fixed packet sizes. Minimal crypto overhead. Runs on MCUs with 64–512 KB RAM.

**Independence**: No internet, no LoRaWAN infrastructure, no central servers required for core messaging. Room servers and MQTT bridges are optional enhancements.

**Site quality over quantity**: One well-placed elevated repeater outperforms several poor indoor nodes. This is a fundamental principle for community deployments.

---

## Packet Size Limits

| Field | Maximum |
|-------|---------|
| Total on-wire packet | 255 bytes |
| Payload | 184 bytes |
| Path (hop records) | 64 bytes (= 64 hops) |

---

## Security Summary

- Node identity: Ed25519 keypairs, generated on first boot
- Peer messages: ECDH shared secret → AES-128-ECB + 2-byte HMAC
- Channel messages: Shared secret → AES-128-ECB + 2-byte HMAC
- Advertisements: Ed25519 signed (unencrypted)
- Known limitation: AES-ECB mode (no IV/nonce) — see [Encryption](./encryption) for details

---

## Deep Dives

### Protocol Internals

- [Packet Structure](./packet-structure) — complete wire format, all field layouts
- [Routing Algorithm](./routing) — flood discovery, path caching, direct routing, duplicate suppression
- [Encryption & Authentication](./encryption) — crypto stack, Ed25519, ECDH, AES-ECB, HMAC
- [Channels & Keys](./channels-and-keys) — channel types, key management, naming conventions

### Implementation

- [Node Roles](./node-roles) — Companion, Repeater, Room Server, Sensor differences
- [Radio Layer](./radio-layer) — LoRa parameters, regional presets, airtime, CAD
- [Firmware Internals](./firmware/overview) — source architecture, MCU support, storage, debugging
- [Companion Protocol](./companion-protocol) — BLE/USB protocol, command codes, frame format

### Deployment

- [Community Rules & Safety](../community/rules-and-safety)
- [Hardware Recommendations](../hardware/recommended)
- [RF & Propagation](../radio/overview)
