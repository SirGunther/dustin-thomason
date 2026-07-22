# PRDV-14055 — Testing and Implementation Record

Created in the PRDV-14055 testing folder at the request of Dustin Thomason. This is the implementation/testing record for this ticket.

## Scope

Callisto Upload Manager only. The ticket changes the first number in the upload title from “files still active” to “files that have started or reached a terminal state,” and makes upload failures visible and terminal.

## Acceptance expectations

- The Upload Manager’s first number counts a file once it has started transferring (`percentCompleted > 0`) and continues to count it when it completes, fails, or is cancelled. It is a count-up value and reaches the unchanged total at terminal batch state.
- Queued files at 0% do not count until they start. Existing `activeUploadsCount`, `hasActiveUploads`, total-progress calculation, and title success/error/failed branches remain otherwise unchanged.
- Chunk, completion, zero-byte, and network failures record an error on the queue item. The error row, terminal total-progress contribution, completed-with-errors or failed title, and closeout state must update.
- A failed-file toast is one dark error toast per distinct file name; duplicate identical failure toasts are suppressed with `multiple: false`.
- Success-only, mixed-result, and all-failed batches close after the five-second countdown. Existing cancel, close-confirmation, and before-unload behavior remains unchanged.
- An offline mid-batch must resolve without external browser/debugger interaction. A request that never settles must become terminal, free its file-upload slot, and allow the next queued file to begin.
- Scope remains Callisto-only: no API/backend contract, schema, or i18n-key changes.

## Rejected and revised approach history

### Initial approach: Axios request timeout only

The first correction added a 10-second `timeout` to the upload-part and upload-complete request configuration and prevented a configured timeout from entering the global network retry loop. The expectation was that Axios would reject the offline request, allowing the existing failure handler and slot-release `finally` block to run.

This was not sufficient. After the frontend server was restarted and the browser page was refreshed, the offline batch still hung for more than 30 seconds. The browser’s pending request did not settle, so a configuration-only Axios timeout was not a reliable terminal signal for this test condition. That approach is retained only as a secondary request-layer guard; it is not the mechanism relied upon to release the upload queue.

### Final approach: code-level upload watchdog

The upload flow now races each chunk and completion mutation against its own 10-second deadline. On expiry it rejects the upload flow, aborts the underlying request through a per-operation abort signal, records the file failure, and returns control to `UploadItem`’s existing `finally`, which releases the file-upload slot. A unit test uses a promise that never resolves and verifies this terminal failure path. This change was made because it does not depend on the browser/network layer choosing to settle the request.

### Browser-observation constraint

During investigation, attaching an external browser debugger coincided with stalled failures resolving and the queue advancing. Because that interaction changes the observed behavior, no further browser/debugger attachment is used to judge the offline test. Manual validation must leave the browser untouched after Offline is selected.

## Observed behavior, expected behavior, and implementation

