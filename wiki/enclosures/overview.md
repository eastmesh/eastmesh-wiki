---
title: overview
description: Enclosure selection, weatherproofing, moisture control, and thermal management for outdoor MeshCore nodes
published: true
date: 2026-02-19T00:00:00.000Z
tags: enclosures, weatherproofing, outdoor, installation
---

# Enclosures & Weatherproofing

How to keep outdoor nodes alive and reliable through weather, temperature swings, and years of exposure.

---

## Enclosure selection

### IP ratings

The IP (Ingress Protection) rating tells you how well a housing resists solid particles and water. For outdoor nodes:

| Rating | Protection | Typical use |
|--------|-----------|------------|
| IP54 | Dust limited, splash resistant | Under-eave sheltered mounting only |
| IP65 | Dust-tight, low-pressure water jets | General outdoor use |
| IP66 | Dust-tight, high-pressure water jets | Exposed rooftop, coastal |
| IP67/68 | Dust-tight, submersion rated | Extreme exposure, flood-prone sites |

For most repeater deployments, **IP65 is the minimum** for any exposed outdoor mounting. IP66 is better near the coast or in high-rainfall areas.

### Material

- **Polycarbonate (PC)**: impact-resistant, UV-stable if UV-inhibited grade is used. Most DIY enclosures on the market. Verify UV rating — cheap PC yellows and cracks within 12–18 months of direct sun exposure.
- **ABS**: lighter and cheaper than PC, but less impact-resistant and more prone to UV degradation. Acceptable for sheltered locations.
- **GRP/fibreglass**: very durable, used in professional telecom enclosures. Higher cost but excellent long-term performance.
- **Aluminium/steel**: excellent for mechanical protection; adds weight and risk of detuning nearby antennas. Ensure antenna is mounted with sufficient standoff from any metal surfaces.

### Gasket quality

A failed gasket defeats even the best enclosure rating. Check:
- Gasket is fully seated in the groove before closing
- No nicks, cuts, or deformation in the gasket material
- Closure screws or latches torqued evenly (do not over-torque)

Re-inspect the gasket annually. Silicone gaskets last 5–10 years. Foam or rubber gaskets degrade faster in UV and heat.

---

## Cable entry

### Cable glands

Every cable entering the enclosure needs a properly sized cable gland (also called a cable transit):

- Match gland size to cable OD (outside diameter); too large allows water ingress, too small may damage the cable jacket
- Use glands rated to at least IP68 for the junction itself
- For coax, use glands sized for the connector body rather than passing bare coax through and reconnecting inside
- Tighten glands fully; hand-tight is usually not enough

### Unused knockout holes

Seal any unused knockout holes with a solid IP-rated blanking plug. Water always finds the path of least resistance.

### Drip loops

Where cable enters from overhead or from a run that is not self-draining:
- Form a drip loop — a downward curve in the cable below the entry point — so water drains off the loop rather than running down into the gland
- The drip loop should extend at least 20 cm below the entry point

---

## Moisture control inside the enclosure

Even with a perfect seal at installation, thermal cycling causes the air inside to expand and contract, pushing moisture in over time through micro-imperfections. Manage this actively:

### Desiccant packs

- Place a silica gel desiccant pack inside every sealed enclosure at installation
- Use indicating gel (colour-change type) so you can visually check saturation status without opening the enclosure unnecessarily
- Replace or regenerate desiccant packs annually, or when the indicator shows saturation
- Sizing: 5–10 g per litre of enclosure volume is a reasonable starting point

### Vent plugs (Gore-type or equivalent)

For enclosures larger than ~2 L or those subject to large daily temperature swings, a vent plug equalises pressure without allowing liquid water entry:
- IP-rated vent plugs allow air exchange while repelling water
- Prevents pressure differential from forcing water through gasket seams
- Used in conjunction with, not instead of, desiccant

---

## Thermal management

Electronics fail faster at elevated temperatures. The inside of a sealed enclosure in direct sun can reach 60–80 °C in summer — well above the rated operating range of most ESP32 or nRF52 modules (typically derated to +70 °C in practice).

### Positioning

- **Avoid direct sun exposure** on the face of the enclosure. Mount with the lid facing away from solar noon (face north in the southern hemisphere, face south in the northern hemisphere).
- Mount under an eave, overhang, or shade structure where possible.
- Lighter-coloured enclosures reflect more solar radiation than dark ones.

### Passive ventilation

- If your IP rating requirements permit it, vent plugs significantly reduce peak internal temperature by allowing convective air movement.
- Some enclosures have internal fins or perforated inner trays to improve air circulation without compromising the external seal.

### Temperature monitoring

- If your hardware supports it (e.g., ESP32 with a BME280 sensor or internal thermistor), log internal temperature as part of telemetry.
- Set an alert threshold (e.g., >65 °C) to identify thermal problems before they cause hardware failure.

---

## Connector weatherproofing

Outdoor RF connectors are a common failure point. Water ingress at a coax connector causes rapid corrosion, impedance mismatch, and eventually complete failure.

- **Self-amalgamating tape**: wrap all outdoor SMA, N-type, or BNC connections. Apply from below the connector upward (overlap each wrap 50%) and extend 2–3 cm past the connector body on each side. Self-amalgamating tape fuses to itself and forms a waterproof seal.
- **Pre-made weatherproof boots**: some connector types have clip-on weatherproof covers. These are faster to install but less reliable than tape for long-term outdoor use.
- **Corrosion protection**: use a dielectric grease or RF-safe corrosion inhibitor on threaded connections before assembly, particularly in coastal or high-humidity environments.

---

## Common failure modes

| Problem | Likely cause | Prevention |
|---------|-------------|-----------|
| Water inside enclosure | Failed gasket, unsealed cable entry, condensation | Annual gasket inspection, desiccant, proper glands |
| Corrosion on connectors | Water ingress at coax joint | Self-amalgamating tape on all outdoor connections |
| Node overheating | Direct sun, no thermal management | Shade or repositioning, use light-coloured enclosure |
| Cracked enclosure | UV-degraded plastic | UV-stable material; inspect annually |
| Antenna detuned | Antenna touching metal enclosure wall | Non-metallic standoff, maintain λ/4 clearance |

---

## Related pages

- [Antenna & RF Basics](../radio/overview)
- [Power & Solar](../power/overview)
- [Build Guides](../build-guides/overview)
- [Community Rules & Safety](../community/rules-and-safety)
