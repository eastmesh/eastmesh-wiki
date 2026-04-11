---
title: packet-structure
description: Complete on-air packet format for MeshCore LoRa transmissions
published: true
date: 2026-02-19T00:00:00.000Z
tags: meshcore, technical, packets, protocol
---

# Packet Structure

Complete reference for the MeshCore over-the-air packet format. All transmissions between nodes follow this layout.

---

## Wire Format Overview

Every MeshCore packet on the LoRa channel follows this layout:

```
[Header: 1 byte]
[Transport Codes: 4 bytes]  ← only present for TRANSPORT_FLOOD or TRANSPORT_DIRECT route types
[Path Length: 1 byte]
[Path: 0–64 bytes]
[Payload: 0–184 bytes]
```

**Maximum total packet size**: 255 bytes (`MAX_TRANS_UNIT = 255`)

Packets are dropped by the firmware if:
- `path_length > 64`
- `payload > 184 bytes`
- Total exceeds 255 bytes

---

## Header Byte

The single-byte header is a bitfield packed as `0bVVPPPPRR`:

| Bits | Mask | Field | Description |
|------|------|-------|-------------|
| 0–1 | `0x03` | Route Type | Controls how packet is forwarded (flood vs. direct) |
| 2–5 | `0x3C` | Payload Type | One of 13 defined message types |
| 6–7 | `0xC0` | Payload Version | Currently always `0x00` (VER_1) |

### Route Types

| Value | Name | Description |
|-------|------|-------------|
| `0x00` | `TRANSPORT_FLOOD` | Flood with 4-byte transport codes prepended |
| `0x01` | `FLOOD` | Standard flood; path field accumulates node hashes in transit |
| `0x02` | `DIRECT` | Directed delivery with explicit hop-by-hop path |
| `0x03` | `TRANSPORT_DIRECT` | Direct routing with transport codes |

### Payload Types

| Value | Name | Description |
|-------|------|-------------|
| `0x00` | `REQ` | Encrypted request (dest, src, MAC, timestamp, type, data) |
| `0x01` | `RESPONSE` | Encrypted response (dest, src, MAC, 4-byte tag, content) |
| `0x02` | `TXT_MSG` | Encrypted peer-to-peer text message |
| `0x03` | `ACK` | Acknowledgement (4-byte CRC of message data) |
| `0x04` | `ADVERT` | Node advertisement (signed, unencrypted) |
| `0x05` | `GRP_TXT` | Group/channel text message |
| `0x06` | `GRP_DATA` | Group/channel binary datagram |
| `0x07` | `ANON_REQ` | Anonymous encrypted request (used for room server login) |
| `0x08` | `PATH` | Path return — reverse route carried back to sender |
| `0x09` | `TRACE` | Path trace — collects per-hop SNR data |
| `0x0A` | `MULTIPART` | Fragmented multi-packet message |
| `0x0B` | `CONTROL` | Control/discovery data |
| `0x0F` | `RAW_CUSTOM` | Application-defined raw bytes |

---

## Path Field

The path field serves dual purpose depending on route type:

**During FLOOD**: starts empty; each forwarding node **appends** its 1-byte node ID (first byte of its Ed25519 public key) before retransmitting. By the time the packet reaches its destination, the path field is an ordered log of every hop traversed.

**During DIRECT**: contains the pre-determined sequence of 1-byte node IDs for each intermediate hop. Each forwarding node checks if `path[0]` matches its own ID. On match, it strips the first byte and retransmits. When `path_length == 0`, the node is the final destination.

**Key constant**: `PATH_HASH_SIZE = 1` byte per hop. Maximum 64 hops.

---

## Transport Codes

When route type is `TRANSPORT_FLOOD` or `TRANSPORT_DIRECT`, four bytes of transport codes follow the header:

```
[region_code: uint16_t, little-endian]
[sub_region_code: uint16_t, little-endian]
```

Repeaters check these against their regional configuration and can selectively suppress forwarding via `REGION_DENY_FLOOD` or `REGION_DENY_DIRECT` flags. This allows geographic scoping — preventing network floods from crossing administrative boundaries.

---

## Payload Layouts by Type

### ADVERT (0x04) — Node Advertisement

Broadcast periodically by all node types. Unencrypted but signed.

```
[public_key:  32 bytes]  Ed25519 public key (node identity)
[timestamp:    4 bytes]  Unix epoch, little-endian
[signature:   64 bytes]  Ed25519 signature over public_key || timestamp
[appdata:   variable]    See flags below
```

**Appdata flags byte** (bitmask):

