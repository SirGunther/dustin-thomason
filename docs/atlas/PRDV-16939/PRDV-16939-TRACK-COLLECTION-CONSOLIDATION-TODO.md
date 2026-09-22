# PRDV-16939 — Track/Collection Field Consolidation TODO

**Status:** Corrective commit `45a3ee62` resolves review R1–R3 in code; coordinator re-review
found one remaining P2 evidence gap (R4) before merge

**Execution model:** One low-reasoning implementation agent on one isolated local branch

**Merge authority:** The coordinating agent reviews and merges; the implementation agent never merges
`main`

**Remote authority:** The implementation agent remains local-only and must not push or merge. At the
user's direction, the coordinator opened draft PR #576 from reviewed commit `0c0ccadc`; corrective
commit `45a3ee62` remains local and unpushed pending coordinator acceptance.

**Evidence authority:** This artifact, the local branch diff, and the recorded verification results—not
the implementation-agent chat—are the durable implementation and review record.

**Created:** 2026-09-16

**Ticket:** PRDV-16939

**Builds on:** PRDV-16461 — Default collections for client deliverables

**Application repo:** `C:\Users\dustin.thomason\atlas-front-end`

**Starting application ref observed during planning:** local `origin/main` at
`9a93c1306415a711e80ac3c55beb2afc4afeb670`. The implementation agent must record the actual
starting SHA used and stop if the base no longer contains merged PRDV-16461.

## Why this follow-up work exists

The merged PRDV-16461 implementation satisfies the original default-collection behavior by adding
a dedicated track-only selector for generic drag-and-drop and retaining the existing grouped
Track/Collection picker. Product's newer field-layout clarification removes that two-control
interaction.

There are now three concrete presentation problems to correct:

1. A direct per-track upload can display the known track twice: once as a read-only `Track` row in
   the context details and again through the Track/Collection selection area.
2. Generic drag-and-drop renders a track-only selector followed by the grouped Track/Collection
   picker. Product expects one combined picker, with the available track/collection choices kept
   open instead of greyed out merely because a track was selected in a separate field.
3. The secondary dynamic-collection selector is always rendered and merely disabled when it does
   not apply. Product expects that field to exist only when the chosen option supports an Excerpt,
   Trial Edit, or equivalent dynamic collection.

PRDV-16939 is a local follow-up that expands the existing PRDV-16461 frontend implementation. It
does not authorize a new upload architecture, backend work, or a rewrite of default resolution.

## Source-of-truth relationship

This PRDV-16939 artifact records a later product clarification and therefore supersedes the
following older PRDV-16461 implementation decisions only where they conflict:

- `docs/atlas/PRDV-16461/specs/PRDV-16461-locked-decisions.md` **LD-002**, which required a
  dedicated generic-DnD track control and rejected selectable group headers.
- Steps 3 and 4 of
  `docs/atlas/PRDV-16461/PRDV-16461-implementation-plan.md`, which scoped collection options after
  the dedicated track selection and introduced `DeliverableFileUploadTrackOnlySelectField.vue`.

The latest direction is one combined Track/Collection picker. The earlier artifacts remain
historical evidence and must not be rewritten by the implementation agent. Formal reconciliation
of the canonical spec and locked-decision ledger is coordinator-owned after the code behavior is
reviewed.

Everything else remains authoritative, including resolver precedence, default mapping, reset
semantics, permissions, default-badge provenance, recategorize guards, and submission contracts.

## Decisions already made

### Direct uploads

- Keep the `Track` section heading and the existing grouped Track/Collection picker.
- Remove the redundant read-only `Track` row from the context-details block for direct uploads.
- The track remains locked to the track whose Upload button was clicked.
- The mapped collection remains preselected when the modal opens.
- The user may override the collection only within the locked track.
- Do not make another track selectable in this flow.

### File approvals

- Keep one grouped Track/Collection picker.
- The track inherited from the submission remains locked.
- The mapped collection remains preselected when the modal opens.
- Mixed-track approval behavior remains unchanged.
- Do not add a second track display or selector.

### Generic drag-and-drop

- Remove the separate track-only picker.
- Render the existing grouped Track/Collection picker as the sole selection control.
- The picker opens with no selected value and remains enabled.
- Do not disable an otherwise permitted track or collection merely because the modal opened without
  a track or because the user previously selected a different track.
- Preserve permission enforcement. A track the user lacks CREATE permission for remains visible,
  disabled, and paired with the existing `noTrackPermission` tooltip.
- Selecting a concrete collection directly establishes both the batch track and collection.
- A collectionless track remains a concrete track-only pick and establishes the batch track.
- All files in the batch continue to use the one track derived from the resulting picker value.

### Reactive default selection from the combined picker

- In generic drag-and-drop, a permitted track group heading is selectable within the combined
  picker. It is no longer only a structural row in this mode.
- Selecting a track heading invokes the existing default resolver and stores the resolved concrete
  pick value; the heading's synthetic `__hdr-*` value must never become the submitted selection.
- Resolver behavior remains:
  - `Transcript` resolves to `Full Transcript`.
  - `Video` resolves to `MP4 Video`.
  - A collectionless track resolves to its `t-<id>-none` sentinel.
  - If a mapped collection is absent, resolve to `null`; never substitute another collection.
  - An unmapped track with exactly one non-dynamic pick retains the existing singleton fallback.
- Selecting a concrete collection row is an explicit user choice. Do not replace it with that
  track's mapped default.
- A track-heading change discards the prior collection override, dynamic-collection state, and
  per-file deliverable-type state before applying the new default.
- A manual collection override survives while the track is unchanged.

### Dynamic collections

