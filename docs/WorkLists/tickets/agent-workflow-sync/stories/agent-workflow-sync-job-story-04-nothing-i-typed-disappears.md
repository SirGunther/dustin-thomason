# Job Story 04 — Nothing I typed disappears

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
| Motivation | *A [user type] doesn't want [undesired outcome].* | Somebody writing in their own notes doesn't want work they just typed to vanish without warning. |
| Context + Intent | *While [context], they want to [action].* | While typing in a note that background work may also be changing, they want both sets of changes to survive. |
| Obstacle + Desired Action | *Except that [obstacle], so they want to [action to rectify].* | Except that the note endpoint replaces the whole body with no precondition and every write rewrites all twelve section files, so they want an optimistic concurrency check and scoped writes. |
| Resolution | *Now they'll be able to [positive outcome].* | Now they'll be able to work in a note concurrently with agent activity without data loss. |

## Revision Matrix

| Component | Before | Issue | After |
| --- | --- | --- | --- |
| Obstacle + Desired Action | Except that the note endpoint replaces the whole body with no precondition and every write rewrites all twelve section files, so they want an optimistic concurrency check and scoped writes. | Solution-speak — "endpoint", "precondition", "section files", "optimistic concurrency", "scoped writes" are entirely design vocabulary. | Except that whoever saves last wins and nobody is told, so they want a save that either keeps both changes or says plainly that it could not. |
| Resolution | Now they'll be able to work in a note concurrently with agent activity without data loss. | Formal register and vague phrasing — "concurrently", "agent activity", "data loss". | Now they'll be able to keep typing while work runs in the background and know nothing went missing. |
| Motivation | Somebody writing in their own notes doesn't want work they just typed to vanish without warning. | Clean — but "without warning" is the load-bearing part and should stay. | Somebody writing in their own notes doesn't want work they just typed to vanish without warning. |

## Delivery Acceptance Statement (DAS)

*We know this story is considered complete when:*

- A note being edited is not overwritten by background work.
- When two changes land on the same note, the user is told and neither change is thrown away quietly.
- One small change does not rewrite parts of their data it never touched.
- The user can keep typing in a note while a ticket's tracking is being updated.
- A collision the system cannot resolve is surfaced to the user rather than retried until something wins.

## Concatenated Story

Somebody writing in their own notes doesn't want work they just typed to vanish without warning. While typing in a note that background work may also be changing, they want both sets of changes to survive. Except that whoever saves last wins and nobody is told, so they want a save that either keeps both changes or says plainly that it could not. Now they'll be able to keep typing while work runs in the background and know nothing went missing.

## Final Review Matrix

| Original Sentence | Issue/Observation | Refined Sentence |
| --- | --- | --- |
| Somebody writing in their own notes doesn't want work they just typed to vanish without warning. | Clean — motivation, observable, no design words. | Somebody writing in their own notes doesn't want work they just typed to vanish without warning. |
| While typing in a note that background work may also be changing, they want both sets of changes to survive. | Clean — context and intent. | While typing in a note that background work may also be changing, they want both sets of changes to survive. |
| Except that whoever saves last wins and nobody is told, so they want a save that either keeps both changes or says plainly that it could not. | Clean — states the obstacle in user terms; the silence is the real defect. | Except that whoever saves last wins and nobody is told, so they want a save that either keeps both changes or says plainly that it could not. |
| Now they'll be able to keep typing while work runs in the background and know nothing went missing. | Emotional abstraction — "know nothing went missing" is a feeling unless something confirms it. | Now they'll be able to keep typing while work runs in the background, and be told if anything collided. |
| A note being edited is not overwritten by background work. | Clean — observable. | A note being edited is not overwritten by background work. |
| When two changes land on the same note, the user is told and neither change is thrown away quietly. | Wordiness — two clauses for one idea. | When two changes land on the same note, the user is told and neither is thrown away. |
| One small change does not rewrite parts of their data it never touched. | Clean — observable, and checkable by looking at what actually got written. | One small change does not rewrite parts of their data it never touched. |
| The user can keep typing in a note while a ticket's tracking is being updated. | Clean — observable. | The user can keep typing in a note while a ticket's tracking is being updated. |
| A collision the system cannot resolve is surfaced to the user rather than retried until something wins. | Solution-speak — "retried" names the mechanism. | A collision that cannot be sorted out automatically is brought to the user instead of being resolved by whoever happens to win. |

## User Story

Somebody writing in their own notes doesn't want work they just typed to vanish without warning. While typing in a note that background work may also be changing, they want both sets of changes to survive. Except that whoever saves last wins and nobody is told, so they want a save that either keeps both changes or says plainly that it could not. Now they'll be able to keep typing while work runs in the background, and be told if anything collided.

## Acceptance Criteria

- A note being edited is not overwritten by background work.
- When two changes land on the same note, the user is told and neither is thrown away.
- One small change does not rewrite parts of their data it never touched.
- The user can keep typing in a note while a ticket's tracking is being updated.
- A collision that cannot be sorted out automatically is brought to the user instead of being resolved by whoever happens to win.

## Open Questions

- How is a collision brought to the user — a message in the app, an entry in a log, or a report from the agent? The request does not say, and the answer changes whether front-end work is in scope. Owner: user.
- Should the app itself hold a note open while it is being edited, or is detecting the collision at save time enough? Detecting at save is far cheaper; holding it open prevents the collision but introduces a stuck-lock failure of its own.

## Story log

### 2026-08-12 — created

- Drafted from `original-ticket.md` message 10 ("Since the data sections and the JSON files behind them are locked, that is what needs to change... I think that is one of the weaknesses of this board in general"). Kept as its own story because the user framed it as a general weakness of the board rather than an agent concern — it is a problem for a person editing notes even with no agent running. The third criterion carries the sweeping-write half of that message; the rest carry the silent-overwrite half.
