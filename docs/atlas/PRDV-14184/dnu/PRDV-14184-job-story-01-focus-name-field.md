# Job story 01 — Focus proceeding name field

| Field | Value |
| --- | --- |
| Ticket | PRDV-14184 |
| Project | atlas |
| Date | 2026-09-11 |
| Source | [original-ticket.md](../PRDV-14184-original-ticket.md) |
| Status | accepted (2026-09-11, Phase 3) |

## 1. Story Matrix

| Component | Story Sentence |
| --- | --- |
| Motivation | A Ops Atlas user doesn't want to click twice to start naming a new Proceeding. |
| Context + Intent | While creating a new Proceeding, or adding an additional one, they want to immediately begin typing its name. |
| Obstacle + Desired Action | Except that the name field isn't focused when the new proceeding row appears, so they want the field to be focused automatically. |
| Resolution | Now they'll be able to start typing the proceeding name right away without an extra click. |

## 2. Revision Matrix

| Component | Before | Issue | After |
| --- | --- | --- | --- |
| Obstacle + Desired Action | Except that the name field isn't focused when the new proceeding row appears, so they want the field to be focused automatically. | Solution-speak ("field", "row", "focused") | Except that they have to take an extra step before they can type the new proceeding's name, so they want that step removed. |

## 3. Delivery Acceptance Statement (DAS)

We know this story is considered complete when:
- Creating a new Proceeding leaves the user able to type the proceeding's name immediately, with no extra click needed.
- Adding an additional proceeding leaves the user able to type that proceeding's name immediately, with no extra click needed.

## 4. Concatenated Story

An Ops Atlas user doesn't want to click twice to start naming a new Proceeding. While creating a new Proceeding, or adding an additional one, they want to immediately begin typing its name. Except that they have to take an extra step before they can type the new proceeding's name, so they want that step removed. Now they'll be able to start typing the proceeding name right away without an extra click.

## 5. Final Review Matrix

| Original Sentence | Issue/Observation | Refined Sentence |
| --- | --- | --- |
| A Ops Atlas user doesn't want to click twice to start naming a new Proceeding. | Vague phrasing (grammar, "click twice" unspecific) | An Ops Atlas user doesn't want an extra click just to start naming a new Proceeding. |
| While creating a new Proceeding, or adding an additional one, they want to immediately begin typing its name. | No issue — observable and design-word-free | While creating a new Proceeding, or adding an additional one, they want to immediately begin typing its name. |
| Except that they have to take an extra step before they can type the new proceeding's name, so they want that step removed. | No issue — kept from Revision Matrix | Except that they have to take an extra step before they can type the new proceeding's name, so they want that step removed. |
| Now they'll be able to start typing the proceeding name right away without an extra click. | No issue — observable outcome | Now they'll be able to start typing the proceeding name right away without an extra click. |
| Creating a new Proceeding leaves the user able to type the proceeding's name immediately, with no extra click needed. | No issue — observable, verifiable | Creating a new Proceeding leaves the user able to type the proceeding's name immediately, with no extra click needed. |
| Adding an additional proceeding leaves the user able to type that proceeding's name immediately, with no extra click needed. | No issue — observable, verifiable | Adding an additional proceeding leaves the user able to type that proceeding's name immediately, with no extra click needed. |

## User Story

An Ops Atlas user doesn't want an extra click just to start naming a new Proceeding. While creating a new Proceeding, or adding an additional one, they want to immediately begin typing its name. Except that they have to take an extra step before they can type the new proceeding's name, so they want that step removed. Now they'll be able to start typing the proceeding name right away without an extra click.

## Acceptance Criteria

- Creating a new Proceeding leaves the user able to type the proceeding's name immediately, with no extra click needed.
- Adding an additional proceeding leaves the user able to type that proceeding's name immediately, with no extra click needed.

## Open Questions

- **CLOSED (Phase 1)** — ~~Does "highlighted by default" mean input focus only, or focus **plus** existing text selected?~~ **Focus only.** Every new proceeding row is an empty string (`ref([''])` and `push('')` on both surfaces), and the backend never generates a default name — `value` is client-supplied on both create DTOs with no default (`create-proceedings.request.dto.ts:14-19`, `CreateProceedingsTS.apply`). There is never any text to select.
- **CLOSED (Phase 1)** — ~~Which entry points does "add an additional proceeding" cover?~~ Exactly two surfaces render an empty proceeding-name input, and **each** has both moments: an initial row and an append handler. `NewProceedingsOverlay.vue` (Job Detail page) and `AddProceedingForm.vue` (Job Submission, reached on both the Pending and Submitted routes). So AC-1 and AC-2 are moments, not components — four moments in total.
- **CLOSED (Phase 3)** — ~~Do both surfaces ship, or only the Job Detail overlay?~~ **Both** ([LD-001](../specs/PRDV-14184-locked-decisions.md)). Closed by re-reading the criteria rather than by a scope call: AC-1 and AC-2 are quantified over the user action ("when users create a new Proceeding"), name no surface, and drop the "Ops" qualifier that appears only in the motivation clause. A criterion in that form is falsified by any surface where the behavior is absent, so narrowing scope would mean **rewriting the criteria**, not merely choosing less work.

**No open questions remain.**

## Story log

- 2026-09-11 (Phase 3) — **ACCEPTED.** The last open question closed against [LD-001](../specs/PRDV-14184-locked-decisions.md). **No criterion changed wording**, which is the point worth recording: the scope question was resolved *by* the criteria rather than resolved *into* them. Both criteria stay surface-agnostic and observable ("able to type … immediately, with no extra click needed"), and the implementation now has four places to satisfy them — two surfaces × two moments. Also confirmed that the Phase 3 design decisions (LD-002 inline, LD-003 `document.activeElement`, LD-005 real-Quasar mount, LD-006 `nextTick`) are all *how* decisions: none of them touches what done means, so none was allowed to edit a criterion. Status `draft` → `accepted`.
- 2026-09-11 (Phase 1): Both Phase 0 open questions **closed against code evidence**, neither by inference. "Highlighted" resolved to *focus*, not *select* — so no criterion needed rewording, since both already say "able to type … immediately," which focus alone satisfies. Entry points resolved to two surfaces × two moments; this did **not** split the story, because all four moments serve the same user outcome and the same acceptance criteria — what changed is that the criteria now have a known number of places to hold true. One **new** open question surfaced and is a genuine decision rather than a fact: whether both surfaces are in scope. Story stays `draft` until that closes at Phase 3.
- 2026-09-11 (Phase 0): Story drafted from the verbatim original request and the ticket's own Acceptance Criteria. Two open questions carried forward for investigation (focus vs. select semantics; scope of "additional proceeding" entry points).
