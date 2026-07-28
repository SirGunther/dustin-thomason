# Test plan — atlas/PRDV-16192

> Seeded from [PRDV-16192-investigation.md](../investigations/PRDV-16192-investigation.md) §9 on 2026-07-27. Refined by spec: pending (Phase 3).

Status: **seeded**

## Scope and surfaces under test

- **Behavior being proven:** a `PERMISSIONS_UPDATED` audit entry in the Europa grid identifies every resource key changed in a save, shows each key's old→new permission state, and renders something meaningful when a key's permissions are cleared entirely — including for entries written before the fix.
- **Surfaces:** `europa-back-end` `SearchAuditEventsPaginatedTS.toItemProjection` + its projection/DTO/responder chain (`GET /audit-events/search-paginated`); `atlas-front-end` `src/europa/types/audit-event.types.ts`, `SearchDataGrid/auditEventColumns.ts`, `SearchDataGrid.vue`, `useColumnOrderSettings.ts`; `callisto-back-end` `PermissionsToAuditEventAssembler` **only if** OV-1 puts work on the emit side.
- **Not under test:** Europa SQS ingest, Mongo storage, the Permissions Manager page's save payload, Europa API authorization. All ruled out or out of scope in the report.

> Several scenarios below are **gated on Phase 3 decisions** (OV-1…OV-5) and are marked `[gated]`. They become concrete assertions at the refine step; they are recorded now so the decision cannot quietly drop them.

## Happy path

- [ ] **HP-1** — Role with existing permissions on ≥2 keys → in Atlas `/permissions`, add `update` to Transcript Track and clear all CRUD from Video Track in **one** save → the Europa grid represents **both** changed keys (AC1).
- [ ] **HP-2** — Same entry → each changed key is identifiable, distinctly from the role name (AC2).
- [ ] **HP-3** — Same entry → for each changed key, both the prior and resulting action sets are readable (AC3).
- [ ] **HP-4** — Same entry → the cleared key renders a meaningful value, not an empty cell (AC4).
- [ ] **HP-5 (retroactivity)** — An entry created **before** the change reads the same way afterwards, with no migration or backfill run. This is the central claim of the read-side approach; if it fails, the approach is wrong.
- [ ] **HP-6** — Single-key save still reads correctly (no regression from the multi-key work).

## Negative paths

- [ ] **NP-1** — No-op save (nothing actually changed) → **no event is emitted at all** (`permissions-matrix.service.ts:41` gates on `diff.length > 0`) → no new grid row. Guards against "improve the display by emitting more".
- [ ] **NP-2 (neighbour)** — `LOGIN` and `LOGOUT` entries (`oldState: null`, `newState: null`) render byte-identically to today (AC5).
- [ ] **NP-3 (neighbour)** — `PROCEEDING` entries (`newState: { value }`, **no `path` key**, `oldState: null`) still fall through to `resourcePath` and render identically (AC5). Highest-risk neighbour for a naive fallback-chain edit.
- [ ] **NP-4 (neighbour)** — Single-resource `FILE` entries (`case-file`, `proceeding-file`, `job-submission`) with real file paths render identically (AC5).
- [ ] **NP-5** — `MERGED` (multi-resource) entries: either deliberately fixed or deliberately unchanged per OV-5 — **asserted either way**, never changed by accident. `[gated on OV-5]`
- [ ] **NP-6** — A queue/dispatch failure must not corrupt the grid: the permission change persists and the audit row is simply absent (existing fire-and-forget behavior; asserting it is unchanged, not fixing it — see concerns).
- [ ] **NP-7** — Malformed/legacy resource shapes (missing `resourcePath`, missing `oldState`) must not throw in the projection; they degrade to today's behavior.

## Edge cases

