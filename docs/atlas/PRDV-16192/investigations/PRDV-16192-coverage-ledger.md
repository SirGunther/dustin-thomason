# Coverage ledger — atlas/PRDV-16192

Investigation question: Why does a `PERMISSIONS_UPDATED` audit entry fail to show which resource key changed, its old→new permission state, and anything at all when all CRUD is removed?

Repo(s): `europa-back-end`, `callisto-back-end`, `atlas-front-end` · Baseline commits: europa `af49e79` (main) · callisto `47f5a841` (main) · atlas `102e034d` (main) · Started: 2026-07-27

> **Baseline note:** the first traversal ran against callisto `8743948b` (branch `PRDV-16216`) and atlas `18a6bf05` (branch `PRDV-14055`). At user instruction all repos were moved to `main` and pulled (+51 and +20 commits respectively), and the three load-bearing files were re-read there and confirmed unchanged. Every entry below is keyed to the **main** SHAs.

## Consulted

- `docs/*/tickets/*/investigations/*-coverage-ledger.md` and `docs/atlas/*/investigations/*-coverage-ledger.md` for "permission", "PERMISSIONS_UPDATED", "audit", "europa", "resourceName", "resource key" — **three ledgers exist** (`atlas/PRDV-14055`, `ClickUpWideLayout/export-clickup-ticket-to-markdown`, `Jaimie/shareplane-modularize-availability`); the two that matched on "permission" matched on **browser-extension `host_permissions` / `manifest.json` permissions**, not role permissions or audit. **No prior coverage of the permissions-audit or Europa subsystem — nothing reused, nothing reopened.**
- `docs/**` for "PERMISSIONS_UPDATED", "resourceName", "15840" — hits only in this ticket's own artifacts. No PRDV-15840 changelog or investigation exists in this repo.

## Areas examined

### 1. Europa — paginated read projection (**the defect**)

| Field | Value |
| --- | --- |
| Inspected | `SearchAuditEventsPaginatedTS.apply`, `toItemProjection`, `buildPagination` |
| Findings | `:55` collapses `event.auditEventResources` to `[0]`, so an event carrying N resources yields one grid item and N−1 are discarded · `:58-62` resolves `path` with `??`, so `newState.path === ''` short-circuits the `oldState.path` and `resourcePath` fallbacks · `:81-83` likewise takes `resourceId`/`resourceType`/`resourceName` from `[0]` only · `:89-103` counts `totalItems` per **event**, so a one-row-per-resource model would change pagination semantics · no `resourcePath` is exposed as its own projection field |
| Status | contributing |
| Commit | `af49e79` · 2026-07-27 |
| Evidence | `europa-back-end/src/audits-event/domain/transaction-scripts/search-audit-events-paginated-TS/search-audit-events-paginated.transaction.script.ts:53-103` |
| Notes | Root cause for all three reported problems. Re-read on `main` after the baseline correction — unchanged. |

### 2. Europa — response contract for the paginated read

| Field | Value |
| --- | --- |
| Inspected | `search-audit-events-paginated.projection.ts`, `search-audit-events-paginated.response.dto.ts`, `search-audits-paginated.responder.ts`, `search-audits-paginated.action.ts`, `audit-events.controller.ts` |
| Findings | Responder is a straight field-for-field passthrough with no formatting · `path: string` documented as "File path associated with the resource" — the doc string is already wrong for permission events · route is `GET /audit-events/search-paginated` |
| Status | fully-inspected |
| Commit | `af49e79` · 2026-07-27 |
| Evidence | `.../search-audits-paginated.responder.ts:12-27`; `.../search-audit-events-paginated.response.dto.ts:43-44`; `.../search-audits-paginated.action.ts:22`; `.../controllers/audit-events.controller.ts:6` |
| Notes | Any new field must be added at all three layers (projection → DTO → responder). |

### 3. Europa — storage schema

| Field | Value |
| --- | --- |
| Inspected | `AuditEvent` entity + indexes, `AuditEventResource` sub-document, module registration |
| Findings | MongoDB/Mongoose, **no migrations exist** in the repo (schema-on-write) · `oldState`/`newState` are `@Prop({ required: true, type: Object })` — free-form JSON, no sub-schema, no key stripping, TS type is compile-time only · `resourcePath` and `resourceBucket` are `required: false` and **are** persisted · `type` is a free-form `string`, so `PERMISSIONS_UPDATED` passes through despite not being in Europa's enum · `path` is **not** indexed and **not** in the `audit_search_text_index` |
| Status | fully-inspected |
| Commit | `af49e79` · 2026-07-27 |
| Evidence | `.../domain/entities/audit-event/audit-event.entity.ts:1-57`; `.../audit-event-resource.entity.ts:1-36`; `.../audit-event.module.ts:21-23` |
| Notes | The "no backfill needed" conclusion rests here plus area 5: the key is stored and nothing strips it. Search/sort are unaffected by a `path` change because it is unindexed. |

