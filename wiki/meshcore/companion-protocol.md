---
title: companion-protocol
description: MeshCore companion radio protocol — BLE/USB/TCP communication between app and device
published: true
date: 2026-02-19T00:00:00.000Z
tags: meshcore, protocol, ble, serial, technical
---

# Companion Radio Protocol

The companion radio protocol defines how the mobile/desktop app communicates with a companion radio device over BLE, USB serial, or WiFi TCP.

---

## Transport Options

| Transport | Details | Use Case |
|-----------|---------|----------|
| BLE (Nordic UART Service) | GATT-based, wireless | Primary mobile interface |
| USB Serial | 115200 baud 8N1, framed | Desktop/development |
| WiFi TCP | Port 4000, TCP server on device | Local network access |
| ESP-NOW | Wi-Fi protocol, no infrastructure | ESP32-to-ESP32 bridging |

---

## BLE Service (NUS — Nordic UART Service)

The device acts as a GATT server exposing the Nordic UART Service:

| Item | UUID |
|------|------|
| Service | `6E400001-B5A3-F393-E0A9-E50E24DCCA9E` |
| RX Characteristic (App → Device) | `6E400002-B5A3-F393-E0A9-E50E24DCCA9E` |
| TX Characteristic (Device → App) | `6E400003-B5A3-F393-E0A9-E50E24DCCA9E` |

- **RX**: App writes frames to this characteristic (Write with Response mode)
- **TX**: Device sends notifications on this characteristic (app subscribes)

BLE device name format: `MeshCore-` + node identity hash.
Default PIN: `123456` (randomised per-session on devices with a display).

---

## Frame Format

### USB Serial Framing

Frames exchanged over USB serial use length-prefixed delimiters:

| Direction | Start Byte | Length | Frame Data |
|-----------|-----------|--------|-----------|
| Device → App | `0x3E` (`>`) | 2-byte little-endian | Variable |
| App → Device | `0x3C` (`<`) | 2-byte little-endian | Variable |

`MAX_FRAME_SIZE = 172` bytes.

### BLE Framing

Over BLE, each characteristic write/notification is one complete frame. The BLE link layer handles integrity — no additional framing bytes are needed.

---

## Protocol Design

The device is the **server**; the app is the **client**.

Key rules:
- Communication is synchronous command/response
- **Send one command, wait for its response before sending the next**
- Use BLE **Write with Response** mode (not Write without Response)
- **Push notifications** (unsolicited messages) can arrive at any time, interleaved with pending command responses
- All multi-byte integers are **little-endian**

---

## Connection Sequence

On connecting to a device, the app should:

1. Subscribe to TX characteristic notifications (BLE) or open serial port
2. Send `CMD_DEVICE_QUERY (22)` → receive firmware version and protocol version
3. Send `CMD_APP_START (1)` → receive node identity, capabilities, and configuration
4. Optionally set device time: `CMD_SET_DEVICE_TIME (6)`
5. Begin normal operation

---

## Command Codes

### Core Commands

| Code | Name | Description |
|------|------|-------------|
| 1 | `CMD_APP_START` | Retrieve node identity, capabilities, and configuration |
| 5 | `CMD_GET_DEVICE_TIME` | Get current device clock (Unix epoch) |
| 6 | `CMD_SET_DEVICE_TIME` | Synchronise device clock from app |
| 19 | `CMD_REBOOT` | Restart the firmware |
| 20 | `CMD_GET_BATT_AND_STORAGE` | Battery voltage and storage statistics |
| 22 | `CMD_DEVICE_QUERY` | Firmware and protocol version negotiation |
| 23 | `CMD_EXPORT_PRIVATE_KEY` | Export node private key (backup) |
| 24 | `CMD_IMPORT_PRIVATE_KEY` | Import a private key (restore) |
| 37 | `CMD_SET_DEVICE_PIN` | Set BLE pairing PIN |
| 51 | `CMD_FACTORY_RESET` | Wipe all keys, contacts, and configuration |

Note: `CMD_DEVICE_QUERY` is spelled `CMD_DEVICE_QEURY` in the source — a typo preserved for backward compatibility.

### Messaging Commands

