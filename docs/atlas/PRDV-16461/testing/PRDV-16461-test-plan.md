# Test plan — atlas/PRDV-16461

> Seeded from [PRDV-16461-investigation.md](../investigations/PRDV-16461-investigation.md) §9 on 2026-09-03. Refined against [PRDV-16461-spec.md](../specs/PRDV-16461-spec.md) and [PRDV-16461-locked-decisions.md](../specs/PRDV-16461-locked-decisions.md) on 2026-09-03.

Status: **refined**

**Phase 3 refinements** — the seed predated two locked decisions and was stale in one place, wrong in another:

| Change | Why |
| --- | --- |
| **NP-7 rewritten** | The seed asserted unpermitted tracks are "not offered." **LD-004 reversed that** — they are listed, disabled, with the `noTrackPermission` tooltip, following `TrackSelectorForm`. As seeded, this scenario would have **failed a correct implementation**. The rewrite also names the absent-from-list case as the failing shape. |
| **Test map row corrected** | Same stale "only permitted tracks offered" wording in the component-spec row. |
| **HP-8 and HP-9 added** | **LD-005** (a defaulted collection is immediately valid, no acknowledgement) had only a manual observation step and no asserted scenario. HP-8 proves submit works without touching the collection; HP-9 proves the boundary — existing validation still gates submission, so "the collection is valid" is not "the form is complete." |
| **Criterion citations renumbered** | Inserting criteria 12 and 13 into the accepted story shifted everything below them, so eight scenarios pointed at the wrong criterion (HP-6, NP-2/3/4, NP-6, EC-1, EC-2, EC-7). Every citation was re-checked against the story text, not just the shifted ones. Verified afterwards that all 14 criteria have at least one scenario and none is orphaned. |

This plan is now **frozen for execution**: it was refined against the locked decisions *before* any code exists, so the tests cannot be shaped by what gets built. There is no post-approval revision at Phase 5.

Each scenario names the acceptance criterion it exercises. Criteria authority is [job story 01](../stories/PRDV-16461-job-story-01-default-collection.md) — this plan proves them, it does not restate or amend them.

## Scope and surfaces under test

- **Behavior:** the collection is pre-selected to a fixed base-case value for Transcript and Video files when adding to client deliverables, overridable, never sticky, never applied by recategorize, and blank rather than wrong when the mapped value is unavailable.
- **Surfaces:** `useDeliverableFileUploadForm` (the resolver and its watchers), `DeliverableFileUploadForm.vue` (the modal, including the new generic-DnD track selection), and the three add paths — generic drag-and-drop, per-track upload, and submission-file approval. Recategorize is under test as a **must-not-change** surface.
- **Not under test:** Callisto (no change), the visual "defaulted" indicator (job story 02), non-GCA flows beyond proving they are untouched.

## Happy path

- [ ] **HP-1** *(criteria 1, 7)* — GCA on, Client Deliverables tab. Drag in transcript files → modal opens with **no track and no collection** → choose Transcript → `Full Transcript` appears immediately and is editable.
- [ ] **HP-2** *(criteria 2, 7)* — Same, with video files → choose Video → `MP4 Video` appears immediately.
- [ ] **HP-3** *(criterion 6)* — Per-track Upload on the Transcript section → modal opens with the track locked and `Full Transcript` already selected.
- [ ] **HP-4** *(criterion 6)* — Per-track Upload on Video → `MP4 Video` already selected.
- [ ] **HP-5** *(criterion 6)* — Approve a submission video file → modal opens with the track inherited and locked, `MP4 Video` selected.
- [ ] **HP-6** *(criterion 11)* — With a default applied, per-file deliverable types resolve from filenames against that collection's eligible-type catalog, with no user interaction on the collection field.
- [ ] **HP-7** *(criterion 4)* — Override the defaulted collection to `Redacted` before submitting → the override is what gets submitted.
- [ ] **HP-8** *(criterion 12)* — With a default applied and types resolved, submit **without ever focusing or opening the collection field** → the add succeeds and the defaulted collection is what gets submitted. No acknowledgement step exists. Proves LD-005: the defaulted value is immediately valid.
- [ ] **HP-9** *(criterion 12, boundary)* — With a default applied but a filename that resolves **no** deliverable type, submit is still blocked until the user picks the type → confirms the defaulted collection is valid while existing validation continues to apply. Distinguishes "collection is valid" from "the form is complete."