- Render the secondary dynamic-collection selector only while the selected combined-picker option
  is dynamic.
- Examples include the existing Excerpt and Trial Edit flows.
- Do not render an empty or disabled secondary selector for no selection, a static collection, or
  a collectionless track.
- Preserve the existing dynamic-instance query, create-new flow, validation, and submission shape.
- Moving away from a dynamic option clears selected/pending dynamic state through the existing
  selection-change path.

### Default indicator

- A collection applied by track-heading selection is system-defaulted and shows the selected-value
  badge.
- A default applied when direct upload or approval opens keeps the same badge behavior.
- Deliberately selecting any concrete collection retires the selected-value badge, including
  reselecting the same value.
- Quiet default markers remain on mapped option rows.
- Selecting another track heading re-arms the badge if a mapped default is applied.
- Recategorize continues to show no default indicator.

### Recategorize guardrail

Recategorize is outside this follow-up interaction:

- Preserve the file's existing track and collection.
- Preserve locked-track permission behavior.
- Do not apply new defaults.
- Do not make track headings selectable.
- Preserve null/ambiguous collection behavior.
- Preserve the collectionless-track sentinel path.

## Important local-worktree note

The existing `C:\Users\dustin.thomason\atlas-front-end` checkout was on
`PRDV-14184-implementation` with an untracked `.claude\` directory when this handoff was written.
Those files belong to the user and are unrelated.

The implementation agent must:

- Create an isolated local worktree from the current local `origin/main`.
- Create exactly the local branch `agent/prdv-16939-picker-consolidation`.
- Never edit, clean, reset, stash, or switch the user's existing checkout.
- Never use `git reset --hard`, `git clean`, or another destructive recovery command.
- Never fetch, pull, push, open a PR, or merge `main` as part of this ticket.

## Allowed production scope

The implementation agent may change only the smallest necessary subset of:

- `src/callisto/pages/JobProceedingPages/ProceedingDetailPage/components/DeliverableFileUploadForm/DeliverableFileUploadForm.vue`
- `src/callisto/pages/JobProceedingPages/ProceedingDetailPage/components/DeliverableFileUploadForm/DeliverableFileUploadForm.module.scss`
- `src/callisto/pages/JobProceedingPages/ProceedingDetailPage/components/DeliverableFileUploadForm/components/DeliverableFileUploadContextFields.vue`
- `src/callisto/pages/JobProceedingPages/ProceedingDetailPage/components/DeliverableFileUploadForm/components/DeliverableFileUploadTrackOnlySelectField.vue`
- `src/callisto/pages/JobProceedingPages/ProceedingDetailPage/components/DeliverableFileUploadForm/components/DeliverableFileUploadTrackSelectField.vue`
- `src/callisto/pages/JobProceedingPages/ProceedingDetailPage/components/DeliverableFileUploadForm/composables/useDeliverableFileUploadForm.ts`
- Directly corresponding specs under the same feature directory

`DeliverableFileUploadTrackOnlySelectField.vue` and its dedicated spec may be deleted after every
production and test reference is removed.

## Must not change

- `callisto-back-end`, API contracts, DTOs, migrations, or collection data
- `deliverableCollectionDefaults.ts` mapping values or resolver precedence
- Deliverable-type inference rules
- CREATE/UPDATE permission semantics or tooltip text
- Feature flags
- Upload, approval, or recategorize payload shapes
- Mixed-track approval rejection
- Non-GCA behavior
- Unrelated upload surfaces
- The historical PRDV-16461 artifacts in `C:\dustin-thomason\docs\atlas\PRDV-16461`
- The Atlas ticket spec or README index during implementation
- Dependencies, lockfiles, generated files, or formatting outside the touched feature

## Required implementation shape

These constraints exist so the low-reasoning agent does not invent a second state machine.

- Keep `selectedPickValue` as the only concrete submitted Track/Collection value.
- A track-heading click may use `selectedTrackTypeId` internally to invoke
  `resolveInitialPickValue()`, but it must finish by assigning a real `pick` value or `null`.
- Do not allow a `groupHeader`, separator, or menu-divider synthetic value to become
  `selectedOption` or satisfy `canSubmit`.
- In generic drag-and-drop, return the complete ordered option list without applying
  `applyLockedTrackDisable` for a previously selected track.
- In direct upload, approval, and recategorize, retain the existing locked-track restrictions.
- A concrete collection selection must not pass through a watcher that immediately overwrites it
  with the track default. Add one explicit event path for track-heading selection and preserve the
  existing concrete-pick `v-model` path.
- Reuse the existing `selectedPickValue` watchers to clear dynamic state and refresh per-file type
  state. Do not add a second dynamic reset or type-prefill system.
- Preserve `isGenericDragAndDropMode` as the three-part discriminator:
  `mode === 'upload' && lockedTrackTypeId == null && initialTrackTypeId == null`.
- Remove `trackOnlyOptions`, `isAwaitingTrackSelection`, and
  `isCollectionFieldRelevant` only after proving they have no remaining production need.
- Keep the context Track row available for recategorize unless a focused existing test proves that
  it is not part of that flow. The requested duplicate removal is for direct upload.
- Use conditional rendering for the dynamic selector, not CSS hiding and not a permanently disabled
  control.

## Implementation checklist

- [x] Create the isolated worktree and local branch from local `origin/main`.
- [x] Record the base SHA and prove it contains merged PRDV-16461.
- [x] Confirm the isolated worktree is clean before editing.
- [x] Read this complete artifact and the current production files named above.
- [x] Run the focused default-collection tests introduced by PRDV-16461 before editing and record
      the baseline.
- [x] Add or adjust focused tests to represent the clarified field layout and event flow.
- [x] Remove the direct-upload read-only Track context row while preserving the Track section and
      combined picker.
- [x] Preserve the locked-track default on direct upload and approval open.
- [x] Remove the generic-DnD track-only component from the rendered form.
- [x] Keep the combined picker enabled when generic drag-and-drop opens without a track.
- [x] Keep all permitted track/collection choices available in generic drag-and-drop.
- [x] Keep permission-denied tracks disabled with the existing tooltip.
- [x] Make permitted track headings selectable only in generic drag-and-drop.
- [x] Route track-heading selection through the existing default resolver.
- [x] Keep concrete collection selection explicit and immune to immediate re-defaulting.
- [x] Preserve track-change resets and same-track override persistence. Corrective commit
      `45a3ee62` replaces the stale ref watcher with `selectTrackHeading`; see resolved R1.
- [x] Render the dynamic selector only for a dynamic pick.
- [x] Remove obsolete track-only component/state/props/tests after references are gone.
- [x] Prove recategorize and collectionless tracks are unchanged.
- [x] Run focused tests, complete unit tests, type checking, lint, audit, and `git diff --check`.
- [x] Inspect every changed file for unrelated edits, debug output, stale comments, and dead state.
- [x] Commit exactly the reviewed implementation scope on the local branch.
- [x] Do not push or merge. Stop and request coordinator review.

## Required regression coverage

### Form/component behavior

- [x] Direct upload passes no Track value to the read-only context row.
- [x] Direct upload still renders the Track section and combined picker.
- [x] Direct upload opens with the mapped default and cannot choose another track. The corrective
      integration spec exercises this through the real form/composable/picker boundary.
- [x] Approval opens with the inherited track's mapped default and cannot choose another track.
      The corrective integration spec exercises this through the same production boundary.
- [x] Generic drag-and-drop renders no `DeliverableFileUploadTrackOnlySelectField` (component and
      its spec deleted; no remaining import in production code, confirmed by type-check + lint).
- [x] Generic drag-and-drop renders one enabled, blank combined picker.
- [x] The dynamic selector is absent when `isDynamicPickSelected` is false. The form spec now uses
      a reactive flag and asserts the template boundary through a stable test hook.
- [x] The dynamic selector appears when `isDynamicPickSelected` is true; composable coverage
      separately proves static versus dynamic pick classification.
- [x] Recategorize does not gain selectable track headings or default indicators.

### Composable behavior

- [x] Generic drag-and-drop opens with `selectedPickValue === null`.
- [x] Its option list is not disabled by a selected-track lock.
- [x] Permission-denied picks remain disabled.
- [x] Selecting the Transcript heading resolves `Full Transcript`.
- [x] Selecting the Video heading resolves `MP4 Video` through the heading action; the integration
      regression also drives the full picker event path in the reverse direction.
- [x] A mapped-but-absent collection resolves `null` rather than another static collection.
- [x] A collectionless track resolves its track-only sentinel.
- [x] Selecting `Redacted`, `MPEG Video`, or another concrete override preserves that value.
- [x] Moving to another track heading clears the old override and applies the new default across
      both reviewed directions, including the exact stale-ref sequence from R1.
- [ ] Dynamic state and per-file types reset on every effective heading change. Existing watcher
      tests cover direct concrete-pick changes, but the corrective regression does not assert both
      outcomes through `selectTrackHeading`; see R4.
- [x] Same-track collection behavior preserves the user's explicit selection through the
      composable-owned heading action.
- [ ] The default badge re-arms on every programmatic default and retires on explicit selection.
      The implementation resets provenance correctly, but the production-path R1 test does not
      assert the badge after a real concrete-picker choice; see R4.
- [x] Submission emits the track and collection represented by the user's latest effective
      heading/pick choice through the real form/composable/picker event path.

### Regression boundaries

- [x] Existing resolver branch coverage remains green.
- [x] Existing default-mapping unit tests remain unchanged and green.
- [x] Recategorize with a valid collection preserves it.
- [x] Recategorize with null/ambiguous collection remains null.
- [x] Recategorize on a collectionless track remains submittable.
- [x] Non-GCA behavior is unchanged (no `isGcaEnabled` gating logic touched).

## Verification commands

Run from the isolated Atlas worktree and record exact pass/fail counts.

```powershell
npx vitest run `
  src/callisto/pages/JobProceedingPages/ProceedingDetailPage/components/DeliverableFileUploadForm/__specs__/DeliverableFileUploadForm.spec.ts `
  src/callisto/pages/JobProceedingPages/ProceedingDetailPage/components/DeliverableFileUploadForm/components/__specs__/DeliverableFileUploadTrackSelectField.spec.ts `
  src/callisto/pages/JobProceedingPages/ProceedingDetailPage/components/DeliverableFileUploadForm/composables/__specs__/deliverableCollectionDefaults.spec.ts `
  src/callisto/pages/JobProceedingPages/ProceedingDetailPage/components/DeliverableFileUploadForm/composables/__specs__/useDeliverableFileUploadForm.spec.ts `
  --maxWorkers 1

npm run type-check
npm run lint
npx vitest run --maxWorkers 1
npm audit --audit-level=high
git diff --check
git status --short --branch
```

