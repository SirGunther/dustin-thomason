# Job Story 03 — The checklist stays mine to change

| Field | Value |
| --- | --- |
| Project | WorkLists |
| Ticket slug | agent-workflow-sync |
| Date | 2026-08-12 |
| Source | [original-ticket.md](../original-ticket.md) |
| Status | draft |

## Story Matrix

| Component | Framework Language | Story Sentence |
| --- | --- | --- |
| Motivation | *A [user type] doesn't want [undesired outcome].* | Somebody who keeps refining their own working process doesn't want improving a step to quietly break the tracking that depends on it. |
| Context + Intent | *While [context], they want to [action].* | While adding, rewording, and reordering steps as the process matures, they want the tracking to keep working. |
| Obstacle + Desired Action | *Except that [obstacle], so they want to [action to rectify].* | Except that each ticket's checklist was pasted and hand-edited so no two versions match, so they want a template record with stable item ids that new cards render from. |
| Resolution | *Now they'll be able to [positive outcome].* | Now they'll be able to evolve the process without the tracking layer decaying. |

## Revision Matrix

| Component | Before | Issue | After |
| --- | --- | --- | --- |
| Obstacle + Desired Action | Except that each ticket's checklist was pasted and hand-edited so no two versions match, so they want a template record with stable item ids that new cards render from. | Solution-speak — "template record", "item ids", "render", "cards" name the design. | Except that the steps get retyped for every ticket and no two tickets carry the same ones, so they want to change a step in one place and have every ticket that follows use it. |
| Resolution | Now they'll be able to evolve the process without the tracking layer decaying. | Vague phrasing and formal register — "evolve", "tracking layer decaying". | Now they'll be able to change how they work whenever they learn something, without breaking what is already running. |

## Delivery Acceptance Statement (DAS)

*We know this story is considered complete when:*

- A step can be reworded or moved without breaking tracking on tickets that already carry it.
- A step added in one place shows up on every ticket started after that.
- A retired step still reads correctly on older tickets that carry it.
- A ticket started before the shared version is identified as one the agent cannot track, rather than being tracked incorrectly.
- Nothing about a step's wording is what the tracking depends on.

## Concatenated Story

Somebody who keeps refining their own working process doesn't want improving a step to quietly break the tracking that depends on it. While adding, rewording, and reordering steps as the process matures, they want the tracking to keep working. Except that the steps get retyped for every ticket and no two tickets carry the same ones, so they want to change a step in one place and have every ticket that follows use it. Now they'll be able to change how they work whenever they learn something, without breaking what is already running.

## Final Review Matrix

| Original Sentence | Issue/Observation | Refined Sentence |
| --- | --- | --- |
| Somebody who keeps refining their own working process doesn't want improving a step to quietly break the tracking that depends on it. | Clean — motivation, no design words, and the "quietly" is doing real work given the failure mode is silent. | Somebody who keeps refining their own working process doesn't want improving a step to quietly break the tracking that depends on it. |
| While adding, rewording, and reordering steps as the process matures, they want the tracking to keep working. | Vague phrasing — "keep working" is not clearly knowable. | While adding, rewording, and reordering steps as the process matures, they want every ticket to keep being tracked correctly. |
| Except that the steps get retyped for every ticket and no two tickets carry the same ones, so they want to change a step in one place and have every ticket that follows use it. | Clean — states the real obstacle, which the evidence bears out at 17 to 35 items across three generations. | Except that the steps get retyped for every ticket and no two tickets carry the same ones, so they want to change a step in one place and have every ticket that follows use it. |
| Now they'll be able to change how they work whenever they learn something, without breaking what is already running. | Clean — observable, everyday phrasing. | Now they'll be able to change how they work whenever they learn something, without breaking what is already running. |
| A step can be reworded or moved without breaking tracking on tickets that already carry it. | Clean — observable and directly testable. | A step can be reworded or moved without breaking tracking on tickets that already carry it. |
| A step added in one place shows up on every ticket started after that. | Clean — observable. | A step added in one place shows up on every ticket started after that. |
| A retired step still reads correctly on older tickets that carry it. | Clean — observable. | A retired step still reads correctly on older tickets that carry it. |
| A ticket started before the shared version is identified as one the agent cannot track, rather than being tracked incorrectly. | Wordiness — two clauses saying one thing. | A ticket started before the shared version is flagged as untrackable rather than tracked wrongly. |
| Nothing about a step's wording is what the tracking depends on. | Vague phrasing — states a negative without a check behind it. | Changing only a step's wording changes nothing about whether it can be tracked. |

## User Story

Somebody who keeps refining their own working process doesn't want improving a step to quietly break the tracking that depends on it. While adding, rewording, and reordering steps as the process matures, they want every ticket to keep being tracked correctly. Except that the steps get retyped for every ticket and no two tickets carry the same ones, so they want to change a step in one place and have every ticket that follows use it. Now they'll be able to change how they work whenever they learn something, without breaking what is already running.

## Acceptance Criteria

- A step can be reworded or moved without breaking tracking on tickets that already carry it.
- A step added in one place shows up on every ticket started after that.
- A retired step still reads correctly on older tickets that carry it.
- A ticket started before the shared version is flagged as untrackable rather than tracked wrongly.
- Changing only a step's wording changes nothing about whether it can be tracked.

## Open Questions

- Is the shared set of steps editable inside the app, or maintained as a file to begin with? This materially changes the work and is one of the three decisions carried into the specs. Owner: user.
- Can a step be added to a single ticket without adding it to the shared set? The user does write bespoke checklists — one existing note carries a hand-written `Action Items` set — so the answer is probably yes, but the request does not say.
- Should the nine existing tickets be brought onto the shared version in one pass, or as each is next worked on? Owner: user; recommendation on record is one pass.

## Story log

### 2026-08-12 — created

- Drafted from `original-ticket.md` messages 2 ("There are different checklist items, so I think that is something that would ultimately need to be maintained") and 11 ("If it is a checklist, we want a standardized way to ensure it is working correctly"). Kept as its own story because the motivation is the user's own process changing, not the agent's behaviour — the same problem would exist without an agent involved.
