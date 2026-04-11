---
title: recommended
description: Recommended hardware for MeshCore companion nodes and fixed installations
published: true
date: 2026-02-21T00:00:00.000Z
tags: hardware, companion, repeater
---

# Recommended Hardware

Field-tested hardware suggestions for MeshCore companions, fixed nodes, and repeaters.

This page focuses on practical picks that are common in the community and reasonably documented.

---

## Choosing the right class of device

Before selecting a model, decide what role you are solving for:

- **Companion node:** battery-powered, portable, convenience-focused
- **Fixed node:** always-on station at home or a stable site
- **Repeater/backbone node:** reliability-first deployment, often outdoors, may require solar or UPS support

A good device in the wrong role usually performs worse than a modest device deployed correctly.

---

## Companion devices (portable / personal)

### WisMesh RAKTAG / Seeed T1000-E
- **Pros:** compact, integrated battery, genuinely pocketable
- **Cons:** limited external antenna flexibility
- **Best use:** daily-carry companion with minimal setup friction

### LilyGO T-Deck
- **Pros:** standalone interaction with integrated keyboard and display
- **Cons:** bulkier; some users report variable RF sensitivity depending on unit and antenna setup
- **Best use:** bench work, field testing, and chat-heavy operation without a phone

### Wio Tracker L1 Pro
- **Pros:** compact all-in-one form factor
- **Cons:** slower text interaction due to joystick-style input
- **Best use:** low-maintenance portable node where simplicity matters more than typing speed

---

## Fixed-node / repeater options

### D5 KeepTeen + nRF52-based controller
- **Pros:** integrated path to first deployment, straightforward power integration
- **Cons:** less modular than discrete builds
- **Best use:** first fixed install when deployment speed matters

### DIY repeater builds
- **Pros:** maximum flexibility across radio, power, enclosure, and monitoring
- **Cons:** requires stronger troubleshooting and maintenance discipline
- **Best use:** long-term rooftop, hilltop, or remote infrastructure deployments

---

## Antenna guidance (915 MHz examples)

- **Gizont 17 cm whip:** practical for companions and short fixed runs
- **Ziisor 26 cm fiberglass:** common baseline for rooftop repeaters
- **Gizont 30–55 cm fiberglass:** can improve range in clear placements; validate in real terrain

Notes:
- Antenna placement and feedline quality usually matter more than adding TX power
- Use proper adapters and strain relief to reduce intermittent faults
- Measure before/after RSSI and SNR when changing antennas so improvements are real, not assumed

---

## Buying checklist

Use this list before purchasing:

- Confirm current MeshCore firmware support for the target board
- Check community reports for your region profile and frequency setup
- Match the power strategy to the role (battery, USB supply, PoE, or solar)
- Verify enclosure/mounting requirements for outdoor plans
- Prefer setups with known-good, repeatable outcomes over novelty hardware

---

## Related pages

- [Getting Started](../getting-started)
- [Build Guides](../build-guides/overview)
- [Power & Solar](../power/overview)
- [Antenna & RF Basics](../radio/overview)
