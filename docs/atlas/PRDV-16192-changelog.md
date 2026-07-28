# PRDV-16192 — Europa permission change improvements (PERMISSIONS_UPDATED audit clarity)

## Ticket

- **ClickUp:** [PRDV-16192](https://app.clickup.com/t/43227262/PRDV-16192)
- **Repo:** _TBD — resolved in Phase 1. Ticket is "Europa permission change improvements" filed under ClickUp project "Atlas Maintenance"; candidate repos are the emitter of `PERMISSIONS_UPDATED` (callisto / atlas permissions page) and the Europa audit-log viewer (`europa-back-end`)._
- **Branch:** `PRDV-16192`
- **PR:** _(link when opened)_

---

## Requirements (verbatim)

_Verbatim from the ClickUp Description and QA Notes as captured at `docs/atlas/PRDV-16192/PRDV-16192-original-ticket.md`. The `Dev Note:` heading was captured with no body — see Capture Gaps in that artifact._

> ## Description:
>
> 1. ****Path column**** doesn't clearly show old/new permission state per resource key (behavior was described in dev notes but never formally AC'd).
>
> 2. ****No resource key indicator**** — when multiple resource keys change in one save (e.g., transcript track + video track), the audit entry doesn't tell you ** which** resource key changed. The `resourceName` is set to the role name, not the resource key.
>
> 3. ****Empty state on full removal**** — when all CRUD permissions are removed from a resource key, `newState.path` is empty string, which renders as blank in Europa. UX-wise it should say something meaningful.
>
> ## QA Notes:
>
> - PERMISSIONS_UPDATED event Path column shows correct old and new permission state for each changed resource key
>
> There is no explicit AC that states this. It comes entirely from the dev notes:
>
> From the event shape example in the dev notes:
>
> - `"oldState": { "path": "read" }` and `"newState": { "path": "read, update, delete" }`
>
> And from the field descriptions:
>
> - `"oldState.path = comma-separated actions the resource key had before this save"` and `"newState.path = comma-separated actions the resource key has after this save"`
>
> This is exactly the pattern the AC review prompt is designed to catch — the story has almost no user-facing ACs at all. The entire testable behaviour is described in the dev notes and design decisions section, not in formal ACs. The "Goals" section mentions `"oldState / newState as human-readable action lists (e.g. "read" → "read, update, delete")"` which is the closest thing to an AC, but it's written as a technical goal, not a user-facing acceptance criterion.
>
> 2. there is no indicator of what exact module permissions was updated. If you added some permissions to transcript track and video track - you still see this: I would recommend adding some info about changed module or *Changing multiple resource keys in one save produces one PERMISSIONS_UPDATED event with one entry per changed resource key*
>
> 3. When removing all CRUD there is no info - from UX perspective it is better to say something like 'removed create-read'
>
> ## Dev Note:

---

## Context

_Optional: related tickets, environment, files to avoid, spec paths, team decisions._

