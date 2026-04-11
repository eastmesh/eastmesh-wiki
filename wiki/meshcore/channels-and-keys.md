---
title: channels-and-keys
description: MeshCore channel definition, types, key management, and naming conventions
published: true
date: 2026-02-19T00:00:00.000Z
tags: meshcore, channels, keys, security
---

# Channels & Keys

How channels are defined, the different channel types, how keys are managed, and how to avoid common interoperability failures.

---

## What Is a Channel?

In MeshCore, a "channel" is a **group communication namespace** defined entirely by cryptography, not radio parameters:

```
GroupChannel {
    hash[1 byte]    ← first byte of the channel secret's hash (packet identifier)
    secret[32 bytes] ← shared key material (AES + HMAC key source)
}
```

All nodes sharing the same 32-byte secret can:
- Decrypt and read group messages sent on that channel
- Authenticate that messages came from channel members
- Identify channel traffic in packet headers via the 1-byte hash

**Important**: channels do not define frequency, spreading factor, or bandwidth. All nodes on a deployment share the same radio parameters via `NodePrefs`. Channels are a crypto layer on top of a common radio layer.

---

## Channel Types

### Public / Shared Channels

Use a universally known or published shared secret. Any operator can join by knowing the channel name/secret.

Use cases:
- Community-wide coordination (e.g., "eastmesh public")
- Emergency coordination
- Onboarding newcomers

Risk: since the secret is public, end-to-end confidentiality is low — treat public channel traffic as visible to anyone who knows the secret.

### Hashtag Channels

Secret is **derived by hashing the channel name**:

```
secret = hash("#channelname")
```

Anyone who knows the channel name can join. Suitable for loosely coordinated groups where the name itself is the membership criteria. Not suitable where confidentiality is important.

### Private Channels

Secret is a **randomly generated 32 bytes** shared out-of-band (via QR code, encrypted message, or in-person). Only people explicitly given the secret can join.

Use cases:
- Team/group operations
- Infrastructure operator coordination
- Sensitive traffic

Sharing format (QR code URI):
```
meshcore://?name=<url-encoded-name>&secret=<64-char-hex-string>
```

---

## Channel Security Properties

| Property | Public Channel | Hashtag Channel | Private Channel |
|----------|---------------|----------------|-----------------|
| Confidentiality | Low (anyone with name/secret) | Low-Medium | High |
| Sender attribution | No (any member can spoof hash) | No | No |
| Join barrier | Know the secret/name | Know the name | Explicit secret share |
| Key rotation | Hard (requires republishing) | Hard | Manual (share new secret) |

MeshCore group messages provide **message confidentiality** (decryption requires the channel secret) and **integrity** (2-byte HMAC verifies content), but do not provide **sender attribution within the channel** — any member could forge a message appearing to come from another member's 1-byte hash.

---

## Channel Naming Conventions

Consistent naming helps operators find and join the right channels.

### eastmesh.au conventions

| Category | Naming Pattern | Example |
|----------|---------------|---------|
| Community general | Descriptor in plain English | `eastmesh` |
| Geographic area | Location name | `melb-north`, `vic-coast` |
| Functional/operational | Function prefix | `ops-vic`, `emcomm-au` |
| Event-specific | Event + year | `hamfest-2026` |
| Private team | Short identifier, shared OOB | `team-alpha` |

Rules:
- Keep names short (for QR code readability and CLI usability)
- Use lowercase and hyphens; avoid spaces and special characters
- Do not include the channel secret in the name
- Document private channel membership somewhere accessible to your team

---

## Public Shared Channel (eastmesh.au)

The **eastmesh public channel** is used for community-wide coordination and onboarding. Contact the community via the forum or chat to obtain current channel credentials.

All operators are encouraged to monitor this channel during normal operation.

---

## Key Management Guidance

### Do

- Share channel secrets only through trusted, encrypted channels (e.g., Signal, encrypted email)
- Use QR codes for in-person sharing — scan-to-join is fast and avoids transcription errors
- Keep a secure local record of all private channel secrets your team uses
- Rotate keys after suspected exposure (see below)
- Document who has each private channel secret

### Do Not

- Post channel secrets in public issue trackers, forum posts, or screenshots
- Share secrets over unencrypted SMS or plain email
- Use the same private channel secret for groups with different trust levels
- Assume a channel is secure just because it's named "private"

---

## Key Rotation

If a private channel secret is compromised (a member leaves, a device is lost or stolen, or a secret is accidentally exposed):

1. Generate a new random 32-byte secret
2. Share it with all remaining authorised members via a trusted out-of-band channel
3. Coordinate a switchover time so members can add the new channel before the old one is abandoned
4. Remove the old channel secret from all devices
5. Update any documentation or stored QR codes

There is no automated key rotation — it is a manual process. Plan rotation procedures before you need them.

---

## Device Channel Storage

The `ChannelDetails` struct on each device stores:

```
GroupChannel {
    hash[1]    ← 1-byte channel identifier
    secret[32] ← 32-byte shared secret
}
name[32]       ← human-readable channel name
```

Stored in `/channels2` on the device filesystem.

Companion radio firmware supports up to **40 group channels** per device.

---

## Related Pages

- [Encryption & Authentication](./encryption)
- [Packet Structure](./packet-structure)
- [Node Roles](./node-roles)
- [Companion Protocol](./companion-protocol)
- [Community Rules & Safety](../community/rules-and-safety)
