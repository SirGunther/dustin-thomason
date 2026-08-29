# Job story 03 — Edit the document where it lives

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
| Motivation | *A [user type] doesn't want [undesired outcome].* | Someone reading their own document beside their work doesn't want to switch to another program to correct a line in it. |
| Context + Intent | *While [context], they want to [action].* | While reading the document they pulled in and spotting something out of date, they want to fix it on the spot. |
| Obstacle + Desired Action | *Except that [obstacle], so they want to [action to rectify].* | Except that the surface is mounted read-only and the save path writes to the notes record rather than the file handle, so they want the editor enabled and the save routed back to the originating file. |
| Resolution | *Now they'll be able to [positive outcome].* | Now they'll be able to correct the document once and have the correction be true everywhere the document is used, including outside this work entirely. |

## Revision Matrix

| Component | Before | Issue named | After |
| --- | --- | --- | --- |
| Obstacle + Desired Action | Except that the surface is mounted read-only and the save path writes to the notes record rather than the file handle, so they want the editor enabled and the save routed back to the originating file. | Solution-speak — "surface", "read-only", "save path", "notes record", "file handle", "editor" are all design elements. | Except that a document pulled in from elsewhere can only be read, so they want to change it in place and have the change land in the actual document. |
| Resolution | Now they'll be able to correct the document once and have the correction be true everywhere the document is used, including outside this work entirely. | Wordiness. | Now they'll be able to fix it once and find it fixed everywhere the document is used, including outside this work. |

## Delivery Acceptance Statement (DAS)

*We know this story is considered complete when:*
- A person can change the text of a pulled-in document in the same way they change anything else in that spot.
- A saved change is written to the actual file, so opening that file anywhere else shows the change.
- ~~Nothing is written to the file until the person saves; abandoning an edit leaves the file untouched.~~ **→ replaced at Phase 3 (LD-006):** Opening or reading a pulled-in document never writes to it; the file changes only after the person has typed in it and moved on.
- When the file changed underneath the person while they were editing, they are told before their version replaces it.
- When the file cannot be written — it is gone, it is read-only, or access has lapsed — the person is told which of those happened and their typing is not lost.
- A change made to a document that has been pulled into more than one place shows up in all of them.

## Concatenated Story

Someone reading their own document beside their work doesn't want to switch to another program to correct a line in it. While reading the document they pulled in and spotting something out of date, they want to fix it on the spot. Except that a document pulled in from elsewhere can only be read, so they want to change it in place and have the change land in the actual document. Now they'll be able to fix it once and find it fixed everywhere the document is used, including outside this work.

## Final Review Matrix

| Original Sentence | Issue/Observation | Refined Sentence |
| --- | --- | --- |
| Someone reading their own document beside their work doesn't want to switch to another program to correct a line in it. | None. | Someone reading their own document beside their work doesn't want to switch to another program to fix a line in it. |
| While reading the document they pulled in and spotting something out of date, they want to fix it on the spot. | None. | While reading the document they pulled in and spotting something out of date, they want to fix it on the spot. |
| Except that a document pulled in from elsewhere can only be read, so they want to change it in place and have the change land in the actual document. | None. | Except that a document pulled in from elsewhere can only be read, so they want to change it in place and have the change land in the actual document. |
| Now they'll be able to fix it once and find it fixed everywhere the document is used, including outside this work. | None. | Now they'll be able to fix it once and find it fixed everywhere the document is used, including outside this work. |
| A person can change the text of a pulled-in document in the same way they change anything else in that spot. | None. | A person can change the text of a pulled-in document in the same way they change anything else in that spot. |
| A saved change is written to the actual file, so opening that file anywhere else shows the change. | None. | A saved change is written to the actual file, so opening that file anywhere else shows the change. |
| Nothing is written to the file until the person saves; abandoning an edit leaves the file untouched. | **Invalidated at Phase 3, not refined.** LD-006 locked autosave-on-focus-exit, so there is no "until the person saves" moment and abandoning an edit does *not* leave the file untouched. Reinterpreting the words to fit would be exactly the failure the story exists to prevent, so the criterion was replaced. | Opening or reading a pulled-in document never writes to it; the file changes only after the person has typed in it and moved on. |
| When the file changed underneath the person while they were editing, they are told before their version replaces it. | None. | When the file changed underneath the person while they were editing, they are told before their version replaces it. |
| When the file cannot be written — it is gone, it is read-only, or access has lapsed — the person is told which of those happened and their typing is not lost. | Wordiness. | When the file cannot be written, the person is told which reason applies and their typing is not lost. |
| A change made to a document that has been pulled into more than one place shows up in all of them. | None. | A change made to a document that has been pulled into more than one place shows up in all of them. |

