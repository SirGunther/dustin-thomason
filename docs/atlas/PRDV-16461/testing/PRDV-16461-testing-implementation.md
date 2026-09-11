# Testing implementation — atlas/PRDV-16461

> Scenario-first record of what was actually stress-tested and what each situation forced. Assembled during implementation; the content below is what goes in the PR comment. Not source-comment material.

## Scenario 1 — A mapped track has both its collections

**Why it matters:** the headline case. Transcript carries `Full Transcript` and `Redacted`; Video carries `MP4 Video` and `MPEG Video`. Two statics is exactly why nothing pre-selected before.

**Held?** Yes.

**What it forced:** `deliverableCollectionDefaults.ts` — a track-value → collection-value map plus a lookup that searches only that track's own picks. Matching is by the collection's `value` string because the API never sends `collection_kind`, and a kind flag would not disambiguate two statics anyway.

## Scenario 2 — A mapped track is missing its base-case collection

**Why it matters:** the acceptance criteria require the field to stay blank, not to guess. The dangerous failure is silent: substituting `Redacted` for an absent `Full Transcript` files documents into the wrong collection while looking like it worked.

**Held?** Yes — and this is the scenario that shaped the whole resolver.

**What it forced:** an explicit five-step precedence in `resolveInitialPickValue()`, where the mapped-track step returns `null` rather than falling through to the pre-existing "exactly one static collection" rule. Without that ordering, a track that had lost one of its two statics would auto-select the survivor. The order is load-bearing, not stylistic.

## Scenario 3 — Recategorize on a track with exactly one static collection

**Why it matters:** **newly uncovered.** The existing suite only exercised recategorize on a *multi*-collection track, so nobody had asked what the single-collection case did.

**Held?** No — this failed on `main`, and it is a **pre-existing defect this ticket surfaces rather than causes.**

**Evidence.** Source stashed, only the new test applied, run against unmodified code:

```
AssertionError: expected 't-2-c-10' to be null
```

**Observed → expected → fix.**
- *Observed:* opening recategorize with a blank collection on a single-static-collection track silently selects that collection.
- *Expected:* recategorize preserves what the files carry and changes it only when the user does.
- *Fix:* `useDeliverableFileUploadForm.ts` — the recategorize guard now covers the pre-existing single-option rule, not only the new mapping.

## Scenario 4 — Recategorize on a collectionless track (Exhibits, MVC)

**Why it matters:** the obvious way to write scenario 3's guard is "return nothing in recategorize." That breaks these tracks, which depend on the same code path to select their track-only sentinel — they would become unusable.

**Held?** Yes, because the guard was deliberately not written that way.

**What it forced:** the sentinel step sits *ahead* of the recategorize guard in the precedence order and applies in every mode. Asserted directly so a later refactor cannot quietly collapse the two.

## Scenario 5 — Generic drag-and-drop, no track supplied

**Why it matters:** the flow the ticket leads with. The modal opens with no track, and track headings are non-selectable rows, so there was no moment for a default to attach to.

**Held?** Yes, after adding the missing interaction.

**What it forced:** a dedicated track control (`DeliverableFileUploadTrackOnlySelectField.vue`) plus `selectedTrackTypeId` state in the composable. Choosing a track feeds the *existing* resolver rather than a parallel path, so the default arrives through one code path in every flow.

## Scenario 6 — Direct per-track upload, track supplied but not locked

**Why it matters:** **newly uncovered, and it invalidated a locked decision.** The spec identified generic drag-and-drop as `mode === 'upload' && lockedTrackTypeId == null`. Direct upload supplies `initialTrackTypeId` without necessarily locking it, so that check captured the wrong flow.

**Held?** No — and it failed loudly.

**Observed → expected → fix.**
- *Observed:* the two-part discriminator classified direct upload as generic drag-and-drop and discarded the caller's track. **12 existing tests failed**, four on the Exhibits/MVC sentinel.
- *Expected:* only the flow where the caller supplies *no track at all* is generic drag-and-drop.
- *Fix:* the discriminator gained a third condition, `initialTrackTypeId == null`. Spec §4.5 and LD-003 were corrected and pushed to the spec PR before implementation continued.

## Scenario 7 — Changing the track after overriding the collection

**Why it matters:** two rules point opposite ways. An async backfill must never overwrite a user's choice; a track change must. Getting the precedence backwards either strands a stale collection under a new track or discards a deliberate choice.

**Held?** Yes.

**What it forced:** a watcher on `selectedTrackTypeId` that re-resolves on change, scoped to generic drag-and-drop. Existing watchers already clear dynamic-collection and per-file type state off `selectedPickValue` and `selectedOption`, so those were reused rather than rebuilt. Both directions are asserted: override survives an unchanged track, and is discarded on a track change.

## Scenario 8 — A track the user cannot upload to

**Why it matters:** the plan said to show only permitted tracks. Checking the established precedent showed both sibling controls *list* them, disabled, with a tooltip explaining why — a missing option leaves the user wondering; a disabled one with a reason does not.

**Held?** Yes, after following precedent instead of the plan.

**What it forced:** the new control lists every track with `option-disable` and reuses the existing `noTrackPermission` tooltip and i18n key. LD-004 supersedes the plan's original wording. A disabled option cannot be chosen, so no permission check is needed inside the resolver.

## Scenario 9 — Collections arrive after the modal is already open

**Why it matters:** a cold cache is ordinary, and the default must still apply once data lands — without clobbering anything the user picked meanwhile.

**Held?** Yes, on existing behavior. The backfill watcher already re-resolves only when nothing is selected; the new mapping flows through it unchanged.

**What it forced:** nothing new. Worth stating: the non-sticky requirement also needed no new code, since the close watcher already nulls the selection. The additions were clearing `selectedTrackTypeId` on close and re-resolving on track change.

---

## Coverage summary

| | |
| --- | --- |
| Suite | 141 files, 1261 passed, 4 skipped (pre-existing) |
| Touched area | 3 files, 99 passing |
| New files | `deliverableCollectionDefaults.ts` (+13 unit tests), `DeliverableFileUploadTrackOnlySelectField.vue` (+6 component tests — the first component-level coverage in this form) |
| Changed test dispositions | `:418` now expects the mapped default; `:445` **keeps** its "no pre-selection on open" assertion, with reactive defaulting asserted separately; `:1481` unchanged |

## Not covered

Manual verification has **not** been performed — it needs a running Atlas against a seeded Callisto. Outstanding: the environment data check closing assumption A3, plus the live-app scenarios (type pre-fill against a defaulted collection, submit-without-touching-collection, non-GCA parity, empty catalog).
