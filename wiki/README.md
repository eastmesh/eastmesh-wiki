---
title: README
description: How this repository is structured and how to contribute wiki content
published: true
date: 2026-02-21T00:00:00.000Z
tags: meta, docs
---

# MeshCore wiki content repository

This repository stores the Markdown source for the EastMesh Zensical wiki content.

If you only need the docs, browse the folders and open the relevant pages directly. If you want to contribute, this file explains the conventions used in this repo.

---

## What this repo is for

- Keep wiki content versioned in Git
- Make edits reviewable and reversible
- Encourage consistent structure and cross-linking between pages

This is content-first documentation, not firmware source code.

---

## Repository layout

Folder names map to wiki sections:

- `meshcore/` — protocol and firmware internals
- `hardware/`, `power/`, `radio/`, `enclosures/`, `build-guides/` — practical deployment guidance
- `community/` — safety, conduct, and community-facing information
- `reference/` — glossary/terminology-style content
- Root pages (`home.md`, `index.md`, `faq.md`, etc.) — top-level navigation and onboarding

---

## Writing style guidelines

Use a practical, conversational technical tone:

- Prefer clear recommendations over rigid mandates
- Explain tradeoffs when there is no single best answer
- Avoid jargon where plain language works
- Use headings and short bullet lists so pages are easy to scan on mobile

When making technical claims, include enough context that a new operator can verify the advice (for example, expected voltage ranges, antenna placement constraints, or packet behavior).

---

## Link and formatting conventions

- Use relative links between pages, e.g. `[Power & Solar](./power/overview)`
- Keep page titles concise and human-readable
- Add a short “Related pages” section at the bottom of major guides
- Use consistent Zensical frontmatter keys: `title`, `description`, `published`, `date`, and `tags`

---

## Contribution workflow (recommended)

1. Edit or add Markdown pages.
2. Check links and obvious formatting issues.
3. Update `changelog.md` when content meaningfully changes.
4. Open a PR with a concise summary of what changed and why.

Small typo fixes usually do not need a detailed changelog entry. Structural or content changes should.
