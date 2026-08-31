---
name: spec-review-gate-larry-adams
description: PRDV flow — deliver a story spec in the larry-adams wiki format for Larry Adams (principal dev) review; prep-only (branch + changelog + spec) then stop before coding.
metadata: 
  node_type: memory
  type: project
  originSessionId: 1ed3b51d-1b8c-4db4-991c-e1b07be10842
---

For PRDV tickets, the user's flow is: plan → grill-me refinement → author a **story spec** for review by **Larry Adams (principal dev)** → PR the spec into `larry-adams` for his review → implement only after approval. On approval to proceed the user may want a **prep-only** pass first — create the branch, scaffold the `dustin-thomason` changelog, write the spec — then **stop before any product code, tests, or commits** until an explicit go-ahead. But "submit for review" means actually pushing a branch + opening a GitHub PR against `larry-adams`, not just writing the file locally — confirm which the user means.

**Why:** the spec is a review gate for the principal dev; the user explicitly confirmed "prep only, stop before code" in one pass, then later asked to actually PR the spec for review.

**How to apply:**
- **`larry-adams` IS a push-able, PR-reviewed shared team wiki for specs** — verified via git history: merged spec PRs (e.g. `PRDV-15591 (#6)`), and the user's own prior commits there (`PRDV-15619: Add refresh-proceedings specs for review`). Do NOT treat it as read-only for specs. The one real restriction (from `.cursor/rules/ticket-changelog.mdc` / `personal-methodology.mdc`) is narrower than "read-only": never push **changelog or workflow bookkeeping files** there — only the actual product/story spec belongs in `larry-adams`, under `systems/{platform}/{feature-folder}/`, wired into `systems/README.md` and Obsidian tags/wiki-links per `AGENT.md`.
- **Model format on precedent, not just the generic template**: search `larry-adams` for the closest existing spec by the SAME author/reviewer and domain first — e.g. Larry's own bug-fix spec `PRDV-16144-users-not-able-to-add-permissions-for-cud.md` was a much better template for a small bug fix than the heavier `PRDV-15591` feature-spec shape. Do not use the personal Problem→Requirement→Solution framing in specs handed to others.
- **Before creating a branch in `larry-adams`**, check `git branch --show-current` and `git log` first — it may already be checked out to the user's own in-progress ticket branch (not `main`). Switch to `main`, `pull --ff-only`, then branch — do not disturb the existing branch.
- `dustin-thomason` keeps the **changelog** (ticket memory, session log, Plans table linking to the wiki spec) and any personal investigation docs — not the spec itself, to avoid two sources of truth.
- To find the reviewer's GitHub handle for `gh pr create --reviewer`, don't guess from display name — check `git log --follow -1 --format="%an <%ae>"` on a file that person authored (frontmatter `author:` field is a strong hint of which file to check).

See [[preserve-intentional-ux-in-defect-fixes]], [[prove-assumptions-before-fixing]].