- [ ] **EC-1** — Every CRUD action removed from **every** changed key in one save (all resources cleared) → still legible; no row collapses to blank.
- [ ] **EC-2** — A brand-new key (no prior permissions) → `oldState.path === ''` → the "added" direction reads meaningfully, mirroring EC-1's "removed" direction. Callisto already emits this (`assembler.spec.ts:214-231`).
- [ ] **EC-3 (scale)** — A `MERGED` event with many resources (file count is unbounded) → the page does not blow up and pagination stays honest. This is the concrete risk behind OV-2. `[gated on OV-2/OV-5]`
- [ ] **EC-4 (pagination)** — Mixed set of events with differing resource counts → `totalItems` / `totalPages` / `hasNextPage` describe what the user actually pages through (AC6). `[gated on OV-2]`
- [ ] **EC-5 (persisted UI state)** — A user whose `localStorage` `europa-audit/column-settings` predates any new column still sees a working grid, and the new information is not silently invisible to them. `[gated — only if a new column is added]`
- [ ] **EC-6** — Sorting and filtering are unaffected: `path` is not indexed and not in `audit_search_text_index` (`audit-event.entity.ts:28-57`), so no sort/filter behavior should move.

## Red→green regression test (the durable guard)

- [ ] **RG-1** — Europa spec for `toItemProjection`: **one event, two resources**, where `resources[0]` has `newState.path = ''`, `oldState.path = 'read, update'`, `resourcePath = 'SUBMISSION_PROCEEDING_FILES_TRANSCRIPT'`, and `resources[1]` carries a second key. **Must fail on `main`** (one item, blank path, second key absent, resource key nowhere) and pass on the branch. This single spec encodes P1, P2 and P3 at once.

## Test map

| Repo | Suite | Asserts |
| --- | --- | --- |
| europa-back-end | `.../search-audit-events-paginated-TS/__specs__/search-audit-events-paginated.transaction.script.spec.ts` | RG-1; multi-resource representation; empty-string handling; neighbour shapes NP-2/NP-3/NP-4/NP-7; pagination EC-4 |
| europa-back-end | `.../actions/search-audits-paginated/__specs__/search-audits-paginated.responder.spec.ts` | New field(s) survive the responder unchanged |
| europa-back-end | `.../application/converters/__specs__/audit-event-to-search-response-dto.converter.spec.ts` | Legacy `/search` parity, only if OV-1 aligns it |
| atlas-front-end | `src/europa/pages/HomePage/SearchDataGrid/__specs__/auditEventColumns.spec.ts` *(new — none exists today)* | Column definition, formatting, empty-state render |
| atlas-front-end | `src/europa/pages/HomePage/SearchDataGrid/__specs__/SearchDataGrid.spec.ts` *(new — none exists today)* | Row rendering incl. the cleared-permissions case; EC-5 |
| callisto-back-end | `.../permissions-audit-dispatcher/__specs__/permissions-to-audit-event.assembler.spec.ts` | **Existing assertion `newState.path === ''` (line 211) must be revisited** — it currently ratifies the defect. `[gated on OV-1]` |

## Gates

| Gate | Command |
| --- | --- |
| audit | `npm audit --audit-level=high` (per repo touched) |
| lint | `npm run lint` (per repo touched; atlas also `npm run lint:fix` when autofix helps) |
| tests — europa / callisto (Jest) | `npm test -- --runInBand` |
| tests — atlas (Vitest, non-watch) | `npx vitest run --maxWorkers 1` |
| types — atlas | `vue-tsc` type-check (per the PRDV-14055 precedent, vitest alone did not catch type errors) |

## Manual verification recipe

Preconditions: a role holding `ATLAS_PERMISSIONS_MANAGER:update`; a target role with permissions on ≥2 resource keys; Callisto + Europa running with SQS wired (dispatch is fire-and-forget — a broken queue fails silently). **No feature flag.** Local runbooks: [callisto-local](../../local/callisto-local.mdc), [europa-local](../../local/europa-local.mdc).

## Results log (filled at execution)

| Date | Gate/Scenario | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- | --- |
