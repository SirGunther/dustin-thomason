# Job story 01 — Default collection pre-selection

- **Ticket:** PRDV-16461
- **Project:** atlas
- **Date:** 2026-09-03
- **Source:** [PRDV-16461-original-ticket.md](../PRDV-16461-original-ticket.md)
- **Status:** accepted (Phase 3, 2026-09-03)

## 1. Story Matrix

| Component | Framework Language | Story Sentence |
| --- | --- | --- |
| Motivation | *A [user type] doesn't want [undesired outcome].* | A Client Access user doesn't want to manually pick the collection for every base-case Transcript or Video file they add. |
| Context + Intent | *While [context], they want to [action].* | While adding files to a client deliverable, they want the common-case collection chosen for them automatically. |
| Obstacle + Desired Action | *Except that [obstacle], so they want to [action to rectify].* | Except that today nothing is pre-chosen, so they want the system to guess correctly for the vast majority of files and let them fix the rare exception. |
| Resolution | *Now they'll be able to [positive outcome].* | Now they'll be able to add most files without touching the collection choice at all, only correcting it when the file is unusual. |

## 2. Revision Matrix

No component carried design words (modal, dropdown, field, selector, DTM) — the matrix sentences already stay at the level of user motivation and outcome. No revision needed.

| Component | Before | Issue | After |
| --- | --- | --- | --- |
| — | — | none found | unchanged |

## 3. Delivery Acceptance Statement (DAS)

*We know this story is considered complete when:*
- A user adding a Transcript-track file to a client deliverable sees the collection already set to the fixed base-case value for that track, without picking it themselves.
- A user adding a Video-track file to a client deliverable sees the collection already set to the fixed base-case value for that track, without picking it themselves.
- The auto-chosen collection is always the same fixed base-case value for a track — never a value that changes based on the file or situation.
- A user can still change the auto-chosen collection to a different one before finishing the add, and their choice is respected.
- When the fixed base-case collection isn't available to choose from in a given proceeding, nothing is auto-chosen and the user picks manually, with no error shown.
- The auto-choice happens whether the user is dragging files in, using the per-track upload action, or approving a submitted file into the deliverable set.
- When adding files by dragging them in, the user is asked which track the files belong to, and the auto-choice appears as soon as they answer — before they have looked at the collection.
- Changing that answer replaces the auto-choice with the one for the newly-chosen track, and discards anything the user had picked under the previous answer.
- Every separate add action gets a fresh auto-choice of the fixed base-case value — a user's earlier manual change on a prior file is never carried forward as the new default.
- Recategorizing a file that's already in the deliverable set never changes its existing collection on its own — only a user's manual change does.
- Once the collection is auto-chosen, the deliverable type is filled in the same way it already is when a user picks that collection manually — i.e., the two behaviors compose rather than requiring the user to touch the collection field first.
- This behavior only occurs for deliverables handled through the GCA-enabled flow; other flows behave exactly as they do today.

## 4. Concatenated Story

A Client Access user doesn't want to manually pick the collection for every base-case Transcript or Video file they add. While adding files to a client deliverable, they want the common-case collection chosen for them automatically. Except that today nothing is pre-chosen, so they want the system to guess correctly for the vast majority of files and let them fix the rare exception. Now they'll be able to add most files without touching the collection choice at all, only correcting it when the file is unusual.

## 5. Final Review Matrix

