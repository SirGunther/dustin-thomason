# PRDV-14055 — Lana (p-lana) review fixes — implementation plan (for Codex)

## Context

PR [atlas-front-end #548](https://github.com/planetdepos/atlas-front-end/pull/548) got a changes-requested review from **p-lana** with two recurring patterns:
1. **Hardcoded user-facing strings → i18n JSON** (comments on `useUploadItem.ts:54, 77, 81`).
2. **Status literals → named constants** (comment on `useUploadItem.ts:192`, `result.status === 'rejected'`).

This plan implements both on the Callisto Upload Manager. Two scope calls were made deliberately (see each change): we also localize the one pre-existing string in the same file she didn't flag (consistency), and we put the status constant in the global constants file (reusable). All changes are Callisto-only and behavior-preserving except the intended string/constant swaps. **New commit on `PRDV-14055`; push updates PR #548** (do not squash away prior history unless asked).

---

## Change 1 — i18n the user-facing strings in `useUploadItem.ts`

**File:** `src/callisto/components/FileUploadWrapper/UploadManager/UploadItem/composables/useUploadItem.ts`

**a. Add the hook** (model: `useApproveFiles.ts`, `UploadManagerTitle.vue`; valid because `useUploadItem()` runs during `UploadItem.vue`'s `setup()`):
- add `import { useI18n } from 'vue-i18n';`
- inside the composable factory, near the refs (~line 23): `const { t } = useI18n();`

**b. Replace all four user-facing strings** (`t` is in closure scope for all of these):

| Line | Before | After |
| --- | --- | --- |
| ~54 | `new Error('Upload request timed out')` | `new Error(t('common.uploadTimedOutTxt'))` |
| ~77 | `: 'Upload failed'` (fallback) | `: t('common.uploadFailedTxt')` — reuse existing key |
| ~81 | `` msg: `${fileToUpload.fileAndPath.file.name} failed to upload` `` | `msg: t('common.fileFailedToUploadTxt', { name: fileToUpload.fileAndPath.file.name })` |
| ~117 | `msg: 'Failed to cancel upload'` | `msg: t('common.cancelUploadFailedTxt')` |

(Line 117 wasn't flagged by Lana but is the same pattern in the same file — folding it in avoids leaving one hardcoded string beside three localized ones. Called out in the PR reply below.)

**c. Add keys** to `src/i18n/en-US/common.json`, next to the existing upload keys (~line 131-135):
```json
"uploadTimedOutTxt": "Upload request timed out",
"fileFailedToUploadTxt": "{name} failed to upload",
"cancelUploadFailedTxt": "Failed to cancel upload",
```
`"uploadFailedTxt": "Upload failed"` already exists — the ~77 fallback reuses it. Do not duplicate it.

---

## Change 2 — `PROMISE_STATUS` constant

**File:** `src/globalUtils/constants.ts` — add, matching the existing `HttpMethod` / `ContentType` `as const` style:
```ts
export const PROMISE_STATUS = {
  FULFILLED: 'fulfilled',
  REJECTED: 'rejected',
} as const;
export type PromiseStatus = (typeof PROMISE_STATUS)[keyof typeof PROMISE_STATUS];
```
(Both members defined to satisfy her "and other statuses"; global so the out-of-scope Triton twin can reuse it later.)

**File:** `useUploadItem.ts` (~line 192):
- import `PROMISE_STATUS` from `@globalUtils/constants`
- `(result) => result.status === 'rejected'` → `(result) => result.status === PROMISE_STATUS.REJECTED`
- **Leave** the `error.name === 'CanceledError' / 'AbortError'` checks (~166-167) unchanged — error *type names*, not statuses; out of scope (flagged to reviewer).
- **Type-check note:** `PROMISE_STATUS.REJECTED` is the literal type `'rejected'` (via `as const`), so discriminated-union narrowing still applies and `failedUpload.reason` (~195) stays valid. The `vue-tsc` gate confirms.

---

## Change 3 — Spec updates

**File:** `src/callisto/components/FileUploadWrapper/UploadManager/UploadItem/composables/__specs__/useUploadItem.spec.ts`

- **Add** the `vue-i18n` mock at the top (identity `t` returning the key; params JSON-appended — matches `useRenameItem.spec.ts`):
  ```ts
  vi.mock('vue-i18n', () => ({
    useI18n: () => ({
      t: (key: string, params?: Record<string, unknown>) =>
        params ? `${key}:${JSON.stringify(params)}` : key,
    }),
  }));
  ```
- **Change** the three `notify` `msg` assertions: `'test.pdf failed to upload'` → `'common.fileFailedToUploadTxt:{"name":"test.pdf"}'`.
- **Change** the timeout test: `expect(fileToUpload.error?.message).toBe('Upload request timed out')` → `toBe('common.uploadTimedOutTxt')`.
- **Keep unchanged:** the `'Network lost'` and `'Zero-part upload failed'` assertions — those come from the test's mocked rejections, not i18n.
- **No new test** for `PROMISE_STATUS` — behavior-preserving; the existing chunk-failure test already drives the `=== REJECTED` path.

---

## Verification (report exact command + result)

1. `npm run lint` — `eslint . --max-warnings 0`. The longer `t(...)` lines may trip a prettier wrap warning (`--max-warnings 0` fails on it); run `npx eslint --fix <file>` and re-lint until clean.
2. `npm run type-check` — `vue-tsc --noEmit` (confirms the i18n types + `PROMISE_STATUS` narrowing). **Vitest does not type-check — this gate is separate and must pass.**
3. Serial unit tests:
   ```
   npx vitest run --maxWorkers 1 \
     src/callisto/stores/__specs__/uploadManagerStore.spec.ts \
     src/callisto/components/FileUploadWrapper/UploadManager/__specs__ \
     src/callisto/components/FileUploadWrapper/UploadManager/UploadItem/composables/__specs__ \
     src/callisto/components/FileUploadWrapper/UploadManager/composables/requests/__specs__
   ```
4. The pre-push hook runs `test:unit:ci` + `lint` + `type-check` — all must be green before the push lands.

---

## PR replies to post on #548 (after the code lands)

**On the constants comment (line 192):**
> Per your comment, moved `'rejected'` into a global `PROMISE_STATUS` constant. Heads-up that there are a couple of similarly-structured literals nearby — the `error.name === 'CanceledError' / 'AbortError'` checks. We scoped this change to the statuses you flagged, but if you'd like those folded in the same way, just say and we'll add them.

**On the cancel string (the i18n thread / line 117):**
> Also moved `'Failed to cancel upload'` in this file to i18n even though it wasn't flagged — same pattern as the ones you called out, and leaving one hardcoded string next to the localized ones would just recreate the inconsistency later.

---

## Out of scope / parked

- **DRY `isTerminal`/`isActive` refactor** (`uploadManagerStore.ts`) — stays in `PRDV-14055-dry-refactor-contingency.md`. Lana didn't ask; different file; keeps this review-response focused.
- **Error-name literals** (`CanceledError` / `AbortError`) — flagged to the reviewer; implement only if she asks.
- **Triton twin** (`src/triton/.../UploadItem/composables/useUploadItem.ts`) has the same hardcoded strings + `'rejected'` — separate follow-up per LD-002; `PROMISE_STATUS` being global lets it reuse the constant when that ticket runs.

## Constraints

- Callisto only; no API/backend/schema changes.
- Behavior-preserving apart from the intended string/constant swaps — existing assertions change only where the asserted value moved to a translation key.
