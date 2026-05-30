# Agent Skills — Evaluation Log

This document records which third-party "agent skills" were evaluated for the
FoodMap project, what each one is, and whether it is useful for a **native iOS
(Swift / SwiftUI) Clean-Architecture** codebase. It exists so the evaluation is
visible and auditable rather than living only in chat history.

| Skill | Type | License | Useful for FoodMap? |
| --- | --- | --- | --- |
| [pbakaus/impeccable](https://github.com/pbakaus/impeccable) | Web front-end design skill | — | ❌ No |
| [twostraws/Swift-Agent-Skills](https://github.com/twostraws/Swift-Agent-Skills) | Curated directory of Swift/Apple skills | MIT | ✅ Yes (as a catalogue) |
| [itgoyo/awesome-agent-skills](https://github.com/itgoyo/awesome-agent-skills) | Bilingual "awesome" list of general skills | CC BY 4.0 | ⚠️ Marginal |

## 1. pbakaus/impeccable — ❌ not applicable

A design-quality skill that audits **web** front-ends (HTML/CSS/JSX/Astro/
Svelte/Vue). Running `npx impeccable detect FoodMap` returns `[]` — it does not
recognise SwiftUI sources because it only scans web markup/styles. It provides
no value for a native iOS app and was **not installed**.

## 2. twostraws/Swift-Agent-Skills — ✅ useful as a catalogue

This is **not a single installable skill**. It is a curated index maintained by
Paul Hudson (Hacking with Swift) that links out to individual, separately
installable Swift/Apple skills, e.g.:

- SwiftUI Pro, SwiftData Pro, Swift Concurrency
- Swift Testing, Accessibility
- App Store / release helpers, Architecture
- iOS Code Audit, iOS Simulator skill, Figma-to-SwiftUI

**Relevance:** high. Several of these map directly onto FoodMap's stack
(SwiftUI, SwiftData, Swift Concurrency, Swift Testing, Accessibility). They are
recommended as **opt-in** additions when working on the matching area; none is a
hard dependency. Adopt individual skills from the list on demand rather than
"installing the list".

## 3. itgoyo/awesome-agent-skills — ⚠️ marginal

A bilingual (EN/CN) awesome-list cataloguing popular agent skills across
categories: standalone skills, Claude Code optimisation, MCP servers,
frameworks, and tooling. Content skews toward web, marketing, and
general-purpose MCP integrations, with little iOS-specific material. Useful as
general background reading; **low direct relevance** to this codebase compared
with the twostraws catalogue.

## Decision

- Keep relying on the in-repo VS Code subagents under `.github/agents/`
  (coordinator + specialists) as the primary workflow.
- Treat `twostraws/Swift-Agent-Skills` as the go-to catalogue when a focused
  Swift/SwiftUI/SwiftData/Testing/Accessibility skill is wanted.
- `impeccable` and `itgoyo/awesome-agent-skills` are **not** adopted.
