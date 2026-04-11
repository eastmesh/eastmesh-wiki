---
title: terminology
description: Core terms and definitions used throughout the MeshCore wiki
published: true
date: 2026-02-19T00:00:00.000Z
tags: reference, terminology, glossary
---

# Terminology

Core terms and definitions used throughout this wiki. Use terms consistently when reporting issues or discussing deployments — it reduces ambiguity and speeds up troubleshooting.

---

## MeshCore protocol terms

- **Node:** any device participating in the mesh, regardless of role
- **Companion node:** personal portable node that sends and receives messages; does not forward traffic from other nodes; connects to the mobile app via BLE or USB
- **Fixed node:** stationary companion node deployed at home or a fixed site for persistent local coverage
- **Repeater / relay:** node configured to forward packets, extending network reach; infrastructure backbone of any deployment; no app interface, managed via CLI
- **Room Server:** store-and-forward message board node; holds messages for offline recipients; login-based access control
- **Sensor node:** transmit-only node that broadcasts telemetry (GPS, environmental data) in CayenneLPP format; no user interface
- **Terminal Chat:** CLI-only companion node; useful for headless Linux devices and development
- **KISS Modem:** firmware that exposes a MeshCore radio as a standard KISS TNC interface for APRS and AX.25 integration
- **Channel:** a group communication namespace defined by a 32-byte shared secret; not related to radio frequency; all nodes sharing the secret can decrypt group messages on that channel
- **Contact:** a known node stored locally with its public key, cached routing path, and derived shared secret
- **Advertisement (ADVERT):** a signed broadcast packet that announces a node's identity, type, name, and optionally GPS coordinates; used for discovery and routing

---

## Routing terms

- **Flood (ROUTE_TYPE_FLOOD):** routing mode where a packet propagates to all nodes; used for initial discovery
- **Direct (ROUTE_TYPE_DIRECT):** routing mode using a cached explicit path; used for subsequent messages to a known contact
- **Path:** ordered sequence of 1-byte node IDs that describes the hops between sender and destination
- **Path caching:** storing the returned path from a flood discovery for reuse in direct routing
- **Hop limit (flood_max):** configurable maximum number of hops a flood packet may traverse before being dropped
- **Duplicate suppression:** mechanism that prevents the same packet from being forwarded more than once by any node
- **ACK (acknowledgement):** a 4-byte CRC response confirming receipt of a message
- **TRACE:** diagnostic packet that collects per-hop SNR data as it traverses the mesh

---

## RF terms

- **RSSI:** received signal strength indicator — the power level of the received signal in dBm; more negative = weaker signal
- **SNR:** signal-to-noise ratio — the signal level relative to the background noise floor in dB; negative SNR means the signal is below the noise floor but may still be decodable due to LoRa processing gain
- **Noise floor:** baseline RF power level at a receiver in the absence of a signal; elevated noise floor reduces effective range
- **LoS (Line of Sight):** unobstructed optical path between two points; near-LoS is sufficient for LoRa links
- **Fresnel zone:** elliptical volume around the straight-line path between two antennas; partial obstruction of this zone causes diffraction loss
- **EIRP:** effective isotropic radiated power — the transmitted power accounting for antenna gain and cable loss, referenced to an isotropic radiator
- **ERP:** effective radiated power — similar to EIRP but referenced to a dipole (3 dB less than EIRP)
- **SWR (standing wave ratio):** ratio measuring antenna/feedline impedance match; high SWR (>2:1) indicates significant reflected power and potential efficiency loss
- **Spreading Factor (SF):** LoRa parameter controlling the number of chirp symbols per bit; higher SF = longer range, longer airtime, more power
- **Bandwidth (BW):** LoRa channel width in kHz; narrower bandwidth improves sensitivity but reduces data rate
- **Coding Rate (CR):** LoRa forward error correction ratio (4/5 to 4/8); higher coding rate improves error resilience at the cost of data rate
- **CAD (Channel Activity Detection):** LoRa feature that checks for on-air activity before transmitting, reducing collisions
- **Duty cycle:** proportion of time a transmitter is allowed to transmit; regulated in some regions (e.g., EU 1–10% for certain sub-bands)

---

## Cryptography terms

- **Ed25519:** elliptic curve signature algorithm used for node identity keypairs and advertisement signing
- **ECDH / X25519:** elliptic curve Diffie-Hellman key exchange used to derive a shared secret between two nodes from their public keys
- **AES-128-ECB:** symmetric encryption algorithm used for message confidentiality; ECB mode means no IV/nonce
- **HMAC-SHA256:** hash-based message authentication code providing message integrity and authenticity
- **Shared secret:** 32-byte value derived from ECDH between two nodes; used as the encryption and MAC key for their private messages
- **Channel secret:** 32-byte shared key material used for group channel encryption and authentication
- **MAC (message authentication code):** 2-byte truncated HMAC tag appended to encrypted messages to verify integrity

---

## Operations terms

- **Uptime:** proportion of time a node is available and functioning; tracks reliability over time
- **Last-seen:** timestamp of the most recent advertisement or message received from a node; primary availability indicator
- **Change window:** planned period when configuration or firmware modifications are made to infrastructure nodes
- **Rollback:** process of returning a node to a previous known-good firmware version or configuration after a failed change
- **Baseline config:** the set of region, frequency, bandwidth, spreading factor, and coding rate settings that all community nodes share for interoperability
- **Commissioning:** the process of deploying, configuring, and validating a new node before handing it over to normal operation
- **Decommissioning:** controlled removal of a node from service, including removal from monitoring and the network map
- **Err flags:** bitmask in node statistics indicating fault conditions (stuck radio, CAD timeout, queue overflow, etc.)

---

## Related pages

- [MeshCore Overview](../meshcore/overview)
- [Node Roles](../meshcore/node-roles)
- [Radio Layer](../meshcore/radio-layer)
- [Encryption & Authentication](../meshcore/encryption)
