# Job story 02 — Pull in a document that already exists

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
| Motivation | *A [user type] doesn't want [undesired outcome].* | Someone whose reference material is already written doesn't want to retype or paste it into a second place to have it beside the work it belongs to. |
| Context + Intent | *While [context], they want to [action].* | While working on a piece of work that leans on a document they already wrote, they want that document sitting with the work. |
| Obstacle + Desired Action | *Except that [obstacle], so they want to [action to rectify].* | Except that the only way to add content is to type a new note into the composer, so they want an item on the card's ellipsis menu that opens a file picker and loads the chosen file into the notes list. |
| Resolution | *Now they'll be able to [positive outcome].* | Now they'll be able to read the document in place, exactly as if they had written it there. |

## Revision Matrix

| Component | Before | Issue named | After |
| --- | --- | --- | --- |
| Obstacle + Desired Action | Except that the only way to add content is to type a new note into the composer, so they want an item on the card's ellipsis menu that opens a file picker and loads the chosen file into the notes list. | Solution-speak — "composer", "ellipsis menu", "file picker" and "notes list" are all design elements. | Except that the only way to get content next to a piece of work is to write it there from scratch, so they want to pick a document that already exists and have it appear with that work. |
| Motivation | Someone whose reference material is already written doesn't want to retype or paste it into a second place to have it beside the work it belongs to. | Wordiness — "reference material" and "a second place" are formal register. | Someone who has already written a document doesn't want a second copy of it just to keep it near the work it explains. |

## Delivery Acceptance Statement (DAS)

*We know this story is considered complete when:*
- A person can pick an existing document from the named folder and have it appear alongside a specific piece of work.
- The picked document reads the same as anything else in that spot — same look, same controls, no second style of thing to learn.
- The document's content shown is the content currently in the file, not a copy taken at the moment it was picked.
- The document is still there the next time the person opens that piece of work, without picking it again.
- When the person picks a document that is already there, they are told rather than ending up with it twice.
- When the file has been moved, renamed, or deleted since it was picked, the person sees plainly that it cannot be found instead of an empty or silently blank spot.

## Concatenated Story

Someone who has already written a document doesn't want a second copy of it just to keep it near the work it explains. While working on a piece of work that leans on a document they already wrote, they want that document sitting with the work. Except that the only way to get content next to a piece of work is to write it there from scratch, so they want to pick a document that already exists and have it appear with that work. Now they'll be able to read the document in place, exactly as if they had written it there.

## Final Review Matrix

| Original Sentence | Issue/Observation | Refined Sentence |
| --- | --- | --- |
| Someone who has already written a document doesn't want a second copy of it just to keep it near the work it explains. | None. | Someone who has already written a document doesn't want a second copy of it just to keep it near the work it explains. |
| While working on a piece of work that leans on a document they already wrote, they want that document sitting with the work. | Wordiness — "a piece of work that leans on a document" repeats itself. | While working on something that depends on a document they already wrote, they want that document sitting right there with it. |
| Except that the only way to get content next to a piece of work is to write it there from scratch, so they want to pick a document that already exists and have it appear with that work. | Wordiness. | Except that the only way to get content in there is to write it from scratch, so they want to grab a document that already exists and have it show up in place. |
| Now they'll be able to read the document in place, exactly as if they had written it there. | None. | Now they'll be able to read the document in place, exactly as if they had written it there. |
| A person can pick an existing document from the named folder and have it appear alongside a specific piece of work. | None. | A person can pick an existing document from the named folder and have it appear alongside a specific piece of work. |
| The picked document reads the same as anything else in that spot — same look, same controls, no second style of thing to learn. | Vague phrasing — "no second style of thing to learn" is not confirmable. | The picked document looks and behaves the same as anything else already in that spot, with the same controls in the same places. |
| The document's content shown is the content currently in the file, not a copy taken at the moment it was picked. | None. | The document's content shown is the content currently in the file, not a copy taken at the moment it was picked. |
| The document is still there the next time the person opens that piece of work, without picking it again. | None. | The document is still there the next time the person opens that piece of work, without picking it again. |
| When the person picks a document that is already there, they are told rather than ending up with it twice. | None. | When the person picks a document that is already there, they are told rather than ending up with it twice. |
| When the file has been moved, renamed, or deleted since it was picked, the person sees plainly that it cannot be found instead of an empty or silently blank spot. | Wordiness. | When the file has been moved, renamed, or deleted since it was picked, the person is told it cannot be found rather than shown a blank. |

