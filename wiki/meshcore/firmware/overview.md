---
title: firmware-internals
description: MeshCore firmware architecture — layers, components, MCU support, and storage
published: true
date: 2026-02-19T00:00:00.000Z
tags: meshcore, firmware, architecture, technical
---

# Firmware Internals

Internal architecture of the MeshCore firmware. Covers the layered design, major source components, supported hardware, storage, and debugging.

---

## Layered Architecture

MeshCore is structured as a clean stack of layers:

```
┌──────────────────────────────────────────────────┐
│  User Interface Layer                            │
│  Mobile app (iOS/Android), web app, CLI terminal │
└───────────────────┬──────────────────────────────┘
                    │ BLE / USB Serial / WiFi TCP / ESP-NOW
┌───────────────────▼──────────────────────────────┐
│  Application Firmware                            │
│  companion_radio | simple_repeater               │
│  room_server | sensor | kiss_modem               │
└───────────────────┬──────────────────────────────┘
                    │ Virtual callbacks (onPeerDataRecv, onAdvertRecv, etc.)
┌───────────────────▼──────────────────────────────┐
│  Mesh Networking Core                            │
│  Mesh.cpp — routing, duplicate suppression       │
│  Dispatcher.cpp — MAC layer, CAD, queuing        │
└───────────────────┬──────────────────────────────┘
                    │ Radio hardware abstraction
┌───────────────────▼──────────────────────────────┐
│  Hardware Abstraction                            │
│  RadioLib wrappers (SX1262, SX1276, LR1110, etc.)│
└───────────────────┬──────────────────────────────┘
                    │ SPI
┌───────────────────▼──────────────────────────────┐
│  Physical Radio                                  │
│  SX1262 / SX1276 / LR1110 / LLCC68 / STM32WL    │
└──────────────────────────────────────────────────┘
```

---

## Source Tree

```
src/
├── MeshCore.h              All global constants (key sizes, packet limits)
├── Packet.h / .cpp         Packet class — header, path, payload, serialization
├── Mesh.h / .cpp           Core routing — onRecvPacket, flood, direct, ACK handling
├── Dispatcher.h / .cpp     Radio MAC layer — CAD, queuing, airtime budget
├── Identity.h / .cpp       Ed25519 identity, ECDH key exchange
├── Utils.h / .cpp          AES-128-ECB, HMAC-SHA256, SHA256, hex utilities
└── helpers/
    ├── BaseChatMesh.h/.cpp         Companion radio base (sendMessage, path caching)
    ├── ContactInfo.h               Contact struct (path, keys, GPS, timestamps)
    ├── ChannelDetails.h            Channel wrapper (GroupChannel + name)
    ├── AdvertDataHelpers.h/.cpp    Advertisement builder/parser
    ├── TxtDataHelpers.h            Text message type constants
    ├── ArduinoSerialInterface.h    USB/UART serial bridge to app
    ├── BaseSerialInterface.h       Abstract interface (MAX_FRAME_SIZE=172)
    ├── CommonCLI.h/.cpp            Text CLI commands, NodePrefs struct
    ├── ClientACL.h/.cpp            Room server access control (4 permission levels)
    ├── IdentityStore.h/.cpp        Key storage abstraction across filesystems
    ├── SimpleMeshTables.h/.cpp     Duplicate suppression (64 ACK, 128 packet hashes)
    ├── StaticPoolPacketManager.h   Pre-allocated packet pool (no malloc at runtime)
    ├── TransportKeyStore.h/.cpp    16-entry transport key cache
    ├── RegionMap.h/.cpp            Region hierarchy (DENY_FLOOD/DENY_DIRECT flags)
    ├── SensorManager.h             Sensor abstraction layer
    ├── bridges/                    AbstractBridge + concrete bridge implementations
    ├── radiolib/                   RadioLib wrappers per chip (SX1262, SX1276, etc.)
    ├── esp32/                      ESP32-specific board support
    ├── nrf52/                      nRF52-specific board support
    ├── stm32/                      STM32-specific board support
    └── ui/                         Display UI helpers

examples/
├── companion_radio/        BLE/USB companion firmware (MyMesh.h/.cpp)
├── simple_repeater/        Repeater firmware
├── simple_room_server/     Room server firmware
├── simple_secure_chat/     Terminal chat firmware
├── simple_sensor/          Sensor node firmware
└── kiss_modem/             KISS TNC firmware

variants/
    67+ hardware-specific platformio.ini + target.cpp configurations
```

---

## Core Components

### Mesh.cpp — Routing Core

