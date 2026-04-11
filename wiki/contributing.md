---
title: contributing
description: How to maintain and improve this wiki
published: true
date: 2026-02-19T00:00:00.000Z
tags: contributing, wiki, maintenance
---

# Contributing to the Wiki

How to keep this wiki accurate, useful, and well-maintained.

---

## What belongs in this wiki

This wiki documents the eastmesh.au MeshCore network and its practical operation. Appropriate content includes:

- Protocol documentation that is accurate to the current firmware
- Deployment guidance that has been tested and verified
- Troubleshooting procedures based on real failure modes
- Hardware information for supported devices
- Operations standards and processes

Content should be specific and actionable. Vague guidance ("it depends") should be avoided where a concrete answer is possible.

---

## What to check before editing

Before making significant changes to a page:

1. **Read the existing content in full** — understand what is already there before adding or changing anything
2. **Check accuracy against the current firmware** — the MeshCore source is the ground truth for protocol and firmware details; do not document how things should work, document how they do work
3. **Check that links work** — broken links reduce the usefulness of every page they appear on

---

## Writing standards

### Language and tone

- Write in clear, direct prose — avoid padding and filler phrases
- Use the second person ("you") for instructions and guides
- Use present tense for descriptions of how things work
- Use active voice; avoid passive constructions where the actor is known

### Structure

- Use `##` and `###` headings to break pages into logical sections
- Keep pages focused on their stated topic; if content belongs on another page, link there rather than duplicating it
- Tables are appropriate for comparison data, parameter references, and option lists
- Code blocks for CLI commands, packet formats, config values

### Technical accuracy

- Include units and ranges (e.g., "−123 dBm", "SF7–SF12", "3.7 V nominal") rather than vague descriptions
- Cross-reference related pages using relative links (e.g., `[Power & Solar](./power/overview)`)
- If something is uncertain or known to vary by hardware/firmware version, say so explicitly

---

## Frontmatter

Every page should include the standard Zensical frontmatter used in this repo:

```yaml
---
title: page-slug
description: One sentence description for search and previews
published: true
date: YYYY-MM-DDT00:00:00.000Z
tags: relevant, tags
---
```

Update the `date` field when making significant content changes.

---

## Updating the changelog

After making significant changes to one or more pages, add an entry to [changelog.md](./changelog) under the current date:

```
## YYYY-MM-DD
- Brief description of what changed and which page(s) were affected
```

---

## Link conventions

- Use relative links for internal wiki pages: `[Page Title](./path/to/page)`
- From subdirectories, use `../` to navigate up: `[FAQ](../faq)`
- Check that linked pages exist before adding a new link

---

## Related pages

- [Changelog](./changelog)
- [Home](./home)