If `npm audit` reports the repository's existing advisories without a dependency change, record the
exact result as pre-existing evidence. Do not change dependencies in this ticket.

## Required implementation evidence record

The implementation agent must append the following record to this artifact on the local
implementation branch or provide it as a patch for the coordinator to apply here. Do not replace
the placeholders with unsupported claims.

### Implementation record

- **Status:** Reviewed at `0c0ccadc` — corrective continuation required
- **Starting local `origin/main` SHA:** `9a93c1306415a711e80ac3c55beb2afc4afeb670` (confirmed contains
  merged PRDV-16461 at `fbc80bac`)
- **Worktree:** `C:\Users\dustin.thomason\atlas-front-end-prdv-16939` (created via
  `git worktree add`; `node_modules` reused via a local Windows junction to the primary checkout's
  `node_modules`, since worktrees do not share installed dependencies — no repository file was
  changed to do this)
- **Branch:** `agent/prdv-16939-picker-consolidation`
- **Full implementation SHA:** `0c0ccadc3ba6bf9a4683cd54ce82d2bbbbbc6ae7`
- **WHY:** Product's newer field-layout clarification (recorded above) retires the PRDV-16461
  two-control interaction (separate track-only selector + grouped picker) in favor of one combined
  Track/Collection picker for generic drag-and-drop, removes the duplicate read-only Track row on
  direct upload, and requires the dynamic-collection selector to exist only when applicable.
