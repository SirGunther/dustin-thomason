# PRDV-14055 — Upload Manager count up instead of down (spec)

> Frontend-only story in `atlas-front-end`. Investigation: [PRDV-14055-investigation.md](../investigations/PRDV-14055-investigation.md).
> Locked decisions: [PRDV-14055-locked-decisions.md](./PRDV-14055-locked-decisions.md). Test plan: [PRDV-14055-test-plan.md](../testing/PRDV-14055-test-plan.md).

## Problem → Requirement → Solution

- **Problem:** In the Upload Manager, the progress message "Uploading N of M files…" shows **N = remaining** uploads, so N *decreases* as files finish. To an Ops user it looks like files are being removed from the queue / failing, not completing.
- **Requirement:** The first number must represent **completed + in-progress** uploads and **count up** to the total as files transfer and finish, ending equal to the total (and the second number) on the happy path. It must **never decrease** — including when a started upload later fails or is cancelled (LD-001).
- **Solution:** Add a dedicated display count (Callisto store) computed as `isComplete || percentCompleted > 0`, and feed it into the existing title `active` slot in place of `activeUploadsCount`. Leave `activeUploadsCount`, `hasActiveUploads`, `totalProgress`, `allUploadsComplete`, and the title's success/error/failed branches untouched. **Callisto only** this ticket (LD-002); Triton is a follow-up (LD-003).

## Locked Decisions From Q and A

| Decision | Source | Implementation consequence |
| --- | --- | --- |
| First number **stays counted** when a started upload later errors/cancels; never drops back (LD-001) | Product, 2026-07-21 | Formula `isComplete \|\| percentCompleted > 0` (a started-then-failed file keeps `percentCompleted > 0`); monotonic, bar-consistent |
| Scope = **Callisto only** (LD-002) | User, 2026-07-21 | Touch only the Callisto store + title; Triton left as-is |
| Triton count fix + i18n **deferred** to follow-up (LD-003) | Follows LD-002 | Recorded in future-development-concerns Concern 2; no Triton files changed here |

Full ledger with sources and rejected paths: [PRDV-14055-locked-decisions.md](./PRDV-14055-locked-decisions.md).

## Acceptance criteria

| Criterion | How met |
| --- | --- |
| First number = completed + in-progress (not remaining) | New display computed `isComplete \|\| percentCompleted > 0` |
| First number counts up to total as files begin/complete | Monotonic: `percentCompleted` and terminal flags only move forward |
| Happy-path end state: first == second == total | All `isComplete` → count === `uploadQueue.length` |
| Second number stays = total | Unchanged (`uploadQueue.length`) |
| Number never drops back on mid-batch failure (LD-001) | Started-then-failed file keeps `percentCompleted > 0` → stays counted |

## 1. Folder hierarchy

N/A — no new folders. Changes are confined to existing files under `src/callisto/`.

## 2. New classes (name + path)

N/A — no new classes. One new **computed** added to the existing Pinia store:

| Symbol | File | Change |
| --- | --- | --- |
| `completedAndInProgressCount` (name TBD in impl) computed | [src/callisto/stores/uploadManagerStore.ts](src/callisto/stores/uploadManagerStore.ts) | **new** computed `isComplete \|\| percentCompleted > 0`; export it |
| `UploadManager.vue` | [src/callisto/components/FileUploadWrapper/UploadManager/UploadManager.vue](src/callisto/components/FileUploadWrapper/UploadManager/UploadManager.vue#L190) | pass the new computed into `:active-uploads-count` |
| `UploadManagerTitle.vue` | [UploadManagerTitle.vue](src/callisto/components/FileUploadWrapper/UploadManager/UploadManagerTitle.vue#L48-L53) | no change needed (renders whatever `activeUploadsCount` prop it receives) — verify prop name/semantics |

Note: `activeUploadsCount` and `hasActiveUploads` are **kept unchanged** (still used by the close-confirmation dialog / beforeunload guard). The new computed is additive so neighbors and their specs stay intact.

## 3. New entities

N/A — frontend display change; no persistence.

## 4. Modified entities

N/A — no entities/DTOs. `TUploadFile` shape is unchanged (`isComplete`, `percentCompleted` already exist).

## 5. New migrations (file names)

N/A — no schema.

## 6. New migration classes

N/A.

## 7. New DTOs

N/A — no API contract change (pure client-side count).

## 8. New projections

N/A.

## Cross-cutting / optional callouts

- **HTTP surface:** N/A — no route/DTO/status change.
- **i18n:** Callisto already uses `common.uploadingProgressTxt` = `"Uploading {active} of {total} files..."`; the `{active}` param now receives the up-count. **No i18n key change.**
- **Registries / module wiring:** N/A.
- **Protect-the-neighbors (regression):** `hasActiveUploads` (close dialog / beforeunload), `totalProgress` (bar), `allUploadsComplete` (title switch), `MAX_CONCURRENT_FILES` gating — all independent computeds, must stay unchanged; asserted in the test plan.
- **Spec tests:** update `uploadManagerStore.spec.ts` (new up-count: empty=0, in-progress+completed rises, all-complete === length; LD-001 mid-batch-failure holds; neighbors unchanged) and `UploadManagerTitle.spec.ts` (title renders the up-count). Detail in the test plan.
- **Feature flags / companion tickets:** Triton follow-up (LD-003 / future-development-concerns Concern 2).