- **Orchestrated ticket** — full seven-phase run; ledger at `docs/atlas/PRDV-16192/orchestration.md`. All artifacts live under `docs/atlas/PRDV-16192/`.
- **Origin:** created as a future improvement to [PRDV-15840 — [BE] Publish permission change to Europa and Permissions page update](https://app.clickup.com/t/43227262/PRDV-15840) (Anastasiya Savchuk, Jul 2), which is already deployed to prod. No PRDV-15840 changelog or artifacts exist in this repo.
- **Team note (Kat Giangiulio, Jul 16):** "The solution may need to be discussed with IT."
- **Assignment (Kat Giangiulio):** sprint addition, co-engineered by Dustin Thomason & Svitlana Pshenychna while Lana is out July 3 – August 3.
- **Sprint points:** 5. Priority: Low. Status at capture: READY FOR WORK.
- **Open at Phase 0:** which repo owns the emit (`resourceName`, `oldState.path`, `newState.path`) vs the render (Europa Path column); whether the referenced dev notes live on this ticket or PRDV-15840.

---

## Plans

_Lives in **dustin-thomason** only. Reference plans here so future agents do not repeat abandoned approaches. **Larry-adams** paths are **read-only links** to coworker specs — never create or push changelog/plan files there._

| Added | Plan (path or link) | Status | One-line approach |
| ----- | ------------------- | ------ | ----------------- |
| 2026-07-27 | Phase 1 investigation plan — `~/.claude/plans/validated-herding-petal.md` (orchestrate run) | `implemented` | Execute the investigation method against the three repos and emit the Phase 2 artifacts; **outcome: reclassified** from three display defects to one audit read-path contract mismatch. |
| 2026-07-27 | Investigation report §10 recommendation — [`investigations/PRDV-16192-investigation.md`](./PRDV-16192/investigations/PRDV-16192-investigation.md) | `active` | Fix the read side (Europa paginated projection → Atlas column) rather than the emit side: matches the confirmed class, is retroactive over stored data because `resourcePath` already holds the resource key, and fixes the `MERGED` neighbour. Gated on OV-1 (fix side) and OV-2 (row model). |

**Status:**

- **active** — current direction; check here before a new plan
- **implemented** — shipped (link session log / commits); keep for history
- **superseded** — replaced by a newer plan row; do not retry without user ask
- **abandoned** — tried or rejected; see **Attempt history** for why

When a Cursor/agent **plan** is generated for this ticket, add a row the same day (path, export, or short title + where it lives). If work followed a plan only loosely, say so in **Session log** → **Plan used:**.

---

## Session log

_Newest first. Add one block before each commit (agents) or end of work session (you)._

### 2026-07-27T19:25:00Z — dustin-thomason (orchestration Phases 1–3, investigation deliverable)

- **Summary:** Ran the investigation end-to-end across `europa-back-end`, `callisto-back-end` and `atlas-front-end`, and **reclassified the ticket**: the three reported display defects are one contract/shape mismatch, and the decisive code is in Europa's paginated read projection — not in Callisto, where the ticket points. Key consequence: the resource key is already stored in `resourcePath` on every historical event, so a read-side fix is retroactive with no backfill. Also found that the ticket's own proposed remedy for item 2 already ships (Callisto emits one entry per changed key; the read discards all but the first), and that the same line already truncates `MERGED` events in prod. Emitted the full Phase 2 artifact set. **Phase 3 was redirected by the user mid-flight** — grill-me halted, no build decision taken; produced a QA/product-facing discussion brief instead, with the six open variables restated as agenda items D1…D6 for a discussion on 2026-07-28.
- **Plan used:** Phase 1 investigation plan (`~/.claude/plans/validated-herding-petal.md`) → `implemented`; investigation report §10 recommendation → `active`.
- **Files:** `docs/atlas/PRDV-16192/` — `PRDV-16192-discussion-brief.md` (new), `investigations/PRDV-16192-investigation.md` (new, + §13 addendum), `investigations/PRDV-16192-coverage-ledger.md` (new), `investigations/PRDV-16192-diagrams.md` (new), `testing/PRDV-16192-test-plan.md` (new, seeded), `PRDV-16192-why-these-changes.md` (new), `PRDV-16192-future-development-concerns.md` (new), `PRDV-16192-pr-draft.md` (new, unfilled shell), `orchestration.md` (updated), `PRDV-16192-original-ticket.md` (downstream links + capture-gap resolution).
- **Commits:** _(none yet — docs repo, uncommitted)_
- **Notes:** **No implementation-repo file was touched.** All three repos were moved to `main` and pulled at user instruction (atlas `102e034d`, callisto `47f5a841`, europa `af49e79`) and the load-bearing evidence re-verified there — unchanged. Two pre-existing audit-reliability defects were discovered and consciously left out of scope (silent fire-and-forget audit loss; concurrent-save diff race), both recorded with evidence and sequence diagrams. One assumption remains confirmed-directionally: retroactivity is proven in code but not against live Mongo data — flagged in the brief as the check to run before relying on it.
- **Conflicts / exceptions:** Tooling gates (audit / lint / tests) — **not applicable**: this session changed only Markdown under `docs/` in `dustin-thomason`, which has no `package.json` at the repo root and no code under test. No API surface touched. No production code read-modified in any app repo.

### 2026-07-27T18:20:00Z — dustin-thomason (orchestration Phase 0)

- **Summary:** Phase 0 (Capture) of the `orchestrate` skill. A prior session had captured the ClickUp ticket to a loose file at `docs/atlas/PRDV-16192-original-ticket.md`; this session relocated it into the canonical ticket folder `docs/atlas/PRDV-16192/` via `git mv` (Original Request untouched), completed the artifact's Explicit Constraints / Context Paths / Downstream Artifacts sections, added a Capture Gaps table for the empty `Dev Note:` body, scaffolded `orchestration.md`, and scaffolded this changelog with verbatim requirements.
- **Plan used:** none — capture phase.
- **Files:** `docs/atlas/PRDV-16192/PRDV-16192-original-ticket.md` (moved + sections filled), `docs/atlas/PRDV-16192/orchestration.md` (new), `docs/atlas/PRDV-16192-changelog.md` (new).
- **Commits:** _(none yet)_
- **Notes:** No implementation-repo file touched. Folder convention follows the atlas precedent `docs/atlas/PRDV-XXXXX/` (PRDV-14055), not the skill's generic `docs/<Project>/tickets/<slug>/`. Next: Phase 1 — Investigate (Plan mode).

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

## Current state (as of 2026-07-27)

_What is merged / on branch / reverted / still pending._

- **Phases 0–2 done; Phase 3 redirected to an investigation deliverable.** Ticket captured verbatim; full investigation artifact set emitted under `docs/atlas/PRDV-16192/`.
- **Ticket reclassified.** Not three display defects — one contract/shape mismatch in Europa's audit read path. Recommended direction (agent, not locked): fix the read side, because it is the only option that closes all three problems, it is retroactive over all history, and it fixes the `MERGED` truncation as a by-product.
- **Nothing implemented.** No branch in any app repo; no implementation-repo file touched. Spec and locked-decision ledger deliberately deferred.
- **Blocked on a decision, not on work:** D1 (fix side) and D2 (row model) must be settled in the 2026-07-28 discussion before a spec is written. See [`PRDV-16192-discussion-brief.md`](./PRDV-16192/PRDV-16192-discussion-brief.md).
- **One open evidence item:** confirm `resourcePath` is populated on a real `PERMISSIONS_UPDATED` document in a live environment — the retroactivity argument depends on it and it is currently proven in code only.

---

## New code introduced

_Optional — new modules, composables, endpoints._


