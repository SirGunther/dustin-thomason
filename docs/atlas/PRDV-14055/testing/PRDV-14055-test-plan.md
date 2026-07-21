# Test plan — atlas/PRDV-14055

> Seeded from [PRDV-14055-investigation.md](../investigations/PRDV-14055-investigation.md) §9 on 2026-07-21. Refined by spec: pending.

Status: seeded

## Scope and surfaces under test

- The Upload Manager first number ("Uploading N of M files") must count **up** (completed + in-progress), rising to the total, with the second number unchanged.
- Surfaces: Callisto `uploadManagerStore.ts` (display computed) + `UploadManagerTitle.vue`; Triton `UploadManager.vue` (local computed) + `UploadManagerTitle.vue` **if scope includes Triton** (open var #2). Neighbors that must stay unchanged: `hasActiveUploads`, `totalProgress`, `allUploadsComplete`, title success/error/failed branches.

## Happy path

- [ ] HP-1: Empty queue → new display computed → returns `0`.
- [ ] HP-2: Queue of N with none started (prep/queued at 0%) → count reflects the locked in-progress rule (recommended: `0`, since none have `percentCompleted > 0`).
- [ ] HP-3: Staged queue — some `percentCompleted > 0`, some `isComplete`, rest queued → count = (in-progress + completed), and is **≥** the previous observed value (monotonic up).
- [ ] HP-4: All files `isComplete` → count === `uploadQueue.length` (first === second === total).
- [ ] HP-5: Callisto `UploadManagerTitle` renders `uploadingProgressTxt` with `active` = the up-count and `total` = queue length.
- [ ] HP-6 (Triton, if in scope): Triton title renders the up-count in its `Uploading X of Y files...` string.

## Negative paths

- [ ] NP-1: All errored → title shows `uploadFailedTxt` (unchanged branch); count never negative or above total.
- [ ] NP-2: Mixed success/error → title shows `uploadCompletedWithErrorsTxt` (unchanged); count treatment of failed files matches locked decision (open var #1) and never drops below a value already shown on the happy path.
- [ ] NP-3: Empty queue → no progress message rendered (preserve existing behavior).

## Edge cases

- [ ] EC-1 (regression): `hasActiveUploads` still gates the close-confirmation dialog / beforeunload guard — unchanged by the count change.
- [ ] EC-2 (regression): `totalProgress` bar math unchanged (existing assertions still pass).
- [ ] EC-3: Second number equals `uploadQueue.length` in every state.

## Test map

| Repo | Suite | Asserts |
| --- | --- | --- |
| atlas-front-end | `src/callisto/stores/__specs__/uploadManagerStore.spec.ts` | new up-count computed: empty=0, in-progress+completed rises, all-complete === length; existing `activeUploadsCount`/`hasActiveUploads`/`totalProgress` assertions still pass (neighbors unchanged) |
| atlas-front-end | `src/callisto/components/FileUploadWrapper/UploadManager/__specs__/UploadManagerTitle.spec.ts` | title renders the up-count in `active` (update the current `"active":1` down-semantics assertion to the new semantics) |
| atlas-front-end | Triton `UploadManagerTitle`/`UploadManager` spec (**new**, if in scope) | first-ever spec for the Triton title/manager count (closes detection gap C4) |

## Gates

| Gate | Command |
| --- | --- |
| audit | `npm audit --audit-level=high` |
| lint | `npm run lint` |
| tests | `npx vitest run --maxWorkers 1 src/callisto/stores/__specs__/uploadManagerStore.spec.ts src/callisto/components/FileUploadWrapper/UploadManager/__specs__` (+ Triton path if in scope) |

## Results log (filled at execution)

| Date | Gate/Scenario | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- | --- |
