# Job story 01 — Default collection pre-selection

- **Ticket:** PRDV-16461
- **Project:** atlas
- **Date:** 2026-09-03
- **Source:** [PRDV-16461-original-ticket.md](../PRDV-16461-original-ticket.md)
- **Status:** draft

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
- For drag-and-drop, the auto-choice appears as soon as the user has indicated which track the file belongs to.
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
- For drag-and-drop, the auto-choice appears as soon as the user has indicated which track the file belongs to.
- Every separate add action gets a fresh auto-choice of the fixed base-case value — a user's earlier manual change on a prior file is never carried forward as the new default.
- Recategorizing a file that's already in the deliverable set never changes its existing collection on its own — only a user's manual change does.
- Once the collection is auto-chosen, the deliverable type fills in the same way it does when a user picks that collection manually.
- This behavior only occurs for deliverables handled through the GCA-enabled flow; other flows behave exactly as they do today.

## Open Questions

1. **Exact production collection values.** The ticket's own "Open items to confirm" flags that "Full Transcript" and "MP4 Video" currently appear only in FE test fixtures — not yet verified as the real production static-collection values on the Transcript and Video tracks. Owner: investigation (Phase 1/2, code + data trace).
2. **Eligible deliverable types configured.** Whether the base-case collections have eligible deliverable types configured so type pre-fill actually resolves once the collection defaults. Owner: investigation (Phase 1/2, code + data trace).

## Story log

- **2026-09-03 — Phase 0 (draft):** Drafted from the verbatim Original Request and Acceptance Criteria in `PRDV-16461-original-ticket.md`, including the three QA clarification rounds already resolved in the ClickUp thread (recategorize excluded; type pre-fill composes with collection default; default always re-applies, never sticky). Split out of the single ticket request into its own story because the Aug 27–present UX-indicator thread (see job story 02) is a materially separate, still-open concern raised after these AC were already settled — bundling them would let an unresolved design question block acceptance of an otherwise-complete story.
