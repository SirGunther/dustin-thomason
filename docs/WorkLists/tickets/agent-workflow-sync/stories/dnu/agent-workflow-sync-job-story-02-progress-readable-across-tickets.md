# Job Story 02 — Progress readable across tickets

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
| Motivation | *A [user type] doesn't want [undesired outcome].* | Someone reviewing their own workload doesn't want to open every ticket one at a time to find out where things stand. |
| Context + Intent | *While [context], they want to [action].* | While carrying dozens of open tickets at once, they want to see which ones are stalled and which are waiting on somebody else. |
| Obstacle + Desired Action | *Except that [obstacle], so they want to [action to rectify].* | Except that the current step and waiting-on values are markdown text inside the card body, unreachable by any filter or sort, so they want them promoted to real fields the board can query. |
| Resolution | *Now they'll be able to [positive outcome].* | Now they'll be able to see the state of everything at a glance instead of ticket by ticket. |

## Revision Matrix

| Component | Before | Issue | After |
| --- | --- | --- | --- |
| Obstacle + Desired Action | Except that the current step and waiting-on values are markdown text inside the card body, unreachable by any filter or sort, so they want them promoted to real fields the board can query. | Solution-speak — "markdown", "card body", "filter", "sort", "fields", "query" are all design words. | Except that where a ticket stands is written as prose that can only be read one ticket at a time, so they want that standing to be something they can pull up across everything at once. |
| Resolution | Now they'll be able to see the state of everything at a glance instead of ticket by ticket. | Vague phrasing — "at a glance" and "the state of everything" are not clearly knowable. | Now they'll be able to spot which tickets are stuck and which are waiting without reading each one. |

## Delivery Acceptance Statement (DAS)

*We know this story is considered complete when:*

- Where every open ticket stands can be pulled up together, without opening each one.
- Tickets waiting on somebody else can be separated from tickets that are actively moving.
- A stalled ticket can be spotted without reading its notes.
- The standing that gets shown is the same record the agent updates, not a second copy kept in parallel.
- A ticket's own step detail is still readable in full when they want it, not flattened away to make it sortable.

## Concatenated Story

Someone reviewing their own workload doesn't want to open every ticket one at a time to find out where things stand. While carrying dozens of open tickets at once, they want to see which ones are stalled and which are waiting on somebody else. Except that where a ticket stands is written as prose that can only be read one ticket at a time, so they want that standing to be something they can pull up across everything at once. Now they'll be able to spot which tickets are stuck and which are waiting without reading each one.

## Final Review Matrix

| Original Sentence | Issue/Observation | Refined Sentence |
| --- | --- | --- |
| Someone reviewing their own workload doesn't want to open every ticket one at a time to find out where things stand. | Clean — motivation, no design words. | Someone reviewing their own workload doesn't want to open every ticket one at a time to find out where things stand. |
| While carrying dozens of open tickets at once, they want to see which ones are stalled and which are waiting on somebody else. | Clean — context and intent, observable. | While carrying dozens of open tickets at once, they want to see which ones are stalled and which are waiting on somebody else. |
| Except that where a ticket stands is written as prose that can only be read one ticket at a time, so they want that standing to be something they can pull up across everything at once. | Wordiness — "that standing" is a stiff back-reference. | Except that where a ticket stands is buried in prose they can only read one ticket at a time, so they want to pull that up across everything at once. |
| Now they'll be able to spot which tickets are stuck and which are waiting without reading each one. | Clean — observable, everyday phrasing. | Now they'll be able to spot which tickets are stuck and which are waiting without reading each one. |
| Where every open ticket stands can be pulled up together, without opening each one. | Clean — observable. | Where every open ticket stands can be pulled up together, without opening each one. |
| Tickets waiting on somebody else can be separated from tickets that are actively moving. | Clean — observable. | Tickets waiting on somebody else can be separated from tickets that are actively moving. |
| A stalled ticket can be spotted without reading its notes. | Non-observable outcome — "stalled" has no stated meaning. | A ticket that has not moved on can be spotted without reading its notes. |
| The standing that gets shown is the same record the agent updates, not a second copy kept in parallel. | Wordiness — "kept in parallel" adds nothing. | What gets shown is the same record the agent updates, not a second copy. |
| A ticket's own step detail is still readable in full when they want it, not flattened away to make it sortable. | Solution-speak — "sortable" names the design. | A ticket's own wording about where it stands is still readable in full when they want it. |

## User Story

Someone reviewing their own workload doesn't want to open every ticket one at a time to find out where things stand. While carrying dozens of open tickets at once, they want to see which ones are stalled and which are waiting on somebody else. Except that where a ticket stands is buried in prose they can only read one ticket at a time, so they want to pull that up across everything at once. Now they'll be able to spot which tickets are stuck and which are waiting without reading each one.

## Acceptance Criteria

- Where every open ticket stands can be pulled up together, without opening each one.
- Tickets waiting on somebody else can be separated from tickets that are actively moving.
- A ticket that has not moved on can be spotted without reading its notes.
- What gets shown is the same record the agent updates, not a second copy.
- A ticket's own wording about where it stands is still readable in full when they want it.

## Open Questions

- Does "where a ticket stands" need a fixed set of values to be groupable, alongside the free wording? The decision map resolved this as two parts — a controlled value plus a free-text detail — but the set of controlled values has not been named. Owner: user.
- Is the across-tickets view a new surface, or an extension of the filtering and sorting that already exists? This changes scope materially and is not answered by the request.

## Story log

### 2026-08-12 — created

- Drafted from `original-ticket.md` message 1 ("It is also important for the visibility and dashboarding of everything I use"). Split from story 01: that story is about not maintaining tracking by hand, this one is about reading across many tickets at once. The last criterion was added after the Final Review Matrix flagged that making the standing sortable could quietly destroy the free wording the user clearly values, evidenced by entries like "Investigating the necessity of alerts from AWS".
