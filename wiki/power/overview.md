---
title: overview
description: Power budgets, battery sizing, and solar charging guidance for MeshCore nodes
published: true
date: 2026-02-19T00:00:00.000Z
tags: power, solar, battery, mppt
---

# Power & Solar

Guidance for keeping nodes online reliably.

---

## Typical node power draw

Understanding actual current draw is the foundation of any power design. Two MCU platforms are common in MeshCore hardware, and they differ dramatically in power consumption:

- **ESP32-based** (T-Beam, Heltec LoRa 32, station-style builds) — higher performance, higher idle draw
- **nRF52840-based** (RAK WisBlock) — ARM Cortex-M4 with aggressive sleep modes, far lower idle and sleep current

### ESP32 vs nRF52 comparison

| State | ESP32 (T-Beam / Heltec) | nRF52840 (RAK WisBlock) |
|---|---|---|
| Deep sleep (MCU + radio off) | 1–10 mA | 0.002–0.015 mA (2–15 µA) |
| Idle / waiting to receive | 30–80 mA | 3–8 mA |
| LoRa receive active | +10–20 mA above idle | +10–15 mA above idle |
| LoRa transmit at +17 dBm | +90–110 mA above idle | +90–110 mA above idle |
| LoRa transmit at +20 dBm (100 mW) | +120–150 mA above idle | +120–150 mA above idle |
| GPS active | +20–30 mA (T-Beam only) | +20–30 mA (optional module) |
| **Practical average (relay, GPS off)** | **40–60 mA @ 3.3–3.7 V (150–220 mW)** | **4–10 mA @ 3.3 V (13–33 mW)** |

> **Why the deep-sleep gap is so large:** The ESP32's built-in voltage regulators and Wi-Fi/BT silicon draw milliamps even when the application core is off. The nRF52840 was designed for coin-cell IoT applications; its entire chip can idle in the low-µA range with RAM retained.

> **Transmit parity:** Both platforms use the same LoRa radio IC (SX1262 or equivalent). Transmit current at a given power level is nearly identical — the difference in average draw comes entirely from idle/sleep time between packets.

**Key point:** LoRa transmit events are very short (a few hundred milliseconds per packet) and infrequent on a typical relay node. The duty cycle of transmit is usually under 5%, so average current is dominated by the idle/receive state. This is why the nRF52840 platform offers roughly a **6–10× reduction in average power** for an equivalent relay workload.

---

## Battery sizing

### Basic energy budget

1. Estimate your average current draw (use the table above as a starting point).
2. Multiply by the hours you need off-grid coverage.
3. Add a margin for depth-of-discharge (DoD) limits and temperature derating.

**Example — ESP32 single-cell 18650 build:**

- Average draw: 50 mA at 3.7 V = **185 mW**
- Target runtime: 48 hours (solar outage / cloudy period)
- Energy needed: 0.185 W × 48 h = **8.9 Wh**
- A standard 3000 mAh 18650 = 3.0 Ah × 3.7 V = **11.1 Wh**
- At 80% DoD (Li-ion): **8.9 Wh usable** — just enough for 48 h

**Example — nRF52 single-cell 18650 build:**

- Average draw: 7 mA at 3.3 V = **23 mW**
- Target runtime: 48 hours
- Energy needed: 0.023 W × 48 h = **1.1 Wh**
- Same 3000 mAh 18650 = **11.1 Wh** usable at 80% DoD
- Equivalent to roughly **400 hours (16+ days)** of reserve on a single cell

For longer cloudy periods or higher-draw ESP32 builds, use two cells in parallel or a larger multi-cell Li-ion pack. nRF52-based builds can typically sustain multi-week outages on a modest battery.

### Chemistry considerations

| Chemistry | Nominal voltage | Recommended max DoD | Notes |
|---|---|---|---|
| **Li-ion / LiPo (18650, 21700, pouch)** | 3.6–3.7 V | 80% | **Recommended for most builds.** High energy density, wide charger support (TP4056, CN3791, most boards). Avoid full discharge and charging below 0 °C. |
| LiFePO4 | 3.2 V | 90% | Longer cycle life and better cold tolerance, but requires a charger specifically programmed for the 3.6 V charge voltage — the common TP4056 and CN3791 modules are **not** compatible. Only use if your charger explicitly supports LiFePO4. |
| NiMH | 1.2 V | 80% | Not recommended for solar — high self-discharge |
| Lead-acid (SLA) | 12 V | 50% | Heavy, but cheap and robust; common for large outdoor builds |

**Li-ion / LiPo is the default recommendation** for MeshCore builds. Every common single-cell charger board (TP4056, CN3791, the built-in charger on T-Beam / Heltec / RAK base boards) is designed for the 4.2 V Li-ion charge profile.

**Cold weather:** Li-ion capacity drops noticeably below 0 °C and should not be charged below freezing. If you're deploying in a climate with sustained sub-zero temperatures and cannot prevent the battery from getting that cold, consider a LiFePO4 pack — but verify your entire charging chain (charger module, BMS) supports the lower 3.6 V charge voltage before doing so.

**Temperature derating rule of thumb:** Expect roughly 20% capacity loss at 0 °C and 40%+ at -20 °C for Li-ion. Size your battery to cover the worst-case temperature you expect.