The heart of MeshCore. Handles all received packets via `onRecvPacket()`:
- Validates header and packet bounds
- Queries `SimpleMeshTables` for duplicates — drops seen packets
- Dispatches to handlers: `onFloodRecv()`, `onDirectRecv()`, `onAdvertRecv()`, etc.
- Implements `sendFlood()` and `sendDirect()` for outgoing messages
- Manages path caching: `onContactPathRecv()` stores returned routes
- Handles `resetPathTo()` when ACKs are not received

### Dispatcher.cpp — MAC Layer

Manages radio access between the core and physical hardware:
- Maintains a priority queue of outgoing packets
- Executes Channel Activity Detection (CAD) before transmitting
- Enforces airtime budget (33.3% duty cycle by default)
- Tracks noise floor via periodic RSSI sampling
- Watchdog timers for stuck-TX and stuck-CAD conditions
- Calculates flood retransmission delays based on SNR score

### SimpleMeshTables.cpp — Duplicate Suppression

Two cyclic ring-buffer tables:
- **ACK table**: 64 × `uint32_t` entries (ACK CRCs)
- **Packet hash table**: 128 × 8-byte entries (packet content hashes)

Both use linear scan for `hasSeen()` and wrap-around overwrite for new entries. Zero dynamic allocation.

### Identity.cpp — Cryptographic Identity

- Ed25519 keypair generation from hardware RNG seed
- `calcSharedSecret()`: converts Ed25519 keys to X25519 curve for ECDH
- Caches shared secrets in `ContactInfo.shared_secret[]` to avoid repeated computation
- Advertisement signing and verification

### Utils.cpp — Crypto Primitives

Low-level cryptographic building blocks:
- AES-128-ECB encrypt/decrypt (16-byte blocks, zero-padded)
- HMAC-SHA256 (used for MAC generation and verification)
- SHA256 (used for ACK CRC and packet hashing)
- `encryptThenMAC()`: combined AES-ECB + 2-byte HMAC
- Hex encoding/decoding utilities

---

## Application Firmware Types

### companion_radio

- Based on `BaseChatMesh : Mesh`
- **Does not forward packets** (`allowPacketForward()` = false)
- Stores up to 350 contacts (ESP32-S3) or 160 contacts (ESP32/nRF52)
- Maintains offline message queue (up to 256 messages)
- Maintains up to 40 group channels
- Exposes BLE/USB/WiFi/ESP-NOW interface to companion app
- 16-entry LRU advertisement path cache

### simple_repeater

- Based on `SimpleRepeater : Mesh`
- **Forwards eligible packets** (`allowPacketForward()` = true)
- No contact storage, no message queue
- Maintains neighbour table (up to 50 entries)
- Managed entirely via USB serial CLI or remote mesh CLI commands
- Configurable flood_max hop limit, power save mode, airtime factor

### simple_room_server

- Based on `SimpleRoomServer : Mesh`
- Store-and-forward message board
- Up to 32 unsynced posts per board, max 151 characters each
- 4-level role-based access control (Guest / Read-only / Read-write / Admin)
- Client login via anonymous ECDH (prevents identity linkage)
- 300 ms delay between sequential client responses

### simple_sensor

- Transmits telemetry only; does not forward
- Reports GPS position via `ADV_LATLON_MASK` in advertisements
- Sensor data encoded in CayenneLPP format
- KISS modem interface for external sensor data ingestion

### kiss_modem

- Standard KISS TNC interface over serial (115200 baud 8N1)
- Enables integration with APRS software and other AX.25 tools
- Maximum unescaped frame: 512 bytes; data payload: 255 bytes
- `SetHardware` extensions expose MeshCore-specific features:
  - Ed25519 signing (start/data/finish flow)
  - AES-128-CBC encryption
  - SHA-256 hashing
  - Radio configuration
  - Telemetry (RSSI, SNR, airtime, noise floor)

---

## Supported MCUs

| MCU | Flash | RAM | Max Contacts | Primary Use |
|-----|-------|-----|--------------|-------------|
| ESP32-S3 | 16 MB | 512 KB | 350 | Companion, repeater |
| ESP32 | 4 MB | 520 KB | 160 | Companion, repeater |
| nRF52840 | 1 MB | 256 KB | 160 | Companion (BLE-native) |
| RP2040 | 2 MB | 264 KB | N/A | Repeater, sensor |
| STM32WL | 256 KB | 64 KB | N/A | Repeater (integrated LoRa) |

Memory footprint (ESP32): approximately 200–300 KB flash, 40–60 KB RAM.

**No dynamic allocation at runtime**: all buffers are compile-time fixed via `StaticPoolPacketManager` and fixed-size arrays. No `malloc()` calls during operation.

---

## Persistent Storage

Key and configuration files are stored on the device filesystem:

