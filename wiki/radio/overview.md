---
title: overview
description: Antenna types, radiation patterns, placement considerations, and minimum distances for MeshCore deployments
published: true
date: 2026-02-19T00:00:00.000Z
tags: radio, antenna, rf, placement
---

# Antenna & RF Basics

Practical RF guidance for MeshCore deployments.

---

## The main rule

**Height beats power.** A good antenna in a good position usually outperforms higher transmit power.

Doubling transmit power adds 3 dB — the equivalent of moving a link from marginal to solid. Gaining 10 metres of height in open terrain can add tens of dB of path improvement. Fix the antenna position before reaching for a higher-power module.

---

## Antenna types and radiation patterns

### Omnidirectional antennas

Omni antennas radiate in all horizontal directions simultaneously. They are the default choice for relay nodes and any deployment where you cannot predict the direction of incoming traffic.

**Dipole (2.15 dBi)**

The reference antenna. A half-wave dipole has a toroidal ("donut") pattern: energy radiates outward in every horizontal direction, with nulls directly above and directly below along the antenna's axis. In practice this means a dipole mounted vertically is excellent for ground-level and low-altitude nodes communicating with other nodes at a similar elevation, but loses efficiency when communicating with nodes directly above or below.

**Colinear / vertical collinear (3–9 dBi)**

Multiple dipole elements stacked end-to-end in phase. The pattern is the same donut shape as a single dipole, but compressed vertically — the gain from extra elements is achieved by squeezing more energy toward the horizon and less toward the sky. Higher gain = flatter pattern.

- 3 dBi (half-wave): gentle compression, still useful for nodes at varying heights
- 5–6 dBi: good all-round choice for rooftop relay nodes
- 9 dBi: very flat pattern, best only when all other nodes are at a similar altitude and terrain is flat

A common mistake is fitting a 9 dBi colinear on a hilltop or mast expecting better performance. If the nodes you need to reach are at lower elevations, the flat pattern may actually miss them because the main lobe shoots out horizontally past them. Use moderate gain (5–6 dBi) unless you have a specific reason for more.

**Rubber duck / whip**

The short stubby antenna bundled with most modules. Convenient but typically lossy and de-tuned when hand-held or mounted flush against a surface. Fine for testing on a desk. Not recommended for permanent installs where anything better can be used.

---

### Directional antennas

Directional antennas focus energy in one direction, trading coverage breadth for range. Use them for point-to-point links, long-distance shots, or intentionally one-sided coverage.

**Yagi-Uda (7–17 dBi)**

A row of parallel elements — a driven element, a reflector behind it, and one or more directors in front. The pattern is a narrow forward lobe with a smaller back lobe and sharp nulls to the sides. Higher element count = more gain = narrower beamwidth.

- 7–9 dBi Yagi: ~60–70° horizontal beamwidth — useful for a wide sector from a hilltop
- 12–14 dBi Yagi: ~30–40° beamwidth — point-to-point over moderate distances
- 16+ dBi Yagi: very narrow beam (~15–20°) — long-distance shots, requires careful alignment

Yagis need to be aimed accurately. A 14 dBi Yagi pointed 20° off-target may perform worse than a modest omni.

**Patch / panel antenna (8–14 dBi)**

A flat antenna element over a ground plane. Pattern is hemispherical forward — a roughly 60–90° cone of coverage in both horizontal and vertical planes. Easier to mount and more weatherproof than a Yagi while offering comparable gain in the mid-range. Common in point-to-point links and under-eave sector coverage.

**Sector antenna (10–16 dBi)**

Wide horizontal (60–120°) but narrow vertical beamwidth. Used at base stations or hilltop nodes to provide defined sector coverage rather than a full 360° sweep. Multiple sectors can cover 360° while maintaining higher gain than a single omni.

---

## Feedline and losses

Coax loss scales with frequency and length. At 915 MHz:

| Coax type | Loss per 10 m |
|---|---|
| RG-174 (thin, flexible) | ~7–9 dB |
| RG-58 | ~3–4 dB |
| RG-8X / LMR-240 | ~1.5–2 dB |
| LMR-400 / Ecoflex 10 | ~0.8–1 dB |

At 868 MHz losses are slightly lower; at 433 MHz roughly half these figures.

A 10 m run of RG-58 costs you 3–4 dB — enough to negate the gain of upgrading from a 3 dBi to a 6 dBi antenna. Keep runs short. If you must run long coax, step up to LMR-240 or LMR-400. Prefer mounting the node near the antenna and running power + data cable (or PoE) instead of long coax runs.

