---
title: node-roles
description: MeshCore node roles — Companion, Repeater, Room Server, Sensor, and Terminal
published: true
date: 2026-02-19T00:00:00.000Z
tags: meshcore, nodes, roles, hardware
---

# Node Roles

MeshCore firmware ships in five distinct roles. Each role serves a specific function in the network and has different capabilities, storage constraints, and management interfaces.

---

## Role Comparison

| Feature | Companion | Repeater | Room Server | Sensor | Terminal |
|---------|-----------|----------|-------------|--------|---------|
| Forwards packets | No | Yes | No | No | No |
| Stores contacts | Yes (up to 350) | No | No | No | Yes (100) |
| Message queue | Yes | No | No | No | No |
| Group channels | Yes (up to 40) | No | No | No | No |
| Store & forward | No | No | Yes | No | No |
| User interface | Mobile/web app | CLI | CLI | None | CLI terminal |
| GPS sharing | Optional | No | No | Yes | Optional |
| BLE | Yes | No | Optional | No | No |

---

## Companion Radio

**Firmware**: `companion_radio`
**Base class**: `BaseChatMesh : Mesh`
**Advert type byte**: `1` (Chat/Companion)

The Companion is the endpoint most users carry. It sends and receives messages but does not forward packets from other nodes.

### What it does

- Sends messages to specific contacts (peer-to-peer) and group channels
- Receives incoming messages and buffers them while the app is disconnected
- Periodically broadcasts ADVERT packets with node identity, name, and optional GPS location
- Tracks up to 350 contacts (ESP32-S3) or 160 contacts (ESP32/nRF52), each storing:
  - Public key
  - Cached path to that contact
  - Shared secret (computed on first contact, cached)
  - Name, last-heard timestamp, GPS coordinates (if shared)
- Manages up to 40 group channels

### Offline queue

When the companion app is disconnected, the firmware buffers incoming messages in an offline queue (up to 256 messages). The app retrieves these via `CMD_SYNC_NEXT_MESSAGE` on reconnect.

### BLE interface

BLE device name format: `MeshCore-` + node identity hash.
Default PIN: `123456` (randomised per-session on devices with displays).

### Connectivity options

| Interface | Notes |
|-----------|-------|
| BLE (NUS profile) | Primary mobile app interface |
| USB Serial | 115200 baud 8N1, framed protocol |
| WiFi TCP | Port 4000, TCP server on device |
| ESP-NOW | Local mesh bridging between ESP32 nodes |

### Hardware examples

- WisMesh RAKTAG (nRF52840 + SX1262)
- LilyGO T-Deck (ESP32-S3 + SX1276 + keyboard + display)
- Heltec Vision Master T190 (ESP32-S3 + SX1262 + display)

---

## Repeater

**Firmware**: `simple_repeater`
**Base class**: `SimpleRepeater : Mesh`
**Advert type byte**: `2` (Repeater)

The Repeater extends network coverage by forwarding packets from other nodes. It is the infrastructure backbone of any MeshCore deployment.

### What it does

- Listens continuously for incoming packets
- Forwards eligible packets based on routing rules:
  - Not a duplicate (checked via `SimpleMeshTables`)
  - Not disabled (`disable_fwd = false`)
  - Flood packets: `path_len < flood_max`
  - Transport packets: transport code not flagged `REGION_DENY_FLOOD`
- Appends its 1-byte node hash to flood packets before forwarding
- Maintains a neighbour table of nearby repeaters it has heard directly
- Broadcasts periodic ADVERT packets so other nodes can discover it

### Neighbour table

Up to 50 entries, each containing:
```
mesh::Identity id
uint32_t advert_timestamp
uint32_t heard_timestamp
int8_t   snr              // quarter-dB units, divide by 4
```

Only populated from zero-hop ADVERT packets from other repeater-type nodes (not companions or sensors).

### Retransmission timing

```
delay = random(0, 5×t + 1)
where t = estimated_airtime × tx_delay_factor
tx_delay_factor: 0.5 for flood, 0.2 for direct
```

### Configuration

Managed entirely via USB serial CLI or remote mesh text commands. No app required.

Key parameters:

| Parameter | CLI Command | Description |
|-----------|-------------|-------------|
| Flood max hops | `set flood.max <n>` | 0–64; drop floods at this hop count |
| Disable forwarding | `set fwd.disable <0/1>` | Emergency kill switch |
| Power saving | `set powersave <0/1>` | 5-second sleep cycle |
| Airtime factor | `set af <value>` | Duty cycle control |
| Radio params | `set radio <freq> <bw> <sf> <cr>` | Must match network |
| TX power | `set txpow <dBm>` | Transmit power |