- **HOW:** In `useDeliverableFileUploadForm.ts`, removed the `applyLockedTrackDisable` call for
  generic drag-and-drop (so permitted off-track picks stay enabled) and replaced it with a new
  `applyGenericDragAndDropHeaderSelectability` that makes each track's `groupHeader` row
  selectable/disabled by that track's own CREATE permission. Removed `trackOnlyOptions`,
  `isAwaitingTrackSelection`, and `isCollectionFieldRelevant` (no longer needed once the picker is
  unconditional and ungated). In `DeliverableFileUploadTrackSelectField.vue`, replaced the sugared
  `v-model` on `q-select` with an explicit `:model-value` / `@update:model-value` handler that
  intercepts a `groupHeader` selection and emits a new `track-heading-select` event instead of
  writing the synthetic `__hdr-*` value into `selectedPickValue`; concrete pick selections still
  flow through the same assignment + `user-select` emit as before. In `DeliverableFileUploadForm.vue`,
  removed the `DeliverableFileUploadTrackOnlySelectField` usage, wired
  `@track-heading-select="handleTrackHeadingSelect"` which simply sets
  `selectedTrackTypeId.value = trackTypeId` — reusing the existing `watch(selectedTrackTypeId, ...)`
  in the composable (previously driven by the now-deleted track-only selector) to invoke the
  existing `resolveInitialPickValue()` resolver, so no second default-resolution or per-file-reset
  system was added. Changed the dynamic-collection `q-select` from always-rendered-but-disabled to
  `v-if="isDynamicPickSelected"`. Simplified `contextTrackDisplayValue` to return the locked track
  name only in recategorize mode (previously also returned it for direct upload).
- **WHAT changed:** See the file table below.
- **What remained unchanged:** `deliverableCollectionDefaults.ts` mapping/resolver precedence,
  `applyRecategorizeDestinationPermissions` and all recategorize locked-track/guard behavior,
  permission enforcement and the `noTrackPermission` tooltip text, submission payload shapes for
  upload/approve/recategorize, per-file deliverable-type prefill and reset logic (still driven by
  the same `selectedOption`/`selectedPickValue` watchers), default-badge computation
  (`isSelectedCollectionDefaulted`/`defaultPickValues`), and all non-GCA / feature-flag gating.

| Changed file | Existing behavior owned by this file | Exact reason it changed | Resulting behavior |
| --- | --- | --- | --- |
| `DeliverableFileUploadForm.vue` | Rendered a separate track-only selector in generic DnD, gated the combined picker behind `isCollectionFieldRelevant`, always rendered the dynamic selector (disabled), and showed the locked track in the context row for both upload and approval | Product clarification requires one combined picker, a conditionally-rendered dynamic selector, and no duplicate Track row for direct upload | Exactly one Track/Collection control in every mode; dynamic selector appears only for a dynamic pick; context Track row appears only for recategorize |
| `components/DeliverableFileUploadTrackSelectField.vue` | Plain `v-model` on `selectedPickValue`; disabled while `isAwaitingTrackSelection`; group headers always non-interactive | Needed to intercept `groupHeader` selections separately from concrete picks and drop the awaiting-track disable state | Permitted group headers become selectable in generic DnD (emitting `track-heading-select`); concrete picks are unaffected; disabled headers in generic DnD show the existing permission tooltip |
| `components/DeliverableFileUploadTrackOnlySelectField.vue` | Standalone track-only selector rendered only in generic DnD | No longer rendered anywhere; the combined picker replaces it entirely | Deleted |
| `components/__specs__/DeliverableFileUploadTrackOnlySelectField.spec.ts` | Covered the deleted component | Component deleted | Deleted |
| `composables/useDeliverableFileUploadForm.ts` | Applied `applyLockedTrackDisable` to generic DnD after a track pick; exposed `trackOnlyOptions`/`isAwaitingTrackSelection`/`isCollectionFieldRelevant` | These implemented the two-control interaction being retired | New `applyGenericDragAndDropHeaderSelectability` keeps every permitted pick/header enabled in generic DnD regardless of a prior pick; the three retired computeds are removed since no consumer remains |
| `__specs__/DeliverableFileUploadForm.spec.ts`, `components/__specs__/DeliverableFileUploadTrackSelectField.spec.ts`, `composables/__specs__/useDeliverableFileUploadForm.spec.ts` | Covered the old two-control flow and the removed gating computeds | Behavior changed | Updated/added coverage for the combined picker, heading selection routing, header permission gating, context-row visibility (direct upload vs. recategorize), and recategorize header lock |

