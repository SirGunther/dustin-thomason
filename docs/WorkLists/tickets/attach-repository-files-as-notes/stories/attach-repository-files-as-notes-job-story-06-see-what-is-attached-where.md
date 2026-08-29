# Job story 06 — See what is attached where

| Field | Value |
| --- | --- |
| Project | WorkLists |
| Ticket slug | `attach-repository-files-as-notes` |
| Date | 2026-08-28 |
| Status | draft — **out of scope for this slice** |
| Source | [original-ticket.md](../original-ticket.md), via [LD-008](../specs/attach-repository-files-as-notes-locked-decisions.md) |

> **Why this story exists and why it is not being built here.** It was surfaced by the owner at Phase 3 while rejecting a different criterion. Story 05 originally asked that a person be able to see where else a document was attached *before changing or removing it* — as a gate. The owner rejected the gate and named what was actually useful underneath it: *"being able to manage it in some way and have visibility of where it is located and how many instances exist is very useful… If I am doing it in so many places, I may have a lot of duplicates. It could be a useful way to get that knowledge."*
>
> That is a management capability, not a safety precondition, and it does not belong to any of stories 01–05. It is written now so the idea is not lost, and left `draft` so nothing downstream can mistake it for accepted scope.

## Story Matrix

| Component | Framework Language | Story Sentence |
| --- | --- | --- |
| Motivation | *A [user type] doesn't want [undesired outcome].* | Someone who has been pulling the same documents into their work for months doesn't want to lose track of which documents are in play and how often. |
| Context + Intent | *While [context], they want to [action].* | While tidying up or deciding whether a document is worth keeping current, they want to see every document currently pulled into their work and where each one sits. |
| Obstacle + Desired Action | *Except that [obstacle], so they want to [action to rectify].* | Except that the references are scattered across individual note records with no index, so they want a management view listing each source file with a count of its attachments. |
| Resolution | *Now they'll be able to [positive outcome].* | Now they'll be able to spot the documents they lean on most, and the ones they have pulled in so many times that the duplication itself is telling them something. |

## Revision Matrix

| Component | Before | Issue named | After |
| --- | --- | --- | --- |
| Obstacle + Desired Action | Except that the references are scattered across individual note records with no index, so they want a management view listing each source file with a count of its attachments. | Solution-speak — "note records", "index", "management view" are all design elements. | Except that there is no way to look at all of it at once, so they want one place that lists every document in play and how many times each is used. |
| Motivation | Someone who has been pulling the same documents into their work for months doesn't want to lose track of which documents are in play and how often. | Wordiness. | Someone who keeps pulling the same documents into their work doesn't want to lose track of which ones are in play. |

## Delivery Acceptance Statement (DAS)

*We know this story is considered complete when:*
- A person can see, in one place, every document currently pulled into their work.
- Each one shows how many places it is used and which ones.
- A document used in an unusually high number of places is visible as such without counting by hand.
- A reference whose file no longer exists is visible in that same place, so broken ones can be found without opening every card.
- Looking at this changes nothing — it is a read, and nothing is attached, detached, or edited by visiting it.

## Concatenated Story

Someone who keeps pulling the same documents into their work doesn't want to lose track of which ones are in play. While tidying up or deciding whether a document is worth keeping current, they want to see every document currently pulled into their work and where each one sits. Except that there is no way to look at all of it at once, so they want one place that lists every document in play and how many times each is used. Now they'll be able to spot the documents they lean on most, and the ones they have pulled in so many times that the duplication itself is telling them something.

## Final Review Matrix

| Original Sentence | Issue/Observation | Refined Sentence |
| --- | --- | --- |
| Someone who keeps pulling the same documents into their work doesn't want to lose track of which ones are in play. | None. | Someone who keeps pulling the same documents into their work doesn't want to lose track of which ones are in play. |
| While tidying up or deciding whether a document is worth keeping current, they want to see every document currently pulled into their work and where each one sits. | Wordiness. | While tidying up, they want to see every document in play and where each one sits. |
| Except that there is no way to look at all of it at once, so they want one place that lists every document in play and how many times each is used. | None. | Except that there is no way to look at all of it at once, so they want one place that lists every document in play and how many times each is used. |
| Now they'll be able to spot the documents they lean on most, and the ones they have pulled in so many times that the duplication itself is telling them something. | Wordiness. | Now they'll be able to spot which documents they lean on most, and where they have pulled the same one in so often that it is worth noticing. |
| A person can see, in one place, every document currently pulled into their work. | None. | A person can see, in one place, every document currently pulled into their work. |
| Each one shows how many places it is used and which ones. | None. | Each one shows how many places it is used and which ones. |
| A document used in an unusually high number of places is visible as such without counting by hand. | Vague phrasing — "unusually high" is not checkable. | The list can be ordered by how many places use a document, so the most-reused ones come first. |
| A reference whose file no longer exists is visible in that same place, so broken ones can be found without opening every card. | Wordiness. | A reference whose file is gone shows up in the same list, so broken ones are findable without opening every card. |
| Looking at this changes nothing — it is a read, and nothing is attached, detached, or edited by visiting it. | None. | Looking at this changes nothing — nothing is attached, detached, or edited by visiting it. |

## User Story

Someone who keeps pulling the same documents into their work doesn't want to lose track of which ones are in play. While tidying up, they want to see every document in play and where each one sits. Except that there is no way to look at all of it at once, so they want one place that lists every document in play and how many times each is used. Now they'll be able to spot which documents they lean on most, and where they have pulled the same one in so often that it is worth noticing.

## Acceptance Criteria

- A person can see, in one place, every document currently pulled into their work.
- Each one shows how many places it is used and which ones.
- The list can be ordered by how many places use a document, so the most-reused ones come first.
- A reference whose file is gone shows up in the same list, so broken ones are findable without opening every card.
- Looking at this changes nothing — nothing is attached, detached, or edited by visiting it.

## Open Questions

1. Where does this live — a further Settings tab beside the repository-root setting, or somewhere on the board? Not decided; the owner called it "potentially useful… for management purposes" without naming a place.
2. Is it worth building before there are enough attachments to be worth managing? The value scales with usage, and there are currently zero.
3. Should it offer bulk actions (detach everywhere, repoint a moved file), or stay strictly read-only as criterion five says? Criterion five is written read-only deliberately; a repoint action would be the natural companion to FDC-05's rename risk, and would change this story's character.

## Story log

- **2026-08-28 — Phase 3 — created, deliberately not accepted.** Split out of story 05 when the owner rejected that story's pre-change visibility criterion (LD-008). The rejected criterion framed visibility as a **gate** on changing a shared document; this story reframes it as **management** — an inventory read, with criterion five stating explicitly that it changes nothing. That reframe is the whole reason it is a separate story rather than a reworded criterion. Left `draft` and out of scope so this slice is not quietly widened.