### 4. Europa — ingest path

| Field | Value |
| --- | --- |
| Inspected | `SqsAuditEventListener.handleMessage`, `AuditEventService.create`, `CreateAuditEventTS.apply`, `AuditEventRepository.create` |
| Findings | SQS-only ingest; no HTTP create endpoint · raw `JSON.parse(message.Body)` saved directly via `new this.auditEventModel(...).save()` · no DTO, no validation, no coercion |
| Status | ruled-out |
| Commit | `af49e79` · 2026-07-27 |
| Evidence | `.../application/listeners/sqs-audit-event.listener.ts:15-33`; `.../infrastructure/repositories/audit-event.repository.ts:26-40` |
| Notes | Nothing is lost or reshaped between Callisto and Mongo. Ruled out as a contributor. |

### 5. Callisto — permissions emit chain

| Field | Value |
| --- | --- |
| Inspected | `UpdatePermissionsMatrixAction`, `PermissionsMatrixService.updatePermissions` + `computeDiff`, `PermissionsAuditAggregator`, `PermissionsAuditDispatcher`, `PermissionsToAuditEventAssembler`, `PermissionsAuditParams`, `audits/constants.ts` |
| Findings | `assembler:15` — `diff.map(...)` emits **one event with one resource per changed key**, i.e. the ticket's proposed remedy already ships · `:19` `resourceName: roleName` (the Resource column's value) · `:20` **`resourcePath: entry.resourceKey` — the resource key IS persisted** · `:22-23` action lists joined into `oldState.path`/`newState.path`; `[].join(', ')` is where `''` originates · actions sorted at `service:80-81` · dispatch gated on `diff.length > 0` and fire-and-forget with `.catch(console.error)` — a broken queue fails silently · `PERMISSIONS_UPDATED` defined in Callisto's enum only |
| Status | contributing |
| Commit | `47f5a841` · 2026-07-27 |
| Evidence | `callisto-back-end/src/generic/auth/domain/sub-domains/infrastructure/dispatchers/permissions-audit-dispatcher/permissions-to-audit-event.assembler.ts:12-34`; `.../domain/services/permissions-matrix-service/permissions-matrix.service.ts:23-93`; `src/audits/constants.ts:1-19` |
| Notes | Re-read on `main` after the baseline correction (+51 commits) — byte-identical to the branch reading. |

### 6. Europa — legacy `/search` read path

| Field | Value |
| --- | --- |
| Inspected | `AuditEventToSearchResponseDtoConverter`, `search-audits.action.ts`, `SearchAuditEventResponseDto`, and the separate `audit-event-to-search-projection.converter.ts` |
| Findings | The legacy converter `.map()`s **all** resources into one DTO each — i.e. it does not suffer the `[0]` collapse — but uses the same `??` chain, so it shares the empty-string defect · the third converter drops resources entirely and has no `path` |
| Status | ruled-out (not consumed by the grid) |
| Commit | `af49e79` · 2026-07-27 |
| Evidence | `.../application/converters/audit-event-to-search-response-dto.converter.ts:7-42`; `.../actions/search-audits/search-audits.action.ts:20`; `.../search-audit-event-TS/converters/audit-event-to-search-projection.converter.ts:8-22` |
| Notes | A decoy: it looks like the render path and behaves better. Atlas calls only `/search-paginated` (area 7). Whether to align the two is a scope decision (OV-1), not a cause. |

### 7. Atlas — Europa audit grid and wire contract

