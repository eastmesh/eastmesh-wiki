---
title: changelog
description: Track major changes to the wiki content and structure
published: true
date: 2026-02-21T00:00:00.000Z
tags: changelog, meta
---

# Changelog

Track major changes to the wiki content and structure.

---


## 2026-04-11

**Zensical migration cleanup across the repo**

- Removed WikiJS-only frontmatter keys (`editor`, `dateCreated`) from all Markdown pages to align metadata with the Zensical format used by this repository.
- `README`: updated platform references and clarified the standard frontmatter keys to keep for Zensical.
- `contributing`: refreshed the frontmatter template to match Zensical metadata expectations.

---

## 2026-02-21

**Content quality pass and stub expansion**

- `README`: rewritten from a short placeholder to a practical repository guide (purpose, layout, writing style, linking conventions, and contribution workflow).
- `home`: refreshed landing page structure and tone, added clearer sectioning and a terminology link for quicker navigation.
- `hardware/recommended`: expanded with role-based hardware selection guidance, improved tradeoff language, and a related pages section.
- General wording pass to make key pages read more naturally and consistently.

---

## 2026-02-19

**Content expansion pass — overview pages**

- `getting-started`: expanded with full step-by-step workflow, first validation tests, common first-time problems table, and corrected links (`rf/overview` → `radio/overview`).
- `build-guides/overview`: removed user-submission section; expanded with build type categories (companion, fixed node, rooftop repeater), design principles, testing and commissioning steps.
- `enclosures/overview`: expanded from stub to full page covering IP ratings, materials, cable glands, drip loops, moisture control, thermal management, and connector weatherproofing.
- `faq`: expanded with organised sections (setup, troubleshooting, operations, protocol questions), adding ten additional Q&A entries.
- `community/rules-and-safety`: expanded from brief bullet list to full page with detailed RF compliance, deployment safety, community conduct, and privacy sections.
- `reference/terminology`: expanded with routing terms, cryptography terms, and operations terms in addition to MeshCore and RF terms.
- `rf/overview`: updated stale stub with proper frontmatter and redirect to `radio/overview`.
- `contributing`: populated previously empty page with wiki maintenance guidelines, writing standards, frontmatter requirements, and link conventions.
- `home`: removed contribution-standard/user-submission language.
- Links: fixed all `rf/overview` references in `getting-started`, `meshcore/overview`, and `meshcore/radio-layer` to point to `radio/overview`.

---

## 2026-02-16

- Added welcome page and initial section stubs.

---

## Unreleased (initial)

- Initial wiki skeleton created.
