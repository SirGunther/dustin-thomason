# Job stories — WorkLists/agent-workflow-sync

Source: [original-ticket.md](../original-ticket.md)

**Project-level** stories covering the overarching goals, not one per body of work. The bodies of work in [`003` work breakdown](../../../features/agent-workflow-sync/003-agent-workflow-sync-work-breakdown.md) each trace to one or more of these criteria; a body of work that traces to none is out of scope.

## Scope boundary

**This effort is about the card the agent is given an id for. Nothing beyond that boundary.**

Stated explicitly because a story was written past it and had to be retired — see `dnu/README.md`. The agent reads one card, reads that card's notes, and writes back to that card and those notes. It does not query across tickets, does not aggregate, and does not need any workflow value to be filterable or sortable.

| # | Story | User type | Criteria | Open questions | Status | File |
| --- | --- | --- | --- | --- | --- | --- |
| 01 | Delegated work stays true | Developer handing ticket work to an agent | 6 | 2 | draft | [file](./agent-workflow-sync-job-story-01-delegated-work-stays-true.md) |
| 02 | *(retired — out of scope)* | — | — | — | superseded (see `dnu/`) | [dnu](./dnu/agent-workflow-sync-job-story-02-progress-readable-across-tickets.md) |
| 03 | The checklist stays mine to change | Someone refining their own working process | 5 | 3 | draft | [file](./agent-workflow-sync-job-story-03-checklist-stays-mine-to-change.md) |
| 04 | Nothing I typed disappears | Someone writing in their own notes | 5 | 2 | draft | [file](./agent-workflow-sync-job-story-04-nothing-i-typed-disappears.md) |
| 05 | Tickets start pre-built | Someone starting a new ticket | 6 | 3 | draft | [file](./agent-workflow-sync-job-story-05-tickets-start-pre-built.md) |

Numbering is not reused — 02 stays retired rather than being reassigned.

## Why four, and why three of them would exist without an agent

- **01** — the user does not want to maintain tracking by hand while delegating.
- **03** — the user's own process keeps changing, and changing it breaks the tracking. Would still be true with no agent.
- **04** — a save can silently destroy the user's typing, and one small change rewrites unrelated data. Framed by the user as a general weakness of the board.
- **05** — the same ticket structure gets rebuilt by hand every time, and the copies drift. Would still be true with no agent; the agent is just the first caller.

**Story 05 was added on 2026-08-12 from conversation, not from the original request.** It is in scope because it is about how the one card the run works on comes into being — the entry point of the same run — and because it replaces a mechanism already in the specs rather than opening a new area. Contrast with story 02, retired for reaching past the single-card boundary.

## Story-to-work-breakdown trace

| Body of work | Serves stories |
| --- | --- |
| W1 `record-level-data-access` | 04 |
| W2 `single-card-read-and-id-handoff` | 01, 05 |
| W3 `card-templates-and-checklist-format` | 03, 05, 01 |
| W4 `note-checklist-patch-and-concurrency` | 04, 01 |
| W5 `card-workflow-section-fields` | 01 |
| W6 `agent-workflow-writer` | 01 |
| W7 `onedrive-per-record-file-spike` | 04 (the storage half, deferred) |

**Every body of work now traces to a live story, and every live story is served by W1–W7.** There are no orphan bodies of work and no unserved stories — which was not true while story 02 existed.

## Talking points

A talking points list — grouped for UI/UX, Backend, and Frontend — is available on request.
