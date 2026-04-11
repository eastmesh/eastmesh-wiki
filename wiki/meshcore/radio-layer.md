---
title: radio-layer
description: MeshCore LoRa radio layer — supported chips, LoRa parameters, regional presets, airtime, and CAD
published: true
date: 2026-02-19T00:00:00.000Z
tags: meshcore, radio, lora, rf, technical
---

# Radio Layer

MeshCore's radio layer sits between the routing core and physical hardware. This page covers supported radio chips, LoRa parameter configuration, regional frequency presets, airtime calculation, and Channel Activity Detection.

---

## Supported Radio Chips

MeshCore supports six radio chipsets via RadioLib wrapper classes:

| Chip | Max TX Power | Notes |
|------|-------------|-------|
| SX1262 | 22 dBm | TCXO, preferred for new designs |
| SX1276 | 20 dBm | Legacy LoRa chip, widely used |
| SX1268 | 22 dBm | Variant of SX1262 |
| LR1110 | 22 dBm | Integrated GNSS (GPS) |
| LLCC68 | 22 dBm | Budget variant of SX1262 |
| STM32WL | 22 dBm | Integrated SoC (MCU + radio in one chip) |

All chips connect to the MCU via SPI. Each chip has a corresponding wrapper in `src/helpers/radiolib/` that adapts the RadioLib API to the MeshCore hardware abstraction.

The **SX1262** is the recommended choice for new hardware designs: TCXO reference oscillator, good sensitivity, widely available.

---

## LoRa Parameters

MeshCore uses four LoRa parameters to define the radio channel. All nodes on the same network must use **identical parameters** or they cannot decode each other's packets.

| Parameter | Field | Typical Range | Notes |
|-----------|-------|--------------|-------|
| Frequency | `freq` | 868–928 MHz | Region-dependent |
| Bandwidth | `bw` | 62.5 / 125 / 250 kHz | Network-wide setting |
| Spreading Factor | `sf` | SF7–SF12 | Affects range, data rate, airtime |
| Coding Rate | `cr` | 4/5 to 4/8 | Error correction overhead |
| TX Power | `tx_power_dbm` | −9 to +22 dBm | Per-node, does not need to match |

Configure via CLI:
```
set radio <freq_MHz> <bw_kHz> <sf> <cr>
set txpow <dBm>
```

---

## Regional Frequency Presets

Default parameters by region:

| Region | Frequency | Bandwidth | SF | CR | Notes |
|--------|-----------|-----------|----|----|-------|
| EU | 869.525 MHz | 62.5 kHz | 7–9 | 4/5 | 10% duty cycle sub-band |
| US / Canada | 910.525 MHz | 62.5 kHz | 7 | 4/5 | |
| Australia / NZ | 915.0 MHz | 62.5 kHz | 7–9 | 4/5 | 915–928 MHz ISM band |
| Switzerland | 869.618 MHz | 62.5 kHz | 8 | 4/8 | |

**Australia/NZ note**: The 915–928 MHz band has generous frequency hopping or wideband rules. MeshCore uses a single fixed frequency rather than frequency hopping, so it operates as a fixed narrowband system within this band. Check ACMA guidelines for your specific use case.

### 62.5 kHz Bandwidth and LoRaWAN Incompatibility

The dominant preset uses **62.5 kHz bandwidth**. This is narrower than LoRaWAN gateway concentrators, which require ≥ 125 kHz. As a result, **MeshCore networks are entirely independent of LoRaWAN infrastructure** — they cannot share concentrators, gateways, or network servers with LoRaWAN devices.

This is not a bug: it is a deliberate choice to use the narrowest practical bandwidth, which provides:
- Higher effective sensitivity (narrower noise bandwidth)
- More frequency diversity (more channels fit in the same spectrum)
- Independence from LoRaWAN congestion

---

## Spreading Factor Trade-offs

Spreading Factor controls the balance between range, data rate, and airtime:

| SF | Data Rate | Airtime | Sensitivity | Max Range |
|----|-----------|---------|-------------|-----------|
| SF7 | Fastest | Shortest | −123 dBm | Shortest |
| SF8 | | | −126 dBm | |
| SF9 | | | −129 dBm | |
| SF10 | | | −132 dBm | |
| SF11 | | | −134.5 dBm | |
| SF12 | Slowest | Longest | −137 dBm | Longest |

**Minimum decodable SNR** (from RadioLib calibration):