| Code | Name | Description |
|------|------|-------------|
| 2 | `CMD_SEND_TXT_MSG` | Send encrypted peer-to-peer text message |
| 3 | `CMD_SEND_CHANNEL_TXT_MSG` | Send encrypted group channel message |
| 7 | `CMD_SEND_SELF_ADVERT` | Broadcast own ADVERT immediately |
| 8 | `CMD_SET_ADVERT_NAME` | Set the node's display name |
| 10 | `CMD_SYNC_NEXT_MESSAGE` | Retrieve next queued message from offline buffer |
| 25 | `CMD_SEND_RAW_DATA` | Send raw binary data |
| 36 | `CMD_SEND_TRACE_PATH` | Send a TRACE packet (diagnostic path quality) |
| 39 | `CMD_SEND_TELEMETRY_REQ` | Request telemetry from a remote node |
| 50 | `CMD_SEND_BINARY_REQ` | Send binary request |
| 52 | `CMD_SEND_PATH_DISCOVERY_REQ` | Trigger explicit path discovery |
| 55 | `CMD_SEND_CONTROL_DATA` | Send CONTROL packet |
| 57 | `CMD_SEND_ANON_REQ` | Send anonymous (ephemeral ECDH) request |

### Contact Management

| Code | Name | Description |
|------|------|-------------|
| 4 | `CMD_GET_CONTACTS` | Retrieve all stored contacts |
| 9 | `CMD_ADD_UPDATE_CONTACT` | Add or update a contact entry |
| 13 | `CMD_RESET_PATH` | Clear cached path to a contact (force re-flood) |
| 14 | `CMD_SET_ADVERT_LATLON` | Set GPS coordinates for own advertisement |
| 15 | `CMD_REMOVE_CONTACT` | Delete a contact |
| 16 | `CMD_SHARE_CONTACT` | Share a contact's public key |
| 17 | `CMD_EXPORT_CONTACT` | Export contact data |
| 18 | `CMD_IMPORT_CONTACT` | Import a contact from exported data |
| 28 | `CMD_HAS_CONNECTION` | Check if a contact is reachable |
| 30 | `CMD_GET_CONTACT_BY_KEY` | Retrieve contact by public key |
| 42 | `CMD_GET_ADVERT_PATH` | Get cached advertisement path to a contact |

### Channel Management

| Code | Name | Description |
|------|------|-------------|
| 31 | `CMD_GET_CHANNEL` | Retrieve a channel definition |
| 32 | `CMD_SET_CHANNEL` | Create or update a channel |
| 54 | `CMD_SET_FLOOD_SCOPE` | Set channel flood scope |

### Radio Configuration

| Code | Name | Description |
|------|------|-------------|
| 11 | `CMD_SET_RADIO_PARAMS` | Set frequency, BW, SF, CR |
| 12 | `CMD_SET_RADIO_TX_POWER` | Set transmit power in dBm |
| 21 | `CMD_SET_TUNING_PARAMS` | Set advanced timing/tuning parameters |
| 38 | `CMD_SET_OTHER_PARAMS` | Set miscellaneous node parameters |
| 43 | `CMD_GET_TUNING_PARAMS` | Read current tuning parameters |
| 60 | `CMD_GET_ALLOWED_REPEAT_FREQ` | Read repeater frequency permissions |

### Room Server Commands

| Code | Name | Description |
|------|------|-------------|
| 26 | `CMD_SEND_LOGIN` | Authenticate to a room server |
| 27 | `CMD_SEND_STATUS_REQ` | Request status from a room server |
| 29 | `CMD_LOGOUT` | Log out from a room server session |

### Signing and Crypto

| Code | Name | Description |
|------|------|-------------|
| 33 | `CMD_SIGN_START` | Begin signing sequence |
| 34 | `CMD_SIGN_DATA` | Feed data to signer |
| 35 | `CMD_SIGN_FINISH` | Complete signature, retrieve result |

### Stats and Diagnostics

| Code | Name | Description |
|------|------|-------------|
| 56 | `CMD_GET_STATS` | Retrieve core, radio, or packet statistics |

Stats type sub-codes: `0` = core, `1` = radio, `2` = packets.

### Custom Variables

| Code | Name | Description |
|------|------|-------------|
| 40 | `CMD_GET_CUSTOM_VARS` | Get custom variable store |
| 41 | `CMD_SET_CUSTOM_VAR` | Set a custom variable |

### Auto-add Configuration

