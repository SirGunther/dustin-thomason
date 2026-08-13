# Job Story 01 — Delegated work stays true

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
| Motivation | *A [user type] doesn't want [undesired outcome].* | A developer handing ticket work to an agent doesn't want the tracking to go stale the moment they stop updating it themselves. |
| Context + Intent | *While [context], they want to [action].* | While an agent works through the stages of a ticket, they want the ticket's record to keep pace with what has actually been finished. |
| Obstacle + Desired Action | *Except that [obstacle], so they want to [action to rectify].* | Except that the agent cannot reach a single card or tick one checklist item through the existing endpoints, so they want new endpoints that let it patch the card and the checklist directly. |
| Resolution | *Now they'll be able to [positive outcome].* | Now they'll be able to look at a ticket and trust that what it says is what actually happened. |

## Revision Matrix

| Component | Before | Issue | After |
| --- | --- | --- | --- |
| Obstacle + Desired Action | Except that the agent cannot reach a single card or tick one checklist item through the existing endpoints, so they want new endpoints that let it patch the card and the checklist directly. | Solution-speak — "endpoints", "patch", "card" name the design rather than the user's problem. | Except that nothing keeps the ticket's record current unless they update it by hand, so they want each finished step recorded as it is finished, without them doing it. |
| Motivation | A developer handing ticket work to an agent doesn't want the tracking to go stale the moment they stop updating it themselves. | Wordiness — "the moment they stop updating it themselves" restates the same idea twice. | A developer handing ticket work to an agent doesn't want to keep the tracking current by hand. |

## Delivery Acceptance Statement (DAS)

*We know this story is considered complete when:*

- The user names which ticket is being worked on at the start, and never has to name it again for that ticket.
- Steps the agent finishes are marked as finished without the user marking them.
- Steps that were not finished are not marked as finished.
- What the ticket says matches what was actually done, confirmed by comparing the ticket against the work that ran.
- When the tracking cannot be updated safely, the user is told instead of the update being skipped quietly.
- A ticket the agent cannot track reliably is reported as such rather than guessed at.

## Concatenated Story

A developer handing ticket work to an agent doesn't want to keep the tracking current by hand. While an agent works through the stages of a ticket, they want the ticket's record to keep pace with what has actually been finished. Except that nothing keeps the ticket's record current unless they update it by hand, so they want each finished step recorded as it is finished, without them doing it. Now they'll be able to look at a ticket and trust that what it says is what actually happened.

## Final Review Matrix

| Original Sentence | Issue/Observation | Refined Sentence |
| --- | --- | --- |
| A developer handing ticket work to an agent doesn't want to keep the tracking current by hand. | Clean — motivation, no design words. | A developer handing ticket work to an agent doesn't want to keep the tracking current by hand. |
| While an agent works through the stages of a ticket, they want the ticket's record to keep pace with what has actually been finished. | Vague phrasing — "keep pace with" is not clearly knowable. | While an agent works through the stages of a ticket, they want the ticket to show what has actually been finished. |
| Except that nothing keeps the ticket's record current unless they update it by hand, so they want each finished step recorded as it is finished, without them doing it. | Wordiness — "record current unless they update it by hand" repeats the motivation. | Except that only they can mark a step done, so they want each step recorded as it is finished without them doing it. |
| Now they'll be able to look at a ticket and trust that what it says is what actually happened. | Emotional abstraction — "trust" is not observable. | Now they'll be able to pull up a ticket and see exactly which steps are done. |
| The user names which ticket is being worked on at the start, and never has to name it again for that ticket. | Clean — observable. | The user names which ticket is being worked on at the start, and never has to name it again for that ticket. |
| Steps the agent finishes are marked as finished without the user marking them. | Clean — observable. | Steps the agent finishes are marked as finished without the user marking them. |
| Steps that were not finished are not marked as finished. | Clean — observable, and the negative case worth stating. | Steps that were not finished are not marked as finished. |
| What the ticket says matches what was actually done, confirmed by comparing the ticket against the work that ran. | Wordiness — the confirmation method belongs in the test plan, not the criterion. | What the ticket says matches what was actually done. |
| When the tracking cannot be updated safely, the user is told instead of the update being skipped quietly. | Vague phrasing — "safely" is undefined at story level. | When a step cannot be recorded, the user is told rather than the step being skipped without notice. |
| A ticket the agent cannot track reliably is reported as such rather than guessed at. | Vague phrasing — "reliably" is undefined. | A ticket the agent cannot track is named as one it cannot track, rather than being partly updated. |

## User Story

A developer handing ticket work to an agent doesn't want to keep the tracking current by hand. While an agent works through the stages of a ticket, they want the ticket to show what has actually been finished. Except that only they can mark a step done, so they want each step recorded as it is finished without them doing it. Now they'll be able to pull up a ticket and see exactly which steps are done.

## Acceptance Criteria

- The user names which ticket is being worked on at the start, and never has to name it again for that ticket.
- Steps the agent finishes are marked as finished without the user marking them.
- Steps that were not finished are not marked as finished.
- What the ticket says matches what was actually done.
- When a step cannot be recorded, the user is told rather than the step being skipped without notice.
- A ticket the agent cannot track is named as one it cannot track, rather than being partly updated.

## Open Questions

- May the agent un-mark a step it previously marked? Un-marking is how a failed verification gets recorded honestly, and also how real progress could be erased. Owner: user. Carried from the decision map's open questions.
- Does the agent set the ticket's overall status, or only the individual steps? Setting status overlaps with the user's own judgement about when something is genuinely in review.

## Story log

### 2026-08-12 — created

- Drafted from `original-ticket.md` messages 1, 5, and 13. Split from the visibility concern, which became story 02, because the motivations differ: this story is about not maintaining tracking by hand, story 02 is about reading across many tickets at once.
