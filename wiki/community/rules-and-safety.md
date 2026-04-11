---
title: rules-and-safety
description: Community conduct, RF compliance, safe deployment practices, and privacy expectations for eastmesh.au operators
published: true
date: 2026-02-19T00:00:00.000Z
tags: community, safety, compliance, privacy, conduct
---

# Community Rules & Safety

Guidelines for RF compliance, safe physical deployments, community conduct, and privacy for operators on the eastmesh.au network.

---

## RF compliance

LoRa radios are unlicensed devices operating in designated ISM bands. Staying within legal limits keeps the network operational and protects the community from regulatory attention.

- **Operate only within legal regional frequency limits** — for Australia/NZ this is the 915–928 MHz ISM band; for EU, the 868 MHz sub-bands with their respective duty cycle limits
- **Respect transmit power limits** — maximum 100 mW (20 dBm) EIRP is typical; check the relevant regulatory framework (ACMA for Australia, ETSI for EU) for your specific case
- **Respect duty cycle constraints** — in EU sub-bands, some channels have strict duty cycle limits (e.g., 1% or 10%); configure `af` (airtime factor) accordingly
- **Use equipment appropriate to your licence class** — in Australia, LoRa in the 915 MHz ISM band does not require an amateur licence; however, if operating under an amateur licence on other bands, comply with applicable amateur radio regulations
- **Do not modify hardware to exceed rated power limits**

Non-compliant operation risks both safety and continuity of community network activity. Regulatory action against one operator can affect everyone.

---

## Safe deployment practices

Physical installations carry real safety risks. No coverage goal justifies injury.

### Height and access

- **Do not climb** without appropriate training, equipment, and a spotter
- Do not install on rooftops or masts in unsafe weather conditions (high wind, lightning, wet surfaces)
- If a site requires specialised access equipment (elevated work platform, safety harness), arrange it properly — do not improvise
- Always tell someone where you are going and when to expect you back when doing a solo rooftop or remote site visit

### Structural and electrical

- Use mounting hardware rated for the expected wind loading at the site; do not use adhesive tape or cable ties as primary antenna support
- Ensure mast bases and wall brackets are anchored to structural members, not just cladding
- Keep antennas and masts away from power lines; assume all overhead lines are live
- Install lightning arrestors on feedlines for any antenna mounted above the roofline in lightning-prone areas, and bond the arrestor ground to the building earth

### Enclosure and weatherproofing

- Weatherproof all outdoor connections (self-amalgamating tape, cable glands)

---

## Community conduct

The community is built on operators helping each other. Maintain an environment where that is possible:

- **Be respectful** — especially during troubleshooting when frustration is high; assume good intent
- **Share accurate, testable information** — if you are not sure, say so; guesses presented as facts waste everyone's time
- **Correct, do not pile on** — if someone shares incorrect information, correct it clearly and move on; extended arguments are unproductive
- **Do not gatekeep** — newcomers often ask questions that seem basic; guide them to the answer rather than dismissing the question
- **Do not promote harmful or illegal use cases** — this includes using the network to facilitate illegal activity or attempting to disrupt the network for any reason
- **Keep dispute resolution private** — personal conflicts belong in direct messages, not public channels

---

## Privacy expectations

MeshCore involves radio transmissions that are observable by anyone with appropriate equipment. Be mindful of what is shared:

### Location privacy

- **Do not publish precise residential GPS coordinates** of any node without the explicit consent of the owner or occupant
- On the public network map, use approximate coordinates for residential nodes (e.g., suburb level rather than street-level precision)
- Disable GPS advertising (`advert_loc_policy = none`) on companion nodes used in sensitive contexts

### Personal information

- Redact personally identifying details (street addresses, names, faces) from photos before sharing
- Do not share photos of site installations that include identifiable vehicle registration plates or neighbouring properties without need

### Channel and key security

- Treat all private channel secrets as sensitive — do not share them in public forums, issue trackers, screenshots, or logs
- If a private channel secret is accidentally exposed, rotate it promptly — see [Channels & Keys](../meshcore/channels-and-keys) for rotation procedures
- Node owner details, site access arrangements, and private contact information shared within the operator community should be treated with discretion

---

## Related pages

- [Build Guides](../build-guides/overview)
- [Channels & Keys](../meshcore/channels-and-keys)
- [Antenna & RF Basics](../radio/overview)
