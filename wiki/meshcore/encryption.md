---
title: encryption
description: MeshCore cryptographic stack — Ed25519 identities, ECDH key exchange, AES-128-ECB, and HMAC-SHA256
published: true
date: 2026-02-19T00:00:00.000Z
tags: meshcore, security, encryption, technical
---

# Encryption & Authentication

MeshCore uses a layered cryptographic stack designed for constrained embedded hardware. This page documents each algorithm, how they compose, and the resulting security properties.

---

## Algorithm Stack Overview

| Layer | Algorithm | Purpose |
|-------|-----------|---------|
| Identity | Ed25519 | Node identity, advertisement signing |
| Key Exchange | ECDH (X25519) | Per-contact shared secret derivation |
| Message Encryption | AES-128-ECB | Confidentiality of message content |
| Authentication | HMAC-SHA256 (truncated to 2 bytes) | Message integrity and authenticity |
| ACK Integrity | SHA-256 (truncated to 4 bytes) | ACK matching and replay protection |

---

## Identity — Ed25519

Every node generates a unique **Ed25519 keypair** at first boot using hardware RNG entropy.

| Component | Size | Description |
|-----------|------|-------------|
| Public key | 32 bytes | Node's identity; shared freely in advertisements |
| Private key | 64 bytes | Seed (32 bytes) + public key (32 bytes); never leaves the device |
| Signature | 64 bytes | Signs advertisement data |

**Node identifier** in the routing layer is the **first byte** of the public key (`PATH_HASH_SIZE = 1`). This is a short address used in path fields — not a cryptographic identifier.

### Advertisement Signing

ADVERT packets are signed but **not encrypted**. Any node can read an advertisement, but can verify the signature to confirm the originating node's identity:

```
signed_data = public_key (32 bytes) || timestamp (4 bytes)
signature   = Ed25519.sign(signed_data, private_key)
```

Verification uses `identity.verify(public_key, signed_data, signature)`.

### Key Storage

Keys are stored at `/_main.id` (or equivalent per-platform path):
- Private key: 64 bytes (seed + pubkey)
- Public key: 32 bytes

The `IdentityStore` class handles read/write across SPIFFS, InternalFS, and LittleFS.

---

## Key Exchange — ECDH (X25519)

For peer-to-peer messages, MeshCore derives a per-contact shared secret via **Elliptic Curve Diffie-Hellman**:

```
shared_secret = ECDH(local_privkey, remote_pubkey)
```

Ed25519 keys are converted to X25519 curve format internally by `calcSharedSecret()`. The 32-byte shared secret is cached in `ContactInfo.shared_secret[]` after first computation (`shared_secret_valid` flag).

This means:
- Two nodes that know each other's public keys can compute the same 32-byte secret independently
- No key exchange messages are required on-air (keys are included in ADVERT packets)
- An eavesdropper observing both public keys cannot compute the shared secret without a private key

---

## Message Encryption — AES-128-ECB

Encrypted payloads use **AES-128-ECB** mode:

- Key: first 16 bytes of the 32-byte shared secret (`CIPHER_KEY_SIZE = 16`)
- Block size: 16 bytes (`CIPHER_BLOCK_SIZE = 16`)
- Padding: last block is zero-padded to 16-byte boundary
- Mode: **Electronic Codebook (ECB)** — no IV or nonce

### Known Limitation: ECB Mode

ECB mode means identical 16-byte plaintext blocks produce identical ciphertext blocks. This is a recognised cryptographic weakness: in theory, patterns within plaintext can be inferred from repeated ciphertext blocks.

In practice for MeshCore:
- Messages are relatively short and varied
- Timestamps embedded in payloads differ for each message
- ECB was chosen deliberately for minimal code size and RAM on resource-constrained MCUs

Users with high confidentiality requirements should be aware of this limitation.

---

## Authentication — Encrypt-then-MAC

MeshCore uses an **Encrypt-then-MAC** construction for authenticated encryption:

```
1. Encrypt plaintext with AES-128-ECB → ciphertext
2. Compute HMAC-SHA256(shared_secret, ciphertext)
3. Prepend truncated MAC (first 2 bytes of HMAC output) to ciphertext
```

The result in the packet:

```
[cipher_mac: 2 bytes]  HMAC-SHA256 truncated to CIPHER_MAC_SIZE
[ciphertext: N bytes]  AES-128-ECB encrypted content
```

**MAC key**: The full 32-byte shared secret is used as the HMAC key (`PUB_KEY_SIZE = 32`).

**MAC size**: 2 bytes (`CIPHER_MAC_SIZE = 2`). This is a deliberate trade-off — a 2-byte MAC has a 1-in-65536 false-positive rate for random data. The primary purpose is authentication/integrity, not collision resistance.

### Verification

```
1. Compute HMAC-SHA256(shared_secret, received_ciphertext)
2. Compare first 2 bytes against received cipher_mac
3. On mismatch: discard packet (authentication failure)
4. On match: decrypt with AES-128-ECB
```

---

## ACK Integrity — SHA-256 CRC

ACK packets carry a 4-byte checksum derived from the original message:

```
ack_crc = SHA256(timestamp || attempt || message_text || sender_pubkey)[0:4]
```

The receiving node recomputes this value from the stored message and verifies it matches the ACK. This:
- Confirms the ACK is for the specific message sent (not a replay from a different message)
- Serves as a round-trip-time measurement anchor

---

## Group Channel Encryption

Group/channel messages (`GRP_TXT`, `GRP_DATA`) use a **channel-specific shared secret** rather than a per-contact shared secret:

```
GroupChannel.secret[32]  →  AES-128-ECB key (first 16 bytes)
GroupChannel.hash[1]     →  Channel identifier in packet header
```

The same Encrypt-then-MAC construction applies, but keyed with the channel secret instead of a contact-derived ECDH secret.

All nodes with the same channel secret can:
- Decrypt group messages
- Authenticate the MAC (verify message came from a channel member)

What group encryption does **not** provide:
- Sender authentication within the channel (any member can forge a message from any other member's hash)
- Protection against members sharing the channel secret

---

## Anonymous Requests — Ephemeral ECDH

Room server login uses `PAYLOAD_TYPE_ANON_REQ` with an **ephemeral keypair**:

```
1. Client generates a one-time Ed25519/X25519 keypair
2. Client computes ECDH(ephemeral_privkey, server_pubkey) → session_secret
3. Client encrypts credentials with session_secret (AES-128-ECB + MAC)
4. Packet contains ephemeral_pubkey (32 bytes) + ciphertext
5. Server computes ECDH(server_privkey, ephemeral_pubkey) → session_secret
6. Server decrypts and authenticates
```

Since the ephemeral key is one-time, login requests cannot be linked to a persistent identity even by a passive network observer.

---

## Security Model Summary

| Threat | Mitigation | Limitation |
|--------|-----------|-----------|
| Passive eavesdropping | AES-128-ECB + HMAC | ECB mode leaks repeated-block patterns |
| Message forgery | 2-byte HMAC-SHA256 | Short MAC; 1:65536 false positive rate |
| Identity spoofing in adverts | Ed25519 signatures | |
| Key compromise | Contact-level ECDH secrets are independent | Key rotation requires manual re-pairing |
| Replay attacks | Timestamp + attempt# in payload | Clock skew window may be exploitable |
| Group message attribution | Channel secret required | Members can forge from each other's hash |
| Room server identity linkage | Ephemeral ECDH for login | |
| Physical key extraction | Keys on internal filesystem | No secure enclave on most MCUs |

---

## Related Pages

- [Channels & Keys](./channels-and-keys)
- [Packet Structure](./packet-structure)
- [Node Roles](./node-roles)
- [Firmware Internals](./firmware/overview)
