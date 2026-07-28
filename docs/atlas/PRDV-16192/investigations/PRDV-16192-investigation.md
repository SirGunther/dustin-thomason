# Investigation Report: PERMISSIONS_UPDATED audit entries are unreadable in the Europa grid

> Emitted at Phase 2 of the `orchestrate` run for PRDV-16192. Companion artifacts: [coverage ledger](./PRDV-16192-coverage-ledger.md) · [diagrams](./PRDV-16192-diagrams.md) · [test plan](../testing/PRDV-16192-test-plan.md) · [why these changes](../PRDV-16192-why-these-changes.md) · [future-development concerns](../PRDV-16192-future-development-concerns.md)

## Metadata

- **Status:** done (investigation); Phase 3 pending
- **Disposition:** **proceed with conditions** — the cause is proven and the fix direction is clear, but the row model and the fix side are open decisions (§10)
- **Date:** 2026-07-27
- **Owner:** Dustin Thomason (co-engineered with Svitlana Pshenychna)
- **Location:** `docs/atlas/PRDV-16192/investigations/PRDV-16192-investigation.md`
- **Ticket:** [PRDV-16192](https://app.clickup.com/t/43227262/PRDV-16192) — spun off [PRDV-15840](https://app.clickup.com/t/43227262/PRDV-15840) (in prod)
- **Domain:** software
- **References / evidence:** `europa-back-end` @ `af49e79` (main) · `callisto-back-end` @ `47f5a841` (main) · `atlas-front-end` @ `102e034d` (main). All three re-verified on `main` after the Phase 1 baseline was corrected off feature branches.

---

## 0. Verdict (bottom line up front)

The three complaints in the ticket are **one defect wearing three faces**, and the decisive code is **not where the ticket points**. The ticket describes emit-side problems in Callisto; the load-bearing failure is in **Europa's paginated read projection**, which collapses an event's resources to `auditEventResources[0]` and resolves the Path value with `??` so an empty string beats every fallback. The single most consequential finding: **the resource key is already persisted in `resourcePath` on every `PERMISSIONS_UPDATED` document ever written** — nothing was lost at write time, so a read-side fix repairs all historical entries with no migration or backfill. A pre-existing neighbour of the same class (`MERGED` events, also multi-resource) is already broken in prod by the same line.

- **Strongest path:** fix the read side (Europa projection → Atlas column), because it matches the confirmed class, is retroactive over stored data, and fixes the `MERGED` neighbour as a by-product. A narrow emit-side correction may ride along; see §7 and OV-1. **Recorded as the investigation's recommendation on 2026-07-27** at the user's instruction (grill-me halted; the open variables become agenda items for a QA/product discussion rather than agent-asked questions) — see §13 and the [discussion brief](../PRDV-16192-discussion-brief.md). It is a recommendation, **not a locked decision**.
- **Not yet proven / not approved:** this is **not** an implementation approval. The row model (one grid row per event vs per resource) has a real pagination consequence and is unresolved (OV-2); the label-vs-raw-key question has a discovered blocker (§10, OV-3); and no code has been written or run. Whether "discuss with IT" (ticket Activity, Jul 16) gates the work is also unanswered (OV-6).

## 1. Problem class

- **Class the request assumed:** three independent UI/UX display defects in the Europa audit entry — fix by improving what is written to the event or shown in the cell.
- **Confirmed class:** **a contract/shape mismatch — a file-oriented audit schema (`resourcePath` / `path` / `bucket`, one resource per event) reused to carry a permissions-diff domain (N changed keys, each with old→new action sets), read by a projection written for the single-resource file case and structurally unable to represent the permissions case.**
- **Reframed?** **Yes** → from *"three display defects"* to *"one schema/read-path mismatch"*. Triggered at **Step 4** by two pieces of root-cause evidence: (a) `search-audit-events-paginated.transaction.script.ts:55` collapses resources to `[0]`, meaning the ticket's own proposed fix for P2 — "one entry per changed resource key" — **already exists on the emit side** and is discarded downstream; (b) `:58-62` uses `??`, so `''` is a hit, which makes P3 not a cosmetic blank but an active suppression of the fallbacks that would have shown the key. The wedge and acceptance criteria were derived *after* this flip, not before.
- **What the confirmed class implies:** the solution space moves from "write nicer strings in Callisto" to "make the audit read path represent an event's resources." That change is retroactive (the data is intact), reusable (it fixes every multi-resource event type, not just permissions), and cross-repo (Europa + Atlas rather than Callisto alone). It also means an emit-side-only fix is **structurally incapable** of satisfying acceptance criterion 1, no matter how well-worded the strings are.

## 2. Problem statement (the raw facts)

- **Named instances:** QA, per the ticket's own QA Notes, reviewing `PERMISSIONS_UPDATED` entries after editing a role's permissions ("If you added some permissions to transcript track and video track - you still see this"). Reported by Anastasiya Savchuk / captured by QA on PRDV-15840 follow-up. The blocked task is *reading the audit log to determine what a permissions change actually did*.
- **One sentence:** When someone changes a role's permissions in Atlas, the resulting Europa audit entry does not tell you which resource keys changed or what their permissions went from and to — and if a key's permissions were fully removed, the row shows nothing at all.
- **Distinct problems (kept separate):**
  - **P1** — The Path column cannot express old→new: one column, and the projection picks exactly one of `newState.path` / `oldState.path`. What it does show is a comma-joined *action list* under a column labeled "Path".
  - **P2** — The row does not identify the changed resource key. Two independent causes: the Resource column renders `resourceName`, which the emitter sets to the **role name**; and the read drops every resource after the first, so in a multi-key save the other keys are not merely unlabeled, they are **absent**.
  - **P3** — Full CRUD removal renders a blank cell, and the blank additionally suppresses the `oldState.path` and `resourcePath` fallbacks.
- **Urgency:** no dated trigger. Sprint 15 addition, 5 points, priority Low, status READY FOR WORK at capture. It bites every time an auditor reads a permissions change — i.e. precisely when the audit log is used for its purpose. The soft deadline is Lana's PTO window (Jul 3 – Aug 3) named in the ticket's assignment comment.
- **Wedge:** make the paginated read represent an event's resources rather than collapsing to `[0]`, and carry the resource key through to Atlas as a first-class field. Smallest change that opens the space; reusable across every multi-resource event type; retroactive over stored data.

### Problem Check

- **Asked:** improve how a `PERMISSIONS_UPDATED` audit entry reads — *evidence:* "**Path column** doesn't clearly show old/new permission state per resource key".
- **Answered:** the ticket only examines the **emit** side — *evidence:* "The `resourceName` is set to the role name, not the resource key." No sentence in the ticket text touches the read/render path, which is where the decisive failure is.
- **Should-ask:** *can the audit read path represent a multi-resource event at all?* It cannot (§5), and answering it first is what decides whether any emit-side wording change can possibly satisfy the ask.
- **Conflation:** **present, twice.** (i) Three items are presented as three defects — *evidence:* the numbered list "1. **Path column**… 2. **No resource key indicator**… 3. **Empty state on full removal**" — but all three follow from one schema/read mismatch, and fixing the read moves all three at once. (ii) Within item 2 the ticket merges a render fact ("the audit entry doesn't tell you **which** resource key changed") with an emit fact ("The `resourceName` is set to the role name") as if they were the same statement; they are different layers, and only the second is what the ticket names — the render fact has a separate and larger cause.
- **Thin:** "the audit entry" — *evidence:* "the audit entry doesn't tell you ** which** resource key changed". The term covers three things that behave differently: the stored Mongo document (**complete and correct**), the API projection (**lossy**), and the grid row (**raw passthrough**). The ticket's single word hides the fact that the data is already there.
- **Off:** **present.** *Evidence:* the ticket's proposed remedy — "*Changing multiple resource keys in one save produces one PERMISSIONS_UPDATED event with one entry per changed resource key*" — contradicts the observed symptom it is meant to fix, because that behavior **already ships**: `permissions-to-audit-event.assembler.ts:15`, `const auditEventResources = diff.map((entry) => ({…}))`. The proposal describes the current emit exactly. The symptom persists because `search-audit-events-paginated.transaction.script.ts:55` throws the extra entries away.

## 3. The contract (locked before any solutioning)

### Acceptance criteria

| Criterion | Status | What's needed to close it |
|-----------|--------|---------------------------|
| **AC1** — A save changing N resource keys is legible in the grid: all N changed keys are visible, not only the first | gap | Read-path change (OV-1/OV-2). Cannot be closed emit-side without splitting into N events (§6 alt B) |
| **AC2** — Each changed key is identified in the row, distinctly from the role name | gap | Surface `resourcePath` (or a labeled derivative) as its own field through Europa's projection → Atlas type → a grid column |
| **AC3** — Old and new action state are both readable for each changed key | gap | Either two fields/columns, or one rendered `old → new`. Requires a decision on presentation vs data (OV-4) |
| **AC4** — Removing all CRUD from a key renders a meaningful value, not a blank cell | gap | Distinguish "empty because cleared" from "absent". Wording is OV-4 |
| **AC5** — Existing `FILE` / `FOLDER` / `PROCEEDING` / `LOGIN` / `LOGOUT` rows render exactly as they do today | needs-proof | Neighbour regression tests (§9); `LOGIN`/`LOGOUT` carry `oldState: null, newState: null`, `PROCEEDING` carries `newState: { value }` with no `path` key |
| **AC6** — Pagination totals stay correct under the chosen row model | needs-proof | Only binding if OV-2 resolves to one-row-per-resource; `totalItems` is currently counted per **event** |

### Non-goals / out of scope

- **Europa API authorization for the `AUDIT` resource key.** A known gap, already documented in-product — `atlas-front-end/src/i18n/en-US/permissionsManager.json`: *"not yet enforced by Europa's API — changes here do not currently restrict direct API access."* Recorded in the concerns artifact; not this ticket.
- **Any redesign of the Permissions Manager page.** It is ruled out as a cause (§5) — it sends the complete allow-set and the diff is computed backend-side.
- **Any Mongo migration or data backfill.** Proven unnecessary: the resource key is already stored (§5).
- **The `permission.repository.ts` findings** (unfiltered `DELETE` by `effect`; matrix omits drive/`NOTIFICATIONS` keys). Real, but a different subsystem — see concerns artifact.

## 4. What changed since the request was created

- **Shifted from:** "three display defects in the Europa audit entry, fixable by changing what Callisto writes" → **to:** "one contract/shape mismatch whose decisive failure is in Europa's read projection." Lead finding — see §1.
- **What that buys us:** a fix that is **retroactive** (repairs every historical entry, because `resourcePath` already holds the key), **reusable** (fixes `MERGED` and any future multi-resource type), and correctly located (stops deepening the field overload that *is* the class).
- **What it still needs to prove:** that changing the projection does not move any existing row's rendering (AC5); that the chosen row model keeps pagination honest (AC6); and that a resource-key label can be produced unambiguously if OV-3 resolves toward labels — currently blocked by a discovered collision (§10).

## 5. Why it exists

**Origin traced to:** PRDV-15840 shipped the permissions audit by **reusing the existing file-audit event contract** rather than extending it. Callisto had a working `AuditEventResource` shape (`resourceId` / `resourceName` / `resourcePath` / `resourceBucket` / `oldState` / `newState`) built for files, and the permissions diff was mapped onto it by analogy: role→`resourceName`, resource key→`resourcePath`, action list→`{ path }`. That mapping is self-consistent at the emit end and is exactly what the dev notes describe. Nobody checked whether the **read** end could express it — and it could not, because the read was written when every event had exactly one resource.

**Evidence (primary-source pointers):**

| # | Location | What it shows |
|---|---|---|
| E1 | `europa .../search-audit-events-paginated.transaction.script.ts:55` | `const firstResource = event.auditEventResources?.[0];` — resources collapsed to the first. **Root cause of P2's data loss.** |
| E2 | same file `:58-62` | `firstResource?.newState?.path ?? firstResource?.oldState?.path ?? firstResource?.resourcePath ?? ''` — nullish, so `''` short-circuits. **Root cause of P3, and of P1's one-value-only limit.** |
| E3 | `callisto .../permissions-to-audit-event.assembler.ts:19` | `resourceName: roleName` — the Resource column's value. **Named by the ticket.** |
| E4 | same file `:20` | `resourcePath: entry.resourceKey` — **the resource key is stored.** The retroactivity finding. |
| E5 | same file `:22-23` | `oldState: { path: entry.oldActions.join(', ') }` / `newState: { path: … }` — `[].join(', ') === ''` is where the empty string is born. Actions sorted upstream at `permissions-matrix.service.ts:80-81`. |
| E6 | same file `:15` | `diff.map(...)` — **one event, N resources.** The emit is already what the ticket asks for. |
| E7 | `callisto .../permissions-matrix.service.ts:41-53` | Dispatch is gated on `diff.length > 0` and fire-and-forget (`.catch(console.error)`) — no event at all when nothing changed. |
| E8 | `europa .../audit-event-resource.entity.ts:16-26` | `oldState`/`newState` are `@Prop({ type: Object })` — free-form JSON, no key stripping. The overload is possible because Mongoose does not police it. |
| E9 | `europa .../sqs-audit-event.listener.ts:15-33` | Ingest is a raw `JSON.parse` → `new Model(...).save()`. No validation, no coercion — **ingest ruled out as a factor.** |
| E10 | `atlas .../auditEventColumns.ts:43-48` + `getOrderedColumns:64-85` | Path column has no `format`; only `createdAt` is special-cased. `SearchDataGrid.vue` overrides only `#body-cell-type` and `#body-cell-resourceType` — no `#body-cell-path`. Raw render confirmed. |
| E11 | `atlas .../types/audit-event.types.ts:5-19` | `SearchAuditEventItem` has no `resourcePath` — **the key never reaches the front end**, even though it is in the database. |
| E12 | `atlas .../fetchAuditEvents.ts:45` | The grid calls `/search-paginated` **only**. The legacy `/search` converter (`audit-event-to-search-response-dto.converter.ts:7-42`), which *does* `.map()` all resources, is not in this path — a decoy. |
| E13 | `callisto .../case-merge-to-audit-event.assembler.ts:24` | `auditEventResources: input.sourceFiles.map(...)` — **`MERGED` is multi-resource too.** E1 is already dropping merged files in prod. |

**Class re-check:** **held, and hardened.** E13 is the decisive confirmation: an event type with no connection to permissions suffers the identical loss from the identical line. That rules out "permissions-specific display bug" and confirms the class is the schema/read mismatch.

### Contract alignment (software lens — candidate 1)

- **Authority:** the audit event contract is defined on the **producer** side in Callisto — `src/audits/domain/domain-events/audit-event.de.ts` and `audit-event-resource.de.ts` (`ResourceState = { path?, bucket?, value?, fileName? }`). Europa's Mongoose entity is the **mirror**.
- **Does the mirror match?** **No, in two ways.** (i) Europa declares `oldState`/`newState` as `{ path: string; bucket: string }` (`audit-event-resource.entity.ts:16-26`) while Callisto's authority allows four optional keys including `value` — and `proceeding-to-audit.converter.ts:22` actually emits `{ value }`. The TS types disagree; only `type: Object` prevents data loss. (ii) Europa marks `oldState`/`newState` `required: true`, yet Callisto's `proceeding-to-audit.converter.ts:21` emits `oldState: null` and the login/logout path stores nulls — the requirement is not enforced on read and the specs rely on nulls.
- **Where they re-drift:** there is **no shared package**; both sides are hand-maintained. Any new `ResourceState` key added in Callisto is invisible to Europa's type. Same pattern as the resource-key list, which is duplicated between `callisto .../resource-key.entity.ts:5-48` and `atlas .../auth/utils/permissions.ts:1-63` with no shared source.

### Detection gap (software lens — candidate 4)

- **Europa has no spec that exercises `newState.path` or `oldState.path` at all.** Every Europa `path` fixture drives the legacy `resourcePath` branch (`audit-event-to-search-response-dto.converter.spec.ts:43,61,96,106`; `search-audit-events-paginated.transaction.script.spec.ts:244`). The `??`/empty-string behavior was never covered.
- **No Europa spec feeds a multi-resource event** — so the `[0]` collapse is untested for both `PERMISSIONS_UPDATED` and `MERGED`.
- **Atlas has zero coverage of the render** — no spec for `auditEventColumns` or `SearchDataGrid`; a grep for `path` across `src/europa/**/*.spec.ts` is empty.
- **Callisto's spec locked the defect in as correct:** `permissions-to-audit-event.assembler.spec.ts:211` — `expect(result.auditEventResources[0].newState.path).toBe('');`. The emit side asserted an empty string because it has no knowledge of how it renders. This is the sharpest instance of the gap: the test net didn't miss the behavior, it **ratified** it.
- **What this designs:** the regression tests belong in **Europa's projection** (multi-resource + empty-string cases), not only in Callisto — see §9.

## 6. Alternatives considered

| Alternative | Rejected because |
|-------------|------------------|
| **A. Emit-side only (Callisto).** Put the resource key or its label into `resourceName`; write a human string such as `removed: create, read` into `newState.path`. | Cannot satisfy **AC1** at all — `[0]` still discards the other keys. Not retroactive: every historical entry keeps the old shape. Deepens the exact field overload the confirmed class is about. Leaves `MERGED` broken. Cheapest option and it fails the class test. |
| **B. Emit N separate events, one per changed resource key.** | Sidesteps `[0]` without touching Europa, but breaks the "one save = one audit event" grouping that the ticket's own QA note wants preserved, inflates event volume by the number of keys changed, is still not retroactive, and still leaves `MERGED` broken. |
| **C. Read-side (Europa projection + Atlas type/column).** | **Not rejected** — the leading candidate. Matches the class, retroactive over stored data, fixes the `MERGED` neighbour for free. Cost: three-repo coordination and a pagination-semantics decision (OV-2). |
| **D. C plus a narrow emit-side correction** (e.g. stop overloading `path` for new events while the read handles both shapes). | **Not rejected** — likely the recommendation, but the split is a Phase 3 decision (OV-1). Carries a dual-shape read for the transition. |
| **E. Mongo migration to reshape stored permission events.** | Rejected outright: unnecessary. E4 proves the key is already stored; the data does not need to move, only to be read. |

## 7. Solution & stress-test

- **Proposed solution (direction, not yet a spec):** surface the audit event's resources through the paginated read instead of collapsing to `[0]`, carry `resourcePath` to Atlas as a first-class field with its own column, and make the empty-vs-absent distinction explicit so a cleared permission set renders meaningfully rather than blank. Exact shape gated on OV-1…OV-4.
- **Solves the confirmed class?** Yes. It addresses the read path's inability to represent a multi-resource event, which is the class — not the permissions instance of it. E13 (`MERGED`) is fixed by the same change, which is the test of whether a fix is class-level or occurrence-level.
- **Scale:** the resource count per event is bounded by the number of resource keys in the matrix (~22 today) for permissions, and by files-per-merge for `MERGED` — which is *unbounded*. If OV-2 resolves to one-row-per-resource, a large case merge could expand one event into hundreds of grid rows and distort pagination. That asymmetry is the strongest argument for the aggregate-in-cell row model, and it is the thing OV-2 must weigh.
- **Generalization:** fixing the projection generically (all resources, all types) is the right altitude — it is where the defect is, and special-casing `type === 'PERMISSIONS_UPDATED'` inside a generic projection would be the overreach in the other direction (a type-aware read is a new coupling). Adding a resource-key **label** map to Europa *would* be overreach: Europa has no business knowing Callisto's permission vocabulary.
- **Fit:** Europa follows Nest action/responder/TS/projection layering; the change lands in `toItemProjection` and its projection type, which is the conventional seam. Atlas's column model already supports per-column `format` and `#body-cell-*` slots, so a new column is idiomatic. Nothing here fights the existing philosophy.
- **Adjacent issues:** (i) the `MERGED` `[0]` collapse — **lower effort to fix now**, it is literally the same line, and shipping the fix without it would mean knowingly leaving a prod defect in code being edited (OV-5); (ii) Europa's `AUDIT` API authorization gap and (iii) the `permission.repository.ts` `DELETE`/omitted-keys findings — both **spin off**, different subsystems, no shared code with this change.
- **Sufficiency:** covers all three reported problems and the unreported data loss behind P2. It does **not** address the deeper "audit schema has no first-class notion of a diff" issue — that would be a contract redesign across both services, and is out of proportion to a 5-point ticket. Noted as a future concern.
- **Feedback speed:** **fast.** A local Europa spec fails today and passes after (§9). End-to-end confirmation needs one permissions save and one grid read — minutes, no waiting on data accumulation.
- **Actor / action / moment:** an **auditor or IT reviewer**, reading the Europa audit grid, **immediately after** (or arbitrarily long after) someone saves a role's permissions in Atlas, asking "what exactly changed?"
- **Happy-path story (30s):** Someone changes the Neptune Operations role — grants `update` on Transcript Track, clears everything on Video Track — and saves. The auditor opens Europa, filters to `PERMISSIONS_UPDATED`, and sees **both** keys represented: Transcript Track `read → read, update`, Video Track `read, update → (all permissions removed)`. They can tell which module changed, in which direction, without opening a database. And the entry they look at from three months ago reads the same way, because the fix is on the read. Without: Callisto changing what it writes, and without any migration.

## 8. Assumptions ledger

- **Claim:** `PERMISSIONS_UPDATED` is emitted only by Callisto; no other service produces it.
  - **Status:** confirmed
  - **Confirm/revise by:** grep of all six workspace repos — hits only in `callisto-back-end` (source), `atlas-front-end/src/europa/utils/constants.ts:10,29` (display constant), and the ticket docs. Europa has zero occurrences.
- **Claim:** the Europa audit grid is rendered by Atlas, not by Europa.
  - **Status:** confirmed
  - **Confirm/revise by:** `europa-back-end` has no `.vue`/template files outside coverage output and no front-end dependency in `package.json`; the grid lives at `atlas-front-end/src/europa/pages/HomePage/SearchDataGrid/`.
- **Claim:** the grid consumes only `/audit-events/search-paginated`, so the legacy `/search` converter is not part of this defect.
  - **Status:** confirmed
  - **Confirm/revise by:** `fetchAuditEvents.ts:45`; repo-wide grep for `getEuropaUri()` finds only `/search-paginated`, `/login`, `/logout`.
- **Claim:** the resource key is already persisted on every historical `PERMISSIONS_UPDATED` document, so no backfill is needed.
  - **Status:** **confirmed directionally** — confirmed in code (`assembler.ts:20` writes `resourcePath`; ingest saves raw; the field exists on the entity), **not** confirmed against live data.
  - **Confirm/revise by:** query one real prod/test `PERMISSIONS_UPDATED` document and assert `auditEventResources[*].resourcePath` is populated. **This is the one open evidence item and it is on the frontier** — see coverage ledger.
- **Claim:** `''` in `newState.path` suppresses the fallback chain because `??` is nullish-coalescing.
  - **Status:** confirmed
  - **Confirm/revise by:** language semantics + `search-audit-events-paginated.transaction.script.ts:58-62`; `'' ?? x` evaluates to `''`.
- **Claim:** the empty-string-wins behavior is unintentional, not a deliberate "prefer newState even when cleared" choice.
  - **Status:** **open** — the code comment says "Path can be in newState (current), oldState (previous), or resourcePath (legacy)", which reads as a *fallback* intent, implying `''` winning is accidental. But no author is on record.
  - **Confirm/revise by:** PRDV-15840's dev notes or its author; or accept the comment as sufficient evidence of intent. Low risk either way — both readings point at the same fix.
- **Claim:** changing `toItemProjection` cannot affect ingest, storage, or search/filtering.
  - **Status:** confirmed
  - **Confirm/revise by:** ingest is a separate listener path (E9); the Mongo query is built by `SearchParamsToMongoQueryConverter` before projection; `path` is not in any index (`audit-event.entity.ts:28-57`), so filtering/sorting never touches it.
- **Claim:** `MERGED` events are multi-resource and therefore already truncated in the grid today.
  - **Status:** confirmed in code; **not** observed in a live grid
  - **Confirm/revise by:** `case-merge-to-audit-event.assembler.ts:24`. To observe: perform a case merge of ≥2 files and read the grid.
- **Claim:** the Permissions Manager page contributes nothing to the defect.
  - **Status:** confirmed
  - **Confirm/revise by:** `usePermissionsMatrix.ts:147-175` sends the complete allow-set; the per-key diff is computed in `permissions-matrix.service.ts:66-93`. Nothing key-specific originates on the client.
- **Claim:** a human-readable resource-key label can be produced unambiguously.
  - **Status:** **refuted**
  - **Confirm/revise by:** `callisto .../fetch-permissions-matrix.response.dto.ts:71-212` — `PERMISSIONS_MATRIX_SECTIONS` labels are **section-scoped and collide**: `SUBMISSION_PROCEEDING_FILES_TRANSCRIPT` and `CLIENT_DELIVERABLE_PROCEEDING_FILES_TRANSCRIPT` are both `"Transcript Track"`. A standalone label is ambiguous without its category. This constrains OV-3.

### Affected surfaces (software lens — candidate 2)

Everything that can reach the `path` value, and how completeness was established:

| Surface | Reaches `path` how | In scope? |
|---|---|---|
| `europa .../search-audit-events-paginated.transaction.script.ts` `toItemProjection` | builds it | **yes — the defect** |
| `europa .../search-audits-paginated.responder.ts:12-27` | passes through | yes (type change) |
| `europa .../search-audit-events-paginated.projection.ts:39` + `.response.dto.ts:43-44` | type/contract | yes |
| `europa .../audit-event-to-search-response-dto.converter.ts` (legacy `/search`) | builds it, maps **all** resources | not consumed by the grid — decide whether to align (OV-1) |
| `europa .../audit-event-to-search-projection.converter.ts` | drops resources; no `path` | no |
| `atlas .../types/audit-event.types.ts:17` | declares `path` | yes |
| `atlas .../auditEventColumns.ts:43-48` + `SearchDataGrid.vue` | renders it | yes |
| `atlas .../useColumnOrderSettings.ts:20-26` | derives default visible columns from `AuditEventColumns`, persisted in `localStorage` under `europa-audit/column-settings` | **yes if a column is added** — existing users have a persisted list that will not contain a new column |

**Completeness claim:** established by (i) grep for `path` across `europa-back-end/src/audits-event/**` and `atlas-front-end/src/europa/**`; (ii) enumerating every `@Get`/`@Post` on `AuditEventsController` (`/`, `/search`, `/search-paginated`, `/audit-event/:userId`, `/login`, `/logout`, delete-all) and checking which return a `path`; (iii) grep for `getEuropaUri()` in Atlas, which yields exactly three call sites. The `localStorage` row is the non-obvious one and was found via `useColumnOrderSettings.ts`, not via the `path` grep.

### Protect-the-neighbors (software lens — candidate 3)

Behaviours sharing the changed code path that **must not move**:

| Neighbour | Shape it relies on | How it will be verified unchanged |
|---|---|---|
| `LOGIN` / `LOGOUT` | `oldState: null, newState: null`, no resources of interest | Existing spec fixtures (`audit-event-to-search-response-dto.converter.spec.ts:104-105,144-145`) plus a paginated-projection assertion that the row is byte-identical |
| `PROCEEDING` (`proceeding-to-audit.converter.ts:21-22`) | `oldState: null` and `newState: { value }` — **no `path` key at all**; relies on falling through to `resourcePath` | A projection spec feeding this exact shape; must still yield `resourcePath` |
| `FILE` single-resource events (`case-file`, `proceeding-file`, `job-submission` converters) | `oldState/newState: { path, bucket }` with real file paths | Existing `resourcePath`-based fixtures must stay green, plus one `newState.path` fixture (currently none exists) |
| `MERGED` | multi-resource; today truncated to `[0]` | Deliberately **will** change if OV-5 says fix it — must be an intentional, asserted change, not a silent one |
| Search / sort / filter | `path` is not indexed and not in the text index (`audit-event.entity.ts:28-57`) | Confirmed by reading the index definitions; no test needed, but stated |
| Column visibility for existing users | persisted `localStorage` list predates any new column | Manual check with a pre-existing `europa-audit/column-settings` value |

## 9. Validation plan

**Happy path**

1. Log in to Atlas with a role holding `ATLAS_PERMISSIONS_MANAGER:update`.
2. Go to `/permissions`; select a role that already has permissions.
3. Change **two** resource keys in one save — e.g. add `update` to Transcript Track and clear all CRUD from Video Track. Confirm the dialog and save.
4. Open the Europa audit page; filter to `PERMISSIONS_UPDATED`.
5. Expect: **both** changed keys represented; each identified by its resource key (distinct from the role name); each showing its old and new action state; the cleared key showing a meaningful "removed" value rather than blank.
6. Expect: an entry created **before** the fix reads correctly too (retroactivity — the whole argument for the read-side fix).

**Negative / inferred paths**

- **Full removal** — clearing every CRUD action from one key must render a meaningful value, never an empty cell, and must still identify the key.
- **Single-key save** — must not regress into showing more or differently than it does today beyond the intended additions.
- **No-op save** — no diff means **no event at all** (`permissions-matrix.service.ts:41`); the grid must show nothing new. Guards against "fix the display by emitting more".
- **Neighbour regression** — `LOGIN`, `LOGOUT`, `PROCEEDING`, and single-resource `FILE` rows render byte-identically (see the neighbours table).
- **`MERGED` multi-resource** — with ≥2 files: either fixed deliberately (OV-5) or explicitly left unchanged; must not change *by accident*.
- **Pagination honesty** — if OV-2 lands on one-row-per-resource, `totalItems` / `totalPages` / `hasNextPage` must still describe what the user actually pages through. Assert against an event set with mixed resource counts.
- **Unbounded expansion** — a merge event with many files must not blow up a page (the scale risk in §7).
- **Persisted column settings** — a user whose `localStorage` predates a new column must not lose the grid or silently miss the column.

**Red→green regression test (encodes the exact defect):** a Europa spec for `SearchAuditEventsPaginatedTS.toItemProjection` feeding **one event with two resources**, where `resources[0]` has `newState.path === ''`, `oldState.path === 'read, update'`, `resourcePath === 'SUBMISSION_PROCEEDING_FILES_TRANSCRIPT'` and `resources[1]` describes a second key. **Today:** one item, `path === ''`, second key absent, resource key nowhere. **After:** both keys represented, the cleared one meaningful. This single spec fails on all of P1/P2/P3 and is the durable guard against re-drift.

**Reproduction recipe / preconditions:** role with `ATLAS_PERMISSIONS_MANAGER:update`; a target role that already has permissions on ≥2 resource keys; Atlas `/permissions`; Callisto and Europa reachable with SQS wired (the dispatch is fire-and-forget — a broken queue fails silently, `permissions-matrix.service.ts:52`). **No feature flag.** Local runbooks: `docs/atlas/local/callisto-local.mdc`, `docs/atlas/local/europa-local.mdc`.

**Metric that proves it works, and how fast:** the red→green spec above flips within one test run (seconds); end-to-end, one save + one grid read (minutes). There is no slow-feedback component to this work.

## 10. Decisions, recommendation & open variables

- **Decisions (settled by evidence, not up for discussion):**
  - The defect's decisive location is Europa's paginated projection, not Callisto's assembler.
  - No Mongo migration or backfill is required (E4).
  - The Permissions Manager page and Europa's SQS ingest are ruled out.
  - The legacy `/search` endpoint is not part of the grid's path.
  - A standalone human label for a resource key is **not** currently derivable unambiguously (§8, refuted claim) — any label direction must first solve the collision.
- **Recommendation (in order):**
  1. Resolve OV-1 and OV-2 in Phase 3 — they determine everything else.
  2. Land the Europa projection change with the red→green spec plus the neighbour regressions.
  3. Carry `resourcePath` through the projection → DTO → Atlas type → grid column, including the `localStorage` column-settings consideration.
  4. Decide the empty-state representation (OV-4) as presentation-layer, not by writing prose into the event.
  5. Fix or spin off `MERGED` (OV-5) — explicitly, either way.
- **Sequencing & gates:** do not write Atlas column code until OV-2 is settled (the row model determines whether a column or a cell-aggregate is correct). Do not pursue any label-mapping work until the OV-3 collision is resolved. Do not treat "the key is in every historical document" as proven until one real document is inspected (§8, the one directional claim).

### Open variables to collect

- [ ] **OV-1 — Which side gets fixed:** read-side only (alt C), read + narrow emit correction (alt D), or emit-side (A/B)? *Evidence framing:* A and B cannot satisfy AC1 or retroactivity; the decision is really "C or D", and D's extra scope is the question. — owner: **user**
- [ ] **OV-2 — Row model:** one grid row per event with the resources aggregated into the cell, vs one row per resource. *Why the structure can't answer it:* `totalItems` is counted per **event** in `buildPagination` (`search-audit-events-paginated.transaction.script.ts:89-103`) against a Mongo document count; there is no field that distinguishes "rows" from "events", so either model is representable and neither is implied by the current code. It is a product call with a real cost — `MERGED` resource counts are unbounded (§7 Scale). — owner: **user**
- [ ] **OV-3 — Raw key or human label** in the new resource-key surface. *Blocked by evidence:* the only label map (`PERMISSIONS_MATRIX_SECTIONS`) is section-scoped and its labels collide across sections; and it lives in Callisto, which Europa has no business importing. Options: ship raw keys; solve the collision first; or map labels in Atlas at render time. — owner: **user**
- [ ] **OV-4 — Empty-state representation** on full removal. The ticket suggests "something like 'removed create-read'". *Sub-question:* is this presentation (Atlas renders a placeholder for an empty action list) or data (the event/projection carries an explicit marker)? Presentation is retroactive; data is not. — owner: **user**
- [ ] **OV-5 — `MERGED` neighbour:** fix in this ticket or spin off? Same line of code; fixing it costs almost nothing extra but widens the blast radius and the test matrix. — owner: **user**
- [ ] **OV-6 — Does "The solution may need to be discussed with IT" (Kat Giangiulio, Jul 16) gate this work,** and if so, what specifically needs IT's input — the audit presentation, or the underlying permission model? — owner: **user**

---

## 11. Plan — Next steps

### Handoff table

| Action | Owner | Done-when (falsifiable) |
|--------|-------|-------------------------|
| Resolve OV-1…OV-6 via grill-me under the Q&A traceability workflow | Dustin + user | Every OV has a row in `specs/PRDV-16192-locked-decisions.md` with a source and a spec destination; none left open |
| Write the story spec | Dustin | `specs/PRDV-16192-spec.md` exists with all `spec-writing` sections (N/A where inapplicable) and a Locked Decisions section linking the ledger |
| Confirm the one directional assumption against live data | Dustin | A real `PERMISSIONS_UPDATED` document is inspected and `auditEventResources[*].resourcePath` is shown populated (or the claim is revised) |
| Refine the test plan to concrete assertions | Dustin | `testing/PRDV-16192-test-plan.md` status is `refined`; every AC maps to at least one scenario |
| Implement + land the red→green spec | Dustin | The two-resource / empty-`newState.path` projection spec fails on `main` and passes on the branch |
| Prove neighbours unchanged | Dustin | `LOGIN`/`LOGOUT`/`PROCEEDING`/single-resource `FILE` rows asserted identical |

### Checklist

#### Investigation
- [x] This report (Sections 0–10)
- [x] Coverage ledger, diagrams, test-plan seed, concerns record

#### Project Spec
- [ ] Resolve open variables (grill-me)
- [ ] Create project spec

#### Development
- [ ] Create new branch
- [ ] Begin implementation

#### Testing & Validation
- [ ] Test and validate implementation locally

#### Deploy & PR
- [ ] Push to GitHub
- [ ] Deploy to sandbox + verify there
- [ ] Open PR
- [ ] Address feedback / wait for approval
- [ ] Merge to main
- [ ] Deploy to test

#### Ticket Closeout
- [ ] Update ClickUp: merged to test
- [ ] Set ticket to Ready for QA
- [ ] (Bug) Document root cause / why it slipped through → §5 detection gap

---

## 12. Definition of done (investigation gate)

- [x] **Class derived from instances, re-confirmed against root cause — "reframed?" answered:** yes, at Step 4, with the trigger evidence named (§1)
- [x] Problem Check pass recorded (§2) — every flag grounded in a trimmed quote from the ticket text
- [x] Problem in one plain sentence (§2)
- [x] Named blocked instance (§2)
- [x] Date it bites next (§2 — no dated trigger; stated as such, with the PTO-window soft deadline)
- [x] Wedge + why it's reusable within the confirmed class (§2)
- [x] Acceptance criteria + non-goals locked before the solution was proposed (§3 precedes §7)
- [x] Alternatives recorded with rejection reasons (§6)
- [x] 30-second happy-path story (§7)
- [x] Metric that proves it works + how fast it arrives (§9)
- [x] Verdict + disposition stated (§0 — proceed with conditions)
- [x] Every open question reconciled: discoverable facts resolved in §8; only genuine decisions in §10, each with an owner; OV-2 and OV-3 carry the evidence proving the structure cannot answer them
- [x] Tracked action with a falsifiable done-when (§11)

---

## §13. Post-Investigation Addendum — Step 7 reconcile results and the recorded recommendation (2026-07-27)

> Appended, not rewritten. §0 carries a one-line pointer here; every section above stands as originally emitted.

### 13.1 Three open variables sharpened by further code evidence

Re-running the Step 7 reconcile at the start of Phase 3 resolved discoverable halves that §10 had left inside the decisions:

| OV | Evidence found | Effect on the decision |
| --- | --- | --- |
| OV-1 | Europa's legacy `GET /audit-events/search` has **no consumer at all**: Atlas calls only `/search-paginated` (`fetchAuditEvents.ts:45`; repo-wide `getEuropaUri()` grep yields exactly three call sites), and no backend calls it — the only "europa"/"audit-events" strings across callisto/triton/nova/hubble are a section id in `fetch-permissions-matrix.response.dto.ts:183` and Triton's SQS group name in `historical-files/.../audit/constants.ts:9`. | The "should we align the legacy endpoint too?" sub-question **dissolves** — no user-facing impact either way. OV-1 reduces to read-side vs read-side-plus-emit vs emit-only. |
| OV-2 | Atlas pagination is genuinely **server-side** — `tablePagination` sets `rowsNumber: props.pagination?.totalItems` and `@request="onRequest"` refetches (`SearchDataGrid.vue:87-99,192-198`) — so a per-resource row model forces Europa to change what it counts, not just Atlas. `row-key="auditEventId"` (`:201`) would also stop being unique. Separately, **expandable-row precedent exists in-repo**: four Callisto tables use `q-tr`/expand patterns. | OV-2 gains a **third viable model** — one row per event, expandable for per-key detail — which is grounded in existing convention rather than invented. It also gains a concrete cost for the per-resource model (pagination semantics + row identity). |
| OV-3 | `fetchPermissionsMatrix` is imported **only** by `usePermissionsMatrixQuery` on the Permissions Manager page. The Europa audit page has no access to the label map today. | On top of the label collision already refuted in §8, using labels would mean pulling a Callisto permissions call into the audit page. Raises the cost of the label option; does not decide it. |

### 13.2 Scope redirection and the recorded recommendation

**User instruction, 2026-07-27:** grill-me was halted before OV-1 was answered — *"we're not trying to build anything… we are trying to create investigative docs so that we can actually understand the scope of the problem."* The agent was directed to make the fix-side call itself and to produce an artifact usable as a **source of truth by QA and product** for a discussion the following day.

Consequences recorded here:

- **OV-1…OV-6 are not agent-asked questions.** They are **agenda items** for that discussion, restated as D1…D6 in the [discussion brief](../PRDV-16192-discussion-brief.md). No locked-decision ledger is created yet, because no decision has been locked by an owner.
- **The spec is deferred.** Phase 3's spec output waits on D1 and D2.
- **Recommendation recorded (agent, not owner):** **alternative C — fix the read side.** Rationale in priority order: it is the only option that can satisfy AC1 (E1 discards the extra resources regardless of what is written); it is retroactive over all stored history (E4); it fixes the `MERGED` neighbour with the same change (E13); and it does not deepen the field overload that the confirmed class is about. The emit-only option (A) is preserved as a legitimate, costed choice for a Low-priority 5-point ticket, with its limits stated explicitly rather than argued away: it closes P3 and half of P2, and cannot close P1 or the multi-key loss.
- **Verdict and problem class are unchanged** by this addendum.

### 13.3 The one check to run before the discussion relies on retroactivity

The retroactivity argument is the load-bearing reason to prefer alternative C, and it is still **confirmed directionally only** (§8): proven in code, not against live data. Opening a single real `PERMISSIONS_UPDATED` document in a live environment and confirming `auditEventResources[*].resourcePath` is populated would convert it to confirmed. It is a minutes-long check and it is on the coverage-ledger frontier.
