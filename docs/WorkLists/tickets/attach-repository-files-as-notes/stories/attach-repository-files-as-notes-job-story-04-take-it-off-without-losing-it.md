# Job story 04 — Take it off without losing the file

| Field | Value |
| --- | --- |
| Project | WorkLists |
| Ticket slug | `attach-repository-files-as-notes` |
| Date | 2026-08-28 |
| Status | accepted (Phase 3) |
| Source | [original-ticket.md](../original-ticket.md) |

## Story Matrix

| Component | Framework Language | Story Sentence |
| --- | --- | --- |
| Motivation | *A [user type] doesn't want [undesired outcome].* | Someone tidying up a finished piece of work doesn't want tidying to destroy the document itself. |
| Context + Intent | *While [context], they want to [action].* | While a document is no longer relevant to the work it was pulled into, they want it gone from that work. |
| Obstacle + Desired Action | *Except that [obstacle], so they want to [action to rectify].* | Except that the delete button on a note removes the underlying record, so they want a detach action distinct from delete, with a confirmation dialog naming which one is which. |
| Resolution | *Now they'll be able to [positive outcome].* | Now they'll be able to clear a document out of one place with certainty that the document itself, and every other place using it, is untouched. |

## Revision Matrix

| Component | Before | Issue named | After |
| --- | --- | --- | --- |
| Obstacle + Desired Action | Except that the delete button on a note removes the underlying record, so they want a detach action distinct from delete, with a confirmation dialog naming which one is which. | Solution-speak — "delete button", "record", "detach action", "confirmation dialog" are all design elements. | Except that removing something from a piece of work has always meant destroying it, so they want taking a document off one piece of work to be plainly different from getting rid of the document. |
| Motivation | Someone tidying up a finished piece of work doesn't want tidying to destroy the document itself. | Wordiness — "tidying" twice. | Someone clearing out a finished piece of work doesn't want the clearing out to destroy the document itself. |

## Delivery Acceptance Statement (DAS)

*We know this story is considered complete when:*
- A person can take a pulled-in document off one piece of work, and it disappears from that work only.
- Taking it off leaves the file on disk exactly as it was, with the same content and the same location.
- The same document, pulled into other places, stays where it is and keeps working.
- Before anything is removed, the person can tell whether they are removing it from this work or getting rid of the file, and the two are not the same action.
- After removing it, the person can pull the same document back in and get the same content.
- Deleting the file outside the app leaves the places that used it showing plainly that it is gone, rather than losing the record of what was there.

## Concatenated Story

Someone clearing out a finished piece of work doesn't want the clearing out to destroy the document itself. While a document is no longer relevant to the work it was pulled into, they want it gone from that work. Except that removing something from a piece of work has always meant destroying it, so they want taking a document off one piece of work to be plainly different from getting rid of the document. Now they'll be able to clear a document out of one place with certainty that the document itself, and every other place using it, is untouched.

## Final Review Matrix

