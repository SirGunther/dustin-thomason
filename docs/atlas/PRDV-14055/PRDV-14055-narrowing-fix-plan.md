# PRDV-14055 — Narrowing fix plan (for Codex)

## Objective

Keep the offline/stalled-upload fix **entirely in the Callisto upload layer** and remove the global/request-layer axios-timeout changes. The abort-based **watchdog** in `useUploadItem` is the real mechanism: its `Promise.race` rejects at 10 s and `abort()`s the request, which makes the file terminal and frees its slot. The axios `timeout` + the `apiClient`/`useApiRequest` changes are redundant belt-and-suspenders behind it, and they widen the blast radius onto every API caller and exceed the approved (Callisto-only) spec.

**Why it's safe to drop them:** an aborted request rejects with `ERR_CANCELED`, which is **not** in `apiClient`'s retryable list, so it never enters the retry loop — there's no orphaned-retry to guard against. The `apiClient` guard existed only because the code *also* set axios `timeout` (`ECONNABORTED`, which **is** retryable). Remove the axios `timeout` and the guard is unnecessary.

## Do NOT touch (this is the fix — leave as-is)

- `src/callisto/components/FileUploadWrapper/UploadManager/UploadItem/composables/useUploadItem.ts` — the `withUploadTimeout` watchdog, `markUploadFailed`, and the re-throw. **Keep** its `import { UPLOAD_REQUEST_TIMEOUT_MS } from '../../composables/requests/constants'` — the watchdog's own `setTimeout` uses it.
- `src/callisto/components/FileUploadWrapper/UploadManager/composables/requests/constants.ts` — keep (`UPLOAD_REQUEST_TIMEOUT_MS` is the watchdog deadline).
- `src/callisto/stores/uploadManagerStore.ts` (`completedOrActiveUploadsCount`) and `src/callisto/components/FileUploadWrapper/UploadManager/UploadManager.vue` (title wiring + closeout-guard removal).
- `src/callisto/components/FileUploadWrapper/UploadManager/types.ts` — **keep** the `signal?: AbortSignal` on `UploadCompleteParams` (the watchdog aborts the completion request through it).
- Specs: `uploadManagerStore.spec.ts`, `UploadManagerTitle.spec.ts`, `UploadManager.spec.ts`, `useUploadItem.spec.ts` (incl. the never-settling watchdog test).

## Undo / change (per file)

1. **`src/globalApi/apiClient.ts` — revert to `main`.** Remove the added block:
   ```ts
   if (error.code === 'ECONNABORTED' && originalRequest?.timeout) {
     return Promise.reject(error);
   }
   ```
   (and its comment). The file should match `origin/main`.

2. **`src/globalApi/useApiRequest.ts` — revert to `main`.** Remove `timeout?: number` from `ApiRequestConfig`, `timeout` from the destructured params, and `timeout` from the `apiClient.request({ … })` call.

3. **`src/callisto/components/FileUploadWrapper/UploadManager/composables/requests/useUploadChunk.ts`** — remove `import { UPLOAD_REQUEST_TIMEOUT_MS } from './constants';` and the `timeout: UPLOAD_REQUEST_TIMEOUT_MS,` line in the `useApiRequest` call. Keep everything else (including `signal`).

4. **`src/callisto/components/FileUploadWrapper/UploadManager/composables/requests/useUploadComplete.ts`** — remove the `constants` import and the `timeout: UPLOAD_REQUEST_TIMEOUT_MS,` line. **Keep** the `signal` in the destructure and the `signal,` passthrough — the watchdog uses it to abort the completion request.

## Test updates

5. **`.../composables/requests/__specs__/useUploadComplete.spec.ts`** — remove the assertion that the request config carries the upload `timeout`. Keep the payload (and any `signal`) assertions.
6. **`.../composables/requests/__specs__/useUploadChunk.spec.ts`** (added this ticket) — remove the timeout assertion. If nothing meaningful remains (the chunk request had no dedicated spec before), **delete the file**.

## Verification (report exact command + result)

- `npm run lint` — must pass.
- Serial Vitest over the touched area:
  ```
  npx vitest run --maxWorkers 1 \
    src/callisto/stores/__specs__/uploadManagerStore.spec.ts \
    src/callisto/components/FileUploadWrapper/UploadManager/__specs__ \
    src/callisto/components/FileUploadWrapper/UploadManager/UploadItem/composables/__specs__/useUploadItem.spec.ts \
    src/callisto/components/FileUploadWrapper/UploadManager/composables/requests/__specs__
  ```
- **Manual re-check (offline):** the watchdog is unchanged, so offline behavior should be identical — reconfirm anyway per the test plan's offline scenario (start online → switch to Offline after transfer begins → leave the browser untouched → each stalled active pair becomes terminal in ~10 s and the batch resolves). This proves removing the axios-timeout belt didn't regress AC5.

## Constraints

- Do **not** remove or weaken the watchdog (`withUploadTimeout`) — it is the mechanism; only the axios-`timeout` belt is being removed.
- Do **not** delete `constants.ts`.
- Do **not** touch anything outside the files listed. The whole point is to shrink back to Callisto-only and off the global API surface.
- Do **not** add new behavior.

## After Codex is done (Dustin/me)

The PR draft ([PRDV-14055-pr-draft.md](./PRDV-14055-pr-draft.md)) needs its **global-layer entries removed**: drop `apiClient.ts` / `useApiRequest.ts` from the per-file GitHub comments, and update the Description's third bullet to state the offline fix is the Callisto-layer watchdog only (no global/API change).
