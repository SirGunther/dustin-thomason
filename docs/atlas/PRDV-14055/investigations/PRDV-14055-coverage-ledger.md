# Coverage ledger — atlas/PRDV-14055

Investigation question: Where is the Upload Manager "Uploading N of M" first number computed, why does it count *down*, and what is the complete surface that must change to make it count *up*?
Repo(s): atlas-front-end  ·  Baseline commit: ef217844 (branch PRDV-16047; PRDV-14055 branch not yet created)  ·  Started: 2026-07-21

## Consulted

- `docs/*/tickets/*/investigations/*-coverage-ledger.md` for "uploadManager", "activeUploadsCount", "UploadManagerTitle", "uploadingProgress" — **none found** (only prior ledger is `ClickUpWideLayout/.../export-clickup-ticket-to-markdown-coverage-ledger.md`, an unrelated subsystem). No prior coverage to reuse.

## Areas examined

### 1. Callisto store — `src/callisto/stores/uploadManagerStore.ts`

| Field | Value |
| --- | --- |
| Inspected | `activeUploadsCount` (43-48), `hasActiveUploads` (37-41), `allUploadsComplete` (50-57), `totalProgress` (59-68), `canStartFileUpload` + `MAX_CONCURRENT_FILES=2` (18,78-80), queue mutators, `registerFileUpload`/`unregisterFileUpload`/`waitForUploadSlot` (197-240) |
| Findings | `activeUploadsCount = filter(!isComplete && !isCancelled && !error).length` — counts **non-terminal (remaining)** files → **decreases** as uploads finish. This is the first number (the defect). `hasActiveUploads`, `totalProgress`, `allUploadsComplete` are **independent computeds**, not derived from `activeUploadsCount`. |
| Status | contributing |
| Commit | ef217844 · 2026-07-21 |
| Evidence | uploadManagerStore.ts:43-48 (root cause); :37-41,50-68 (neighbors, independent) |
| Notes | Fix target #1. Recommend a new sibling display computed; do not repurpose `activeUploadsCount` (name means "in-flight"; consumed only by the title). |

### 2. Callisto title — `src/callisto/components/FileUploadWrapper/UploadManager/UploadManagerTitle.vue`

| Field | Value |
| --- | --- |
| Inspected | Progress-text template branches (37-55); prop `activeUploadsCount` (11); i18n render (48-53) |
| Findings | Renders `t('common.uploadingProgressTxt', { active: activeUploadsCount, total: uploadQueue.length })`. Title switches to success/error/failed once `allUploadsComplete` — so "Uploading N of M" shows **only while uploads are active**. |
| Status | contributing |
| Commit | ef217844 · 2026-07-21 |
| Evidence | UploadManagerTitle.vue:48-53; i18n key common.json:134 `"Uploading {active} of {total} files..."` |
| Notes | `active` slot is where the up-count must feed. `total` already correct. |

### 3. Callisto manager — `src/callisto/components/FileUploadWrapper/UploadManager/UploadManager.vue`

| Field | Value |
| --- | --- |
| Inspected | Prop wiring (189-198); close/abort dialog (56-87); watchers |
| Findings | Passes `:active-uploads-count="uploadStore.activeUploadsCount"`. Close-confirmation uses `hasActiveUploads` (separate) — unaffected by the count change. |
| Status | contributing |
| Commit | ef217844 · 2026-07-21 |
| Evidence | UploadManager.vue:190 |
| Notes | Only wiring; behavior lives in the store computed. |

### 4. Triton manager — `src/triton/layouts/MainLayout/FileUploadWrapper/shared/UploadManager/UploadManager.vue`

| Field | Value |
| --- | --- |
| Inspected | Local `activeUploadsCount` computed (244-248); prop wiring (282); `allUploadsComplete`/`totalProgress` (203-218) |
| Findings | **Second independent copy** of the same formula (component-local, not store-backed). Same down-counting defect. |
| Status | contributing |
| Commit | ef217844 · 2026-07-21 |
| Evidence | UploadManager.vue:244-248, :282 |
| Notes | Fix target #2 (scope decision pending — open variable #2). Re-drift risk: duplicate logic. |

### 5. Triton title — `.../shared/UploadManager/UploadManagerTitle.vue`

