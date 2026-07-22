# PRDV-14055 — DRY / config refactor contingency (only if a reviewer asks)

> **Status:** not scheduled. Pure cleanup, no behavior change. Execute **only if a PR #548 reviewer calls it out** — otherwise leave as-is. Ready to hand to Codex.

## Trigger

A reviewer flags either the repeated terminal/active predicate in `uploadManagerStore.ts` or the scattered upload tuning constants.

## 1. Extract the terminal/active predicate (primary)

**File:** `src/callisto/stores/uploadManagerStore.ts`. The test `isComplete || error || isCancelled` (and its inverse) is inlined across 5 computeds. Add two helpers in the store setup:

```ts
const isTerminal = (f: TUploadFile) => !!(f.isComplete || f.error || f.isCancelled);
const isActive = (f: TUploadFile) => !isTerminal(f);
```

Rewrite the computeds to use them (behavior must be **identical**):

- `hasActiveUploads` → `uploadQueue.value.some(isActive)`
- `activeUploadsCount` → `uploadQueue.value.filter(isActive).length`
- `completedOrActiveUploadsCount` → `uploadQueue.value.filter((f) => isTerminal(f) || (f.percentCompleted ?? 0) > 0).length`
- `allUploadsComplete` → keep the empty-queue guard, then `every((f) => f.prepPhase === undefined && isTerminal(f))`
- `totalProgress` → in the reduce, `isTerminal(item) ? acc + 100 : acc + (item.percentCompleted || 0)`

## 2. Co-locate upload tuning constants (optional, only if also asked)

Upload knobs live in 4 places: `CHUNK_SIZE` (shared triton util), `MAX_CONCURRENT_UPLOADS = 5` (`useUploadItem.ts`), `MAX_CONCURRENT_FILES = 2` (`uploadManagerStore.ts`), `UPLOAD_REQUEST_TIMEOUT_MS = 10_000` (`constants.ts`). If asked, move `MAX_CONCURRENT_FILES` (and optionally `MAX_CONCURRENT_UPLOADS`) into `constants.ts` next to the timeout; leave `CHUNK_SIZE` (shared) where it is. Low value — skip unless requested.

## Verification

- The refactor is behavior-preserving, so **the existing specs must stay green with NO test changes**. If any assertion needs editing, the refactor changed behavior — stop and reassess.
- `npm run lint`, `npm run type-check` (vue-tsc), and serial Vitest over the store/title/manager/upload-item suites.

## Constraints

- Pure refactor — neighbors (`activeUploadsCount`, `hasActiveUploads`, `totalProgress`, `allUploadsComplete`) must return identical values.
- Callisto only; do not touch the watchdog or failure logic.
- Do **not** do this proactively — only on an explicit reviewer request.