| Code | Name | Description |
|------|------|-------------|
| 58 | `CMD_SET_AUTOADD_CONFIG` | Configure automatic contact addition policy |
| 59 | `CMD_GET_AUTOADD_CONFIG` | Read auto-add configuration |

---

## Response Codes

### Synchronous Responses (replies to commands)

| Code | Name | Description |
|------|------|-------------|
| 0 | `RESP_CODE_OK` | Command succeeded, no data |
| 1 | `RESP_CODE_ERR` | Command failed |
| 5 | `RESP_CODE_SELF_INFO` | Device identity and capabilities (reply to CMD_APP_START) |
| 6 | `RESP_CODE_SENT` | Message was transmitted on-air |
| 7 | `RESP_CODE_CONTACT_MSG_RECV` | Incoming message (legacy, v1/v2 protocol) |
| 8 | `RESP_CODE_CHANNEL_MSG_RECV` | Incoming channel message (legacy) |
| 16 | `RESP_CODE_CONTACT_MSG_RECV_V3` | Incoming message with SNR/RSSI metadata (v3+) |
| 17 | `RESP_CODE_CHANNEL_MSG_RECV_V3` | Incoming channel message with SNR/RSSI (v3+) |
| 24 | `RESP_CODE_STATS` | Statistics frame (v8+ protocol) |

### Push Codes (Unsolicited Notifications)

| Code | Name | Description |
|------|------|-------------|
| `0x80` | `PUSH_CODE_ADVERT` | A new node advertisement was received |
| `0x83` | `PUSH_CODE_MSG_WAITING` | One or more messages are waiting in queue |
| `0x85` | `PUSH_CODE_LOGIN_SUCCESS` | Room server login was accepted |
| `0x8E` | `PUSH_CODE_CONTROL_DATA` | Control message received (v8+) |
| `0x90` | `PUSH_CODE_CONTACTS_FULL` | Contact storage is full — warning |

Push codes have the high bit set (`>= 0x80`), distinguishing them from synchronous response codes.

---

## Stats Binary Frame Format

Stats are retrieved via `CMD_GET_STATS (56)`. Send: `[0x38][type_byte]`.

### Core Stats (type 0) — 11 bytes

```
[0x18][0x00]
battery_millivolts  uint16  little-endian
uptime_secs         uint32  little-endian
err_flags           uint8   error bitmask
queue_len           uint8   transmit queue depth
```

### Radio Stats (type 1) — 14 bytes

```
[0x18][0x01]
noise_floor   int8    quarter-dB units (divide by 4)
last_rssi     int8    last received RSSI
last_snr      int8    last received SNR (divide by 4)
tx_airtime_ms uint32  total TX airtime in ms
rx_airtime_ms uint32  total RX airtime in ms
```

### Packet Stats (type 2) — 26 bytes (or 30 with extended)

```
[0x18][0x02]
total_sent    uint32
flood_sent    uint32
direct_sent   uint32
total_recv    uint32
flood_recv    uint32
direct_recv   uint32
[extended only:]
rx_errors     uint16
crc_errors    uint16
```

All SNR/RSSI values in stats frames are in quarter-dB units — divide by 4.0 for dBm.

---

## QR Code Format

Contacts and channels can be shared via QR code encoding a URI:

### Contact QR

```
meshcore://contact?pubkey=<64-char-hex-pubkey>&name=<url-encoded-name>
```

### Channel QR

```
meshcore://?name=<url-encoded-name>&secret=<64-char-hex-secret>
```

The `secret` field is the 32-byte channel secret encoded as a 64-character hex string. Scan with the MeshCore app to add the contact or join the channel directly.

---

## Protocol Version Notes

The protocol has evolved across multiple versions:

| Version | Key Changes |
|---------|-------------|
| v1/v2 | Basic messaging, `RESP_CODE_CONTACT_MSG_RECV` (7) and channel (8) |
| v3+ | Added SNR/RSSI to message receipts (`_V3` response codes 16/17) |
| v8+ | Added `RESP_CODE_STATS` (24), `PUSH_CODE_CONTROL_DATA` (0x8E) |

Always send `CMD_DEVICE_QUERY` first to negotiate and adapt to the device's supported version.

---

## Related Pages

- [Node Roles](./node-roles)
- [Channels & Keys](./channels-and-keys)
- [Encryption & Authentication](./encryption)
- [Firmware Internals](./firmware/overview)
