# PRDV-14055 — atlas-front-end PR draft (ready to open)

> When ready: commit → push `PRDV-14055` → `gh pr create --base main` (**no `--reviewer`**) with the body below.
> The **Testing and Verification** section has a header per functional area — drop the corresponding **video** under each on GitHub. The **Per-file review comments** at the bottom are **not** part of the PR body — post each as a comment on that file in the PR's *Files changed* tab (keeping the "why" out of the codebase).
>
> **Title:** `PRDV-14055: Upload Manager counts up instead of down`

---

### Clickup

https://app.clickup.com/t/43227262/PRDV-14055

### Description:

The Upload Manager progress message "Uploading N of M files…" showed **N = remaining** uploads, so it counted *down* as files finished — it looked like files were being removed from the queue rather than completing. This makes the first number **count up** and makes upload failures visible and terminal (Callisto only; Triton is a separate follow-up).

- **Count up** — new `uploadManagerStore` computed `completedOrActiveUploadsCount` (`isComplete || error || isCancelled || percentCompleted > 0`) feeds the title in place of `activeUploadsCount`. `activeUploadsCount`, `hasActiveUploads`, and `totalProgress` are unchanged.
- **Failures are terminal + visible** — `useUploadItem` writes the error to the queue item for chunk, completion (incl. 0-byte / zero-part), and outer failures, shows the error row, and fires one file-named dark toast (`multiple: false`). The all-failed/mixed batch now starts the 5-second closeout (previously an all-failed batch showed "Closing in 5s" but never closed).
- **Offline / stalled requests resolve without a debugger** — a 10-second watchdog in `useUploadItem` races each chunk/completion mutation against a deadline, aborts the underlying request on expiry, and marks the file terminal so its upload slot frees and the batch resolves. Entirely in the Callisto upload layer — no global/API change.

No API/backend contract, schema, global-API, or i18n-key changes; scope is Callisto only.

### Testing and Verification

Automated: `npm run lint` passes; focused serial Vitest passes (7 files, 52 tests) across the store, title, upload-manager, upload-item (incl. a never-settling request hitting the watchdog), and request-composable suites. `npm audit --audit-level=high` is blocked by 93 pre-existing dependency vulnerabilities — no dependencies changed here.

Manual runtime evidence (video per area):

#### Count-up — happy path
_(video: batch uploads, first number climbs to the total, then "All files uploaded successfully")_

#### Zero-byte file — terminal failure + closeout
_(video: 0-byte file errors, shows the error row + file-named toast, batch starts the 5s closeout)_

#### Mixed batch — completed with errors
_(video: normal files + a 0-byte file; both counted, number never drops, ends "completed with errors")_

#### All-failed batch — closeout
_(video: an all-failed batch starts and completes the 5s closeout)_

#### Offline mid-batch — resolves via watchdog (no debugger)
_(video: start online, switch to Offline after transfer begins, browser left untouched; stalled files become terminal ~10s and the batch resolves)_

#### Regression — per-file cancel
_(video: the upload item's X still cancels; cancel/close-confirm behavior unchanged)_

### Checklist

- [ ] Evidence provided. _(videos above + automated results)_

---

## Per-file review comments — post on GitHub (Files changed tab), NOT in the code

One comment per file, anchored to the noted spot. These carry the "why" so it stays in the PR record, not the codebase.

| File | Comment to post |
| --- | --- |
| `src/callisto/stores/uploadManagerStore.ts` | Added `completedOrActiveUploadsCount` (terminal-or-started) as the count-up value. Deliberately additive — `activeUploadsCount` is left intact because it still drives the close-confirmation dialog and before-unload guard, so those neighbors don't change. |
| `src/callisto/components/FileUploadWrapper/UploadManager/UploadManager.vue` | Two changes: (1) title now binds the new count-up computed instead of `activeUploadsCount`; (2) removed the success-only guard in the `allUploadsComplete` watcher — an all-failed (or mixed) batch previously showed "Closing in 5s" but never actually closed; now every terminal batch runs the closeout. |
| `src/callisto/components/FileUploadWrapper/UploadManager/UploadItem/composables/useUploadItem.ts` | `markUploadFailed` writes the failure to the queue item (not just local state) for chunk/completion/outer failures + one file-named toast (`multiple:false`), so failures are counted, shown, and let the batch resolve. `uploadPart` now re-throws (previously swallowed the error, which is why failures were silent). The 10s watchdog (`withUploadTimeout`) races each chunk/completion mutation against a deadline and aborts on expiry — chosen because a browser-stalled/offline request may never settle on its own, and this frees the upload slot without any debugger interaction. Self-contained here — no global/API change needed. |
| `src/callisto/components/FileUploadWrapper/UploadManager/composables/requests/constants.ts` (new) | `UPLOAD_REQUEST_TIMEOUT_MS = 10s` — the watchdog deadline used by `useUploadItem`. |
| `src/callisto/components/FileUploadWrapper/UploadManager/composables/requests/useUploadComplete.ts` + `types.ts` | `UploadCompleteParams` gains an optional `signal`, threaded to the completion request so the watchdog can abort it (`useUploadChunk` already accepted a `signal`). |

_Spec files (`*.spec.ts`) don't need a rationale comment unless a reviewer asks._