---

## Placement considerations

### Height and line of sight

LoRa is a near-line-of-sight technology. The Fresnel zone — an elliptical volume around the straight-line path between two antennas — must be mostly clear of obstructions for reliable links. A rough rule: for a 1 km link at 915 MHz, the first Fresnel zone radius at the midpoint is about 9 m. Buildings, trees, and terrain that intrude into this zone cause diffraction loss.

- Rooftop mounts: get the antenna above the roofline. A few extra metres of mast makes a large difference.
- Indoor placements near windows: performance is sharply reduced compared to outdoor. Avoid where possible for relay nodes.
- Tree line: trees cause 10–20 dB of loss per 10 m of depth, and the loss varies with foliage and weather.

### Polarisation

Keep all antennas in the same polarisation. Virtually all MeshCore nodes use vertically polarised antennas. Mixing a vertical transmitter with a horizontally polarised receiver introduces approximately 20 dB of cross-polarisation loss, killing the link.

### Metal surfaces and ground planes

An antenna's pattern and resonant frequency can be disturbed by nearby metal. As a practical minimum:

- Keep the antenna at least **λ/4 (quarter wavelength)** away from large metal surfaces.
  - At 915 MHz, λ/4 ≈ **8 cm**
  - At 868 MHz, λ/4 ≈ **9 cm**
  - At 433 MHz, λ/4 ≈ **17 cm**
- Metal enclosures and mast clamps directly touching a vertical antenna will detune it and distort the pattern. Use non-metallic standoffs or a mast offset bracket.
- Rooftop HVAC units, metallic railings, and vent stacks within 20–30 cm of an antenna cause reflections and pattern distortion.

### Separation from other antennas

When multiple antennas share a mast or enclosure:

- **Same node, different bands** (e.g. 915 MHz LoRa + 2.4 GHz WiFi BLE): 15–20 cm separation is usually enough at these frequencies.
- **Two LoRa antennas on the same band on the same node:** avoid; mutual coupling will distort patterns and may damage receiver front-ends. Use a diplexer/combiner or a single antenna.
- **Adjacent nodes sharing a mast:** 30–50 cm vertical or horizontal separation between antennas to reduce coupling.

---

## Minimum distances

### From metallic structures

| Situation | Minimum separation |
|---|---|
| Large flat metal surface (roof, HVAC) | 15 cm (≥ λ/2 preferred) |
| Mast/pole the antenna mounts to | 5 cm radially — use a standoff |
| Metallic enclosure walls | 10 cm from any wall |

### Between co-located antennas

| Scenario | Minimum separation |
|---|---|
| Same band, same mast | 30 cm vertical |
| Different bands on same mast | 15–20 cm |
| High-power co-located transmitter (Wi-Fi AP, cellular) | 50 cm |

### Between nodes on a network

Very close nodes can overload each other's receivers. At +20 dBm (100 mW) LoRa transmit power:

- Two nodes within 1–2 m of each other will likely saturate each other's receivers, causing them to miss packets from the other.
- **Recommended minimum node separation: 10 m** for nodes intended to communicate with each other directly.
- If two nodes serve different sectors and are co-located at a shared site, ensure at least 50 cm antenna separation and consider reducing transmit power if they are intended to relay each other.

### RF safety

At the power levels used in LoRa (maximum 100 mW / +20 dBm), the RF exposure is far below regulatory safety limits at any normal installation distance. No special RF safety exclusion zone is required. As a matter of good practice, avoid placing an antenna transmitting at full power directly adjacent to where people spend extended time — but this is not a compliance concern at these power levels.

---

## Safety

- **Secure mounts and guying:** outdoor antennas must be mechanically secure. A rooftop mast in wind or ice load is a structural hazard if not properly guyed or bracketed.
- **Lightning and grounding:** elevating a conductive antenna above a structure increases lightning risk. In high-risk areas (open terrain, elevated sites), use a proper lightning arrestor in the feedline and bond the arrestor ground to the building earth. Indoor nodes behind closed windows have some natural protection; outdoor mast-mounted antennas do not.
- **Weatherproofing coax joints:** outdoor N-type and SMA connections should be wrapped with self-amalgamating tape or fitted with weatherproof boots. Water ingress into connectors is a leading cause of coax failure.

