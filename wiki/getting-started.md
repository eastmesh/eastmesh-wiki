---
title: getting-started
description: Fastest reliable path to joining the shared MeshCore network
published: true
date: 2026-02-19T00:00:00.000Z
tags: getting-started, setup, onboarding
---

# Getting Started with MeshCore

This guide gives you the fastest reliable path to joining the shared MeshCore network.

---

## What you need

### Minimum
- A compatible MeshCore device (see [Recommended Hardware](./hardware/recommended))
- Correct antenna for your region and band
- Phone or computer for initial configuration
- Current supported firmware flashed to the device

### Recommended additions
- A better external antenna and elevated placement (even a windowsill above ground level helps)
- A USB power bank or always-on power supply so the node stays online when you are not actively using it

---

## Quick start workflow

1. **Flash firmware** — Download and flash the appropriate MeshCore firmware for your device and role (companion or repeater). Use the MeshCore firmware installer or PlatformIO.

2. **Set your region** — Via USB serial CLI or the companion app, confirm the correct frequency profile for your region (e.g., 916.575MHz BW:62.5 SF:7 CR:8 for Vic). All nodes on the network must use the same profile.


3. **Set or join community channels** —
Public a good starting place but other channels exist. 


5. **Run first validation tests** — Join #ping and see if the bot replys

6. **Improve placement and retest** — Move the device to a higher position or closer to a window and compare RSSI/SNR. Even small placement improvements compound over distance.

---

## First validation tests

Once the node is on air, confirm basic operation:

- Send a test message to the public channel
- Confirm the message appears on at least one other device (yours or a known peer)
- Observe RSSI and SNR for received packets — this is your baseline
- Move placement (indoors vs. outdoors, ground vs. elevated) and compare

Treat these readings as baseline data. If RSSI is below −120 dBm or SNR is consistently negative, you likely have a placement or configuration problem — check antenna connection, region settings, and channel match before assuming hardware issues.

---

## Common first-time problems

| Symptom | Check first |
|---------|------------|
| No messages received | Channel key/name mismatch; region profile mismatch |
| Range is very short | Antenna not connected, or rubber duck not suited to band |
| App won't connect via BLE | Default PIN is `123456` on devices without a display |
| Node not visible on map | GPS not enabled in ADVERT settings |
| Messages send but no ACK | No repeater within range; try elevated placement |

---

## Next steps

- Improve station quality: [Antenna & RF Basics](./radio/overview)
- Build a better fixed station: [Build Guides](./build-guides/overview)
- Understand power options: [Power & Solar](./power/overview)
- Troubleshoot common issues: [FAQ](./faq)
- Understand the protocol: [MeshCore Overview](./meshcore/overview)