## Negative paths

- [ ] **NP-1** *(criterion 5)* — **Load-bearing.** A track is mapped but the mapped collection is absent from the returned catalog → **nothing is selected, no error, and no fall-through to a different static collection.** This is the ordering rule's proof. A pass where the field shows some *other* collection is the specific failure this scenario exists to catch.
- [ ] **NP-2** *(criterion 10)* — Recategorize files that already have a collection → the existing collection is preserved, no default applied.
- [ ] **NP-3** *(criterion 10)* — Recategorize files whose collections **disagree** (ambiguous) on a multi-collection track → stays blank.
- [ ] **NP-4** *(criterion 10)* — **The singleton hole.** Recategorize with a null initial collection on a track that has **exactly one** static collection → stays blank. Fails today via the pre-existing `matches.length === 1` fallback; this is the regression test for concern C4.
- [ ] **NP-5** *(criterion 3)* — A dynamic pick (Excerpt / Trial Edit) is never auto-selected in any flow.
- [ ] **NP-6** *(criterion 14)* — Non-GCA upload and approve paths behave exactly as before; no collection is sent.
- [ ] **NP-7** *(criterion 13)* — A track the user lacks CREATE permission on **is listed in the new DnD track selector but disabled**, with the `noTrackPermission` tooltip explaining why. It cannot be chosen, so no default can land on an unsubmittable pick. **Failing shape to watch for:** the track being *absent* from the list — that is the behavior LD-004 rejected, and it breaks consistency with `TrackSelectorForm`.

## Edge cases

- [ ] **EC-1** *(criterion 9)* — Close and reopen the modal after overriding → the default re-applies; the previous choice is **not** remembered.
- [ ] **EC-2** *(criterion 8)* — In generic DnD, after choosing Transcript and manually overriding to `Redacted`, **change the track to Video** → the override is discarded, dynamic and per-file type state are cleared, and `MP4 Video` is applied.
- [ ] **EC-3** — Manual override with the track **unchanged**, while the collections query resolves late → the async backfill does **not** overwrite the override.
- [ ] **EC-4** — Collections arrive after the modal is already open (cold cache) → the default still applies once options land.
- [ ] **EC-5** — Exhibits and MVC (collectionless tracks) → still auto-select their internal `t-<id>-none` sentinel and show no collection field. Proves the recategorize guard did not blanket-block the singleton path.
- [ ] **EC-6** — An unmapped track that has exactly one static collection → the pre-existing single-option fallback still fires.
- [ ] **EC-7** *(criterion 11)* — A filename matching no auto-select rule → deliverable type left blank. Expected, not an error.
- [ ] **EC-8** — Empty catalog (no track types returned) → no selection, no error.

## Manual verification

**Before / after** — what changes, and what must not:

| | Before | After |
| --- | --- | --- |
| Generic DnD modal on open | Opens with a combined track/collection list, nothing selected; user picks a collection row | Opens asking for the track; on answering, the collection is filled in already |
| Per-track Upload (Transcript / Video) | Collection field empty | `Full Transcript` / `MP4 Video` pre-filled, editable |
| Approve a submission file | Collection field empty | Mapped collection pre-filled, editable |
| Recategorize | Existing collection shown; blank when files disagree | **Identical** — including the single-static-collection case, which today wrongly auto-selects |
| Exhibits / MVC | No collection field; track auto-selects | **Identical** |
| Non-GCA upload | No collection sent | **Identical** |

**Preconditions**
- Atlas running against a Callisto with the deliverable-collection seeds applied (migrations `1775761245238`, `1780604349327`, `1782200000003`).
- GCA feature flag **enabled** for the test user; user has CREATE on Transcript and Video for the proceeding.
- A proceeding with a Client Deliverables tab and at least one pending submission file on the Video track (for HP-5).
- **Baseline reading before acting:** open the per-track Upload modal on Transcript and confirm the collection field is empty today. That is the "before" screenshot.