| Observed behavior | Expected behavior | Implemented fix | Files changed |
| --- | --- | --- | --- |
| The title’s first number dropped as files completed, so it did not provide a count-up view of batch progress. | The first number increases as a file starts transferring and remains counted when it completes, fails, or is cancelled. The total remains unchanged. | Added `completedOrActiveUploadsCount`, which counts `isComplete`, `error`, `isCancelled`, or `percentCompleted > 0`; wired the title to that computed value only. | `src/callisto/stores/uploadManagerStore.ts`; `src/callisto/components/FileUploadWrapper/UploadManager/UploadManager.vue` |
| Failed chunk and completion operations could leave the manager without terminal error state. | A failed file displays as an error, contributes to terminal batch state and total progress, and lets the batch resolve. | `markUploadFailed` writes the error to the queue item for chunk, completion, and outer upload failures. | `src/callisto/components/FileUploadWrapper/UploadManager/UploadItem/composables/useUploadItem.ts` |
| A zero-byte file has no chunk requests and goes directly to upload completion; when that completion fails, it must not remain active or leave the batch open. | A zero-byte completion failure is terminal: it shows the file error, contributes to the final count and total progress, displays the failed/completed-with-errors state, and starts the five-second closeout. | The completion failure path calls `markUploadFailed`; the final watchdog also bounds a completion request that never settles. | `src/callisto/components/FileUploadWrapper/UploadManager/UploadItem/composables/useUploadItem.ts`; `src/callisto/components/FileUploadWrapper/UploadManager/types.ts`; `src/callisto/components/FileUploadWrapper/UploadManager/composables/requests/useUploadComplete.ts` |
| A failed file emitted a generic dark toast; a batch could stack identical toasts. | Failure is visible without duplicate toast spam. | The toast names the failed file and uses the existing dark/error presentation with `multiple: false`. | `src/callisto/components/FileUploadWrapper/UploadManager/UploadItem/composables/useUploadItem.ts` |
| An all-failed batch displayed “Closing in 5s” but did not actually close. | Every terminal batch—success, mixed result, or all failed—starts the five-second closeout. | Removed the success-only guard from the terminal-batch watcher. | `src/callisto/components/FileUploadWrapper/UploadManager/UploadManager.vue` |
| During the offline-batch test, the manager sat at a partial count until an external browser debugger attached. The debugger attachment then caused failed requests to settle and the queue to advance. The initial Axios timeout configuration alone did not change this behavior. | Offline or browser-stalled requests must become terminal without debugger or browser interaction, freeing the two upload slots and allowing the batch to resolve. | Added a code-level 10-second watchdog around each chunk and completion mutation. It races the mutation against a deadline, aborts the underlying request, marks the file terminal on expiry, and returns so `UploadItem`’s existing `finally` releases the slot. The request-layer timeout remains as a secondary guard. Ordinary rejected network errors retain the existing retry behavior. | `src/callisto/components/FileUploadWrapper/UploadManager/UploadItem/composables/useUploadItem.ts`; `src/callisto/components/FileUploadWrapper/UploadManager/types.ts`; `src/globalApi/useApiRequest.ts`; `src/globalApi/apiClient.ts`; `src/callisto/components/FileUploadWrapper/UploadManager/composables/requests/constants.ts`; `src/callisto/components/FileUploadWrapper/UploadManager/composables/requests/useUploadChunk.ts`; `src/callisto/components/FileUploadWrapper/UploadManager/composables/requests/useUploadComplete.ts` |

## Test coverage added or updated

| Test file | Coverage |
| --- | --- |
| `src/callisto/stores/__specs__/uploadManagerStore.spec.ts` | Empty, queued, active, complete, error, and cancelled count behavior; final total and existing store behavior. |
| `src/callisto/components/FileUploadWrapper/UploadManager/__specs__/UploadManagerTitle.spec.ts` | Title count-up and success/error/failed title branches. |
| `src/callisto/components/FileUploadWrapper/UploadManager/__specs__/UploadManager.spec.ts` | All-error terminal batch starts the closeout and clears after five seconds. |
| `src/callisto/components/FileUploadWrapper/UploadManager/UploadItem/composables/__specs__/useUploadItem.spec.ts` | Chunk, completion, and zero-byte failure terminal handling and notification behavior; includes an intentionally never-settling chunk request that becomes terminal after the watchdog deadline. |
| `src/callisto/components/FileUploadWrapper/UploadManager/composables/requests/__specs__/useUploadComplete.spec.ts` | Completion request includes the bounded upload timeout while preserving payload assertions. |
| `src/callisto/components/FileUploadWrapper/UploadManager/composables/requests/__specs__/useUploadChunk.spec.ts` | Chunk request includes the bounded upload timeout so a stalled request can release its slot. |

## Verification performed

- `npm run lint` — passed.
- Focused Vitest run — passed: 7 files, 52 tests.
  - Store spec
  - Upload Manager component specs
  - Upload Item composable spec
  - Upload request composable specs

## Manual testing notes

- Happy-path upload behavior was recorded manually.
- A zero-byte failure was manually verified to show terminal failure and begin the five-second closeout after the closeout fix.
- A mixed normal-file and zero-byte batch was manually verified to count both files and display the completed-with-errors state.
- Regression — per-file cancellation was manually exercised by clicking the upload item’s X control. PRDV-14055 does not change cancellation behavior; this confirms the existing cancel path remains available while the new count and failure-terminal behavior are in place.
- The offline-batch observation above identified a browser-stalled-request case. The code-level watchdog is the targeted correction. The follow-up manual check should begin online, switch to Offline after transfer begins, and leave the browser untouched; each stalled active pair should become terminal after approximately ten seconds without external debugger attachment.