## User Story

Someone reading their own document beside their work doesn't want to switch to another program to fix a line in it. While reading the document they pulled in and spotting something out of date, they want to fix it on the spot. Except that a document pulled in from elsewhere can only be read, so they want to change it in place and have the change land in the actual document. Now they'll be able to fix it once and find it fixed everywhere the document is used, including outside this work.

## Acceptance Criteria

- A person can change the text of a pulled-in document in the same way they change anything else in that spot.
- A saved change is written to the actual file, so opening that file anywhere else shows the change.
- Opening or reading a pulled-in document never writes to it; the file changes only after the person has typed in it and moved on.
- When the file changed underneath the person while they were editing, they are told before their version replaces it.
- When the file cannot be written, the person is told which reason applies and their typing is not lost.
- A change made to a document that has been pulled into more than one place shows up in all of them.

## Open Questions

1. ~~Editing on by default, or read-only until unlocked?~~ **Closed at Phase 3** (LD-006): on by default, exactly like an ordinary note. The read-only-until-unlocked option was rejected by the owner.
2. ~~What counts as a save?~~ **Closed at Phase 3** (LD-006): focus exit, inherited unchanged from ordinary notes. **This invalidated a criterion** — see the Final Review Matrix. Accepted risk recorded as FDC-04.
3. ~~Live, or on next open?~~ **Closed at Phase 3** (LD-011): on next open. The mtime precondition (LD-017) is what makes that safe rather than merely stale — a second place that autosaves over a change it never saw is refused with a `409`.
4. ~~Any history or undo?~~ **Closed at Phase 3 by evidence** (LD-012): none in the app, because the chosen root `C:\dustin-thomason` is a git repo. Every write is already versioned and revertible by the tooling in daily use. This is also what makes LD-006's accepted risk tolerable.

**All open questions closed.**

## Story log

- **2026-08-28 — Phase 3 — ACCEPTED, with one criterion replaced.** LD-006 (inherit autosave) **invalidated** the criterion "Nothing is written to the file until the person saves; abandoning an edit leaves the file untouched." Under autosave there is no save moment and abandoning an edit *does* write. The criterion was **replaced, not reworded to fit**: "Opening or reading a pulled-in document never writes to it; the file changes only after the person has typed in it and moved on." That still forbids the thing the original was protecting — a read causing a write — while being true of what was decided. Two knock-on effects recorded elsewhere: the accepted risk (FDC-04) and the safety requirement it forced on story 02 (LD-021, the path display). All four questions closed. Status → `accepted`.
- **2026-08-28 — Phase 1.** No criterion changed; two gained a precedent. "Told before their version replaces it" now mirrors an existing pattern rather than inventing one — `PATCH /api/notes/:noteId` already takes `expectedLastModified` and answers `409` with the server's current value (`server.js:2896-2920`). Q2 (autosave vs explicit save) **gained weight**: the surface today autosaves on focus exit (changelog, 2026-08-28 entry), which under this story would mean autosaving into a real file on disk — a materially different risk from autosaving into a database row, and the reason this stays a decision for the owner rather than a default carried over.
- **2026-08-28 — Phase 0.** Drafted from the verbatim request. Open questions 1–4 are things the request left undecided; none were decided here.