| Bits | Mask | Meaning |
|------|------|---------|
| 0–3 | `0x0F` | Node type: 0=none, 1=Companion/Chat, 2=Repeater, 3=Room server, 4=Sensor |
| 4 | `0x10` | `ADV_LATLON_MASK`: followed by `int32_t lat, lon` (×1E6 scale) |
| 5 | `0x20` | `ADV_FEAT1_MASK`: followed by 16-bit feature flags |
| 6 | `0x40` | `ADV_FEAT2_MASK`: followed by second 16-bit feature flags |
| 7 | `0x80` | `ADV_NAME_MASK`: followed by null-terminated name string |

### TXT_MSG (0x02) — Encrypted Text Message

Peer-to-peer private message. All content from `cipher_mac` onward is encrypted.

```
[dest_hash:     1 byte]  First byte of destination's public key
[src_hash:      1 byte]  First byte of sender's public key
[cipher_mac:    2 bytes] HMAC-SHA256 truncated to 2 bytes (authentication tag)
[timestamp:     4 bytes] Unix epoch, little-endian
[type_attempt:  1 byte]  Lower 2 bits = retry attempt number; upper bits = message subtype
[message:    variable]   UTF-8 text, null terminated
```

`type_attempt` upper bits subtypes: `0` = plain text, `1` = CLI data, `2` = signed plain text.

### ACK (0x03) — Acknowledgement

Sent in reply to confirm receipt of a message.

```
[crc: 4 bytes]  SHA256(timestamp || attempt || text || sender_pubkey), truncated to 4 bytes
```

The receiving node verifies the CRC matches the previously sent message. This also serves as a round-trip-time measurement point.

### PATH (0x08) — Path Return

Sent by the destination after receiving a flood packet, carrying the reverse route back to the originator.

```
[dest_hash:      1 byte]
[src_hash:       1 byte]
[cipher_mac:     2 bytes]
[path_length:    1 byte]
[path:        variable]  Ordered 1-byte node hashes (reverse of the flood path)
[extra_type:     1 byte]
[extra_payload: variable]
```

### GRP_TXT / GRP_DATA (0x05, 0x06) — Group Channel Messages

Group/channel messages are keyed per-channel rather than per-contact.

```
[channel_hash: 1 byte]  First byte of the channel's hash
[cipher_mac:   2 bytes] HMAC-SHA256 truncated, over ciphertext
[ciphertext: variable]  AES-128-ECB encrypted content
```

### ANON_REQ (0x07) — Anonymous Encrypted Request

Used primarily for room server login — the ephemeral key prevents linking requests to a known identity.

```
[dest_hash:          1 byte]
[ephemeral_pubkey:  32 bytes] One-time X25519 public key
[cipher_mac:         2 bytes]
[ciphertext:      variable]  Encrypted credentials/request
```

### TRACE (0x09) — Path Trace

Diagnostic packet that collects per-hop SNR as it traverses the mesh.

```
[dest_hash:   1 byte]
[src_hash:    1 byte]
[hop_data:  variable]  Sequence of [node_hash(1 byte) + snr(1 byte)] pairs appended at each hop
```

SNR bytes are stored as `int8_t` in quarter-dB units (divide by 4 for dBm float).

### CONTROL (0x0B) — Control/Discovery

```
[flags:    1 byte]  Upper 4 bits = sub_type
[data:  variable]
```

---

## Size Constants Reference

| Constant | Value | Notes |
|----------|-------|-------|
| `MAX_TRANS_UNIT` | 255 bytes | Maximum total on-wire packet size |
| `MAX_PACKET_PAYLOAD` | 184 bytes | Maximum payload field length |
| `MAX_PATH_SIZE` | 64 bytes | Maximum path field length (= max 64 hops) |
| `PATH_HASH_SIZE` | 1 byte | Node identifier per hop in path field |
| `PUB_KEY_SIZE` | 32 bytes | Ed25519 public key |
| `PRV_KEY_SIZE` | 64 bytes | Ed25519 private key (seed + pub) |
| `SIGNATURE_SIZE` | 64 bytes | Ed25519 signature |
| `CIPHER_KEY_SIZE` | 16 bytes | AES-128 key |
| `CIPHER_BLOCK_SIZE` | 16 bytes | AES block size |
| `CIPHER_MAC_SIZE` | 2 bytes | Truncated HMAC tag |
| `MAX_ADVERT_DATA_SIZE` | 32 bytes | Maximum advertisement appdata |
| `MAX_HASH_SIZE` | 8 bytes | Seen-packet dedup hash entry size |

---

## Example: Decoding a Header Byte

Given header byte `0x12`:

```
Binary:       0 0 0 1 0 0 1 0
Bits 6–7:     00  → Version = 0 (VER_1)
Bits 2–5:   0100  → Payload type = 0x04 = ADVERT
Bits 0–1:     10  → Route type = 0x02 = DIRECT
```

This is a directly-routed advertisement packet.

---

## Related Pages

- [Routing Algorithm](./routing)
- [Encryption & Authentication](./encryption)
- [Channels & Keys](./channels-and-keys)
- [Firmware Internals](./firmware/overview)