| Field | Value |
| --- | --- |
| Inspected | `fetchAuditEvents.ts`, `audit-event.types.ts`, `auditEventColumns.ts` + `getOrderedColumns`, `SearchDataGrid.vue` body-cell slots and row mapper, `useColumnOrderSettings.ts`, `europa/utils/constants.ts`, `europa/api/getUrl.ts` |
| Findings | Grid calls **`/search-paginated` only** (`:45`); repo-wide `getEuropaUri()` grep yields exactly three call sites (`/search-paginated`, `/login`, `/logout`) · `SearchAuditEventItem` has **no `resourcePath`** — the resource key never crosses the wire · Path column has no `format`; only `createdAt` is special-cased in `getOrderedColumns` · `SearchDataGrid.vue` overrides only `#body-cell-type` and `#body-cell-resourceType`, so `path` renders raw · default visible columns are derived from `AuditEventColumns` and **persisted to `localStorage`** under `europa-audit/column-settings`, so existing users hold a stale column list · Atlas does know the `PERMISSIONS_UPDATED` and `PERMISSION` literals for filtering/severity |
| Status | contributing |
| Commit | `102e034d` · 2026-07-27 |
| Evidence | `atlas-front-end/src/europa/pages/HomePage/requests/fetchAuditEvents.ts:45`; `src/europa/types/audit-event.types.ts:5-19`; `.../SearchDataGrid/auditEventColumns.ts:43-48,64-85`; `.../SearchDataGrid/useColumnOrderSettings.ts:20-26`; `src/europa/utils/constants.ts:10,17,29` |
| Notes | The `localStorage` column persistence is the non-obvious surface — found via `useColumnOrderSettings`, not via the `path` grep. Re-read on `main` (+20 commits) — unchanged. |

### 8. Atlas + Callisto — Permissions Manager page and its save endpoint

| Field | Value |
| --- | --- |
| Inspected | `PermissionsManagerPage.vue`, `usePermissionsMatrix.ts` (`save`, `toggleCell`, `cellMap`), `updatePermissionsMatrix.ts`, `UpdatePermissionsMatrixRequestDto`, `UpdatePermissionsMatrixAction`, `UpdatePermissionsMatrixTS`, `PermissionRepository.replaceRolePermissions`, `NoSelfLockoutValidator` |
| Findings | The client sends the **complete desired ALLOW set**, not a delta — nothing key-specific originates on the client · the per-key diff is computed server-side against a pre-replace snapshot · persistence is delete-all-then-insert inside a transaction · **incidental findings, out of scope:** the `DELETE` is not filtered by `effect`, so any `DENY` rows are destroyed; and the matrix omits `K/V/R/T/H_DRIVE` and `NOTIFICATIONS`, so a save from the page deletes those rows for the role and never re-inserts them |
| Status | ruled-out (as a cause of this defect) |
| Commit | atlas `102e034d`, callisto `47f5a841` · 2026-07-27 |
| Evidence | `atlas .../PermissionsManagerPage/composables/usePermissionsMatrix.ts:147-175`; `callisto .../update-permissions-matrix.request.dto.ts:15-41`; `.../infrastructure/repositories/permission.repository.ts:102-146` |
| Notes | The two incidental findings are recorded in the concerns artifact, not carried as causes. |

### 9. Callisto — resource-key definitions and label sources

| Field | Value |
| --- | --- |
| Inspected | `resource-key.entity.ts` `RESOURCE_KEY_TYPES`, `atlas/src/auth/utils/permissions.ts`, `PERMISSIONS_MATRIX_SECTIONS` in `fetch-permissions-matrix.response.dto.ts`, `i18n/en-US/permissionsManager.json` `resourceKeyDescriptions`, resource-key seed migrations |
| Findings | **Three hand-maintained parallel key lists** (Callisto const, Atlas const, i18n description map) plus the DB `resource_keys` table; no shared package · the only short-label map is `PERMISSIONS_MATRIX_SECTIONS`, and its labels are **section-scoped and collide** — `SUBMISSION_PROCEEDING_FILES_TRANSCRIPT` and `CLIENT_DELIVERABLE_PROCEEDING_FILES_TRANSCRIPT` are both "Transcript Track" · the i18n map holds unique *descriptions* but they are tooltip prose, not labels · the i18n map also contains stale pre-rename `*_RECORD_*` keys |
| Status | fully-inspected |
| Commit | callisto `47f5a841`, atlas `102e034d` · 2026-07-27 |
| Evidence | `callisto .../domain/entities/resource-key.entity.ts:5-48`; `.../fetch-permissions-matrix.response.dto.ts:71-212`; `atlas .../auth/utils/permissions.ts:1-63`; `atlas .../i18n/en-US/permissionsManager.json:44-77` |
| Notes | This is what refutes the "we can just show a friendly label" assumption and constrains OV-3. |

### 10. Callisto — neighbour audit assemblers (regression surface)