| SF | Min SNR |
|----|---------|
| SF7 | −7.5 dB |
| SF8 | −10.0 dB |
| SF9 | −12.5 dB |
| SF10 | −15.0 dB |
| SF11 | −17.5 dB |
| SF12 | −20.0 dB |

For community mesh networks, **SF9 at 62.5 kHz** is a common balanced choice — longer range than SF7 without the severe airtime penalty of SF12.

**Important**: Changing SF changes airtime significantly. A message that takes 200 ms at SF7 may take 1600 ms at SF9 on 62.5 kHz. This directly affects duty cycle limits and network throughput.

---

## Airtime Estimation

The firmware uses RadioLib's built-in time-on-air calculator:

```
airtime_ms = radio.getTimeOnAir(packet_length_bytes) / 1000
```

The `Dispatcher` queries this before queuing transmissions to enforce the airtime budget.

### Example Airtimes (approximate, 62.5 kHz BW)

| SF | 50-byte packet | 100-byte packet | 200-byte packet |
|----|---------------|----------------|----------------|
| SF7 | ~85 ms | ~155 ms | ~290 ms |
| SF9 | ~340 ms | ~625 ms | ~1150 ms |
| SF12 | ~2700 ms | ~5000 ms | ~9200 ms |

These are rough estimates; actual values depend on coding rate, preamble length, and header mode.

---

## Duty Cycle and Airtime Budget

The `Dispatcher` enforces an airtime budget to stay within duty cycle limits:

```
airtime_budget_factor = 2.0
duty_cycle = 100 / (factor + 1) = 33.3%
```

The radio must be silent for at least **2× the last transmission duration** before the next transmission fires.

For stricter regional limits (e.g., EU 869.525 MHz at 10% max):

```
set af 9.0   (airtime factor = 9.0 → 10% duty cycle)
```

Formula: `duty_cycle = 100 / (af + 1)`

| `af` value | Effective duty cycle |
|-----------|---------------------|
| 1.0 | 50% |
| 4.0 | 20% |
| 9.0 | 10% (EU legal limit for this sub-band) |
| 19.0 | 5% |

---

## Channel Activity Detection (CAD)

Before every transmission, the Dispatcher performs LoRa **Channel Activity Detection** to check if the channel is already in use.

Timing constants:

| Constant | Value | Description |
|----------|-------|-------------|
| `CAD_FAIL_MAX_DURATION` | 4000 ms | If channel stays busy this long, declare CAD timeout error |
| `STARTRX_TIMEOUT` | 8000 ms | Watchdog for radio stuck in TX |
| `NOISE_FLOOR_CALIB_INTERVAL` | 2000 ms | Interval between RSSI noise floor samples |

### Noise Floor Calibration

The firmware continuously samples RSSI at 2-second intervals. 64 consecutive samples below a threshold are used to compute the noise floor baseline, clamped at a minimum of −120 dBm.

Elevated noise floor readings indicate:
- Local RF interference (WiFi on 900 MHz where applicable, industrial equipment)
- Other LoRa networks on the same or adjacent frequency
- Hardware issues (faulty antenna, damaged RF path)

---

## SNR Storage Format

Throughout the firmware, SNR is stored as `int8_t` in **quarter-dB units**:

```
stored_value = SNR_float * 4
SNR_float    = stored_value / 4.0
```

This allows -32.0 dB to +31.75 dB range in a single signed byte. Always remember to divide by 4 when reading raw stats values.

---

## Receive Sensitivity and Link Budget

Approximate receive sensitivity (SX1262, BW 62.5 kHz):

| SF | Sensitivity |
|----|------------|
| SF7 | −123 dBm |
| SF9 | −129 dBm |
| SF12 | −137 dBm |

Example link budget (SX1262, SF9, 62.5 kHz):
```
TX power:          +22 dBm  (SX1262 max)
TX antenna gain:    +3 dBi  (simple vertical)
Cable/connector:    −1 dB
Free space path:  −140 dB   (≈30 km at 915 MHz, with terrain loss)
RX antenna gain:   +3 dBi
RX sensitivity:  −129 dBm

Available margin:  22 + 3 - 1 - 140 + 3 - (-129) = +16 dB
```

A 16 dB margin is comfortable. Real-world performance depends heavily on terrain, obstructions, and antenna installation quality.

---

## Related Pages

- [RF & Propagation](../radio/overview)
- [Hardware Recommendations](../hardware/recommended)
- [Routing Algorithm](./routing)
- [Firmware Internals](./firmware/overview)
- [Community Rules & Safety](../community/rules-and-safety)
