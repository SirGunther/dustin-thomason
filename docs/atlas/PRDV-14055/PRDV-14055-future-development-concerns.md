---
ticket: PRDV-14055
tags: [atlas, upload-manager, concerns]
author: Dustin Thomason
created: 2026-07-21
modified: 2026-07-21
---

# PRDV-14055 — Future-development concerns (Upload Manager count)

> **Context:** attaches to LD-001 (the first number stays counted when a started upload later fails; it never drops back). While confirming that, Product noted a possible future enhancement to the upload manager.
> **Purpose of this document:** a dated record that these future directions were raised and deliberately left out of this ticket's scope — for later discussion, not a blocker now.
> **Constructive path forward:** capture the specific design from the ClickUp thread into a companion ticket if/when pursued.

## Executive summary (for escalation)

This ticket ships a Callisto-only fix by explicit decision (LD-002). Two items remain deferred, neither blocking PRDV-14055: (1) the **Triton upload manager carries the identical defects** (count + failure handling + hardcoded label); (2) a Product-noted **future "additional context" enhancement**. **Concern 3 (upload failures not surfaced to shared state) is no longer deferred — it was folded into this ticket per PR #26 (LD-004); kept below for history.** Decisions requested: create the Triton follow-up (Concern 2); prioritize the enhancement (a) fold into a follow-up, (b) separate ticket, or (c) drop.

## Concern 1 — Product-noted "additional context" on the upload manager (future)

Product indicated that beyond fixing the count direction, the upload manager might in the future show **additional context** to the user.

- **Evidence (verified 2026-07-21):** Product response in the ClickUp thread: *"In the future we might add additional context, like this"*. **The specific example referenced by "like this" was not included in the pasted response** — per the `source-truth` rule it is not reconstructed here; retrieve it from the ClickUp thread (screenshot/attachment) if this is pursued.
- **What would resolve it:** a companion ticket capturing the exact "additional context" design from the source thread. Explicitly **out of scope** for PRDV-14055, whose acceptance criteria cover only the count direction.

## Concern 2 — Triton upload manager keeps the count-down defect (deferred to follow-up)

Scope was locked to Callisto only (LD-002). The Triton main-layout upload manager has the **same** first-number defect — its local `activeUploadsCount` counts remaining files and decreases as uploads finish — and its progress label is a **hardcoded English string**, not i18n. Both are left unfixed by this ticket.

- **Evidence (verified 2026-07-21):** Triton local computed [UploadManager.vue:244-248](../PRDV-14055-original-ticket.md) (`!isComplete && !isCancelled && !error` — identical down-count); hardcoded label `UploadManagerTitle.vue:27-29` (`Uploading ${activeUploadsCount} of ${uploadQueue.length} files...`, no `t(...)`); Triton already consumes the shared `common.*` namespace and `common.uploadingProgressTxt`/`uploadAllSuccessTxt` already exist, so the i18n conversion is low-effort (no new keys). Mount: Triton app via `TritonAppContainer.vue`.
- **What would resolve it:** a follow-up ticket applying the same "stays counted / never drops back" count fix (mirror LD-001) to the Triton manager, and converting its label to the existing `common.*` i18n keys (LD-003). Small, well-scoped; the investigation report §14 and coverage ledger areas 4–5, 10 already document the exact surfaces.

## Concern 3 — Upload failures not surfaced to shared state — RESOLVED (folded into PRDV-14055, LD-004)

> Reversed on PR #26 — this is now fixed in PRDV-14055 (mark failed uploads terminal). Retained for history. The Triton equivalent stays part of the Triton follow-up (Concern 2).


Surfaced by PR #26 review (midnjerry) via the 0-byte case. `useUploadItem` records mid-upload and upload-complete failures only in a **component-local `isFailed` ref** — it never sets `fileToUpload.error`/`isComplete` on the queue item. Consequently any such failure is invisible to every queue-level consumer: the new count, the existing `activeUploadsCount`, `totalProgress`, and `allUploadsComplete` — so the batch can also fail to register as complete (the upload manager can appear to hang at "Uploading N of M").

- **Evidence (verified 2026-07-21):** [useUploadItem.ts:114,139,162,166](../PRDV-14055-original-ticket.md) set `isFailed.value = true` only; `fileToUpload.error` is set exclusively by `FileUploadWrapper.setQueueItemError` for prep/upload-start failures (`FileUploadWrapper.vue:50,193,202`). No client-side 0-byte guard: `partsCount = Math.ceil(file.size / CHUNK_SIZE) = 0` for a 0-byte file → `uploadComplete` called with 0 parts. A 0-byte file rejected at upload-**start** is visible (`error` set); one rejected at upload-**complete** is not.
- **Why it's deferred (LD-004):** fixing it reaches beyond a display computed into shared upload behavior, and the same "failure not surfaced to shared state" shape **likely exists in other upload paths — notably Triton** (component-local upload manager). Fixing it inside PRDV-14055 would patch one of several occurrences and inflate a 2-point display fix.
- **What would resolve it:** a dedicated ticket that (1) sets a queue-visible terminal flag on failure in `useUploadItem` (and equivalents), and (2) surveys the other upload paths (Triton included) for the same gap. Until then, PRDV-14055 counts every terminal/started state the queue already exposes; silent failures remain uncounted (pre-existing behavior, not a regression).

## Decision history

- 2026-07-21 — Product confirmed the count should not drop back (→ LD-001) and, in the same response, floated the future "additional context" idea (Concern 1).
- 2026-07-21 — User locked scope to Callisto only (→ LD-002/LD-003); Triton's identical defect + i18n gap deferred to a follow-up ticket (Concern 2).
- 2026-07-21 — PR #26 review (midnjerry) surfaced the 0-byte case; user scoped the silent-failure/hang fix out of PRDV-14055 into its own ticket with a cross-system survey (→ LD-004, Concern 3).

## Open questions to settle

1. Create the Triton follow-up ticket (count fix mirroring LD-001 + i18n conversion per LD-003). — owner: Dustin Thomason / grooming.
2. Create the silent-failure ticket (queue-visible terminal flag on failure in `useUploadItem` + survey other upload paths, Triton included). — owner: Dustin Thomason / grooming.
3. What is the exact "additional context" Product envisions (the "like this" example)? — owner: Product / whoever grooms the companion ticket.
