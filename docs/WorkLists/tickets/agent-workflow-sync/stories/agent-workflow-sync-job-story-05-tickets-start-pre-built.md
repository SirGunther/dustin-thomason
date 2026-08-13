# Job Story 05 — Tickets start pre-built

| Field | Value |
| --- | --- |
| Project | WorkLists |
| Ticket slug | agent-workflow-sync |
| Date | 2026-08-12 |
| Source | [original-ticket.md](../original-ticket.md) — added from the 2026-08-12 conversation, recorded in the Story log |
| Status | draft |

## Story Matrix

| Component | Framework Language | Story Sentence |
| --- | --- | --- |
| Motivation | *A [user type] doesn't want [undesired outcome].* | Somebody starting a new ticket doesn't want to rebuild the same structure by hand every time. |
| Context + Intent | *While [context], they want to [action].* | While starting tickets that all follow the same shape, they want that shape to already be there. |
| Obstacle + Desired Action | *Except that [obstacle], so they want to [action to rectify].* | Except that there is no card template record or settings surface to hold one, so they want a templates section with an API that emits a card and its notes. |
| Resolution | *Now they'll be able to [positive outcome].* | Now they'll be able to spin up a fully-formed ticket instead of assembling one. |

## Revision Matrix

| Component | Before | Issue | After |
| --- | --- | --- | --- |
| Obstacle + Desired Action | Except that there is no card template record or settings surface to hold one, so they want a templates section with an API that emits a card and its notes. | Solution-speak — "record", "settings surface", "templates section", "API", "emits" name the design rather than the problem. | Except that they retype or copy it each time and the copies drift apart, so they want to define the shape once and have every new ticket start from it. |
| Motivation | Somebody starting a new ticket doesn't want to rebuild the same structure by hand every time. | Clean — the repetition is the real pain. | Somebody starting a new ticket doesn't want to rebuild the same structure by hand every time. |

## Delivery Acceptance Statement (DAS)

*We know this story is considered complete when:*

- The shape a new ticket should start with is defined in one place, and changing it there changes what new tickets get.
- More than one shape can be kept, so different kinds of work can start differently.
- A new ticket comes out with its progress sections and its checklist already in place.
- Starting a ticket this way does not require retyping or hunting for an old ticket to copy.
- The shape can be looked at and changed in the same place the rest of the app's settings live.
- Whoever starts the ticket is told which ticket was created, so they can go straight to it.

## Concatenated Story

Somebody starting a new ticket doesn't want to rebuild the same structure by hand every time. While starting tickets that all follow the same shape, they want that shape to already be there. Except that they retype or copy it each time and the copies drift apart, so they want to define the shape once and have every new ticket start from it. Now they'll be able to spin up a fully-formed ticket instead of assembling one.

## Final Review Matrix

| Original Sentence | Issue/Observation | Refined Sentence |
| --- | --- | --- |
| Somebody starting a new ticket doesn't want to rebuild the same structure by hand every time. | Clean — motivation, observable pain. | Somebody starting a new ticket doesn't want to rebuild the same structure by hand every time. |
| While starting tickets that all follow the same shape, they want that shape to already be there. | Wordiness — "shape" twice in one sentence. | While starting tickets that all follow the same pattern, they want that groundwork already done. |
| Except that they retype or copy it each time and the copies drift apart, so they want to define the shape once and have every new ticket start from it. | Clean — the drift is the load-bearing half, and it is what the evidence shows (three heading generations across nine cards). | Except that they retype or copy it each time and the copies drift apart, so they want to define it once and have every new ticket start from that. |
| Now they'll be able to spin up a fully-formed ticket instead of assembling one. | Everyday phrasing is good; "fully-formed" is slightly abstract. | Now they'll be able to start a ticket that already has its structure in place. |
| The shape a new ticket should start with is defined in one place, and changing it there changes what new tickets get. | Clean — observable and directly testable. | What a new ticket starts with is defined in one place, and changing it there changes what new tickets get. |
| More than one shape can be kept, so different kinds of work can start differently. | Clean — the plural case matters and would otherwise be assumed away. | More than one can be kept, so different kinds of work start differently. |
| A new ticket comes out with its progress sections and its checklist already in place. | Clean — observable. | A new ticket comes out with its progress sections and its checklist already in place. |
| Starting a ticket this way does not require retyping or hunting for an old ticket to copy. | Wordiness. | Starting a ticket needs no retyping and no hunting for an old one to copy. |
| The shape can be looked at and changed in the same place the rest of the app's settings live. | Solution-speak — "settings" names the surface. | It can be looked at and changed in the same place the rest of the app's own configuration is managed. |
| Whoever starts the ticket is told which ticket was created, so they can go straight to it. | Clean, and load-bearing — without it a created ticket is lost. | Whoever starts the ticket is told which one was created, so they can go straight to it. |

## User Story

Somebody starting a new ticket doesn't want to rebuild the same structure by hand every time. While starting tickets that all follow the same pattern, they want that groundwork already done. Except that they retype or copy it each time and the copies drift apart, so they want to define it once and have every new ticket start from that. Now they'll be able to start a ticket that already has its structure in place.

## Acceptance Criteria

- What a new ticket starts with is defined in one place, and changing it there changes what new tickets get.
- More than one can be kept, so different kinds of work start differently.
- A new ticket comes out with its progress sections and its checklist already in place.
- Starting a ticket needs no retyping and no hunting for an old one to copy.
- It can be looked at and changed in the same place the rest of the app's own configuration is managed.
- Whoever starts the ticket is told which one was created, so they can go straight to it.

## Open Questions

- **What is this called in the app?** The user is still deciding. Candidates that fit the existing configuration vocabulary (`Models`, `Classification Prompts`): **Card Templates**, **Ticket Templates**, **Card Blueprints**. Recommendation: **Card Templates** — it says what it holds and matches the flat, literal naming already in use. Owner: user.
- **Can a ticket be started this way from the app, or only by an agent to begin with?** The user raised leaving it agent-only at first. That is a legitimate first step, but note it means the last criterion ("whoever starts the ticket is told which one was created") is only exercised through the agent until an in-app path exists.
- **How many notes can one definition carry?** The user described a main note plus secondary notes. Whether that is exactly two roles or an ordered list of any length is undecided. Recommendation: an ordered list, since the checklist is one note and nothing argues for a fixed count.

## Story log

### 2026-08-12 — created

- Added from the conversation of 2026-08-12, not from the original request text. The user proposed it directly: *"it would be really helpful to integrate the template feature into the settings menu... This tool could define what a card should contain, including fields for your main or secondary notes. I think we may even need to include a job story for this."*
- **Why it is in scope where story 02 was not.** Story 02 asked for reading across many tickets, which is outside the boundary of "the card the agent was given an id for." This story is about how that one card comes into being — the entry point of the very same run. It also replaces a mechanism already in the specs (duplicating a card), rather than adding a new capability area.
- Supersedes the duplicate-card approach recorded in W2's earlier path B. Duplication returned the new id, which was the part that worked; it could not define what the shape *should* be, only copy whatever an existing card happened to have — including its drift.
