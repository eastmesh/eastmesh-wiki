---
title: repeater regions and unscoped messages
description: Configure MeshCore repeater regions and control unscoped flood messages
published: true
date: 2026-08-25T00:00:00.000Z
tags: meshcore, repeaters, regions, routing, operations
---

# Repeater Regions & Unscoped Messages

MeshCore regions let repeaters limit which **region-scoped flood messages** they forward. A region is a named scope encoded into the packet's transport code; it is not a radio frequency, channel, or geographic boundary enforced by GPS.

This page applies to repeater firmware with region management support, available from **v1.10+**. Check the firmware's CLI help or release notes if a command is unavailable.

---

## Region concepts

A repeater can store a tree of named regions. The special `*` entry represents traffic with no region transport code; it is not a wildcard that matches every named region. For EastMesh, a useful example is:

```text
*
└── au
    └── au-vic
```

`au` and `au-vic` are separate region scopes. The parent/child relationship documents the hierarchy and is useful when managing a larger region tree; it does **not** make an `au` packet and an `au-vic` packet interchangeable. A sender must choose the scope it intends to use, and repeaters must have that scope defined and allowed if they are to forward it.

For ordinary names such as `au` and `au-vic`, MeshCore derives the transport key as an implicit hashtag region. A leading `#` is therefore not required for these examples. Keep names short, lowercase, and consistent across the nodes that should participate in the scope.

### Home region and default scope

These settings are related but different:

- **Home region** identifies the region associated with the repeater itself.
- **Default scope** selects the region used for outgoing flood messages when the sender has not explicitly selected another scope.
- **Flood permission** controls whether the repeater forwards incoming floods for a region.

Setting a home or default region does not, by itself, permit forwarding. Define the region and review its flood permission separately.

---

## Before changing a repeater

1. Confirm that the repeater is running firmware with region support.
2. Connect through the repeater's authorised serial or remote CLI.
3. Record the existing configuration:

   ```text
   region
   get flood.max
   get flood.max.unscoped
   ```

4. Make sure you have a recovery path. A restrictive `*`/unscoped-traffic policy can stop unscoped remote administration from travelling beyond the first repeater.

Do not change the radio frequency, bandwidth, spreading factor, or channel keys as part of a region-only change.

---

## Add `au` and `au-vic`

The concise command creates `au` below `*` and `au-vic` below `au`:

```text
region def au au-vic
region save
region
```

The final `region` command displays the resulting tree. Review it before continuing. `region def` changes the in-memory region map; `region save` persists it to the repeater's filesystem so it survives a reboot.

New regions created with `region def` are flood-allowed by default. If the reply reports an error, stop and inspect the tree before retrying. A failed multi-region command can leave earlier regions from that command in place.

The equivalent individual commands are useful when adding one region at a time:

```text
region put au
region put au-vic au
region allowf au
region allowf au-vic
region save
```

Use one method or the other rather than blindly repeating both. `region put` accepts an optional parent; when a region is created directly with it, explicitly use `region allowf` if it is intended to forward floods.

### Optional local defaults

If this repeater should identify as Victorian and use Victorian scope for its own outgoing floods, set the relevant defaults deliberately:

```text
region home au-vic
region default au-vic
region save
```

Use `region home` and `region default` only when that matches the deployment's operating policy. They do not replace `region allowf au-vic`.

### Verify the entries

On firmware that supports it, use:

```text
region get au
region get au-vic
region list allowed
```

On older firmware, use `region` to dump the region tree and flood permissions. Confirm that both names exist and are flood-allowed before testing a scoped message.

---

## Allowing and blocking scoped floods

A region-scoped flood carries a transport code calculated from its region scope. A repeater checks that code against its region map:

- If the matching region exists and flooding is allowed, the repeater may forward the packet, subject to hop limits and normal duplicate/loop controls.
- If there is no matching allowed region, the repeater does not forward the scoped flood.
- `region allowf <name>` allows flood forwarding for that region.
- `region denyf <name>` blocks flood forwarding for that region.

Examples:

```text
region allowf au
region allowf au-vic
region denyf au-vic
region save
```

The last two commands intentionally leave `au` allowed while blocking `au-vic`; use the policy that matches the repeater's role. A node does not need every possible region in the network, only the scopes it is meant to carry.

The special `*` entry controls packets with no region transport code. It is not a wildcard and is not a substitute for defining named regions.

---

## What an unscoped message is

An **unscoped** flood message has no region transport code. It is not automatically a message for every named region and should not be treated as a global broadcast. Each repeater applies the `*` entry's unscoped-traffic policy and the separate unscoped flood hop limit.

Unscoped traffic is useful for compatibility, bootstrap, or deliberately local messages, but unrestricted unscoped flooding can cross the regional boundaries that named scopes are intended to provide.

### Unscoped-traffic policy (`*`)

To allow unscoped flood forwarding:

```text
region allowf *
region save
```

To drop unscoped flood packets at the repeater:

```text
region denyf *
region save
```

`region denyf *` is a boundary-style policy: an unscoped flood is not forwarded by that repeater. It does not block correctly region-scoped traffic whose named region is separately defined and allowed.

### Limit unscoped flood distance

Instead of completely blocking unscoped floods, set a smaller hop limit:

```text
set flood.max.unscoped 3
```

This permits an unscoped message to propagate locally while limiting how far it can travel. The valid range is `0`–`64`; `0` prevents an unscoped flood from making progress beyond the receiving hop. Check the result with:

```text
get flood.max.unscoped
```

This setting is separate from `flood.max`, which controls ordinary scoped flood hop limits. It is also separate from `flood.max.advert`, which controls advert floods.

### Choosing a policy

| Policy | Example | Result |
|---|---|---|
| Open unscoped forwarding | `region allowf *` and a suitable `flood.max.unscoped` | Compatibility traffic can cross the repeater, subject to the hop limit |
| Local unscoped forwarding | `region allowf *` plus `set flood.max.unscoped 3` | Unscoped traffic can travel a short distance only |
| No unscoped forwarding | `region denyf *` or `set flood.max.unscoped 0` | Unscoped floods are stopped at the boundary |
| Named regional forwarding | `region allowf au-vic` | Matching `au-vic` scoped floods can cross; unscoped policy is independent |

For a regional repeater, prefer named scopes for normal network traffic and choose an explicit, documented policy for unscoped messages. Coordinate the policy with neighbouring operators before applying it: clients or tools that depend on unscoped floods may appear unreachable after restricting the `*`/unscoped-traffic entry.

---

## Testing and troubleshooting

After saving the configuration:

1. Run `region` and confirm the tree and flood flags.
2. Check `get flood.max.unscoped` and, if changed, `get flood.max`.
3. Test a message using the intended named scope, such as `au-vic`, from a node that is authorised and configured for that scope.
4. Test unscoped traffic separately; do not use a successful named-scope test as evidence that unscoped traffic is allowed.
5. If a scoped message stops unexpectedly, check every repeater on the path for the same region name, an allowed flood flag, and a sufficient `flood.max`.
6. If remote administration stops working, use the local serial/recovery connection and restore the documented `*`/unscoped-traffic or unscoped-hop policy.

A region name is a configuration convention, not proof that a packet came from that physical location. Treat region labels as routing scope and operational policy, and document who maintains each scope.

---

## Related pages

- [Routing Algorithm](./routing)
- [Channels & Keys](./channels-and-keys)
- [Node Roles](./node-roles)
- [MeshCore Overview](./overview)
