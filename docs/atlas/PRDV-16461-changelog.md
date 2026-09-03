# PRDV-16461 — Default collections for client deliverables

## Ticket

- **ClickUp:** [PRDV-16461](https://app.clickup.com/t/43227262/PRDV-16461)
- **Repo:** `atlas-front-end`
- **Branch:** `PRDV-16461`
- **PR:** _(link when opened)_

---

## Requirements (verbatim)

_Paste from ClickUp, spec, or the user's first description. Do not paraphrase on first capture._

> **Original Request**
> As an Ops Atlas user, I want there to be default collections for files added to the client deliverables file set, so that I don't have to manually set collections for the most common, base-case workflows.
>
> **Acceptance Criteria (as captured — see `PRDV-16461-original-ticket.md` for full text):**
> - Transcript Track → default collection **Full Transcript**; Video Track → default collection **MP4 Video**. Always the static base-case collection, never a dynamic one (Excerpt / Trial Edit). Exhibits/MVC unaffected.
> - Defaults are a front-end track → default-collection mapping (Option A); no backend/DTM config in scope. Falls back to current behavior (no pre-select) if the mapped collection isn't present, and must not error.
> - Applies to drag-and-drop uploads (reactively once track is chosen), direct uploads (pre-selected on modal open), and file approvals (pre-selected on modal open).
> - Not sticky — every new file-add action re-applies the base-case default; no cross-session memory of the last-used collection.
> - Recategorize is unaffected — existing track/collection is preserved unless the user manually changes it.
> - Deliverable-type pre-fill continues to run against the defaulted collection's eligible-types catalog (composes with AC1).
> - GCA-enabled flow only.

> **UX clarification thread (Aug 27 – ticket "Yesterday"), verbatim from ClickUp:**
>
> **Dustin Thomason** — Aug 27 at 11:12am:
> "UI/UX consideration, the collections will show automatically which will be useful, the simple quality of life idea here is someway notating that the collection was chosen for them. I've seen this before as a '\*' or '(default)' in the drop down or similar so that the user is aware that this is something that can be adjusted and has been predetermined for them. Basically a heads up is all."
>
> **Shaye Lankford** — "Yesterday" at 12:21pm:
> "@Dustin Thomason - I agree, do you have a suggestion for how you'd prefer to handle this."

---

## Context

_Optional: related tickets, environment, files to avoid, spec paths, team decisions._

- No Figma file exists for this ticket at this time.
- Shaye has agreed the pre-selected default should be visually distinguished from a user's manual choice, but has not yet named (and is asking Dustin for) the concrete mechanism — that reply has not been given in the ClickUp thread as of this capture.
- Ticket status just moved Ready For Work → In Progress (assigned to Dustin) as of this session; AC1 (the default-collection mapping itself) has not been implemented in `atlas-front-end` yet — see recon below.
- Per Dustin (this chat): he was assigned the ticket because his Aug 27 comment read as if he understood the intended user behavior — he characterizes it as "just a suggestion" that got him roped into owning the follow-through. Relevant context for why he's driving the UX-signal decision rather than Shaye or Product.

---

## Plans

_Lives in **dustin-thomason** only. Reference plans here so future agents do not repeat abandoned approaches. **Larry-adams** paths are **read-only links** to coworker specs — never create or push changelog/plan files there._

| Added | Plan (path or link) | Status | One-line approach |
| ----- | ------------------- | ------ | ----------------- |
| 2026-09-02 | Plan A — session-scoped marker (Claude's suggestion, this chat) | `active` (candidate — not yet confirmed with Shaye) | Add an `isDefaultPick`-style flag to `DeliverableTrackCollectionPickOption` that clears the moment the user makes a deliberate selection (even re-picking the same value), and render a `(default)` suffix off that flag in the `#selected-item` (closed-box) and `#option` (menu row) slots of `DeliverableFileUploadTrackSelectField.vue`. |
| 2026-09-02 | Plan B — always-on marker (Dustin's refinement, this chat) | `active` (candidate — not yet confirmed with Shaye) | Mark "default" as a static property of the option itself (independent of selection history), so the closed box shows it whenever that option happens to be selected, with no extra state to track or clear. Simpler than Plan A. |
| 2026-09-02 | ~~Default Collection Cues (claude.ai Artifact)~~ | `abandoned` | Published to a claude.ai-hosted Artifact — Dustin flagged this as a data-handling/security problem (external hosting, outside these repos), even though it defaulted to private. Do not use the Artifact tool for this ticket, or for any product/ticket mockup, going forward — see [[artifact-tool-boundary]]. |
| 2026-09-02 | [PRDV-16461-default-collection-prototype.html](PRDV-16461/PRDV-16461-default-collection-prototype.html) — decision-support prototype | `active` | Self-contained local HTML/CSS/JS file (no network calls, no publishing) living in **this repo**. One real, click-to-open Track/Collection dropdown replica with live controls for Signal (none/asterisk/text/caption/chip) × Timing (Plan A / Plan B) so Shaye can actually operate the field, not just read about it. |

**Status:**

- **active** — current direction; check here before a new plan
- **implemented** — shipped (link session log / commits); keep for history
- **superseded** — replaced by a newer plan row; do not retry without user ask
- **abandoned** — tried or rejected; see **Attempt history** for why

When a Cursor/agent **plan** is generated for this ticket, add a row the same day (path, export, or short title + where it lives). If work followed a plan only loosely, say so in **Session log** → **Plan used:**.

---

## Session log

_Newest first. Add one block before each commit (agents) or end of work session (you)._

### 2026-09-03T00:00:00Z — orchestration Phase 0 (atlas)

- **Summary:** Invoked the `orchestrate` skill for PRDV-16461 per user request ("we are going to spec this thing out regardless, the UI can be a last min decision before full implementation"). Repos aligned to `main` first: `atlas-front-end` (was on `PRDV-16403`, clean, switched) and `callisto-back-end` (was on `PRDV-16595-sqlite3-upgrade`, only line-ending noise in `.swcrc`/`notification-template-preview.html`, no real diff, switched). No `PRDV-16461` branch exists yet anywhere. Ticket folder already existed (`docs/atlas/PRDV-16461/`, non-canonical location) with `PRDV-16461-original-ticket.md` and the decision-support prototype from the prior session — user chose explicitly to keep that location rather than migrate to the skill's default `docs/atlas/tickets/<slug>/` layout; noted in `orchestration.md`.
- **Phase 0 output:** Drafted two job stories via the `job-story` sequence (Story Matrix → Revision → DAS → Concatenated → Final Review → User Story → Acceptance Criteria), split because they are materially separate concerns:
  - **Story 01 — Default collection pre-selection** (`stories/PRDV-16461-job-story-01-default-collection.md`): the core AC1–8 track→collection mapping, non-sticky reset, recategorize guardrail, and type pre-fill composition. 11 criteria, `draft`, 2 open questions — both code-discoverable (exact production collection values; whether eligible deliverable types are configured for them) rather than product decisions, deferred to the Phase 1 investigation.
  - **Story 02 — Default-selection visual indicator** (`stories/PRDV-16461-job-story-02-default-indicator.md`): the Aug 27–present UX thread (Dustin's suggestion, Shaye's "I agree" with no mechanism named yet). 4 criteria, `draft`, 2 open questions — both genuine product decisions (concrete signal mechanism; whether a deliberate re-pick of the same value still reads as "default"). Per this session's explicit instruction, this story is **not a gate** on Story 01 or the spec — it resolves last, before full implementation.
  - Scaffolded `orchestration.md` (ledger) recording the WorkLists card id `todo-1788443447379-798e4585` and Phase 0 `done`.
- **Plan used:** none new this session — existing Plan A/B rows and the prototype (table above) carry forward unchanged into Story 02's Open Question 1.
- **Files:** `stories/PRDV-16461-job-story-01-default-collection.md`, `stories/PRDV-16461-job-story-02-default-indicator.md`, `stories/PRDV-16461-job-stories-index.md`, `orchestration.md` (all new, all under `docs/atlas/PRDV-16461/`). `PRDV-16461-original-ticket.md` untouched (frozen per orchestrate rules).
- **Commits:** none — docs-only, dustin-thomason repo.
- **Notes:** Next is Phase 1 (Plan mode) — recon and investigation per the `investigation` method, starting with the two Story 01 open questions (production collection values, eligible-types config) since those are code-discoverable, not product decisions.

### 2026-09-02 — atlas-front-end

- **Summary:** Parsed the ClickUp comment thread to locate Dustin's Aug 27 UX suggestion and Shaye's "I agree" reply (both captured verbatim above). Shaye agreed with the problem (a pre-selected default collection looks identical to a manually-chosen one) but has not yet named a mechanism — he's asking Dustin for one. Did a codebase recon in `atlas-front-end` for where AC1 (track → default-collection pre-selection) and this UX indicator would attach. No branch exists yet for this ticket (current repo branch is `PRDV-16403`, an unrelated ticket).
- **Plan used:** Plans row above (candidate, not yet confirmed)
- **Files (recon only — nothing modified):**
  - `src/callisto/pages/JobProceedingPages/ProceedingDetailPage/components/DeliverableFileUploadForm/composables/useDeliverableFileUploadForm.ts` — builds `DeliverableTrackCollectionPickOption[]` (`buildPickOptions`); has `rowKind`/`label`/`disable` etc. but **no default-collection or "is default" concept yet** — AC1 itself isn't implemented.
  - `src/callisto/pages/JobProceedingPages/ProceedingDetailPage/components/DeliverableFileUploadForm/components/DeliverableFileUploadTrackSelectField.vue` — the actual `q-select` combining track+collection into one "pick"; `#selected-item` slot (closed box, ~line 53) and `#option` template (menu rows, ~line 93) are where a "(default)" marker would render.
  - `src/callisto/pages/JobProceedingPages/ProceedingDetailPage/components/DeliverableFileUploadForm/DeliverableFileUploadForm.vue` — hosts the field for both drag-and-drop/direct-upload and recategorize modes (recategorize must **not** get the marker — AC says it's unaffected).
  - `src/callisto/pages/JobProceedingPages/ProceedingDetailPage/components/DeliverableFileUploadForm/composables/trackCollectionOptionLabels.ts` — existing label-building helper; likely where a default-collection map would live per Option A in the AC.
- **Commits:** none
- **Notes:** Before implementation: still need Shaye's/Product's sign-off on the actual visual treatment (asterisk vs. "(default)" text vs. tooltip) and on whether the marker persists if a user manually re-selects the same default value. Recommend replying in the ClickUp thread with the concrete proposal below rather than leaving it open.

**Later same session:** Dustin flagged that my prior write-up referred to him in the third person ("Dustin's wording") as if he were a separate party from the user in this chat — he is the ticket assignee and the Aug 27 commenter; corrected going forward. He then asked to turn the two competing marker/timing ideas (his ClickUp original, his in-chat refinement, the current no-signal baseline, plus anything neither of us had raised) into a visual comparison for Shaye rather than resolving it over more chat back-and-forth — Shaye is the product manager who'll make the call. First attempt published this as a claude.ai Artifact with staged "simulate" buttons — Dustin rejected both the hosting choice (flagged as a security/data-handling problem: content pushed outside these repos, regardless of the artifact defaulting to private) and the interaction quality (buttons + captions describing behavior, not a real operable control). Rebuilt as `PRDV-16461/PRDV-16461-default-collection-prototype.html`: a single self-contained file, zero external network calls, saved directly in this repo. It's one genuinely functioning replica of the Track/Collection `q-select` — click it, it opens, lists the track's real collections, clicking one selects it — with live Track / Signal / Timing controls layered on top so Shaye operates the actual field under whichever combination he's comparing, plus a "Reopen modal" control that demonstrates the non-sticky-default behavior from the AC. Visual tokens still pulled from `quasar.variables.scss` / `pd.variables.scss` / `DeliverableFileUploadForm.module.scss`, not invented. No Artifact tool used this time; see [[artifact-tool-boundary]] for the standing rule going forward.

---

## Root cause analysis

_Optional — fill when debugging._

---

## Attempt history

_Optional — one subsection per failed or partial approach._

### Attempt 1 — short label (commit `abc1234` optional)

**What:**

**Result:**

---

## Key technical learnings

1. 

---

## Current state (as of 2026-09-02)

_What is merged / on branch / reverted / still pending._

- No branch, no code, no spec exist yet for this ticket. Everything is at the ClickUp-discussion stage.
- AC1's core mapping (Transcript→Full Transcript, Video→MP4 Video pre-selection) is **not implemented** in `atlas-front-end`.
- Open UX question (default-selection indicator) is agreed-in-principle by Shaye but has no confirmed mechanism yet. A decision-support prototype now exists locally in this repo (`docs/atlas/PRDV-16461/PRDV-16461-default-collection-prototype.html` — see Plans table) for Dustin to send Shaye directly (e.g. as an email/Slack attachment); once Shaye picks a signal + timing combination, update this section and promote the winning Plan row to reflect the confirmed direction before implementation starts.

---

## New code introduced

_Optional — new modules, composables, endpoints._


