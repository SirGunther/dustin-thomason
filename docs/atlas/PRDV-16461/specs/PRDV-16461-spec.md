# PRDV-16461 — Default collections for client deliverables

**Ticket:** [PRDV-16461](https://app.clickup.com/t/43227262/PRDV-16461) · **Repo:** `atlas-front-end` · **Type:** story (3 points, re-estimate pending)
**Acceptance criteria:** [job story 01](../stories/PRDV-16461-job-story-01-default-collection.md) — the authority on what done means. This spec cites it and does not amend it.
**Investigation:** [PRDV-16461-investigation.md](../investigations/PRDV-16461-investigation.md) · **Diagrams:** [PRDV-16461-diagrams.md](../investigations/PRDV-16461-diagrams.md)

---

## 1. Problem → Requirement → Solution

**Problem.** Ops users adding files to the Client Deliverables set pick the same collection by hand on nearly every file: a Transcript file belongs in `Full Transcript`, a Video file in `MP4 Video`. The upload form already contains a rule that auto-selects a collection, but it fires only when a track has exactly one non-dynamic collection. Both target tracks carry two, so it declines every time. In generic drag-and-drop the situation is worse: the form opens with no track at all, and track headings are non-selectable rows, so there is no moment at which a default could apply.

**Requirement.** For files added to client deliverables on the GCA-enabled flow, the collection must already be set to the fixed base-case value for the file's track by the time the user looks at it — across drag-and-drop, per-track upload, and approval — while remaining overridable, never sticky, never applied by recategorize, and blank rather than wrong when the mapped collection is unavailable.

**Solution.** Three parts, all in `atlas-front-end`:
1. A named track → collection mapping consulted inside the existing initial-selection resolver.
2. An explicit precedence order in that resolver, so the mapping and the pre-existing single-option rule cannot conflict.
3. A dedicated track control for generic drag-and-drop, giving the default a trigger, with a reset transition when the track changes.

No backend change, no new endpoint, no Deliverable Type Manager configuration (**LD-013**). The collection catalog already delivers `staticCollections[].value` and `eligibleTypes` per track.

## 2. Locked decisions from Q and A

Full ledger: **[PRDV-16461-locked-decisions.md](./PRDV-16461-locked-decisions.md)**. Summary of the decisions this spec implements:

| ID | Decision |
| --- | --- |
| LD-001 | Implement the drag-and-drop criterion; do not revise it |
| LD-002 | A dedicated track control, not selectable group headers |
| LD-003 | `mode === 'upload' && lockedTrackTypeId == null` identifies generic DnD; no new form mode |
| LD-004 | Unpermitted tracks are shown disabled with the existing tooltip, not hidden |
| LD-005 | A defaulted collection is immediately valid; no acknowledgement state |
| LD-006 | Resolver precedence is explicitly ordered; mapped-but-absent returns `null` |
| LD-007 | The recategorize guard covers the mapping **and** the singleton fallback, without breaking collectionless tracks |
| LD-008 | The recategorize singleton defect is fixed here, attributed as pre-existing |
| LD-009 | The reset transition fires on the mutable DnD track change only |
| LD-010 | A manual override survives only while the track is unchanged |
| LD-011 | The mapping is a new, separately-named constant |
| LD-012 | Matching is by collection `value` within the track's own `staticCollections` |
| LD-013 | Front-end only |
| LD-014 | The visual "defaulted" indicator is out of scope and must not affect validity |
| LD-015 | A component spec for `DeliverableFileUploadForm.vue` is part of done |

## 3. Behavior by flow

**Generic drag-and-drop** — the user drops files on the Client Deliverables tab. The modal opens with no track and no collection selected. It asks for the track. On answering, the mapped collection for that track appears immediately and remains editable; the eligible-type query runs against it and per-file deliverable types pre-fill. The user may override the collection, and may submit without ever opening the collection field (**LD-005**). Changing the track discards the previous collection, any dynamic-collection state, and per-file type selections, then applies the new track's default (**LD-009**, **LD-010**). All files in the batch take the one selected track.

**Direct / per-track upload** — the track is locked by the control the user clicked, exactly as today. The modal opens with the mapped collection already selected, type pre-fill already run, and the collection editable.

**File approval** — the track is inherited from the submission files and locked, exactly as today; mixed-track selections remain blocked by existing behavior. The modal opens with the mapped collection already selected and types pre-filled.

**Recategorize** — unchanged. Each file's existing track and collection are preserved. No default is applied, including when the collection is blank or the selected files disagree, and including on a track that has only one static collection (**LD-007**, **LD-008**). Only a deliberate user action changes the collection.

**Fallback, all flows** — if the track has no mapping, or the mapped collection is not present in the returned catalog, nothing is selected. No error is shown, and no other collection is substituted (**LD-006**).

## 4. Design

### 4.1 Folder hierarchy

New paths under `atlas-front-end/src/`:

```text
callisto/pages/JobProceedingPages/ProceedingDetailPage/components/DeliverableFileUploadForm/
  composables/
    deliverableCollectionDefaults.ts          NEW - the mapping + lookup helper
    __specs__/
      deliverableCollectionDefaults.spec.ts   NEW
  __specs__/
    DeliverableFileUploadForm.spec.ts         NEW - first component spec (LD-015)
```

Modified in place: `composables/useDeliverableFileUploadForm.ts`, `DeliverableFileUploadForm.vue`, `composables/__specs__/useDeliverableFileUploadForm.spec.ts`.

### 4.2 The mapping

`deliverableCollectionDefaults.ts` exports a map from track **value** to collection **value**, plus a resolver helper. It is a new, separately-named module and must not be merged with `src/globalUtils/fileTypeLabel.ts`, whose MIME-label map coincidentally contains the string `'MP4 Video'` (**LD-011**).

| Track value | Default collection value |
| --- | --- |
| `Transcript` | `Full Transcript` |
| `Video` | `MP4 Video` |

Matching is by `value` string against the picks built from that track's own `staticCollections` (**LD-012**). This is forced rather than chosen: the collections endpoint exposes only `{ id, value, eligibleTypes }` per collection, so no kind flag is available client-side — and `Redacted` and `MPEG Video` are also `static`, so a kind flag would not identify the winner anyway. Unmapped tracks (Exhibits, MVC, Audio, Planet Suite) have no entry and are unaffected.

### 4.3 Resolver precedence

`resolveInitialPickValue()` in `useDeliverableFileUploadForm.ts` resolves in this order (**LD-006**). The order is normative — an implementation that produces the same result for today's data by a different order does not satisfy this spec, because the ordering is what guarantees step 3.

1. **Recategorize with a valid existing collection** → select that collection.
2. **Collectionless track** (no `staticCollections`, no dynamic support) → select the track-only sentinel `t-<id>-none`. Applies in every mode, recategorize included.
3. **Outside recategorize, track is mapped** → select the pick whose `deliverableCollectionId` corresponds to the mapped `value` within that track. **If the mapped value is not present, return `null`** — do not continue to step 4. Substituting a different collection because it is the only one left contradicts the fallback criterion.
4. **Outside recategorize, track is unmapped and has exactly one non-dynamic pick** → select it. This is the pre-existing rule, preserved for tracks outside the mapping.
5. **Otherwise** → `null`.

A dynamic pick (`isDynamic === true`) is never selected by any step. A disabled pick is never selected by any step; combined with LD-004 this needs no separate condition, since a disabled option cannot be chosen and the locked-track flows are permission-gated before the modal opens.

### 4.4 Recategorize guard

Steps 3 and 4 are both gated on `!isRecategorizeMode.value` (available at `useDeliverableFileUploadForm.ts:354`). Step 4's gating is the fix for the pre-existing defect (**LD-008**): today a recategorize opened with a null or ambiguous collection on a single-static-collection track auto-selects that collection, contrary to the recategorize guarantee.

The guard must **not** be a blanket `return null` for recategorize (**LD-007**). Step 2 stays reachable, or Exhibits and MVC recategorize flows lose their track-only selection and become unusable.

### 4.5 The drag-and-drop track control

Generic DnD is identified by `mode === 'upload' && lockedTrackTypeId == null` (**LD-003**). No new form mode value is introduced.

The control follows the established precedent in `TrackSelectorForm.vue:104-131` and `useTrackSelectorForm.ts`: a single `q-select` over the ordered track list for the client-deliverables tab, `option-disable` bound to a per-option `disable`, with the `common.callisto.dragDrop.noTrackPermission` tooltip on disabled rows. Tracks the user lacks CREATE permission on are **shown and disabled**, not hidden (**LD-004**) — `DeliverableFileUploadTrackSelectField.vue:23` already uses the same i18n key, so this is consistent within the surface being changed.

On a track change (**LD-009**, **LD-010**):

```text
clear the selected collection
clear dynamic-collection state
clear per-file deliverable-type state
resolve the mapped default for the new track
let the existing type-query and pre-fill behavior run
```

The transition fires on this control only. Locked-track flows keep their existing initialization through the `isOpen` and `trackCollectionOptions` watchers, and recategorize never runs it.

Two guards sit in tension and their precedence is normative: the existing async backfill must not overwrite a user's selection, but a **track change** must. An override belongs to the track it was made under; a deliberate track change discards it.

### 4.6 Composition with deliverable-type pre-fill

No new wiring. `selectedOption` is already a dependency of the pre-fill watcher, so setting the collection programmatically cascades into the eligible-type query and per-file type resolution exactly as a manual selection does. The observable change is that the query now runs when the modal opens for a mapped track, where previously it waited for a click.

A filename that matches no auto-select rule for the defaulted collection leaves the deliverable type blank. This is expected behavior, not an error, and does not make the collection invalid — though an unresolved required type still gates submission under existing validation (**LD-005**).

## 5. Non-goals

- The visual indicator that a value was defaulted (**LD-014**) — [job story 02](../stories/PRDV-16461-job-story-02-default-indicator.md), Product decision pending. If later added, it must not affect validity or submission.
- Any change to: how the app determines whether the user chose the *correct* track; one-track-per-upload-batch semantics; file-type inference or validation; mixed-track batch support; drop locations or track-specific drop zones; post-upload track behavior; non-GCA upload behavior.
- Backfilling component coverage for the form's pre-existing modes. This ticket adds the first component spec, covering the new interaction only.
- Backend, DTM, or API changes of any kind.

## 6. Sections not applicable

This is a front-end-only story. The following spec-writing sections are **N/A**:

- **New entities / modified entities** — N/A, no schema change.
- **New migrations / migration classes** — N/A, no schema change. Existing seeds (`1775761245238`, `1780604349327`, `1782200000003`) are consumed as data, not modified.
- **New DTOs** — N/A, no API contract change.
- **New projections / domain inputs** — N/A, no backend layer touched.
- **HTTP surface** — N/A. `GET /granting-client-access/deliverable-collections` is consumed unchanged.
- **Registries / module wiring / ports / domain events / domain exceptions** — N/A, no Nest module involved.
- **Authorization** — no new guard or policy. Existing permission checks are reused, and LD-004 changes only how an unpermitted track is *presented* in the new control.

## 7. New classes and modules

| Name | Path | Purpose |
| --- | --- | --- |
| `DELIVERABLE_COLLECTION_DEFAULTS` | `…/DeliverableFileUploadForm/composables/deliverableCollectionDefaults.ts` | Track value → collection value map |
| `resolveDefaultCollectionPick` | same file | Given a track's picks and its value, return the mapped pick or `null` |

No new classes; Atlas convention here is composables and plain helpers.

## 8. Testing

Full plan: **[PRDV-16461-test-plan.md](../testing/PRDV-16461-test-plan.md)** (7 happy, 7 negative, 8 edge, plus manual verification). Obligations specific to this spec:

- **Unit** — every resolver branch, with the ordering of steps 3 and 4 asserted independently. The load-bearing case is mapped-but-absent returning `null` rather than substituting.
- **Regression** — the recategorize singleton case (currently uncovered), and the collectionless-track sentinel still selecting.
- **Component (new, LD-015)** — `DeliverableFileUploadForm.spec.ts` proving the DnD interaction end to end: track selectable, unpermitted tracks visible but disabled, collections scoped to the chosen track, the default **visible**, override surviving an unchanged track, and a track change clearing the override and re-defaulting.
- **Existing specs** — `useDeliverableFileUploadForm.spec.ts:418` changes to expect the mapped default. `:445` **keeps** its assertion that generic DnD opens with no pre-selection, with a new assertion added for reactive defaulting after track selection. `:1481` is unchanged.

Gates per `git-commit-workflow`: `npm audit --audit-level=high`, `npm run lint`, `npx vitest run --maxWorkers 1`.

## 9. Risks

| Risk | Mitigation | Concern |
| --- | --- | --- |
| A production rename of a mapped collection silently disables the default — the graceful fallback makes it fail quietly | The mapping is one named constant; the fallback is covered by NP-1 | [C2](../PRDV-16461-future-development-concerns.md) |
| `'MP4 Video'` also exists as a MIME-type display label; a future reader may conflate the two | Separately-named module with the collision documented at its definition | [C1](../PRDV-16461-future-development-concerns.md) |
| The form's pre-existing modes remain without component coverage | This ticket adds the first component spec; broader coverage is a named follow-up | [C3](../PRDV-16461-future-development-concerns.md) |
| Scope pressure to expand the DnD change into a redesign | §5 fences it explicitly | — |

## 10. Estimate

Sized at 3 points before the drag-and-drop interaction requirement was identified. **Re-estimate at Phase 4** — the mapping and resolver are small, but the new track control plus the first component spec for this form are not covered by the original sizing.