**Steps**
1. Navigate to the proceeding detail page → **Client Deliverables** tab.
2. Drag two `.pdf` transcript files onto the page. Record what the modal asks for first.
3. Choose **Transcript**. Observe the collection field without touching it.
4. Change the track to **Video**. Observe what happens to the collection and to any per-file type selections.
5. Close the modal. Re-drag the same files, choose Transcript, override the collection to `Redacted`, close, and re-open. Confirm the default returns.
6. Use the per-track **Upload** control in the Transcript section. Observe the collection field on open.
7. Approve a Video submission file. Observe the collection field on open.
8. Select two already-uploaded deliverable files with **different** collections → Recategorize. Confirm the collection is blank and nothing was chosen for you.

**Evidence** — confirm the seeded rows exist in the environment under test (closes assumption A3):

```sql
SELECT dc."value", dc."collection_kind", tt."value" AS track
FROM "callisto"."deliverable_collections" dc
JOIN "callisto"."file_proceeding_track_types" tt
  ON tt."id" = dc."file_proceeding_track_type_id"
WHERE dc."proceeding_id" IS NULL
ORDER BY track, dc."value";
```

Expect at least: `Full Transcript`/static/Transcript, `Redacted`/static/Transcript, `MP4 Video`/static/Video, `MPEG Video`/static/Video, plus two `*DYNAMIC*` sentinel rows.

Screenshots should have the collection field **and** the track control in frame together — a screenshot of the collection alone does not show which track produced it.

**Pass / fail**

| Step | Passes | Fails |
| --- | --- | --- |
| 3 | `Full Transcript` appears without being clicked | Field stays empty → the mapping never fired, or the track change is not being observed |
| 4 | Collection becomes `MP4 Video`; prior per-file types cleared | Collection stays `Full Transcript` → the reset transition is missing; stale types → the clear is incomplete |
| 5 | Default returns on reopen | Override persists → stickiness regression against criterion 8 |
| 6, 7 | Mapped collection pre-filled with the track locked | Empty → the locked-track path was not covered; wrong value → mapping keyed incorrectly |
| 8 | Collection blank, nothing auto-chosen | A collection appears → recategorize guard failed; this is the criterion-9 violation |

**Load-bearing step: NP-1 / step 8's single-collection variant.** NP-1 proves the feature fails *blank* rather than *wrong* when data is missing, which is the difference between a graceful fallback and silently filing a file into the wrong collection. Step 8's variant proves the recategorize guard covers the pre-existing fallback, not just the new mapping. If either regresses, the defect is back.

## Test map

| Repo | Suite | Asserts |
| --- | --- | --- |
| `atlas-front-end` | `…/DeliverableFileUploadForm/composables/__specs__/useDeliverableFileUploadForm.spec.ts` | Resolver branches: mapped default per track, mapped-but-absent → null, recategorize guard (both multi- and single-collection), singleton fallback preserved for unmapped tracks, dynamic never selected, non-stickiness, async backfill guard |
| `atlas-front-end` | `…/DeliverableFileUploadForm/__specs__/DeliverableFileUploadForm.spec.ts` **(new — none exists today)** | The generic-DnD interaction end to end: track is selectable, unpermitted tracks are listed but disabled with the tooltip, collections scoped to the chosen track, default becomes **visible**, override survives an unchanged track, track change clears the override and re-defaults |

**Existing specs whose disposition changes** — recorded here so the diff is not mistaken for breakage:

| Spec | Line | Disposition |
| --- | --- | --- |
| `useDeliverableFileUploadForm.spec.ts` | `:418` | **Changes.** Multi-collection track with an initial track id: `null` → the mapped default |
| `useDeliverableFileUploadForm.spec.ts` | `:445` | **Unchanged — keep the assertion.** Generic DnD opens with no pre-selection; this is still the target state. *Add* a second assertion for reactive defaulting after track selection |
| `useDeliverableFileUploadForm.spec.ts` | `:1481` | **Unchanged.** Recategorize with a null collection on a multi-collection track must stay `null` |

