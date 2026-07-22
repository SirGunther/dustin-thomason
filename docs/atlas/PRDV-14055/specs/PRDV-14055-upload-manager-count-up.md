---
ticket: PRDV-14055
tags: [neptune, callisto, upload-manager, files]
author: Dustin Thomason
created: 2026-07-21
modified: 2026-07-21
---

# PRDV-14055: Upload Manager Counts Up Instead of Down

> **Parent epic:** Atlas Maintenance
>
> **Prerequisites:** None
>
> **Companion tickets:** Triton upload-manager count + i18n (follow-up, to be created)

---

## User Story

> As an Ops Atlas User, I want the upload manager to have the number of uploading items count up instead of down, so that it appears like the uploads are completing successfully and not being removed from the queue as it currently does.

---

## Summary

The Upload Manager progress message reads "Uploading **N** of **M** files…". Today **N** is the count of *remaining* uploads, so it **decreases** as files finish — to an Ops user it looks like files are being removed from the queue rather than completing.

The first number is driven by `activeUploadsCount` in the Callisto upload store, computed as the files that are **not** terminal — a remaining count. This story replaces the value fed to the progress title with a **completed-plus-in-progress** count that rises to the total, so the number counts up and, on the happy path, ends equal to the second number.

It also makes **upload failures resolve instead of hang.** Today a failure mid-upload (a 0-byte file, a lost network) is recorded only in component-local state and never marked on the queue item, so the batch never completes and the manager sits on "Uploading N of M" forever with no toast. This story marks failed uploads as failed on the queue item, so a failure is counted, surfaced with a toast, and the batch resolves like any other completion.

Scope is **Callisto only**. The Triton upload manager has the same defects and is a separate follow-up (its own count fix + i18n).

---

## Approach

- **Count computed.** Add a computed to `uploadManagerStore` — a file counts once it is **terminal or actively transferring**: `isComplete || error || isCancelled || percentCompleted > 0`. Feed it into the existing `UploadManagerTitle` `active` slot in place of `activeUploadsCount`. Counting the terminal flags (not just `percentCompleted > 0`) is what lets an errored file that never transferred a byte still count.
- **Mark failures terminal.** In `useUploadItem`, when an upload fails (chunk failure, upload-complete failure, network loss), set `fileToUpload.error` on the queue item — today it sets only a component-local `isFailed`, so the store never sees the failure. This is the change that makes failures counted, renders the proper error row, lets the batch reach a terminal state, and makes the failure toast fire.
- **Leave neighbors unchanged.** `activeUploadsCount`, `hasActiveUploads` (close dialog / beforeunload guard), `totalProgress`, and the title's success/error/failed branches are untouched; the count computed is additive.
- **No i18n change.** The Callisto title already renders `common.uploadingProgressTxt` = `"Uploading {active} of {total} files..."`; `{active}` receives the up-count, `{total}` stays `uploadQueue.length`.

---

## Locked decisions

| Decision | Source |
| --- | --- |
| A file **stays counted** once terminal (incl. errored/cancelled) or transferring; the number never drops back. Formula `isComplete \|\| error \|\| isCancelled \|\| percentCompleted > 0`. | Product, 2026-07-21: "I don't think it should drop back. The number should stay the same." |
| Failure handling (mark failed uploads terminal → counted, toasted, batch resolves) is **in scope** for this ticket. | PR #26: "folding it in, because it's a feature and will make errors known/testable." |
| Scope = **Callisto only**; Triton (count + i18n) is a separate follow-up. | Team direction, 2026-07-21 |

Full ledger: [PRDV-14055-locked-decisions.md](./PRDV-14055-locked-decisions.md).

---

## Frontend

### 1. Folder hierarchy

```
src/
└── callisto/
    ├── stores/
    │   ├── uploadManagerStore.ts                         ← MODIFY (add count computed)
    │   └── __specs__/uploadManagerStore.spec.ts          ← MODIFY (count coverage)
    └── components/FileUploadWrapper/UploadManager/
        ├── UploadManager.vue                             ← MODIFY (pass count to title)
        ├── UploadItem/composables/useUploadItem.ts       ← MODIFY (mark queue item failed on failure)
        └── __specs__/UploadManagerTitle.spec.ts          ← MODIFY (title renders up-count)
```

### 2. Modified files

| File | Change |
|---|---|
| `uploadManagerStore.ts` | Add + export count computed: `uploadQueue.filter(f => f.isComplete \|\| f.error \|\| f.isCancelled \|\| (f.percentCompleted ?? 0) > 0).length`. Neighbors unchanged. |
| `UploadManager.vue` | Bind `:active-uploads-count` to the new computed instead of `uploadStore.activeUploadsCount`. |
| `useUploadItem.ts` | On failure, set `fileToUpload.error` (queue-visible) in addition to the local `isFailed`, and ensure the failure toast fires. Covers chunk failures, upload-complete failures (incl. 0-byte / 0-part), and network loss. |
| `uploadManagerStore.spec.ts` | Cover the count computed; keep `activeUploadsCount`/`hasActiveUploads`/`totalProgress` assertions (neighbors unchanged). |
| `UploadManagerTitle.spec.ts` | Title renders the up-count. |

`UploadManagerTitle.vue` needs no change — it renders whatever `activeUploadsCount` prop it receives.