### Statistics tracked

- Battery voltage
- Queue length
- Noise floor (dBm)
- Last RSSI and SNR
- Flood/direct send and receive counts
- TX and RX airtime (ms)
- Uptime (seconds)
- Duplicate packet count
- Error event flags

### Hardware examples

- D5 KeepTeen + nRF52840 controller board (field-deployable with weatherproofing)
- LilyGO TTGO LoRa32 (ESP32 + SX1278)
- Heltec WiFi LoRa 32 (ESP32 + SX1276 or SX1262)
- STM32WL-based boards (integrated LoRa, lowest power consumption)
- RP2040-based boards (e.g., RAK4631 + RAK5005-O)

---

## Room Server

**Firmware**: `simple_room_server`
**Base class**: `SimpleRoomServer : Mesh`
**Advert type byte**: `3` (Room)

The Room Server is a **store-and-forward message board**. Clients connect to it, post messages, and sync down messages they haven't yet seen — similar to an offline bulletin board system.

### What it stores

- Up to 32 unsynced posts per board
- Each post: author identity, timestamp, text (max 151 characters)
- `PostInfo` struct: `mesh::Identity author`, `uint32_t timestamp`, `char text[151]`

### Access control

Four permission levels via `ClientACL` (max 20 clients):

| Level | Name | Capabilities |
|-------|------|-------------|
| 0 | Guest | Read with guest password |
| 1 | Read-Only | Read without password |
| 2 | Read-Write | Read and post |
| 3 | Admin | All operations, manage users |

Default credentials: admin password `password`, guest password `hello`. **Change these immediately on deployment.**

### Login flow

Clients authenticate using `PAYLOAD_TYPE_ANON_REQ` (anonymous ECDH request). The ephemeral keypair prevents linking login requests to a known node identity. After successful login, the server issues a session context.

- `CLIENT_RESPONSE_DELAY = 300 ms` between sequential responses (rate limiting)

### Use cases

- Offline community message boards for events or emergencies
- Coordination messages that need to persist when recipients are offline
- Shared notice boards for infrastructure operators

---

## Sensor Node

**Firmware**: `simple_sensor`
**Base class**: `Mesh` (transmit-only variant)
**Advert type byte**: `4` (Sensor)

The Sensor node transmits telemetry data into the mesh. It does not forward packets and has no user interface.

### What it does

- Broadcasts ADVERT packets with GPS coordinates (via `ADV_LATLON_MASK`)
- Transmits sensor data encoded in **CayenneLPP format**
- Accepts sensor data input via the **KISS modem interface** (external sensor systems)
- Does not decode or respond to incoming messages

### GPS encoding

Latitude and longitude are encoded as `int32_t` (×1E6 scale = 6 decimal places of precision) in the ADVERT appdata field.

### CayenneLPP

CayenneLPP is a compact binary encoding for IoT sensor payloads (temperature, humidity, GPS, etc.). The sensor node uses this for standardised telemetry output that can be decoded by MQTT bridges and monitoring tools.

---

## Terminal Chat

**Firmware**: `simple_secure_chat`
**Base class**: `Mesh` with CLI interface
**Advert type byte**: `1` (Chat)

Terminal chat is a CLI-only companion. Useful for:
- Headless Linux devices (Raspberry Pi, etc.)
- Development and testing
- Command-line workflows

Limitations vs. full companion_radio:
- 100 contact limit (vs. 350/160)
- No BLE interface
- All interaction via serial terminal only

---

## KISS Modem

**Firmware**: `kiss_modem`

Not strictly a node "role" in the mesh sense, but a firmware that exposes MeshCore as a standard **KISS TNC** (Terminal Node Controller) over USB serial. Enables:

- Integration with APRS software
- AX.25 packet radio workflows
- Programmatic access from any KISS-capable application

The firmware passes LoRa packets through as KISS frames. `SetHardware` extension frames expose MeshCore-specific features (signing, encryption, radio config, telemetry) while remaining transparent to standard KISS clients that ignore them.

---

## Choosing a Role for Your Deployment

| Scenario | Recommended Role |
|----------|-----------------|
| Portable device for messaging | Companion |
| Fixed hilltop/rooftop coverage extension | Repeater |
| Community notice board / offline BBS | Room Server |
| Environmental monitoring, weather station | Sensor |
| Developer workstation integration | Terminal Chat or KISS Modem |
| Gateway to MQTT/internet | Repeater or Companion with bridge |

---

## Related Pages

- [Routing Algorithm](./routing)
- [Firmware Internals](./firmware/overview)
- [Hardware Recommendations](../hardware/recommended)
- [Community Rules & Safety](../community/rules-and-safety)