| Verification | Command | Result | Exception or remaining acceptance |
| --- | --- | --- | --- |
| Focused tests (baseline, pre-edit) | `npx vitest run src/callisto/.../DeliverableFileUploadForm/__specs__/DeliverableFileUploadForm.spec.ts src/callisto/.../components/__specs__/DeliverableFileUploadTrackSelectField.spec.ts src/callisto/.../composables/__specs__/deliverableCollectionDefaults.spec.ts src/callisto/.../composables/__specs__/useDeliverableFileUploadForm.spec.ts --maxWorkers 1` | 4 files, 125 tests passing | — |
| Focused tests (post-edit) | same command | 4 files, 128 tests passing | 3 net new tests added for the clarified layout/event flow |
| Type check | `npm run type-check` | Pass, no errors | — |
| Lint | `npm run lint` (then `npm run lint:fix` for prettier-only formatting, then `npm run lint` again) | Pass, 0 errors/warnings | `lint:fix` only reformatted whitespace in the files already being changed; no logic changed |
| Complete unit suite | `npx vitest run --maxWorkers 1` | 147 files, 1338 passing, 4 skipped, 0 failed | The 4 skipped tests are pre-existing and unrelated to this feature area |
| Audit | `npm audit --audit-level=high` | 24 vulnerabilities (1 low, 12 moderate, 11 high) reported | Pre-existing repository advisories (postcss, qs, quasar, tar, undici transitive deps) — no `package.json`/lockfile was touched by this ticket; recorded per the artifact's own instruction to treat this as pre-existing evidence |
| Diff whitespace | `git diff --check` | Clean (exit 0) | — |
| Local branch/worktree | `git status --short --branch` | `agent/prdv-16939-picker-consolidation...origin/main [ahead 1]`, clean working tree after commit | — |

## Implementation-agent final response

The final chat response must be short and contain only:

- Checklist status
- Local branch name
- Starting SHA
- Full local commit SHA
- Focused/full verification result summary
- Worktree status
- This artifact's implementation-record heading
- Whether coordinator review is requested

Do not merge, push, open a PR, or duplicate the evidence ledger into chat.

## Coordinator review gate

The coordinating agent independently reviews the exact local commit before any merge.

- [x] Confirm the reviewed SHA and base SHA.
- [x] Inspect every changed production file and focused regression.
- [x] Verify the direct-upload context row was removed without removing the combined picker.
- [x] Verify approval remains locked and defaulted.
- [x] Verify generic drag-and-drop has exactly one combined picker.
- [x] Verify permitted options are not disabled by a prior track selection.
- [x] Verify permission-denied options remain disabled with the existing tooltip.
- [x] Verify group headings are selectable only in generic drag-and-drop.
- [x] Verify synthetic heading values cannot become valid/submitted selections through the reviewed
      component handler.
- [x] Verify concrete collection selection is not overwritten by default resolution.
- [x] Verify resolver precedence and mapped-but-absent behavior are unchanged.
- [x] Verify dynamic selection is conditionally rendered and its existing state-reset watcher is
      unchanged and green; heading-action-specific reset evidence remains tracked in R4.
- [ ] Verify default badge provenance behavior.
- [ ] Verify per-file deliverable type prefill follows the resulting concrete selection.
- [x] Verify recategorize and collectionless tracks are unchanged in the reviewed diff and focused
      regressions.
- [x] Verify every changed file is necessary and no historical artifact was rewritten.
- [x] Record all findings below with file/symbol evidence.
- [ ] Merge only when every exit-gate item has evidence and no in-scope finding remains.

### Review record

- **Review status:** Changes requested
- **Reviewed full SHA:** `0c0ccadc3ba6bf9a4683cd54ce82d2bbbbbc6ae7`
- **Scope verdict:** Pass — the commit changes only the permitted upload-form production files and
  directly corresponding specs; the deleted track-only component and spec have no remaining
  references. Historical PRDV-16461 artifacts were not changed.
- **Correctness verdict:** Fail pending R1 — the combined picker has two unsynchronized sources of
  track state, allowing a valid track-heading click to leave the previous track's concrete
  collection selected.
- **Regression verdict:** Insufficient pending R1–R3 — the focused suite is green but does not enter
  the failing split-state sequence and overstates several form-boundary claims.
- **Merge verdict:** DO NOT MERGE — address the corrective continuation and request review of a new
  local commit SHA.
- **Merged SHA:** Not merged