| Original Sentence | Issue/Observation | Refined Sentence |
| --- | --- | --- |
| Someone clearing out a finished piece of work doesn't want the clearing out to destroy the document itself. | None. | Someone clearing out a finished piece of work doesn't want the clearing out to destroy the document itself. |
| While a document is no longer relevant to the work it was pulled into, they want it gone from that work. | None. | Once a document no longer belongs with the work it was pulled into, they want it gone from that work. |
| Except that removing something from a piece of work has always meant destroying it, so they want taking a document off one piece of work to be plainly different from getting rid of the document. | Wordiness. | Except that removing something has always meant destroying it, so they want taking a document off one place to be plainly different from getting rid of it. |
| Now they'll be able to clear a document out of one place with certainty that the document itself, and every other place using it, is untouched. | Emotional abstraction — "with certainty". | Now they'll be able to clear a document out of one place and find the document, and every other place using it, untouched. |
| A person can take a pulled-in document off one piece of work, and it disappears from that work only. | None. | A person can take a pulled-in document off one piece of work, and it disappears from that work only. |
| Taking it off leaves the file on disk exactly as it was, with the same content and the same location. | None. | Taking it off leaves the file exactly as it was, same content and same place. |
| The same document, pulled into other places, stays where it is and keeps working. | Vague phrasing — "keeps working". | The same document, pulled into other places, is still there and still readable in each of them. |
| Before anything is removed, the person can tell whether they are removing it from this work or getting rid of the file, and the two are not the same action. | Wordiness. | Before anything is removed, the person can tell whether they are taking it off this work or getting rid of the file, and the two are separate actions. |
| After removing it, the person can pull the same document back in and get the same content. | None. | After removing it, the person can pull the same document back in and get the same content. |
| Deleting the file outside the app leaves the places that used it showing plainly that it is gone, rather than losing the record of what was there. | Wordiness. | Deleting the file elsewhere leaves each place that used it saying so, rather than quietly forgetting it. |

## User Story

Someone clearing out a finished piece of work doesn't want the clearing out to destroy the document itself. Once a document no longer belongs with the work it was pulled into, they want it gone from that work. Except that removing something has always meant destroying it, so they want taking a document off one place to be plainly different from getting rid of it. Now they'll be able to clear a document out of one place and find the document, and every other place using it, untouched.

## Acceptance Criteria

- A person can take a pulled-in document off one piece of work, and it disappears from that work only.
- Taking it off leaves the file exactly as it was, same content and same place.
- The same document, pulled into other places, is still there and still readable in each of them.
- Before anything is removed, the person can tell whether they are taking it off this work or getting rid of the file, and the two are separate actions.
- After removing it, the person can pull the same document back in and get the same content.
- Deleting the file elsewhere leaves each place that used it saying so, rather than quietly forgetting it.

## Open Questions

1. ~~Should deleting the file itself be possible from inside the app?~~ **Closed at Phase 3** (LD-007): **no, and not deferred — closed.** The owner identified the ambiguous wording in the request as a summarization artifact: *"we are to detach files from the 'card'. That is all that we're talking about here."*
2. ~~Same removal control as written notes, or a different one?~~ **Closed at Phase 3** (LD-022): the same one. LD-007 removed the thing it needed separating from — with no delete-the-file action in existence, removing the note record *is* detaching. Only the label and confirmation wording change for a file-backed note.
3. ~~When the last place takes it off, does anything about the file change?~~ **Closed at Phase 3** (LD-007): nothing. It is simply no longer referenced. There is no reference count and nothing watches for the last one.

**All open questions closed.**

## Story log

- **2026-08-28 — Phase 3 — ACCEPTED.** All three questions closed (LD-007, LD-022, LD-007). **No criterion changed**, and one is satisfied more strongly than drafted: "the two are separate actions" now holds because the destructive one does not exist at all, which is the strongest available form of it. Recorded plainly rather than quietly: the Phase 1 recon sketched a separate `Detach` menu item, and LD-022 **supersedes that sketch** — a second control for the only remaining action would have been worse, and would have broken story 02's "same controls in the same places". Status → `accepted`.
- **2026-08-28 — Phase 1.** No criterion changed. Q2 (shared removal control) **sharpened**: the two surfaces are already separate in the DOM — the per-note action row carries the destructive `data-delete-note` control (`public/todolist2.js:5170`) while `.notes-pane-note-menu` carries the non-destructive items (`:5181`). So "plainly different from getting rid of the file" can be satisfied without breaking story 02's "looks like any other note", because the note already has two distinct action surfaces. Q1 stays open and stays the user's: it is a scope question, not a lookup.
- **2026-08-28 — Phase 0.** Drafted from the verbatim request. Open questions 1–3 are things the request left undecided; none were decided here. Question 1 records a genuine ambiguity in the request's wording rather than a design choice.
