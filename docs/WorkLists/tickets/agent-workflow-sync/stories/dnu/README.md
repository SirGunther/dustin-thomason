# dnu — retired stories

Do not use. Kept because the reasoning is worth the trail, not because it is current.

| File | Retired | Why | Superseded by |
| --- | --- | --- | --- |
| `agent-workflow-sync-job-story-02-progress-readable-across-tickets.md` | 2026-08-12 | **Out of scope — written from a misread.** The original request said "It is also important for the visibility and dashboarding of everything I use." That was context about why the board matters, not a requirement for this feature. It got turned into a story about querying across all tickets, which this effort was never about — the ask is that the agent updates **the card it was given an id for**, nothing beyond that boundary. | Nothing. The requirement did not exist |

## What this retirement removed downstream

- **W9** (`queryable-workflow-mirror-properties`) — existed only to serve this story.
- **The "two copies of one value" decision** — the whole mirror-property tension came from needing workflow values to be queryable across cards. Nothing needs that, so nothing needs a second copy.
- **Four "gap" rows** in the validation matrix — they were gaps against criteria that should never have been written.