## User Story

Someone who has already written a document doesn't want a second copy of it just to keep it near the work it explains. While working on something that depends on a document they already wrote, they want that document sitting right there with it. Except that the only way to get content in there is to write it from scratch, so they want to grab a document that already exists and have it show up in place. Now they'll be able to read the document in place, exactly as if they had written it there.

## Acceptance Criteria

- A person can pick an existing document from the named folder and have it appear alongside a specific piece of work.
- A person can pick several documents at once, and can pick a whole folder's worth without selecting each one by hand.
- Before anything is added, the person can see how many documents they are about to add and change their mind about any of them.
- The picked document looks and behaves the same as anything else already in that spot, with the same controls in the same places.
- The document's content shown is the content currently in the file, not a copy taken at the moment it was picked.
- The document is still there the next time the person opens that piece of work, without picking it again.
- When the person picks a document that is already there, they are told rather than ending up with it twice.
- When the file has been moved, renamed, or deleted since it was picked, the person is told it cannot be found rather than shown a blank.
- When some of a selection could not be added, the person is told how many and why, rather than given a count that hides it.

## Open Questions

1. ~~Browsing or typing a path?~~ **Closed at Phase 3** (LD-020): browsing. A typed path would be a second route to the filesystem for the containment check to defend, for no gain.
2. ~~Where does it sit relative to written notes?~~ **Closed at Phase 3 by evidence.** `renderTaskNotes` sorts by `createdAt` descending (`public/todolist2.js:5175`); a pulled-in document gets a `createdAt` when it is attached and sorts in like anything else. No grouping, which is what the criterion asks for.
3. ~~Is the origin visible at a glance?~~ **Closed at Phase 3** (LD-021): yes — the note shows its root-relative path where an ordinary note shows its timestamp. **This became a safety requirement rather than a preference once LD-006 locked autosave**: a person who cannot tell which notes write to a real file cannot avoid the accident autosave accepts. The criterion "same controls in the same places" still holds — one existing field shows different content; nothing is added.
4. ~~Does the content refresh while the person is looking at it?~~ **Closed at Phase 3** (LD-011): no watcher in this slice. Content is read through on card open, which satisfies criterion three; a file that changes under an open note is caught at save by the mtime precondition rather than by watching.

**All open questions closed.**

## Story log

- **2026-08-29 — Phase 5 — REOPENED and re-accepted, criteria added.** The owner, reviewing the built feature, raised that picking should cover a batch of files and a folder, not one document at a time. Checked against the verbatim request: its three uses of "folder" are all about the permissioned root, so folder-selection is **new scope**; but *"attach files"* and *"pull items … to attach files"* are plural, so multi-select was a fair reading of the original text that the first implementation missed. **Three criteria added** — batch and folder selection, seeing and trimming the count before committing, and being told when part of a selection was skipped. Nothing was removed or reworded. The existing criteria all still hold: each attached document is still its own note, still looks like any other note, and a folder still never becomes a note (LD-023). Decisions: LD-023 through LD-027.

- **2026-08-28 — Phase 3 — ACCEPTED.** All four questions closed (LD-020, evidence, LD-021, LD-011). **No criterion changed**, but one is now under tension worth naming rather than hiding: "looks and behaves the same as anything else already in that spot, with the same controls in the same places" versus LD-021's path display. Judged satisfied — the control set is identical and the difference is the content of one field that already exists. Recorded here so a reviewer who spots it sees it was decided, not missed. Status → `accepted`.
- **2026-08-28 — Phase 1.** No criterion changed and no question closed. Two confirmations worth recording: the criterion "looks and behaves the same as anything else already in that spot" is achievable without special work, because every note already mounts the same Dantalion surface (`public/todolist2.js:5197`); and the request's "use the ellipsis on a specific card" lands on an existing extension seam (`getNotesPaneCollapseMenuActions`, `public/todolist2.js:4700`) rather than needing a new menu. Q4 (refresh while open) was **confirmed a genuine decision** by the Step 7 reconcile — the code cannot answer it because nothing today watches a file.
- **2026-08-28 — Phase 0.** Drafted from the verbatim request. Open questions 1–4 are things the request left undecided; none were decided here.