| Platform | Filesystem | Key Files |
|----------|-----------|-----------|
| ESP32 | SPIFFS | `/_main.id`, `/new_prefs`, `/contacts3`, `/channels2` |
| nRF52 | InternalFS | Same naming |
| RP2040 | LittleFS | Same naming |
| STM32 | InternalFS | Same naming |

**`/_main.id`**: 64-byte Ed25519 private key + 32-byte public key.

**`/new_prefs`**: NodePrefs struct (radio frequency, BW, SF, CR, TX power, flood_max, etc.)

**`/contacts3`**: Serialized contact database (keys, cached paths, timestamps, names).

**`/channels2`**: Group channel definitions (hash + secret + name).

**Lazy write**: Contact changes are batched by a 5-second dirty timer to minimize flash wear cycles.

The `IdentityStore` class provides an abstraction layer so the same code path works across all filesystem types.

---

## NodePrefs — Configuration Structure

The `NodePrefs` struct contains all persistent node configuration:

| Field | Type | Description |
|-------|------|-------------|
| `freq` | `float` | Radio frequency in MHz |
| `bw` | `float` | LoRa bandwidth in kHz |
| `sf` | `uint8_t` | Spreading factor (7–12) |
| `cr` | `uint8_t` | Coding rate (5–8 = 4/5 to 4/8) |
| `tx_power_dbm` | `int8_t` | Transmit power in dBm |
| `flood_max` | `uint8_t` | Maximum hops for flood forwarding (0–64) |
| `disable_fwd` | `bool` | Disable all packet forwarding |
| `powersaving_enabled` | `bool` | Enable sleep mode between transmissions |
| `agc_reset_interval` | `uint8_t` | AGC reset interval (stored as seconds/4) |
| `bridge_*` | various | Bridge configuration (type, delay, secret) |
| `advert_loc_policy` | `uint8_t` | GPS in adverts: none / current / stored |

Configure via CLI: `set radio <freq> <bw> <sf> <cr>`, `set flood.max <n>`, etc.

---

## Bridge Architecture

`AbstractBridge` allows MeshCore to interconnect with external networks:

| Bridge Type | Description |
|-------------|-------------|
| MQTT | Forward mesh messages to/from an MQTT broker (meshcore-mqtt project) |
| Serial | Raw serial bridge for integration with other systems |
| ESP-NOW | Wi-Fi inter-mesh links between ESP32 nodes without infrastructure |

Bridge configuration in NodePrefs includes: type/enable, 500 ms default delay, source selection, baud rate, ESP-NOW channel number, and a 16-byte bridge secret.

---

## Debugging

### Serial Console

All firmware variants expose a serial CLI at 115200 baud 8N1. Connect via USB and use any terminal emulator.

Useful commands:
```
status          — show node identity, uptime, battery
stats           — packet counts, airtime, error flags
contacts        — list known contacts
mesh            — show neighbour table (repeater only)
set             — configure parameters (use 'set ?' for help)
reboot          — restart firmware
```

### Stats and Error Flags

`RepeaterStats` tracks:
- Battery voltage
- Queue length
- Noise floor (dBm)
- Last RSSI/SNR
- Flood/direct send and receive counts
- TX/RX airtime (ms)
- Uptime (seconds)
- Duplicate packet count
- Error event flags

The `err_flags` byte in stats frames encodes fault conditions (stuck radio, CAD timeout, queue overflow, etc.).

### Common Issues

| Symptom | Likely Cause |
|---------|-------------|
| No packets received | Frequency or BW mismatch with network |
| High duplicate count | Overlapping repeater coverage, flood_max too high |
| ACK timeouts, path resets | Marginal links, node moved, topology changed |
| CAD timeout errors | RF interference, radio chip lockup (fixed by reboot or AGC reset) |
| Queue overflow | Burst traffic exceeding airtime budget |
| High noise floor | Near interference source (WiFi, other LoRa deployments) |

### SNR Interpretation

SNR is stored as `int8_t` in quarter-dB units throughout the firmware. Always divide by 4.0 to get dBm float.

Minimum decodable SNR per spreading factor:

| SF | Min SNR |
|----|---------|
| SF7 | −7.5 dB |
| SF8 | −10.0 dB |
| SF9 | −12.5 dB |
| SF10 | −15.0 dB |
| SF11 | −17.5 dB |
| SF12 | −20.0 dB |

---

## Related Pages

- [Packet Structure](../packet-structure)
- [Routing Algorithm](../routing)
- [Encryption & Authentication](../encryption)
- [Node Roles](../node-roles)
- [Radio Layer](../radio-layer)
- [Companion Protocol](../companion-protocol)