| Original Sentence | Issue/Observation | Refined Sentence |
| --- | --- | --- |
| A Client Access user doesn't want to manually pick the collection for every base-case Transcript or Video file they add. | none | A Client Access user doesn't want to manually pick the collection for every base-case Transcript or Video file they add. |
| While adding files to a client deliverable, they want the common-case collection chosen for them automatically. | none | While adding files to a client deliverable, they want the common-case collection chosen for them automatically. |
| Except that today nothing is pre-chosen, so they want the system to guess correctly for the vast majority of files and let them fix the rare exception. | none | Except that today nothing is pre-chosen, so they want the system to guess correctly for the vast majority of files and let them fix the rare exception. |
| Now they'll be able to add most files without touching the collection choice at all, only correcting it when the file is unusual. | none | Now they'll be able to add most files without touching the collection choice at all, only correcting it when the file is unusual. |
| A user adding a Transcript-track file to a client deliverable sees the collection already set to the fixed base-case value for that track, without picking it themselves. | none | (unchanged) |
| A user adding a Video-track file to a client deliverable sees the collection already set to the fixed base-case value for that track, without picking it themselves. | none | (unchanged) |
| The auto-chosen collection is always the same fixed base-case value for a track — never a value that changes based on the file or situation. | none | (unchanged) |
| A user can still change the auto-chosen collection to a different one before finishing the add, and their choice is respected. | none | (unchanged) |
| When the fixed base-case collection isn't available to choose from in a given proceeding, nothing is auto-chosen and the user picks manually, with no error shown. | none | (unchanged) |
| The auto-choice happens whether the user is dragging files in, using the per-track upload action, or approving a submitted file into the deliverable set. | none | (unchanged) |
| For drag-and-drop, the auto-choice appears as soon as the user has indicated which track the file belongs to. | none | (unchanged) |
| Every separate add action gets a fresh auto-choice of the fixed base-case value — a user's earlier manual change on a prior file is never carried forward as the new default. | none | (unchanged) |
| Recategorizing a file that's already in the deliverable set never changes its existing collection on its own — only a user's manual change does. | none | (unchanged) |
| Once the collection is auto-chosen, the deliverable type is filled in the same way it already is when a user picks that collection manually. | Wordiness (trailing clause) | Once the collection is auto-chosen, the deliverable type fills in the same way it does when a user picks that collection manually. |
| This behavior only occurs for deliverables handled through the GCA-enabled flow; other flows behave exactly as they do today. | none | (unchanged) |

## 6. User Story

A Client Access user doesn't want to manually pick the collection for every base-case Transcript or Video file they add. While adding files to a client deliverable, they want the common-case collection chosen for them automatically. Except that today nothing is pre-chosen, so they want the system to guess correctly for the vast majority of files and let them fix the rare exception. Now they'll be able to add most files without touching the collection choice at all, only correcting it when the file is unusual.

## Acceptance Criteria

- A user adding a Transcript-track file to a client deliverable sees the collection already set to the fixed base-case value for that track, without picking it themselves.
- A user adding a Video-track file to a client deliverable sees the collection already set to the fixed base-case value for that track, without picking it themselves.
- The auto-chosen collection is always the same fixed base-case value for a track — never a value that changes based on the file or situation.
- A user can still change the auto-chosen collection to a different one before finishing the add, and their choice is respected.
- When the fixed base-case collection isn't available to choose from in a given proceeding, nothing is auto-chosen and the user picks manually, with no error shown.
- The auto-choice happens whether the user is dragging files in, using the per-track upload action, or approving a submitted file into the deliverable set.
- When adding files by dragging them in, the user is asked which track the files belong to, and the auto-choice appears as soon as they answer — before they have looked at the collection.
- Changing that answer replaces the auto-choice with the one for the newly-chosen track, and discards anything the user had picked under the previous answer.
- Every separate add action gets a fresh auto-choice of the fixed base-case value — a user's earlier manual change on a prior file is never carried forward as the new default.
- Recategorizing a file that's already in the deliverable set never changes its existing collection on its own — only a user's manual change does.
- Once the collection is auto-chosen, the deliverable type fills in the same way it does when a user picks that collection manually.
- A user can finish the add without ever opening or touching the collection — the auto-chosen value counts as their choice. Anything else the add already required of them still applies.
- A user who isn't allowed to add files to a track can see that track listed and can tell why it isn't available to them, rather than finding it missing.
- This behavior only occurs for deliverables handled through the GCA-enabled flow; other flows behave exactly as they do today.

## Open Questions

_Both original questions are **closed** by Phase 1 evidence. One new question opened and closed within the same phase._