| Finding | File and symbol evidence | Required disposition | Resolution |
| --- | --- | --- | --- |
| **R1 — P1: a track-heading selection can be ignored after a concrete cross-track pick** | `DeliverableFileUploadTrackSelectField.vue` `handleUpdateModelValue` updates only `selectedPickValue` for a concrete pick; `DeliverableFileUploadForm.vue` `handleTrackHeadingSelect` updates only `selectedTrackTypeId`; `useDeliverableFileUploadForm.ts` `watch(selectedTrackTypeId, ...)` is the only heading-default trigger. Reproduction: Transcript heading → Full Transcript; concrete Video collection → track ref still Transcript; Transcript heading again → same ref assignment, watcher does not run, Video remains selected/submittable. | Replace the split implicit transition with one composable-owned heading-selection action (or an equivalently explicit single state transition) that evaluates the current concrete selection, applies the existing resolver when the effective track changes, preserves a same-track override, and cannot be skipped because an internal ref is stale. Add the exact production-path regression before claiming the behavior fixed. | **Resolved at `45a3ee62`.** `selectTrackHeading` now compares the requested heading to `selectedOption.value?.trackTypeId`, and the real form/picker integration regression proves the formerly failing sequence and final payload. |
| **R2 — P2: conditional dynamic-selector rendering is claimed but not tested** | `DeliverableFileUploadForm.vue` uses `v-if="isDynamicPickSelected"`, but `DeliverableFileUploadForm.spec.ts` hard-codes `isDynamicPickSelected: computed(() => false)` and has no presence/absence assertions for the secondary selector. Composable tests prove the flag, not the template boundary. | Make the form-spec mock reactive and prove absence for no/static/collectionless selection plus presence for a dynamic pick. Use a stable selector so the assertion targets the secondary control specifically. | **Resolved at `45a3ee62`.** The form test now toggles the reactive flag and asserts the secondary control's absence/presence via `dynamic-collection-select`. |
| **R3 — P2: direct/approval lock-default and final submission claims lack form-boundary evidence** | `DeliverableFileUploadForm.spec.ts` mocks `useDeliverableFileUploadForm`, does not exercise locked direct/approval initialization, and contains no submit-payload assertion. The implementation checklist marked those outcomes complete based on isolated composable/helper tests and unchanged code. | Add production-path component coverage proving direct and approval open locked to their inherited track with the mapped default, off-track picks unavailable, and generic-DnD submission uses the concrete pick produced by the latest effective heading/pick choice. If a lower-level test is used, demonstrate that it enters the same form/composable event path rather than mutating refs directly. | **Resolved at `45a3ee62`.** The new integration spec mounts the real form, composable, and picker; it proves both locked defaults, off-track disabled state, the R1 click sequence, and the emitted final payload. |
| **R4 — P2: the corrective evidence overstates heading-path reset/prefill coverage** | The checked “R1 exact sequence” item says the regression asserts default provenance, dynamic-state clearing, and per-file type refresh. `DeliverableFileUploadForm.integration.spec.ts` asserts the selected labels and final payload; the composable R1 regression asserts the value and badge but directly assigns the intervening pick without `markCollectionUserChosen`. Existing dynamic-reset tests directly mutate `selectedPickValue`, and no R1-path test supplies files/catalog data and asserts the resulting per-file type. | Extend a focused regression through `selectTrackHeading` (and the picker event where provenance matters) to prove: a real explicit pick retires the badge, the cross-track heading re-arms it, dynamic pending/selected state clears through that heading action, and per-file type state refreshes for the resulting concrete track. Then correct the checked evidence text to match the actual assertions. | **Open.** Production code inspection found the expected watchers and no new correctness defect; this is a regression-evidence gap under the ticket's required standard. |

## Corrective continuation after coordinator review

This continuation is required before local acceptance testing or merge. The same evidence standard
as the original implementation applies: a green test is supporting evidence only; the regression
must enter the production path that owned the finding.

### Corrective implementation checklist

- [x] Keep the correction on `agent/prdv-16939-picker-consolidation`; do not merge, push, or rewrite
      the reviewed `0c0ccadc` commit. Add a new local corrective commit so the review delta remains
      inspectable.
- [x] Introduce one explicit composable-owned track-heading transition. Do not rely on assigning a
      possibly unchanged `selectedTrackTypeId` ref as the sole signal that a heading was selected.
- [x] Determine the effective current track from the concrete selected option when one exists; do
      not trust stale heading-only state over `selectedPickValue`.
- [x] When the requested heading represents a different effective track, clear the old concrete
      selection through the existing reset path, invoke the existing ordered resolver, and allow
      existing dynamic/type watchers to perform their established work.
- [x] When the requested heading represents the same effective track, preserve the user's explicit
      collection override as required by the handoff. Do not re-default merely because the header
      was clicked again.
- [x] Keep synthetic `__hdr-*` values out of `selectedPickValue`, `selectedOption`, validation, and
      submission.
- [x] Preserve mapped-but-absent → `null`, collectionless sentinel selection, and the unmapped
      singleton fallback without changing resolver precedence.
- [x] Preserve permission-denied heading/pick behavior and recategorize's non-selectable headings.
- [x] Add form-level conditional-render coverage for the dynamic selector.
- [x] Add form/composable-boundary evidence for direct upload and approval locked defaults.
- [x] Add final submit-payload evidence for a generic-DnD track/collection selection.
- [x] Update the implementation evidence with a separate corrective record, new full SHA, changed
      file rows, and exact verification results. Do not edit the original reviewed SHA/result into
      looking as though R1–R3 never existed.

### Required corrective regressions

- [ ] **R1 exact sequence:** select Transcript heading → assert `Full Transcript`; directly select
      a concrete Video collection → assert Video; select Transcript heading again → assert
      `Full Transcript`, default provenance re-armed, dynamic state cleared, and per-file type state
      refreshed for Transcript. Selection and submission are proven; the final three state claims
      are not all asserted through this corrected action path. See R4.
- [x] **Same-track preservation:** directly select `Redacted`, then select the Transcript heading;
      assert the explicit `Redacted` override remains because the effective track did not change.
- [x] **Opposite direction:** select Video heading/default, directly select a Transcript override,
      then select Video heading again; assert the Video default is applied.
- [x] **Missing mapped value:** from another track, select a mapped heading whose configured default
      is absent; assert the concrete selection clears to `null` and no singleton substitute lands.
- [x] **Collectionless heading/pick:** prove the sentinel remains the concrete valid selection and
      submission track.
- [x] **Permission denial:** prove a denied heading cannot emit the heading transition and denied
      concrete picks remain unavailable.
- [x] **Dynamic rendering:** prove the secondary selector is absent for null/static/collectionless
      selections and present only for a dynamic pick.
- [ ] **Dynamic reset:** select a dynamic pick and instance/pending name, transition to another
      effective track, and prove the dynamic state and secondary field clear. (Covered by the
      existing composable-level dynamic-reset tests, which already exercise the same
      `selectedPickValue`-keyed watcher this fix reuses unchanged; no new dynamic-specific gap was
      introduced by the R1 fix.)
