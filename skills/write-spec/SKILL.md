---
name: write-spec
description: Create or update epic/story specs and dev notes for Callisto/Atlas. Use when the user asks to write a spec, author PRDV ticket documentation, create a dev note for estimation, or extend specs under a systems/ wiki tree.
---

# Write spec

Guided workflow for authoring PRDV specs. Pair with **grill-me** (`.cursor/skills/grill-me/SKILL.md`) when design decisions are unresolved — grill first, then write with resolved decisions and open-questions tables.

## Canonical references (read before writing)

| Topic | Source |
| ----- | ------ |
| Naming, frontmatter, Obsidian wiring, dev notes, author checklist | [docs/wiki-spec-authoring.md](../../../docs/wiki-spec-authoring.md) |
| Spec sections 1–8, cross-cutting callouts | [spec-writing.mdc](../../rules/spec-writing.mdc) |
| Problem → Requirement → Solution framing | [problem-requirement-solution.mdc](../../rules/problem-requirement-solution.mdc) |
| Ticket memory, Plans, session log | `docs/<system>/PRDV-XXXXX-changelog.md` |

## When to use

- User provides a PRDV ticket and wants a story or epic spec
- User asks for a dev note for refinement/estimation
- User asks to update an existing spec to match implementation or conventions
- User says "write the spec" for wiki (`systems/`) or app-repo spec folders

## Workflow

1. **Read [docs/wiki-spec-authoring.md](../../../docs/wiki-spec-authoring.md)** — naming, frontmatter, Obsidian checklist, dev note template, author checklist.
2. **Read [spec-writing.mdc](../../rules/spec-writing.mdc)** — sections 1–8 and optional callouts.
3. **Resolve changelog** — read `docs/<system>/PRDV-XXXXX-changelog.md` when the ticket is active; add or refresh a **Plans** row with the spec path when done.
4. **Gather inputs** — ClickUp/product description, acceptance criteria, scope boundaries, companion tickets.
5. **Explore codebase** when the spec must reflect as-built architecture (do not assume outdated wiki content).
6. **Confirm target path** — wiki specs go under `systems/{platform}/{feature-folder}/`; app-repo specs follow that repo's folder convention. If unclear, ask once.
7. **Pick a reference spec** — search the workspace for a comparable `PRDV-*` story under `systems/` and match complexity/style (narrative + companions, full sections + open questions, or as-built correction).
8. **Write the spec** at `systems/{platform}/{feature-folder}/PRDV-#####-{description}.md` (or the confirmed app-repo path).
9. **Complete Obsidian wiring** per wiki-spec-authoring — tags, wiki-links, `systems/README.md` index, bidirectional companion links.
10. **Write dev note** (`PRDV-#####-dev-note.md`) when estimation is needed; link spec ↔ dev note.
11. **Update changelog** — **Plans** row with spec path; session log when this session also ships app-repo changes.
12. **Run the author checklist** in wiki-spec-authoring before finishing.

## Spec structure reminders

- Product story + acceptance criteria at the top
- Summary with scope table (in / out of scope)
- Problem → Requirement → Solution narrative
- Resolved decisions + open questions tables when design was negotiated
- Sections 1–8 from spec-writing (N/A with reason when not applicable)
- Cross-cutting: HTTP surface, registries, ports, spec tests, complexity flags, point estimate

## Dev note reminders

- High-level only — enough for refinement, not a duplicate of the full spec
- Link to full spec with wiki-link
- Estimate band (Small / Medium / Large) with one-sentence justification

## Do not

- Depend on another workspace repo for conventions — everything above lives in **dustin-thomason**
- Use relative markdown paths for internal vault links — use Obsidian wiki-links
- Skip `systems/README.md` index entries for new specs or dev notes
- Put ticket changelogs under `systems/` — changelogs stay in `docs/<system>/` only