### Sizing for longer autonomy

For nodes where solar may be unavailable for several days (e.g., dense overcast, winter at high latitude), size for at least 3–5 days of reserve at average draw. Use a spreadsheet or tool like the [Battery Runtime Calculator](https://www.omnicalculator.com/everyday-life/battery-life) to confirm your math before committing to a battery size.

---

## Solar charging

### Panel sizing

A small solar panel can comfortably sustain a typical MeshCore node in most climates. The key figure is **peak sun hours (PSH)** for your location and time of year — commonly 3–5 h/day in mid-latitudes, dropping to 2–3 h/day in winter.

**Example — 5 W panel with an ESP32 relay (GPS off):**

- Panel output: 5 W × 4 PSH = **20 Wh/day**
- Node consumption: 0.185 W × 24 h = **4.4 Wh/day**
- Net surplus: ~15 Wh/day to charge the battery

**Example — 1 W panel with an nRF52 relay (GPS off):**

- Panel output: 1 W × 4 PSH = **4 Wh/day**
- Node consumption: 0.023 W × 24 h = **0.55 Wh/day**
- Net surplus: ~3.5 Wh/day — even a tiny panel keeps the battery topped up

A 5 W panel is generally sufficient for an ESP32 node in a reasonably sunny location. An nRF52 node can be sustained by a 1–3 W panel in most climates, making coin-sized or flexible panels viable. In areas with frequent overcast, step up one size for margin. Larger builds with GPS, display, or high-duty-cycle operation may need 10–20 W.

| Node type | MCU | Avg draw | Recommended minimum panel |
|---|---|---|---|
| Low-power relay, GPS off | nRF52840 (RAK) | ~7 mA / 23 mW | 1–3 W |
| Low-power relay, GPS on | nRF52840 (RAK) | ~30 mA / 100 mW | 3–5 W |
| Standard relay, GPS off | ESP32 | ~50 mA / 185 mW | 5–10 W |
| Standard relay, GPS on | ESP32 | ~70 mA / 260 mW | 10 W |
| High-traffic repeater or base node | ESP32 | ~100 mA / 370 mW | 20 W |

Mount the panel at an angle that faces the sun at solar noon (true south in the northern hemisphere, true north in the southern hemisphere). Tilt angle approximately equal to your latitude is a reasonable starting point for year-round operation.

### MPPT vs. PWM charge controllers

Most small solar charge controller kits sold for DIY electronics use a simple **PWM (pulse-width modulation)** scheme. They work, but waste energy — particularly when the panel voltage is significantly higher than the battery voltage.

**MPPT (maximum power point tracking)** controllers continuously find the panel's operating point that delivers maximum power and step-convert it into charging current. This typically improves harvest by 15–30% compared to PWM, with larger gains when the panel is cold or partially shaded.

For small builds (< 10 W panel, 1–2 cell battery), the efficiency gain from MPPT may not justify the cost premium. For anything larger or any deployment where every watt-hour matters, use MPPT.

**Common small charging modules suitable for MeshCore builds:**

- **TP4056 with DW01** — the most common single-cell Li-ion charger board. Not true MPPT (it's a linear charger), but works fine with panels up to ~5 W. Charges to 4.2 V — **Li-ion / LiPo only.**
- **CN3791** — solar-optimised single-cell charger with basic input-tracking. Up to ~500 mA charge current, compact and inexpensive. Charges to 4.2 V — **Li-ion / LiPo only.** (Often mislabelled as LiFePO4-compatible; it is not.)
- **EPEVER Tracer / Victron SmartSolar** — full-featured MPPT controllers for 12 V systems; battery chemistry (lead-acid, Li-ion, LiFePO4) is user-configurable. Suited to larger permanent installations with a 12 V battery bank.

### Wiring and fusing

- Keep panel wiring as short as practical. Use appropriately rated wire (at least 22 AWG for panel to controller on small builds).
- Fuse the positive wire close to the battery. A 1 A fuse is adequate for most single-cell builds.
- Waterproof all outdoor connectors. MC4 connectors are standard for larger panels; JST-PH or XT30 are common for small panels in enclosures.
- Diodes: most MPPT modules include a blocking diode to prevent reverse current at night. Verify yours does before omitting an external diode.

---

## Common setups

### USB power bank (portable / temporary)

The simplest starting point. Most power banks output 5 V USB and supply 1–2 A, which is more than enough for a single node. Drawbacks: most power banks auto-shutoff when draw drops below ~100 mA, which can happen if the node is in a low-power idle state. Look for banks advertised as "always-on" or test your specific bank before relying on it.

### PoE (power over Ethernet)

Where an Ethernet run is available, 802.3af PoE provides 48 V at up to 15 W. A small PoE splitter steps this down to 5 V USB for the node. Very reliable for fixed indoor or under-eave installations with network infrastructure nearby.

### Solar + MPPT (outdoor / off-grid)

The typical choice for rooftop, mast, or remote deployments. Use the sizing guidance above. A well-sized solar + Li-ion system will run a node indefinitely with no intervention. For large permanent installations using a 12 V battery bank, a configurable MPPT controller (EPEVER, Victron) can be set for Li-ion or LiFePO4 as appropriate.

