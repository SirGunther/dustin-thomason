# Why these changes — atlas/PRDV-16192

> The living "Why" of this ticket. Created Phase 1, updated every phase, finalized at close. High-level — scenarios live in the testing-implementation doc; point-in-time classification lives in the [investigation report](./investigations/PRDV-16192-investigation.md).

## Problem class (the core — what are we actually solving?)

**A contract/shape mismatch between two domains sharing one audit schema.**

The audit event model was designed for **file** events: one resource per event, with `resourcePath` / `path` / `bucket` describing where a file lives and what happened to it. `PERMISSIONS_UPDATED` reuses that model to carry a **permissions-diff** domain instead: N changed resource keys per save, each with an old and a new *set of actions*. The two do not fit — and the read path, written for the single-resource file case, structurally cannot represent the permissions case.

Every symptom the ticket reports is a face of that one mismatch, not three independent display bugs. See investigation report §1.

## The code at the root (what/where is the problem)

Primary — **`europa-back-end`**, `src/audits-event/domain/transaction-scripts/search-audit-events-paginated-TS/search-audit-events-paginated.transaction.script.ts`, method `toItemProjection`:

- **`:55`** — `const firstResource = event.auditEventResources?.[0];` — an event's resources are collapsed to the first one. A save changing N keys renders one row and **drops N−1 changed keys**.
- **`:58-62`** — `newState?.path ?? oldState?.path ?? resourcePath ?? ''` — nullish coalescing, so an empty string is a *hit*. When all CRUD is removed, `newState.path === ''` wins and the fallbacks (including `resourcePath`, which holds the actual resource key) are never reached.

Contributing — **`callisto-back-end`**, `.../permissions-audit-dispatcher/permissions-to-audit-event.assembler.ts:19-23`: `resourceName: roleName` (so the Resource column shows the role), `resourcePath: entry.resourceKey`, and the action lists stuffed into `oldState.path` / `newState.path`.

Render surface — **`atlas-front-end`**, `src/europa/pages/HomePage/SearchDataGrid/auditEventColumns.ts:43-48` (Path column, raw passthrough, no `format`, no body-cell slot) and `src/europa/types/audit-event.types.ts:5-19` (`SearchAuditEventItem` has no `resourcePath` field, so the resource key never crosses the wire).

Full trace: investigation report §5.

## The problems we're solving

- **P1** — The Path column cannot show old→new state; only one of the two can reach a single column, and what it holds is an action list under a column labeled "Path".
- **P2** — The row does not identify *which* resource key changed: the Resource column carries the role name, and every key after the first is dropped entirely by the read.
- **P3** — Removing all CRUD from a key renders a blank cell, and that blank also suppresses the fallbacks that would have shown the key.

## Why-log (append per phase; label each entry)

### Phase 1 — 2026-07-27 — [NEW UNDERSTANDING + COURSE CHANGE]

- **Obvious:** `resourceName: roleName` is exactly what the ticket says it is — a one-line assignment in the Callisto assembler. `[].join(', ') === ''` explains the blank cell at the emit end. Both were confirmed in minutes.
- **Not obvious (the course change):** the ticket frames all three items as *emit-side* display defects. The evidence puts the decisive failure on the **read** side, in Europa's paginated projection — a file that the ticket never mentions. Two findings drove the reframe:
  1. `auditEventResources?.[0]` means multi-key saves lose data at read time. The ticket's own proposed fix for P2 — "one entry per changed resource key" — **is already what Callisto emits**. The ticket asks for a behavior that exists, because it was looking at the wrong layer.
  2. `??` rather than `||` means the empty string doesn't just render blank, it *suppresses the fallbacks*. So P3 isn't cosmetic — it also costs you the resource key that was otherwise recoverable from `resourcePath`.