| Field | Value |
| --- | --- |
| Inspected | `case-merge-to-audit-event.assembler.ts` + its resource converter, `case-file-to-audit-event.assembler.ts`, `proceeding-to-audit.converter.ts`, `proceeding-file-to-audit.converter.ts`, `job-submission-file-to-audit.converter.ts`, `audit-event-resource.de.ts` |
| Findings | **`MERGED` is multi-resource** — `auditEventResources: input.sourceFiles.map(...)` — so the `[0]` collapse is already truncating merged files in prod today · `case-file` emits `auditEventResources: [fileResources]` (single) · `PROCEEDING` emits `oldState: null` and `newState: { value }` with **no `path` key**, relying on the fallback to `resourcePath` · the authoritative `ResourceState` allows `path? bucket? value? fileName?`, which Europa's entity type does **not** mirror (it declares only `path`/`bucket`) |
| Status | contributing (regression surface) |
| Commit | `47f5a841` · 2026-07-27 |
| Evidence | `.../case-merge-to-audit-event-assembler/case-merge-to-audit-event.assembler.ts:24`; `.../case-merge-to-audit.converter.ts:14-32`; `.../case-file-to-audit-event.assembler.ts:29`; `.../proceeding-to-audit.converter.ts:19-22`; `src/audits/domain/domain-events/audit-event-resource.de.ts` |
| Notes | `MERGED` is the evidence that promotes this from a permissions bug to a class. `PROCEEDING`'s null/`value` shape is the neighbour most at risk from a naive fallback-chain edit. |

### 11. Existing test coverage across all three repos

| Field | Value |
| --- | --- |
| Inspected | Europa `__specs__` for the paginated TS, the legacy converter, the responder and the DTO converter; Callisto `__specs__` for the assembler, aggregator, matrix service and update TS; Atlas `__specs__` under `src/europa/**` and `PermissionsManagerPage/**` |
| Findings | **Europa has no spec that exercises `newState.path` or `oldState.path`** — every `path` fixture drives the legacy `resourcePath` branch · **no Europa spec feeds a multi-resource event**, so the `[0]` collapse is untested · **Atlas has zero coverage of the Path column** — the only `src/europa` spec is `useAuditSearch.spec.ts`, and a `path` grep across `src/europa/**/*.spec.ts` is empty; no `SearchDataGrid` or `auditEventColumns` spec exists · **Callisto's assembler spec ratifies the defect**: `expect(...newState.path).toBe('')` · Callisto's matrix-service spec does cover no-dispatch-on-empty-diff and swallowed dispatch failure · Atlas's `usePermissionsMatrix` save spec matches only `{ roleId }` via `objectContaining`, so the payload contents are untested · no e2e/integration test hits `PUT /callisto/permissions/matrix` |
| Status | fully-inspected |
| Commit | europa `af49e79`, callisto `47f5a841`, atlas `102e034d` · 2026-07-27 |
| Evidence | `europa .../__specs__/audit-event-to-search-response-dto.converter.spec.ts:43,61,96,104-106,144-145,156-157`; `europa .../__specs__/search-audit-events-paginated.transaction.script.spec.ts:244`; `callisto .../__specs__/permissions-to-audit-event.assembler.spec.ts:174-231` (esp. `:211`); `atlas .../PermissionsManagerPage/composables/__specs__/usePermissionsMatrix.spec.ts:234-288` |
| Notes | This is the detection-gap evidence and it designs where the new tests go: **Europa's projection**, not only Callisto's assembler. |

## Not yet inspected (frontier)

- **A real `PERMISSIONS_UPDATED` document in a live Mongo (test or prod).** The single open evidence item. Would convert the "resource key is on every historical event, so no backfill" claim from *confirmed directionally* (code-level) to *confirmed* (data-level). Highest-value next inspection.
- **A live grid observation of a multi-key save and of a `MERGED` event.** Both truncations are proven in code but not yet seen rendered.
- **Europa's other read actions** — `find-all` (`@Get()`), `find-by-user-id` (`@Get('/audit-event/:userId')`), `delete-all`. Not on the grid's path; would matter only if a projection/DTO shape is shared.
- **Europa auth on the audit endpoints.** The `AUDIT` resource key is documented in Atlas's own i18n as not enforced by Europa's API; not inspected here and explicitly out of scope (see concerns).
- **`SearchParamsToMongoQueryConverter`** — only reasoned about via the index definitions (that `path` is unindexed); not read line by line. Would matter if filtering on the new field is ever requested.
- **Atlas `localStorage` migration behavior** for `europa-audit/column-settings` when a column is added — identified as an affected surface, not yet exercised.
