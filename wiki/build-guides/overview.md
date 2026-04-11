---
title: overview
description: Field-tested build guides and design principles for MeshCore nodes and repeaters
published: true
date: 2026-02-19T00:00:00.000Z
tags: build, hardware, repeater, deployment
---

# Build Guides

Field-tested builds and design principles for MeshCore nodes, repeaters, and fixed stations.

---

## Core design principles

Every reliable build shares the same foundations:

### Height over power

Antenna placement is the single highest-leverage improvement you can make. A well-placed antenna at 6 m beats a high-power radio at ground level every time. For repeaters, prioritise elevated rooftop or mast positions with clear horizon angles.

### Stable power

An intermittent power supply is the most common cause of repeater failure. Size your battery for at least 48–72 hours of reserve, use a quality MPPT charge controller with solar, and verify that your power bank does not auto-shutoff under low load. See [Power & Solar](../power/overview) for sizing guidance.

### Weatherproofing

For any outdoor build, assume moisture will find a way in unless you actively prevent it. Use a rated IP enclosure, weatherproof coax connectors with self-amalgamating tape, and add desiccant packs to the enclosure interior. See [Enclosures & Weatherproofing](../enclosures/overview) for specifics.

### Minimum viable complexity

Start simple. A single-board device with a good antenna and reliable power will outperform an over-engineered build that takes longer to deploy and is harder to maintain. Add features (telemetry, remote monitoring, GPS) once the fundamentals are working.

---

## Build types

### Companion / portable node

**Goal**: reliable personal carry device for messaging.

Key choices:
- Antenna: external SMA whip or upgraded stub; avoid relying on internal PCB trace antennas
- Power: integrated battery (always-on or charge-then-use pattern)

Tips:
- Mount the antenna vertically, away from your body when transmitting
- Keep the device in a consistent location (bag exterior pocket) for predictable signal
- Test range before relying on the node in the field

---

### Fixed home/site node

**Goal**: persistent always-on presence at a home or fixed site.

Key choices:
- Device: ESP32 or nrf52 based modules
- Antenna: fiberglass vertical on mast or rooftop bracket
- Power: mains-powered via USB adapter or PoE splitter

Tips:
- Mount the antenna above the roofline; even 1–2 m of mast makes a difference
- Use a short, high-quality coax run (LMR-240 for runs over 3 m)
- Consider a watchdog reset circuit or firmware auto-reboot timer for long-running nodes

---

### Rooftop or mast repeater

**Goal**: extend mesh coverage from an elevated fixed site.

Key choices:
- Device: D5 KeepTeen, prefer nrf52 for solar installs
- Antenna: 5–6 dBi fiberglass vertical at the highest practical point; avoid 9 dBi unless terrain is flat
- Power: solar + LiFePO4 for off-grid sites; mains or PoE where available
- Enclosure: IP66-rated box with UV-stable polycarbonate or ABS

Tips:
- Align the antenna plumb (vertical) — a tilted collinear degrades the radiation pattern
- Keep the coax runs as short as possible; use N-type connectors outdoors, not SMA
- Record GPS coordinates and RSSI baselines at commissioning for future reference
- Install in a way that allows the hardware to be serviced without full enclosure disassembly

---

## Testing and commissioning

Before leaving a new installation:

- Verify solar or mains power is charging correctly (check battery voltage under load)

After deployment:
- Check back in 24–48 hours to confirm sustained operation
- Review uptime and any reboot events via `status` or monitoring

---

## Related pages

- [Recommended Hardware](../hardware/recommended)
- [Power & Solar](../power/overview)
- [Enclosures & Weatherproofing](../enclosures/overview)
- [Antenna & RF Basics](../radio/overview)
- [Community Rules & Safety](../community/rules-and-safety)
