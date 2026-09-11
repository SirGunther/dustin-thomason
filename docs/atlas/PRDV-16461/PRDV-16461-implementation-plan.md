# PRDV-16461 — Phase 4 Implementation Plan

**Ticket:** [PRDV-16461](https://app.clickup.com/t/43227262/PRDV-16461) · **Repo:** `atlas-front-end` (branch `PRDV-16461`, already exists, currently holds the spec commit)
**Spec:** `docs/specs/atlas-client-access/deliverable-management/PRDV-16461-default-collections-for-client-deliverables.md` ([PR #565](https://github.com/planetdepos/atlas-front-end/pull/565))
**Decisions:** `docs/atlas/PRDV-16461/specs/PRDV-16461-locked-decisions.md` · **Test plan (frozen):** `docs/atlas/PRDV-16461/testing/PRDV-16461-test-plan.md`
**Criteria authority:** [job story 01](../../../../dustin-thomason/docs/atlas/PRDV-16461/stories/PRDV-16461-job-story-01-default-collection.md) — 14 accepted criteria

> Planned from the artifacts. No re-investigation; every step below traces to a spec section, a locked decision, and a test-plan scenario.

---

## Context

Ops users adding files to the Client Deliverables set pick the same collection by hand on nearly every file: a Transcript file belongs in `Full Transcript`, a Video file in `MP4 Video`. Two things have to change for that to stop.

A defaulting rule **already exists** in the upload form — it auto-selects whenever a track has exactly one non-dynamic collection — but Transcript and Video each carry two statics, so it declines every time. And generic drag-and-drop has **no track-selection moment at all**: the modal opens with no track, and track group headings are non-selectable rows, so there is nothing for a default to react to.

The intended outcome: the collection is already correct by the time the user looks at it, across all three add paths, while remaining overridable, never sticky, and never applied by recategorize.

---

## Approach

Four changes, ordered so each is independently verifiable and the riskiest lands last against a proven base.

### Step 1 — The mapping module (new)

**File:** `src/callisto/pages/JobProceedingPages/ProceedingDetailPage/components/DeliverableFileUploadForm/composables/deliverableCollectionDefaults.ts`

Exports the track-value → collection-value map (`Transcript` → `Full Transcript`, `Video` → `MP4 Video`) and a lookup helper that, given a track's picks and its track value, returns the matching pick's `value` or `null`.

The helper matches on `DeliverableCollectionItem.value` within that track's own options and returns `null` when the mapped value is absent — it must never fall back to another pick. That null-vs-substitute distinction is the whole point of the module and belongs in its own unit tests (**LD-006**, **LD-012**).

A header comment records the collision hazard: `src/globalUtils/fileTypeLabel.ts:67,149` maps `'video/mp4' → 'MP4 Video'` as a MIME-type display label, unrelated to this collection. The two must never be merged or cross-imported (**LD-011**).

*Reuses:* the `DeliverableTrackCollectionPickOption` type already exported from `useDeliverableFileUploadForm.ts:45-56` (`trackTypeId`, `deliverableCollectionId`, `isDynamic`, `disable` are all already present — no type changes needed).

### Step 2 — Resolver precedence + recategorize guard

**File:** `composables/useDeliverableFileUploadForm.ts`, `resolveInitialPickValue()` at `:386-415`

Restructure to the spec's five-step order (§4.3). The order is normative — an implementation that returns the same values for today's data by a different order does not satisfy the spec:

1. Recategorize with a valid existing collection → that collection *(existing logic, `:390-406`)*
2. Collectionless track → the `t-<id>-none` sentinel, **in every mode including recategorize**
3. Outside recategorize, track mapped → the mapped pick; **if absent, return `null`** — do not fall through
4. Outside recategorize, track unmapped with exactly one non-dynamic pick → that pick *(existing rule, `:407-414`)*
5. Otherwise → `null`

Steps 3 and 4 are both gated on `!isRecategorizeMode.value` (`:354`). Gating **step 4** is the pre-existing-defect fix (**LD-008**) — today a recategorize on a single-static-collection track with a blank collection auto-selects it.

The guard must not be a blanket `return null` for recategorize: step 2 has to stay reachable or Exhibits/MVC recategorize loses its track-only selection (**LD-007**). This is the single most likely way to get the change wrong.

*Watch:* the current singleton filter at `:407-412` admits the `t-<id>-none` sentinel, which is precisely why step 2 must be ordered ahead of it rather than folded in.

### Step 3 — Track state for generic drag-and-drop

**Files:** `composables/useDeliverableFileUploadForm.ts`, `DeliverableFileUploadForm.vue`

Generic DnD is `mode === 'upload' && lockedTrackTypeId == null` (**LD-003**) — no new mode value.

Add a `selectedTrackTypeId` ref to the composable, exposed on its return type, meaningful only in that case. Feed it into the effective track the resolver reads, so choosing a track drives the default through the *existing* resolution path rather than a parallel one.

`trackCollectionOptions` (`:358-381`) gains a scoping filter: once a track is selected in generic DnD, the combined field lists only that track's picks and its dynamic pick. This is what makes "all files in the batch take the one selected track" true rather than merely asserted, and it reuses the existing computed rather than adding a second options source.

**On track change** (**LD-009**, **LD-010**) — clear the selected collection, dynamic-collection state, and per-file type state, then resolve the new track's default. Partly free: the watcher at `:571-583` already clears dynamic state whenever `selectedPickValue` moves, and per-file types refresh off `selectedOption` at `:735-746`. Reuse both; do not rebuild them.

**Guard precedence (normative):** the existing async backfill (`:431-440`) must not overwrite a user's selection, but a deliberate track change must. An override belongs to the track it was made under.

### Step 4 — The track control (component)

**New file:** `components/DeliverableFileUploadTrackOnlySelectField.vue`, rendered in the existing `trackControlsRow` (`DeliverableFileUploadForm.vue:528`) ahead of the combined field, only for generic DnD.

Follows `TrackSelectorForm.vue:104-131` + `useTrackSelectorForm.ts:44-63` exactly: one `q-select`, `option-disable` bound per option, unpermitted tracks **shown and disabled** with the existing tooltip (**LD-004**). Model it on the sibling presentational component `DeliverableFileUploadTrackSelectField.vue` — props in, `defineModel` out, no data fetching.

*Reuses, no new strings:* `common.callisto.dragDrop.trackLabel`, `trackPlaceholder` ("Select track to upload files"), and `noTrackPermission` all already exist in `src/i18n/en-US/common.json:447-451`. Permission comes from the existing `singleProceedingFileAuth(trackId, true, ACTION_TYPES.CREATE)`, the same call `buildPickOptions` already makes at `:363-364`.

---

## Files touched

| File | Change |
| --- | --- |
| `composables/deliverableCollectionDefaults.ts` | **new** — mapping + lookup |
| `composables/useDeliverableFileUploadForm.ts` | resolver order, recategorize guard, track state, options scoping |
| `components/DeliverableFileUploadTrackOnlySelectField.vue` | **new** — track control |
| `DeliverableFileUploadForm.vue` | render the control for generic DnD; wire the track model |
| `composables/__specs__/deliverableCollectionDefaults.spec.ts` | **new** |
| `composables/__specs__/useDeliverableFileUploadForm.spec.ts` | resolver branches; 3 existing tests re-dispositioned |
| `__specs__/DeliverableFileUploadForm.spec.ts` | **new** — first component spec for this form |

---

## Verification

The test plan is **frozen** (refined at Phase 3 against the locked decisions, before any code exists) — execute it, do not revise it.

**Unit** — every resolver branch, steps 3 and 4 asserted independently. Load-bearing: **NP-1**, mapped-but-absent returns `null` rather than substituting. A pass showing some *other* collection is the specific failure this exists to catch.

**Regression** — **NP-4** (recategorize, single-static-collection track, blank collection → stays blank; fails on `main` today) and **EC-5** (Exhibits/MVC keep their sentinel — proves the guard wasn't blanket-applied).

**Existing specs** — `useDeliverableFileUploadForm.spec.ts:418` flips to expect the mapped default. **`:445` keeps its assertion** that generic DnD opens with no pre-selection (still the target state); *add* a second assertion for reactive defaulting after track selection. `:1481` unchanged.

**Component** (**LD-015**) — `DeliverableFileUploadForm.spec.ts`, following the module-mock + module-scoped-reactive-ref convention already used by the composable spec (`mockTrackTypes` etc., not `createComposableMock`): track selectable, unpermitted tracks visible-but-disabled, collections scoped to the chosen track, default **visible**, override surviving an unchanged track, track change clearing the override and re-defaulting.

**Manual** — test-plan steps 1–8, with the collection field *and* track control in frame together in any screenshot. Includes the environment data check (`SELECT` over `deliverable_collections WHERE proceeding_id IS NULL`) that closes assumption A3.

**Gates** (audit → lint → tests, reported with exact command + scope + result):

```
npm audit --audit-level=high      # fails pre-existing on main (11 high, undici et al) — waived, no dependency touched
npm run lint
npx vitest run --maxWorkers 1
```

---

## Shipping obligations

- **Tests are part of shipping**, not a follow-up — new behavior gets happy, failure, edge, and graceful-degradation coverage per the build guardrails.
- **Regression boundary:** shared surface (`useDeliverableFileUploadForm`) serves four flows; recategorize and the collectionless-track sentinel are explicitly asserted unchanged.
- **API docs:** not relevant — no HTTP surface touched. Route, DTO, and auth decorators all unchanged; the collections endpoint is consumed as-is.
- **Changelog:** session log entry in `dustin-thomason/docs/atlas/PRDV-16461-changelog.md` before the commit.
- **Self-review** against `docs/reviewers/pr-review-patterns.md` after the code, before the tests.
- **PR:** fill `PRDV-16461-pr-draft.md`; full template this time (description + test evidence + checklist) since there is executable code. No reviewer requested.

## Risks

| Risk | Mitigation |
| --- | --- |
| Blanket recategorize guard breaks Exhibits/MVC | Step 2 ordered ahead of the guard; EC-5 asserts it |
| Step 3 falls through to step 4 when the mapped value is absent | Ordering is normative; NP-1 is the load-bearing test |
| Track-change reset fights the async backfill guard | Precedence stated in the spec; EC-2 and EC-3 assert both directions |
| Scoping `trackCollectionOptions` disturbs the three locked-track flows | Filter applies only when `mode === 'upload' && lockedTrackTypeId == null`; HP-3/4/5 assert the others |

## Open

**None.** The spec carries no open questions; where it is silent the acceptance criteria govern.

**Estimate:** sized at 3 points before the drag-and-drop requirement was known. Steps 1–2 fit that; steps 3–4 (new UI + the form's first component spec) do not. Flag on the ticket rather than absorbing it silently.

**Gate note:** no reviewer has responded to spec PR #565. Proceeding under the user's explicit waiver of 2026-09-03, recorded in the orchestration ledger with the risk it carries.
