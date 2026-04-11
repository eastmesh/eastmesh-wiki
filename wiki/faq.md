---
title: faq
description: Common questions about MeshCore deployments, operations, and troubleshooting
published: true
date: 2026-02-19T00:00:00.000Z
tags: faq, troubleshooting, getting-started
---

# FAQ

Common questions about MeshCore deployments, operations, and troubleshooting.

---

## Setup and configuration

### What frequencies are used?

Use only frequencies and duty-cycle/power settings allowed in your region. For Australia and New Zealand, the community uses the 915 MHz ISM band. For EU deployments, 868 MHz is standard.

For most local deployments, use the shared community frequency profile so all nodes remain interoperable. If you are unsure what settings to use, ask on the forum or IRC before transmitting — a misconfigured node that cannot decode any traffic is not useful to anyone.

### What hardware should I buy first?

Start with one well-supported companion device and a known-good external antenna. Avoid relying on the tiny built-in antennas on most modules.
See: [Recommended Hardware](./hardware/recommended)

### What app do I need?

The MeshCore companion app (iOS and Android) is the primary interface for companion radio devices. For repeaters and terminal nodes, all configuration is done via USB serial CLI at 115200 baud.

### How do I set my node name?

Via the companion app: Settings → Node name.
Via CLI: `set name <your_name>`

### How do I join the community channel?

Contact the community via the forum at **https://forum.eastmesh.au** or IRC at **https://irc.eastmesh.au** to get the current community channel credentials. Channels are defined by a name and a 32-byte shared secret; both must match exactly on all nodes.

---

## Troubleshooting

### Why can't I hear anyone?

Most failures are basic setup mismatches. Check these in order:

1. **Channel name and key must match exactly** — a single character difference means no messages are decryptable
2. **Region/frequency profile must match** — a 1 MHz offset or different bandwidth will prevent all packet decoding
3. **Spreading factor must match** — SF9 and SF7 are incompatible
4. **Firmware version must be compatible** — very old firmware may not decode packets from current versions
5. **Antenna must be connected** — a disconnected antenna does not prevent transmission, but it cripples receive sensitivity
6. **Placement matters** — indoors on a ground floor is the worst possible position; try outdoors or elevated

### Why is range poor even when messages work nearby?

Range is mainly an RF and placement problem, not a transmit power problem:
- **Antenna quality and mounting height** — 3 dBi at 10 m height beats 9 dBi at ground level
- **Feedline quality and connector integrity** — 10 m of RG-58 costs 3–4 dB; a corroded SMA can cost more
- **Obstruction and local RF noise** — buildings and trees absorb signal; check the noise floor via `stats`
- **Repeater placement** — a well-placed elevated repeater provides more benefit than anything else in the network

See: [Antenna & RF Basics](./radio/overview)

### The app connects via BLE but shows no contacts or messages

1. Confirm the node has been on air long enough to receive advertisements from other nodes
2. Check that the channel key is correctly configured — without the matching key, messages cannot be decrypted
3. Confirm the device time is correct: `CMD_SET_DEVICE_TIME` sync on app connect; old timestamps can affect message processing

### My node sends messages but never receives an ACK

Possible causes:
- No repeater within range — try improving placement or confirming a repeater is active in your area
- The destination node is offline or out of range
- TX power is too high and causing front-end overload on nearby nodes (unlikely unless nodes are very close together)
- Check the network map at **https://map.eastmesh.au** for nearby repeater coverage

### BLE won't connect / wrong PIN

Default BLE PIN is `123456`. On devices with a display, the PIN is randomised per session and shown on screen. If you cannot connect, try a factory reset: `CMD_FACTORY_RESET` (warning: this erases all keys, contacts, and channels).

---

## Operations and maintenance

### What metrics should I watch?

At minimum, track:
- **RSSI** — received power level; use trends rather than single readings
- **SNR** — signal quality against noise floor; negative SNR means the signal is below the noise
- **Noise floor** — baseline RF noise at the site; elevations indicate new interference
- **Uptime** — frequent reboots indicate power or firmware issues

Use trends over several days rather than one-time readings. A sudden change in RSSI or SNR is more diagnostic than an absolute value.

### How often should I update firmware?

Update when a release contains:
- Security fixes
- Interoperability fixes for the current network
- Measured stability improvements for your hardware

Avoid updating critical infrastructure nodes during peak usage hours. Ensure you can roll back (keep a copy of the previous firmware binary) before updating.

Do not update firmware on all nodes simultaneously — stagger updates so you can confirm the new version is working before updating the rest.

### How do I report an issue effectively?

Include in your report:
- Device model and firmware version
- Region/frequency profile used
- Channel configuration summary (never include the private channel secret)
- Antenna type and mounting context
- Logs or screenshots showing the observed behaviour
- What you have already tried

Well-structured reports with this information get resolved much faster than "it doesn't work."

### My node keeps rebooting

Check in this order:
1. Battery voltage under load — a weak battery can dip below MCU minimum voltage during transmit
2. `err_flags` value from `stats` — specific bits indicate the failure type (stuck radio, CAD timeout, queue overflow)
3. Recent firmware update — test the previous version if reboots started after an update
4. Brownout on mains power — a quality USB power adapter matters; cheap ones cause noise and undervoltage events

---

## Protocol questions

### What is the difference between a Companion and a Repeater?

- **Companion**: endpoint device for sending/receiving messages. Does not forward packets from other nodes. Connects to the mobile app via BLE.
- **Repeater**: infrastructure node that forwards packets and extends coverage. No app interface — managed via USB serial CLI.

See: [Node Roles](./meshcore/node-roles)

### Are messages encrypted?

Yes. Peer-to-peer messages use ECDH-derived shared secrets with AES-128-ECB + HMAC-SHA256. Channel messages use a channel-specific shared secret with the same encryption. See: [Encryption & Authentication](./meshcore/encryption)

### Does MeshCore use LoRaWAN?

No. MeshCore uses LoRa radio modulation but does not use the LoRaWAN protocol, network servers, or gateways. MeshCore nodes communicate directly with each other without any internet or cloud infrastructure.

### What is the maximum range?

Range depends heavily on antenna placement, terrain, and spreading factor. Under good conditions (elevated antennas, SF9, flat terrain):
- Node-to-node direct: 5–30 km
- With intermediate repeaters: effectively unlimited across a network

Range claims without specifying these conditions are not useful. See: [Antenna & RF Basics](./radio/overview)