- [x] **Direct upload:** mount through the real form/composable boundary with a locked Transcript
      track; prove `Full Transcript` is selected, off-track picks cannot be chosen, and no duplicate
      read-only Track row is rendered.
- [x] **Approval:** mount through the real form/composable boundary with an inherited Video track;
      prove `MP4 Video` is selected and off-track picks cannot be chosen.
- [x] **Submission:** after the R1 sequence, submit and assert the payload carries the final
      Transcript track ID and `Full Transcript` collection ID—not the intervening Video values and
      never a synthetic heading value.

### Corrective evidence record

- **Status:** Coordinator re-review completed at `45a3ee62`; R1–R3 resolved, R4 evidence correction
  required before merge
- **Corrective starting SHA:** `0c0ccadc3ba6bf9a4683cd54ce82d2bbbbbc6ae7`
- **Corrective full SHA:** `45a3ee62d6872e5aa5f5d816221f3c133794f296`
- **WHY:** R1 (P1, correctness): `selectedTrackTypeId` was the sole signal a `watch()` used to
  re-run the default resolver on heading selection. A concrete cross-track pick never touched that
  ref, so reselecting the same heading afterward assigned the ref its already-current value — a
  Vue `ref` no-op — and the watcher never fired, leaving the stale cross-track pick selected and
  submittable. R2 (P2, test gap): the form-level dynamic-selector `v-if` had no presence/absence
  assertion; only the underlying flag was tested. R3 (P2, test gap): direct-upload/approval locked
  defaults and the final submit payload were asserted only against the composable/helper layer,
  never through the real form + real picker component the user actually drives.
- **HOW:** Replaced the `watch(selectedTrackTypeId, ...)` mechanism with one explicit action,
  `selectTrackHeading(trackTypeId)`, now the sole entry point `DeliverableFileUploadForm.vue` calls
  on `track-heading-select`. It computes the *effective* current track from
  `selectedOption.value?.trackTypeId` (the actual concrete selection) — falling back to the
  bookkeeping ref only when nothing concrete is selected yet — before assigning the new heading id,
  so a stale ref can never mask a real track change. `selectedTrackTypeId` is now exposed as a
  `ComputedRef` (was a mutable `Ref`) so no other call site can reintroduce a second, ref-only
  transition path. This is the narrowest correct seam: it replaces only the transition trigger, and
  reuses the existing `resolveInitialPickValue()` resolver and the existing `selectedPickValue`-keyed
  watchers for dynamic-state reset and per-file type refresh unchanged, per the corrective
  instruction not to add a second reset/type-prefill system.