---

## Implementation Details

- **The count:** `isComplete || error || isCancelled || percentCompleted > 0`. Terminal flags and `percentCompleted` only move forward, so the count is monotonic — it never decreases. A file counts once it is terminal (in any way) or has begun transferring.
- **Concurrency:** `MAX_CONCURRENT_FILES = 2`; files beyond two sit queued at `percentCompleted = 0` and aren't counted until they start. As each begins the number ticks up; as they complete it continues to the total.
- **Failure is terminal.** Today `useUploadItem` records mid-upload / upload-complete failures only in a component-local `isFailed` and never on the queue item, so the store (count, `totalProgress`, `allUploadsComplete`) can't see them and the batch hangs. Setting `fileToUpload.error` on failure makes the failure: (a) **counted** (via the `|| error` term), (b) **shown** as the `ErrorUploadItem` row, (c) able to **resolve the batch** (`allUploadsComplete` includes `error`, so the title switches to "completed with errors"), and (d) **toasted** — today the failure toast lives on a branch that never executes because the chunk error is swallowed without marking the item; marking it is what makes the toast reachable.

### Failure scenarios covered

- **0-byte file** — no client size guard; `partsCount = 0`, so `uploadComplete` is called with 0 parts and errors. Fails at `uploadStart` → `error` already set → counted. Fails at `uploadComplete` → now set `error` → counted and resolves (previously invisible).
- **Network loss mid-upload** — in-flight chunk requests fail; the file (and any that can't complete) is marked failed → counted, toasted, batch resolves. See the offline acceptance criterion.

---

## Scope boundaries

- **Callisto only.** Triton's identical count-down + failure-handling + hardcoded-label issues are a separate follow-up.
- **No change** to `activeUploadsCount`, `hasActiveUploads`, `totalProgress` (progress-bar math), `allUploadsComplete` logic, or the title branches. (Marking failures terminal doesn't change that logic — it just means failed items now correctly reach it.)
- **No backend, API, schema, routing, or i18n-key changes.** `TUploadFile` is unchanged (`isComplete`, `error`, `isCancelled`, `percentCompleted` already exist).
- **Not building** automatic retry/resume or offline detection — on interruption the expected behavior is to fail gracefully (mark failed, count, toast, resolve), not to retry. Retry/resume would be its own feature.

---

## Affected surfaces

| Surface | Component | How it's covered |
|---|---|---|
| Every Callisto route (upload manager mounts app-wide via `isCallistoRoute`) | `uploadManagerStore` → `UploadManager` → `UploadManagerTitle` + `useUploadItem` | Count computed + prop wiring + failure-terminal fix |
| Triton app upload manager | Triton `UploadManager`/`UploadManagerTitle` | **Out of scope** — follow-up ticket |

---

## Acceptance criteria

1. The first number shows **completed + in-progress** uploads, not remaining, and **counts up** to the total as files begin and complete.
2. On the happy path the end state has all files uploaded with the first and second numbers equal; the second number stays the batch total.
3. A file that fails or is cancelled at any point (including a 0-byte file and a network-interrupted file) is **counted** and does **not** cause the number to drop back.
4. A failed upload is **marked failed** (error row) and the user gets a **failure toast** — failures are visible, not silent.
5. **Offline mid-upload:** if a batch is uploading (e.g. 20 files × 10 MB) and the network drops, every file that cannot finish is marked failed, the count still finishes counting up, and the batch **resolves to a terminal state** (e.g. "Upload completed with errors" / all-failed title) with failure toasts — the manager does **not** hang on "Uploading N of M".
6. No change to the close-confirmation dialog, progress-bar math, or the success/error/failed title branches.

---

## Spec tests

### `uploadManagerStore.spec.ts` (count computed)

| Scenario | Expected |
|---|---|
| Empty queue | 0 |
| Queued, none started (percentCompleted 0) | 0 |
| Mix of in-progress + completed | in-progress + completed; monotonic (≥ prior) |
| All complete | === `uploadQueue.length` |
| Errored / cancelled file at 0% | counted (verifies `\|\| error` / `\|\| isCancelled`) |
| Neighbors unchanged | existing `activeUploadsCount` / `hasActiveUploads` / `totalProgress` assertions pass |

### `useUploadItem` (failure terminal + toast)

| Scenario | Expected |
|---|---|
| Chunk failure (network) | `fileToUpload.error` set; failure toast fired |
| Upload-complete failure (incl. 0-byte, 0 parts) | `fileToUpload.error` set; counted; batch can resolve |
| Successful upload | `isComplete` set; no `error` (unchanged) |
| Offline mid-batch (multiple in-flight fail) | each failed item marked `error`; `allUploadsComplete` resolves; count reaches total |

### `UploadManagerTitle.spec.ts`

| Scenario | Expected |
|---|---|
| Uploads in progress | renders `uploadingProgressTxt` with `active` = up-count, `total` = queue length |
| All complete / errors / failed | unchanged branches |

---

## Suggested point range

**Small–Medium (~3 points).** Count computed + wiring, plus a `useUploadItem` change to mark failed uploads terminal (so failures — 0-byte, network — are counted, toasted, and resolve the batch), with unit tests across three specs. No backend, schema, endpoint, or i18n-key changes.
