# Job story 05 — One document, many places

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
| Motivation | *A [user type] doesn't want [undesired outcome].* | Someone whose one reference document is relevant to several pieces of work doesn't want a divergent copy of it sitting with each one. |
| Context + Intent | *While [context], they want to [action].* | While the same standing document explains several different pieces of work, they want it present with each of them. |
| Obstacle + Desired Action | *Except that [obstacle], so they want to [action to rectify].* | Except that each note row stores its own text, so they want many rows to reference a single file record rather than duplicate its content. |
| Resolution | *Now they'll be able to [positive outcome].* | Now they'll be able to keep one document current and have every piece of work that leans on it stay current too. |

## Revision Matrix

| Component | Before | Issue named | After |
| --- | --- | --- | --- |
| Obstacle + Desired Action | Except that each note row stores its own text, so they want many rows to reference a single file record rather than duplicate its content. | Solution-speak — "note row", "file record", "reference" are all design elements. | Except that anything added to a piece of work has always been its own separate copy, so they want the same document to be present in several places while remaining one document. |
| Motivation | Someone whose one reference document is relevant to several pieces of work doesn't want a divergent copy of it sitting with each one. | Wordiness and formal register — "divergent". | Someone whose one document matters to several pieces of work doesn't want copies of it drifting apart. |

## Delivery Acceptance Statement (DAS)

*We know this story is considered complete when:*
- A person can pull the same document into more than one piece of work.
- Each place shows the same content, because each is showing the same document rather than a copy of it.
- A change saved in one place is what the other places show the next time they are opened.
- ~~The person can find out where else a document has been pulled in before they change or remove it.~~ *(struck at Phase 3 — LD-008)*
- Taking the document off one place leaves it in the others.

## Concatenated Story

Someone whose one document matters to several pieces of work doesn't want copies of it drifting apart. While the same standing document explains several different pieces of work, they want it present with each of them. Except that anything added to a piece of work has always been its own separate copy, so they want the same document to be present in several places while remaining one document. Now they'll be able to keep one document current and have every piece of work that leans on it stay current too.

## Final Review Matrix

| Original Sentence | Issue/Observation | Refined Sentence |
| --- | --- | --- |
| Someone whose one document matters to several pieces of work doesn't want copies of it drifting apart. | None. | Someone whose one document matters to several pieces of work doesn't want copies of it drifting apart. |
| While the same standing document explains several different pieces of work, they want it present with each of them. | Wordiness — "standing" adds nothing. | While the same document explains several pieces of work, they want it sitting with each of them. |
| Except that anything added to a piece of work has always been its own separate copy, so they want the same document to be present in several places while remaining one document. | Wordiness. | Except that anything added has always been its own separate copy, so they want one document to show up in several places and still be one document. |
| Now they'll be able to keep one document current and have every piece of work that leans on it stay current too. | Wordiness. | Now they'll be able to keep one document up to date and find every piece of work that uses it up to date too. |
| A person can pull the same document into more than one piece of work. | None. | A person can pull the same document into more than one piece of work. |
| Each place shows the same content, because each is showing the same document rather than a copy of it. | None. | Each place shows the same content, because each is showing the same document rather than a copy of it. |
| A change saved in one place is what the other places show the next time they are opened. | None. | A change saved in one place is what the other places show the next time they are opened. |
| The person can find out where else a document has been pulled in before they change or remove it. | **Struck at Phase 3, not refined.** The owner rejected the premise: a pointer's consumer list is not a precondition of updating what it points at (LD-008). No wording fixes a criterion whose requirement is not wanted. | *(removed — carried to story 06 in a different, non-gating form)* |
| Taking the document off one place leaves it in the others. | None. | Taking the document off one place leaves it in the others. |

## User Story

Someone whose one document matters to several pieces of work doesn't want copies of it drifting apart. While the same document explains several pieces of work, they want it sitting with each of them. Except that anything added has always been its own separate copy, so they want one document to show up in several places and still be one document. Now they'll be able to keep one document up to date and find every piece of work that uses it up to date too.

## Acceptance Criteria

- A person can pull the same document into more than one piece of work.
- Each place shows the same content, because each is showing the same document rather than a copy of it.
- A change saved in one place is what the other places show the next time they are opened.
- Taking the document off one place leaves it in the others.

## Open Questions

1. ~~Is "find out where else it is used" required in the first delivery?~~ **Closed at Phase 3 — the criterion was rejected by the owner** (LD-008). Their reasoning is the design principle, not a preference: *"All that attachment really says is that it is a pointer… It can be updated from any one of the locations, and we do not need to know where else it actually touches."* The model is a package — updating it reaches downstream consumers, and knowing the consumer list is not a precondition of publishing. The useful part underneath (inventory and duplicate visibility, for management rather than as a gate) became [story 06](./attach-repository-files-as-notes-job-story-06-see-what-is-attached-where.md), out of scope for this slice.
2. ~~Does the identity follow the path, or something more durable?~~ **Closed at Phase 3 by evidence** (LD-009): path relative to the root. The two durable alternatives were both worse — injecting a front-matter id mutates documents the app does not own and shows in every git diff; a sidecar index is a second source of truth for something the filesystem already answers. The root is a git repo, so a rename is visible and recoverable. Residual risk recorded as FDC-05.
3. ~~Can the same document be pulled into the same piece of work twice?~~ **Closed at Phase 3** — no; a duplicate attach is refused with a message (story 02's fifth criterion, test NP-6). Attaching to *different* cards is the whole point of this story and stays unrestricted.

## Story log

- **2026-08-28 — Phase 3 — ACCEPTED.** One criterion **removed**, not reworded: *"The person can find out where else a document has been pulled in before they change or remove it."* The owner rejected its premise — knowing the consumer list is not a precondition of changing a shared document (LD-008). Removed from the DAS, the Final Review Matrix, and the Acceptance Criteria; the surviving four are unchanged. All three open questions closed — one by the owner, two by evidence. Story 06 was created to carry the useful requirement the rejected criterion was reaching for, and is explicitly **not** part of this slice. Status → `accepted`.
- **2026-08-28 — Phase 1.** No criterion changed. Q2 (path vs durable identity) **confirmed undecidable from the code**, with the evidence that proves it: nothing in WorkLists references a file at all — there is no field, no resolver, and therefore no precedent to mirror. It is a decision, not an un-run lookup. One criterion gained supporting evidence: "each is showing the same document rather than a copy of it" is achievable within the existing record shape, since several rows in `data/event-notes.json` can carry the same source reference without duplicating content. Also recorded: this story is the one that most sharply constrains the mechanism decision — browser-held content cannot satisfy "each place shows the same content" on a second machine, because notes render from `ApiService.fetchNotes` and a browser that was never granted the folder has nothing to render.
- **2026-08-28 — Phase 0.** Drafted from the verbatim request. Open questions 1–3 are things the request left undecided; none were decided here.