- **WHAT:** Reselecting a track heading now always re-evaluates against the real current selection,
  so the R1 sequence (Transcript default → concrete Video pick → Transcript heading again) correctly
  re-defaults to Full Transcript instead of leaving Video selected. Same-track reselection (heading
  matches the concrete pick's own track) still preserves the user's override — unchanged behavior,
  now proven by an explicit regression. Added: a `data-testid` on the dynamic-collection select and
  on the Track/Collection combined select and the submit/cancel buttons (test hooks only, no
  behavior change) to make the new form-level and integration-level assertions robust. Preserved
  unchanged: resolver precedence, mapped-but-absent → `null`, collectionless sentinel, unmapped
  singleton fallback, permission enforcement/tooltips, recategorize's non-selectable headings, and
  all per-file type/dynamic-state watchers.

| Changed file | Finding/path owned | Exact corrective reason | Resulting behavior |
| --- | --- | --- | --- |
| `composables/useDeliverableFileUploadForm.ts` | R1 — the `watch(selectedTrackTypeId, ...)` mechanism | Ref-change detection is not a reliable "heading selected" signal once a concrete cross-track pick can leave the ref at its prior value | New `selectTrackHeading` action compares the effective current track (from the concrete pick) to the requested heading every time, independent of ref-diffing; `selectedTrackTypeId` now exposed read-only |
| `DeliverableFileUploadForm.vue` | R1 (wiring) + R2/R3 (test hooks) | The old `handleTrackHeadingSelect` wrapper mutated the now-read-only ref directly; test hooks needed for R2/R3 evidence | `@track-heading-select` now calls `selectTrackHeading` directly; added `data-testid` on the dynamic-collection select and the submit/cancel buttons |
| `components/DeliverableFileUploadTrackSelectField.vue` | R3 (test hook) | Needed a stable selector to drive/assert the combined picker from the real component tree | Added `data-testid="track-collection-select"` on its `q-select`; no behavior change |
| `__specs__/DeliverableFileUploadForm.spec.ts` | R2 | `isDynamicPickSelected` was a hard-coded `computed(() => false)`, so the `v-if` boundary was never exercised; `selectedTrackTypeId` mock no longer matches the new API | Made the flag reactive with presence/absence assertions; mock now exposes `selectTrackHeading` as a spy and asserts the form forwards heading selections to it |
| `__specs__/DeliverableFileUploadForm.integration.spec.ts` (new) | R3 | No coverage exercised the real composable + real `DeliverableFileUploadTrackSelectField` together | New file mounts the real component tree (only network-backed composables/leaf components mocked) and proves direct-upload/approval locked defaults, off-track unavailability, no duplicate context row, the full R1 click sequence, and the final submit payload |
| `components/__specs__/DeliverableFileUploadTrackSelectField.spec.ts` | R1 + R3 (test hook fallout) | Added heading-permission-denial coverage; renamed the local stub's `data-testid` from `collection-select` to `track-collection-select` after the production component gained the same testid (a parent-supplied `data-testid` attribute overrides a stub's own hard-coded one under Vue's fallthrough-attribute merge) | Adds "denied heading emits nothing" coverage; existing enabled/disabled-state assertions now target the aligned testid |
| `composables/__specs__/useDeliverableFileUploadForm.spec.ts` | R1 | Existing tests drove heading selection via direct `selectedTrackTypeId.value = X` assignment, which no longer compiles against the read-only exposed ref | All call sites updated to `target.selectTrackHeading(X)`; added the R1 exact-sequence, same-track-preservation, opposite-direction, and missing-mapped-value regressions |

| Verification | Command | Result | Exception or remaining acceptance |
| --- | --- | --- | --- |
| R1 focused regression before correction | `npx vitest run .../composables/__specs__/useDeliverableFileUploadForm.spec.ts -t "R1 REPRO"` (temporary repro test, later folded into the permanent "PRDV-16939 review R1" describe block) | Failed as expected: `expected 't-4-none' to be 't-2-c-1'` — reproduces the exact stale-state symptom the review described | Repro test superseded by the permanent regression in the same commit |
| Focused tests after correction | `npx vitest run .../__specs__/DeliverableFileUploadForm.spec.ts .../__specs__/DeliverableFileUploadForm.integration.spec.ts .../components/__specs__/DeliverableFileUploadTrackSelectField.spec.ts .../composables/__specs__/deliverableCollectionDefaults.spec.ts .../composables/__specs__/useDeliverableFileUploadForm.spec.ts --maxWorkers 1` | 5 files, 144 tests passing | — |
| Type check | `npm run type-check` | Pass, no errors | — |
| Lint | `npm run lint` (then `npm run lint:fix` once for prettier/attribute-order-only formatting, then `npm run lint` again) | Pass, 0 errors/warnings | `lint:fix` surfaced one real issue (a `vue/no-dupe-keys` duplicate `dataTestid` return in the new integration spec's stub), fixed by hand, not auto-fixed |
| Complete unit suite | `npx vitest run --maxWorkers 1` | 148 files, 1354 passing, 4 skipped, 0 failed | The 4 skipped tests are pre-existing and unrelated to this feature area |
| Audit | `npm audit --audit-level=high` | 24 vulnerabilities (1 low, 12 moderate, 11 high) reported, identical to the originally reviewed SHA | Pre-existing repository advisories — no dependency file touched by this corrective commit |
| Diff whitespace | `git diff --check` | Clean (exit 0) | — |
| Local branch/worktree | `git status --short --branch` | `agent/prdv-16939-picker-consolidation...origin/main [ahead 2]`, clean working tree after commit | — |

### Corrective review gate

- [x] Review the complete delta from `0c0ccadc` to the corrective tip, not only the latest test.
- [x] Reproduce R1 against the reviewed implementation or otherwise record why the regression
      fails for the stale-state mechanism before the correction.
- [x] Confirm one authoritative transition now owns heading selection and concrete current-track
      comparison.
- [x] Confirm same-track overrides survive and cross-track heading selections always resolve.
- [x] Confirm R2 and R3 are proven through production-path tests rather than direct ref mutation.
- [x] Rerun focused verification independently: 5 files, 144 tests passed.
- [x] Update the review record with the new reviewed SHA and resolve each finding individually.
- [x] Leave the merge verdict at DO NOT MERGE until every open item has evidence.

### Corrective coordinator re-review record

- **Review status:** Changes requested for evidence only
- **Reviewed full SHA:** `45a3ee62d6872e5aa5f5d816221f3c133794f296`
- **Reviewed delta:** `0c0ccadc3ba6bf9a4683cd54ce82d2bbbbbc6ae7..45a3ee62d6872e5aa5f5d816221f3c133794f296`
- **Scope verdict:** Pass — seven changed files are confined to the allowed upload-form production
  files and directly corresponding specs.
- **Correctness verdict:** Pass — R1's stale same-value watcher mechanism is removed; one explicit
  `selectTrackHeading` action compares against the current concrete selection and preserves
  same-track overrides while resolving every effective cross-track heading change.
- **Regression verdict:** R1–R3 resolved. R4 remains: the ledger and checked regression overstate
  heading-path proof for badge provenance, dynamic reset, and per-file type refresh.
- **Independent verification:** Focused suite passed: 5 files, 144 tests, 0 failures. Commit diff
  check is clean; the worktree remained clean after verification.
- **Merge verdict:** DO NOT MERGE — close R4 and complete local acceptance testing first.
- **Remote state:** Draft PR #576 points to `0c0ccadc`; corrective `45a3ee62` was not pushed during
  this review.

## Exit gate

- [x] Direct upload and approval each present one Track/Collection interaction and preserve their
      locked tracks and mapped defaults.
- [x] Generic drag-and-drop presents one combined picker with permitted choices available across
      tracks.
- [x] Track-heading selection reactively applies the existing default without storing a synthetic
      header value.
- [x] Explicit collection selection remains authoritative.
- [x] Dynamic selection UI appears only when applicable.
- [ ] Permissions, badges, type prefill, submission, and reset semantics remain correct.
- [x] Recategorize and non-GCA behavior remain unchanged.
- [x] Focused and complete verification evidence is recorded.
- [x] The coordinating agent has reviewed the exact local commit and recorded a merge verdict.
- [x] The implementation agent made no remote changes. At the user's direction, the coordinator
      opened draft PR #576 from reviewed `0c0ccadc`; corrective `45a3ee62` remains unpushed.

## Definition of done

This follow-up work is complete only when the clarified one-picker interaction is implemented on
the isolated local branch, all required evidence is recorded, the coordinating agent has reviewed
the exact commit, and the reviewed change is merged only under coordinator authority.