- **What got us there:** tracing the wire in the opposite direction from the ticket — grid column → Atlas type → which endpoint Atlas actually calls (`/search-paginated`, not the legacy `/search`) → that endpoint's projection. The legacy `/search` converter *does* map all resources, which is a decoy: it isn't what the grid uses.
- **The finding that changes the solution space:** the resource key **is already persisted** in `resourcePath` on every `PERMISSIONS_UPDATED` document ever written. Nothing was lost at write time. That makes a read-side fix **retroactive over all history with no backfill**, and an emit-side fix not. This reframes the cost comparison entirely.
- **Assumptions logged:** that Atlas is the only consumer of the paginated endpoint; that no Mongo migration is needed because the data is intact; that the `??`→ empty-string behavior is unintentional rather than a deliberate "prefer newState even when cleared" choice. All three carried into report §8.
- **Noise / discarded:** the Europa legacy `/search` endpoint (not consumed by the grid); the Atlas Permissions Manager page itself (it sends the full allow-set; the diff is computed backend-side, so nothing on the page contributes to the defect); Europa's SQS ingest (raw passthrough, no coercion — ruled out).
- **Adjacent discovery, same class:** `MERGED` events are multi-resource too (`case-merge-to-audit-event.assembler.ts:24`), so the `[0]` collapse is **already hiding merged files in prod today**. This is the strongest evidence that the class is the schema/read mismatch and not a permissions-specific bug — recorded in the concerns artifact.
- **Detection gap:** Callisto's own spec asserts `newState.path === ''` as correct behavior, Europa has no spec touching `newState.path`/`oldState.path` at all, and Atlas has zero coverage of the Path column. Nothing in the net could have caught this.

### Phase 2 — 2026-07-27

- Baseline corrected at user instruction: all three repos moved to `main` and the load-bearing evidence re-read there — unchanged. The Phase 1 findings stand against `main`, not a feature branch.
- Why unmoved otherwise: no new understanding this phase; Phase 2 emitted the artifacts that record the Phase 1 reframe.

### Phase 3 — 2026-07-27 — [COURSE CHANGE — scope of the phase, not of the why]

- **What changed:** the phase's purpose was redirected mid-flight. Grill-me was halted before the first question was answered; the ask became *"we're not trying to build anything… we are trying to create investigative docs so that we can actually understand the scope of the problem."* The deliverable is an artifact QA and product can use as a source of truth in a discussion, not a spec.
- **Effect on the why:** none. The problem class, the root-cause location, and the three problems are unchanged. What moved is who decides and when — the six open variables are now agenda items (D1…D6), and the fix-side call is recorded as the **investigation's recommendation** rather than a locked decision.
- **What further evidence added:** the legacy `/search` endpoint has no consumer anywhere, so that sub-question dissolved; Atlas pagination is server-side and `row-key` is per-event, which prices the per-resource row model concretely; expandable-row precedent exists in four Callisto tables, which makes "one row per event, expandable" a grounded third option rather than a guess; and the audit page has no access to the resource-key label map, which raises the cost of the label option already weakened by the collision.
- **Noise / discarded:** the idea that the legacy `/search` converter needed aligning — it looked like a live inconsistency and turned out to be dead code from a consumer standpoint.
- **Still not proven:** retroactivity is confirmed in code only. It is the single strongest argument for the recommended direction, and it rests on an unverified live-data check. Flagged in the brief under "what we have not proven" so the discussion doesn't over-trust it.

## Changes made — categorized (filled as implementation locks; subject to update)

_Not yet — implementation is Phase 5. Populated then with a headline count and Before / After / Why per change._

## Why it shipped together

_Pending — written once the change set is locked (Phase 5/6), tied to the acceptance criteria in report §3._

## Scope

_Pending Phase 3 decisions (OV-1…OV-6), chiefly: which side is fixed, the row model, and whether the `MERGED` neighbor rides along or spins off._

## Net

_Pending._

## Verified

_Pending — gates and manual evidence from the test plan and testing-implementation doc._