| Field | Value |
| --- | --- |
| Inspected | Progress-text template (22-31); prop `activeUploadsCount` (5) |
| Findings | Renders **hardcoded English** `` `Uploading ${activeUploadsCount} of ${uploadQueue.length} files...` `` — NOT i18n. |
| Status | contributing |
| Commit | ef217844 · 2026-07-21 |
| Evidence | UploadManagerTitle.vue:27-29 |
| Notes | i18n conversion is a pre-existing inconsistency → future-development concern, not required by this ticket (open variable #3). |

### 6. File lifecycle — `FileUploadWrapper.vue` + `useUploadItem.ts`

| Field | Value |
| --- | --- |
| Inspected | Queue population + prep (FileUploadWrapper.vue:78-233); chunked upload + progress/complete (useUploadItem.ts:71-171) |
| Findings | State progression: `prepPhase` (parsing/starting, uploadId='') → uploadId assigned, `prepPhase=undefined` → chunks transfer, `percentCompleted` 0→100 (useUploadItem.ts:103-104) → terminal `isComplete` (159-160) / `error` / `isCancelled`. With concurrency 2, queued files sit at `percentCompleted=0`. **`percentCompleted > 0` is the reliable "actively transferring" signal**; prep/queued files are indistinguishable from just-started 0% files otherwise. |
| Status | fully-inspected |
| Commit | ef217844 · 2026-07-21 |
| Evidence | FileUploadWrapper.vue:138-200; useUploadItem.ts:103-104,159-160 |
| Notes | Determines the exact count formula (open variable #1). |

### 7. Existing specs (detection net)

| Field | Value |
| --- | --- |
| Inspected | `stores/__specs__/uploadManagerStore.spec.ts`; `components/.../__specs__/UploadManagerTitle.spec.ts`; Triton `__specs__` (glob) |
| Findings | Callisto store spec asserts `activeUploadsCount` **down**-semantics (:29 empty=0, :72 one added=1, :93 completed=0). Callisto title spec asserts `"active":1` for a 2-file queue with 1 not-complete (:57-65). **Triton manager/title have NO spec** (only DragDropUpload path-util specs exist). These encode the current behavior and are the red→green anchors. |
| Status | fully-inspected |
| Commit | ef217844 · 2026-07-21 |
| Evidence | uploadManagerStore.spec.ts:75-94; UploadManagerTitle.spec.ts:48-67; glob src/triton/.../FileUploadWrapper/**/__specs__ |
| Notes | New tests: up-count on store + Callisto title; first Triton title/manager spec; assert neighbors unchanged. |

### 8. Concurrency wiring — `UploadItem.vue` + store slot mechanism

| Field | Value |
| --- | --- |
| Inspected | `UploadItem.vue` onMounted (60-68); store `waitForUploadSlot`/`registerFileUpload`/`unregisterFileUpload` (208-240); grep of all callers |
| Findings | Gating is **wired**: each UploadItem awaits `waitForUploadSlot()` then `registerFileUpload()` before `uploadFile()`, `unregisterFileUpload()` in `finally`. With `MAX_CONCURRENT_FILES=2`, files beyond 2 sit **queued at `percentCompleted=0`** — a genuine state. The waiting state lives in the component's `onMounted`, **not** on the `TUploadFile`, so queue state cannot distinguish "waiting for slot" from "just started at 0%". `percentCompleted > 0` is the earliest reliable "actively transferring" signal. |
| Status | fully-inspected |
| Commit | ef217844 · 2026-07-21 |
| Evidence | UploadItem.vue:60-66; uploadManagerStore.ts:197-240; grep `waitForUploadSlot\|registerFileUpload` → only this caller |
| Notes | Resolves the **code half of open variable #1**: the count formula's in-progress term is constrained to `percentCompleted > 0`. |

### 9. Mounting / app binding — `App.vue`, `TritonAppContainer.vue`

| Field | Value |
| --- | --- |
| Inspected | `App.vue` (Callisto UploadManager mount, `isCallistoRoute` gate); `TritonAppContainer.vue` (Triton FileUploadWrapper/UploadManager mount) |
| Findings | Callisto `UploadManager` is mounted app-wide at `App.vue:34` gated by `isCallistoRoute` → renders across the **Callisto** route-space. Triton `UploadManager` is mounted inside `TritonAppContainer.vue` wrapping the Triton app → renders in the **Triton** app. **Both are live in separate apps; both carry the identical defect; neither is dead code.** |
| Status | fully-inspected |
| Commit | ef217844 · 2026-07-21 |
| Evidence | App.vue:5,9,19,34 (`checkIsCallistoRoute`); TritonAppContainer.vue:20-34 (FileUploadWrapper wrap) |
| Notes | Resolves the **code half of open variable #2**: scope's remaining question is a product decision (which app Ops uses), not a code fact. |

### 10. Triton i18n availability

| Field | Value |
| --- | --- |
| Inspected | Triton `FileUploadWrapper.vue` i18n usage; Triton `UploadManagerTitle.vue` (hardcoded); `common.json` keys |
| Findings | Triton components already use the shared `common.*` i18n namespace (Triton `FileUploadWrapper.vue` → `t('common.invalidFileName')`, etc.). `common.uploadingProgressTxt` and `uploadAllSuccessTxt` already exist. A Triton conversion **reuses existing keys — no new keys required** → low-effort. |
| Status | fully-inspected |
| Commit | ef217844 · 2026-07-21 |
| Evidence | Triton FileUploadWrapper.vue:37,68,73 (`useI18n`/`t('common.*')`); common.json:132-134 |
| Notes | Resolves the **code half of open variable #3**: conversion cost is small; convert-vs-defer stays a scope decision. |

## Not yet inspected (frontier)

- **Which app the Ops user operates in** (Callisto route-space vs Triton app) — the **workflow half** of scope (open var #2). Now a product/PM decision, not a code question — the code half is resolved (both apps live, both defective; areas 9).
- **Mid-batch error/cancel count treatment** — the **workflow half** of open var #1 (stay-counted vs drop). UX decision, code-unconstrained.
- **Runtime confirmation** of the count rising (browser-loop) — deferred to Phase 5 validation, not root-cause.
- **`buildContextForFile` / mime helpers / abort paths** — out of scope for the count behavior; not inspected.