1. ~~**Exact production collection values.**~~ **CLOSED (Phase 1).** Both are real seeded production rows, not fixtures: `callisto-back-end/src/typeorm/migrations/1775761245238-seed__deliverable_collections__table.ts:22,32` inserts `'Full Transcript'` on the Transcript track and `'MP4 Video'` on the Video track, each with `collection_kind = 'static'` and `proceeding_id = NULL`. The ticket's worry was accurate about Atlas (which correctly hardcodes nothing and renders `collection.value` from the API) and wrong about the system.
2. ~~**Eligible deliverable types configured.**~~ **CLOSED (Phase 1).** Both have them: `1782200000003-seed__deliverable_type_deliverable_collections__table.ts:23-268` — ~19 eligible types for Full Transcript, ~11 for MP4 Video. Five types are eligible for Full Transcript *only*, indicating the config was authored per-collection deliberately. Type pre-fill will resolve.
3. ~~**Does generic drag-and-drop have a track-selection moment for the default to react to?**~~ **OPENED AND CLOSED (Phase 1, review).** It does not today — the form opens with no track and track group headers are non-selectable. Product direction is to implement the criterion rather than revise it, so the work includes an explicit track-selection state for generic DnD. Criterion 7 below is reworded to match. See the recon-and-plan's F6a/F6c.

## Story log

- **2026-09-03 — Phase 3 (ACCEPTED):** All open questions closed; no question carried forward. Two criteria added from locked decisions, both written to stay observable rather than importing the design word the decision introduced:
  - From **LD-005** — "a user can finish the add without ever opening or touching the collection." The decision's own language was about validity state and an absent `hasAcknowledgedDefault` flag; the criterion states what a person can observe instead. The trailing clause ("anything else the add already required still applies") preserves the decision's boundary: the defaulted collection is valid, but existing validation — an unresolved deliverable type, for instance — still gates submission.
  - From **LD-004** — "a user who isn't allowed to add files to a track can see that track listed and can tell why." Phase 3 reconcile found the established precedent (`useTrackSelectorForm.ts:53-63`, `TrackSelectorForm.vue:118-129`) disables unpermitted tracks with an explanatory tooltip rather than hiding them, and both sibling controls already share that i18n key. This **superseded** the Phase 1 plan's "permitted tracks only" wording.
  - No criterion was reinterpreted to match a decision. Criteria count 12 → 14.
- **2026-09-03 — Phase 1/2 (revised, still `draft`):** Both original open questions **closed by evidence**, not by decision — the collection values and their eligible types are seeded production data (Callisto migrations `1775761245238`, `1782200000003`). Neither needed to go to a person.
  - **One criterion reworded, one added.** The drag-and-drop criterion previously read "the auto-choice appears as soon as the user has indicated which track the file belongs to," which quietly assumed an indicating-a-track moment exists in that flow. Investigation found it does not: the form opens with no track and track headings are not selectable. Product direction is to build that moment rather than drop the criterion, so the criterion now states the user is *asked* which track, and a second criterion covers what happens when they change the answer (the previous auto-choice and any manual pick under it are discarded).
  - **Why reworded rather than reinterpreted:** the original wording would have "passed" against an implementation where the user picks a combined track+collection row, since that technically indicates a track. That reading would have satisfied the sentence while defeating its purpose. Rewriting keeps the criterion observable; reinterpreting it would have hidden the gap.
  - No change to the other nine criteria. Story stays `draft` pending Phase 3 acceptance.
- **2026-09-03 — Phase 0 (draft):** Drafted from the verbatim Original Request and Acceptance Criteria in `PRDV-16461-original-ticket.md`, including the three QA clarification rounds already resolved in the ClickUp thread (recategorize excluded; type pre-fill composes with collection default; default always re-applies, never sticky). Split out of the single ticket request into its own story because the Aug 27–present UX-indicator thread (see job story 02) is a materially separate, still-open concern raised after these AC were already settled — bundling them would let an unresolved design question block acceptance of an otherwise-complete story.