## Results log

**Automated execution — 2026-09-03.** Final post-lint state.

| Gate | Command | Scope | Result | Exception / risk |
| --- | --- | --- | --- | --- |
| audit | `npm audit --audit-level=high` | atlas-front-end | **fail (waived)** | 11 high / 7 moderate / 1 low, all pre-existing on `main` (undici et al). This branch adds no dependency and touches no `package.json` or lockfile. Waived by user 2026-09-03; findings remain outstanding on `main` independently. |
| lint | `npm run lint` | atlas-front-end (`eslint . --max-warnings 0`) | **pass** | Required two `lint:fix` passes for Prettier formatting in new files; re-run clean, and tests were re-run against the post-lint tree. |
| types | `npx vue-tsc --noEmit` | atlas-front-end | **pass** | — |
| tests | `npx vitest run --maxWorkers 1` | whole suite — 141 files | **pass** — 1261 passed, 4 skipped | Skips are pre-existing, untouched by this work. |

**Scenario coverage — automated.** Scoped run: `npx vitest run --maxWorkers 1 src/callisto/.../DeliverableFileUploadForm/` → 99 passing across 3 files.

| Scenario | Covered by | Result |
| --- | --- | --- |
| HP-1, HP-2 *(mapped default appears on track choice)* | `useDeliverableFileUploadForm.spec.ts` — "choosing a mapped track applies its default collection"; `deliverableCollectionDefaults.spec.ts` | pass |
| HP-3 *(Transcript direct upload defaults on open)* | "a track is supplied by the caller without being locked → not treated as generic DnD" | pass |
| HP-4 *(Video direct upload)* | **not covered automatically** — the cited test exercises a Transcript initial track id only. Same code path, but the Video lane has no behavioural assertion | manual only |
| HP-5 *(approval)* | **not covered automatically** — no spec exercises the approve entry point | manual only |
| HP-7 *(override respected)* | "an override survives while the track is unchanged" | pass |
| **NP-1 — load-bearing** *(mapped-but-absent → blank, no substitution)* | "a mapped track is missing its base-case collection → stays null rather than falling back"; plus 8 unit cases in `deliverableCollectionDefaults.spec.ts` | pass |
| NP-2, NP-3 *(recategorize preserves / stays blank)* | existing recategorize specs, unchanged | pass |
| **NP-4 — regression** *(recategorize singleton stays blank)* | "recategorize opens with no collection on a track that has exactly one static" | pass — **red-before-green verified**, see below |
| NP-5 *(dynamic never auto-selected)* | `deliverableCollectionDefaults.spec.ts` — dynamic pick case | pass |
| NP-7 *(unpermitted track listed but disabled)* | `DeliverableFileUploadTrackOnlySelectField.spec.ts` — disabled-not-hidden + tooltip; composable "track options list every track, disabling those without permission" | pass |
| EC-1 *(non-sticky across reopen)* | "closing clears the track so the next open asks again" | pass |
| EC-2 *(track change clears override and re-defaults)* | "changing the track discards the previous override and re-defaults" | pass |
| EC-3 *(async backfill does not overwrite an override)* | existing "backfill should not overwrite the user choice" | pass |
| EC-5 *(collectionless tracks keep their sentinel)* | "recategorize opens on a collectionless track → sentinel still selected" | pass |
| EC-6 *(unmapped single-static track still auto-selects)* | existing single-pick auto-select spec | pass |

**Red-before-green proof (NP-4).** The pre-existing recategorize defect was verified real, not theoretical. With the source stashed and only the new test applied, it failed against unmodified code:

```
AssertionError: expected 't-2-c-10' to be null
```

Confirming a recategorize on a single-static-collection track auto-selects that collection on `main` today. The same test passes with the guard in place.

**Not yet executed — manual verification.** The manual steps above (including the environment `SELECT` closing assumption A3) require a running Atlas against a seeded Callisto and have **not** been performed. HP-6, HP-8, HP-9, NP-6, EC-4, EC-7 and EC-8 are either manual-only or best proven in the live app; they remain outstanding.
