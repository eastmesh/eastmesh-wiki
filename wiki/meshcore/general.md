MeshCore: How It Works
What Is MeshCore?
MeshCore is a lightweight, open-source C++ library and protocol designed for multi-hop packet routing over LoRa radios and other packet radio hardware. It creates decentralized, off-grid mesh networks — no internet, no cell towers, no central server required. It's broadly comparable to Meshtastic and Reticulum but occupies a middle ground: more sophisticated routing than Meshtastic, simpler and more embedded-friendly than Reticulum.
Protocol Architecture (4 Layers)
MeshCore loosely mirrors the OSI model:
1. Physical Layer — LoRa (Long Range) radio modulation. Operates on 433 MHz, 868 MHz (EU/UK), or 915 MHz (US/AU/NZ). Configurable spreading factor (SF7–SF12), bandwidth, and TX power. Higher spreading factors mean more range but slower throughput (~250 bps at SF12, ~5–10 kbps at SF7).
2. Link Layer — Uses CSMA/CA (Carrier Sense Multiple Access with Collision Avoidance): nodes listen before transmitting, and apply a random backoff on collision. ACK/NACK and retry logic live here too.
3. Network Layer — The mesh routing logic. This is where MeshCore gets interesting (more below).
4. Application Layer — Message types: TEXT, POSITION, TELEMETRY, ACK. Payload is encrypted with AES-256.
Packet Structure
Each packet is structured as:
[HEADER 8 bytes] [PAYLOAD up to 237 bytes] [CHECKSUM 2 bytes CRC16]

HEADER:
  - Packet ID (4 bytes)
  - Source Address (2 bytes)
  - Destination Address (2 bytes)
  - Hop Count (1 byte)
  - Flags (1 byte)

PAYLOAD:
  - Message Type (1 byte)
  - Encrypted Data (up to 236 bytes)
Nodes are identified by 16-bit mesh addresses (not IP). Overhead is only ~4% of the 247-byte max packet size — very efficient for LoRa.
Routing: The Key Differentiator
This is where MeshCore stands apart from Meshtastic. It uses a hybrid routing model:
Flood routing (fallback): When no known path exists, a message is broadcast to all in-range nodes. Each node checks if it's the destination; if not, it rebroadcasts (incrementing the hop count). This continues until the message arrives or the hop limit is hit. Typically 3–7 hops maximum, though the firmware supports up to 64. Duplicate detection prevents looping.
Path-based routing (preferred): After a node discovers a path to a destination (e.g., via a repeater advert or prior exchange), it can send directly along that path rather than flooding. This is a major efficiency gain over Meshtastic's flood-only approach — far less channel congestion.
Repeaters as dedicated routers: Unlike Meshtastic where all nodes relay everything, MeshCore has distinct repeater nodes that intelligently forward packets rather than blindly rebroadcasting. They don't forward every packet they hear — only what needs forwarding. They advertise themselves every 240 minutes (configurable) so client nodes can discover paths through them.
Node Discovery & Adverts
When a node wants to announce itself, it sends an Advert — a broadcast containing its name, GPS position, and public encryption key (signed to prevent spoofing). Adverts come in two flavors:
Zero-hop: Broadcast to immediate neighbors only.
Flooded: Broadcast + relayed by repeaters throughout the network.
Clients only advertise when the user manually triggers it. This is intentional — it keeps channel usage low. Repeaters auto-advertise periodically.
Security
All communications use AES-256 encryption at the application layer. Public/private keypairs are used for identity, and adverts are signed so you can't spoof another node's identity. The encryption keys are exchanged via the advert mechanism.
Node Roles
Role
Description
Client
User-facing device (phone via BLE, T-Deck, web client)
Repeater
Extends range by intelligently forwarding packets
Room Server
BBS-style shared message board; stores last 16 unread messages for latecomers
A Room Server can also double as a repeater.
How It Compares
Feature
MeshCore
Meshtastic
Reticulum
Routing
Hybrid (flood + path-based)
Flood-first
Advanced link-state
Target
Embedded/custom
Casual LoRa users
General networking
Complexity
Medium
Low
High
Encryption
AES-256 + signed keys
AES-256
Elliptic curve
Smart repeaters
Yes
No (all nodes relay)
Yes
Hardware Support
MeshCore runs on a wide range of LoRa boards: Heltec V3 LoRa32, RAK Wireless modules, Lilygo T-Deck, T-1000E, and others. Firmware can be flashed via a web flasher without compiling code. Clients connect over BLE, USB, or WiFi depending on the firmware variant.