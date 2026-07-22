# Test plan — atlas/PRDV-14055

> Seeded from [PRDV-14055-investigation.md](../investigations/PRDV-14055-investigation.md) §9 on 2026-07-21. Refined against the approved Callisto-only spec on 2026-07-21.

Status: complete with manual runtime validation pending

## Scope and surfaces under test

- The Upload Manager first number ("Uploading N of M files") must count **up** (completed + in-progress), rising to the total, with the second number unchanged.
- Surfaces: Callisto `uploadManagerStore.ts`, `UploadManager.vue`, `UploadManagerTitle.vue`, and `useUploadItem.ts`. Triton is out of scope. Neighbors that must stay unchanged: `activeUploadsCount`, `hasActiveUploads`, `totalProgress`, `allUploadsComplete`, and title success/error/failed branches.

## Happy path

- [x] HP-1: Empty queue → new display computed → returns `0`.
- [x] HP-2: Queue of N with none started (prep/queued at 0%) → count reflects the locked in-progress rule (recommended: `0`, since none have `percentCompleted > 0`).
- [x] HP-3: Staged queue — some `percentCompleted > 0`, some `isComplete`, rest queued → count = (in-progress + completed), and is **≥** the previous observed value (monotonic up).
- [x] HP-4: All files `isComplete` → count === `uploadQueue.length` (first === second === total).
- [x] HP-5: Callisto `UploadManagerTitle` renders `uploadingProgressTxt` with `active` = the up-count and `total` = queue length.
- [x] HP-6: Successful uploads retain existing completion behavior: `isComplete` is set and no `error` is introduced.

## Negative paths

- [x] NP-1: All errored → every queue item has `error`; title shows `uploadFailedTxt` (unchanged branch); count reaches the total without exceeding it.
- [x] NP-2: Mixed success/error → title shows `uploadCompletedWithErrorsTxt` (unchanged); errored files remain counted and the number never drops.
- [x] NP-3: Empty queue → no progress message rendered (preserve existing behavior).
- [x] NP-4: Chunk/network failure marks `fileToUpload.error` and fires the failure toast.
- [x] NP-5: Upload-complete failure, including a 0-byte/zero-part upload, marks `fileToUpload.error`, fires the failure toast, and allows the batch to resolve.

## Edge cases

- [x] EC-1 (regression): `hasActiveUploads` still gates the close-confirmation dialog / beforeunload guard — unchanged by the count change.
- [x] EC-2 (regression): `totalProgress` bar math unchanged (existing assertions still pass).
- [x] EC-3: Second number equals `uploadQueue.length` in every state.
- [x] EC-4: Offline mid-batch: each upload that cannot finish is marked failed, remains counted, fires failure feedback, and does not leave the manager hanging.

## Test map

| Repo | Suite | Asserts |
| --- | --- | --- |
| atlas-front-end | `src/callisto/stores/__specs__/uploadManagerStore.spec.ts` | new up-count computed: empty=0, in-progress+completed rises, all-complete === length; existing `activeUploadsCount`/`hasActiveUploads`/`totalProgress` assertions still pass (neighbors unchanged) |
| atlas-front-end | `src/callisto/components/FileUploadWrapper/UploadManager/__specs__/UploadManagerTitle.spec.ts` | title renders the up-count in `active` (update the current `"active":1` down-semantics assertion to the new semantics) |
| atlas-front-end | nearest `useUploadItem` unit/composable suite | chunk, completion, and offline failures set queue-visible `error`, notify the user, and permit terminal batch resolution |

## Gates

| Gate | Command |
| --- | --- |
| audit | `npm audit --audit-level=high` |
| lint | `npm run lint` |
| tests | `npx vitest run --maxWorkers 1 src/callisto/stores/__specs__/uploadManagerStore.spec.ts src/callisto/components/FileUploadWrapper/UploadManager/__specs__` (+ Triton path if in scope) |

## Results log (filled at execution)

| Date | Gate/Scenario | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- | --- |
| 2026-07-21 | audit | `npm audit --audit-level=high` | `atlas-front-end` dependency tree | blocked: 93 existing vulnerabilities (90 high) | No fix available reported for affected dependency paths; ticket changes no dependencies. |
| 2026-07-21 | lint | `npm run lint` | full `atlas-front-end` lint scope | pass | — |
| 2026-07-21 | tests | `npx vitest run --maxWorkers 1 src/callisto/stores/__specs__/uploadManagerStore.spec.ts src/callisto/components/FileUploadWrapper/UploadManager/__specs__ src/callisto/components/FileUploadWrapper/UploadManager/UploadItem/composables/__specs__/useUploadItem.spec.ts` | Callisto Upload Manager store, title, error row, and upload-item failure behavior | pass: 4 files, 47 tests | Runtime browser upload remains Phase 6 manual-review evidence; automated failure and terminal-batch paths are covered. |
| 2026-07-22 | lint | `npm run lint` | full `atlas-front-end` lint scope | pass | Toast deduplication follow-up. |
| 2026-07-22 | tests | `npx vitest run --maxWorkers 1 src/callisto/components/FileUploadWrapper/UploadManager/UploadItem/composables/__specs__/useUploadItem.spec.ts` | Upload-item terminal failure notifications | pass: 1 file, 3 tests | Verifies a file-specific error toast with `multiple: false`. |
