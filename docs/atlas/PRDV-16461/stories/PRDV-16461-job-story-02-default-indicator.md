# Job story 02 — Default-selection visual indicator

- **Ticket:** PRDV-16461
- **Project:** atlas
- **Date:** 2026-09-03
- **Source:** [PRDV-16461-original-ticket.md](../PRDV-16461-original-ticket.md) (Aug 27 – present comment thread)
- **Status:** draft

## 1. Story Matrix

| Component | Framework Language | Story Sentence |
| --- | --- | --- |
| Motivation | *A [user type] doesn't want [undesired outcome].* | A Client Access user doesn't want to mistake a collection that was chosen for them for a collection they chose themselves. |
| Context + Intent | *While [context], they want to [action].* | While looking at the collection shown for a file they're adding, they want to tell whether it was picked automatically or by a person. |
| Obstacle + Desired Action | *Except that [obstacle], so they want to [action to rectify].* | Except that an automatically-picked collection looks identical to a manually-picked one, so they want some heads-up that this value was predetermined and can be adjusted. |
| Resolution | *Now they'll be able to [positive outcome].* | Now they'll be able to trust at a glance whether a collection needs their attention or was already handled correctly. |

## 2. Revision Matrix

No component carried design words (dropdown, asterisk, tooltip, chip, label) — the matrix sentences stay at the level of user motivation and outcome. No revision needed.

| Component | Before | Issue | After |
| --- | --- | --- | --- |
| — | — | none found | unchanged |

## 3. Delivery Acceptance Statement (DAS)

*We know this story is considered complete when:*
- A user can tell, without opening or interacting with the collection choice, whether the currently-shown collection was set automatically or set by a person (themselves or a prior action).
- The moment a user manually sets or changes the collection for a file, that file's collection no longer reads as automatically-set.
- The signal is visible everywhere the automatically-set collection can appear — wherever job story 01's auto-choice shows up.
- The signal does not change what collection is selected or otherwise alter the add/approve/recategorize behavior — it only communicates provenance of the current value.

## 4. Concatenated Story

A Client Access user doesn't want to mistake a collection that was chosen for them for a collection they chose themselves. While looking at the collection shown for a file they're adding, they want to tell whether it was picked automatically or by a person. Except that an automatically-picked collection looks identical to a manually-picked one, so they want some heads-up that this value was predetermined and can be adjusted. Now they'll be able to trust at a glance whether a collection needs their attention or was already handled correctly.

## 5. Final Review Matrix

| Original Sentence | Issue/Observation | Refined Sentence |
| --- | --- | --- |
| A Client Access user doesn't want to mistake a collection that was chosen for them for a collection they chose themselves. | none | (unchanged) |
| While looking at the collection shown for a file they're adding, they want to tell whether it was picked automatically or by a person. | none | (unchanged) |
| Except that an automatically-picked collection looks identical to a manually-picked one, so they want some heads-up that this value was predetermined and can be adjusted. | none | (unchanged) |
| Now they'll be able to trust at a glance whether a collection needs their attention or was already handled correctly. | none | (unchanged) |
| A user can tell, without opening or interacting with the collection choice, whether the currently-shown collection was set automatically or set by a person (themselves or a prior action). | none | (unchanged) |
| The moment a user manually sets or changes the collection for a file, that file's collection no longer reads as automatically-set. | none | (unchanged) |
| The signal is visible everywhere the automatically-set collection can appear — wherever job story 01's auto-choice shows up. | none | (unchanged) |
| The signal does not change what collection is selected or otherwise alter the add/approve/recategorize behavior — it only communicates provenance of the current value. | none | (unchanged) |

## 6. User Story

A Client Access user doesn't want to mistake a collection that was chosen for them for a collection they chose themselves. While looking at the collection shown for a file they're adding, they want to tell whether it was picked automatically or by a person. Except that an automatically-picked collection looks identical to a manually-picked one, so they want some heads-up that this value was predetermined and can be adjusted. Now they'll be able to trust at a glance whether a collection needs their attention or was already handled correctly.

## Acceptance Criteria

- A user can tell, without opening or interacting with the collection choice, whether the currently-shown collection was set automatically or set by a person (themselves or a prior action).
- The moment a user manually sets or changes the collection for a file, that file's collection no longer reads as automatically-set.
- The signal is visible everywhere the automatically-set collection can appear — wherever job story 01's auto-choice shows up.
- The signal does not change what collection is selected or otherwise alter the add/approve/recategorize behavior — it only communicates provenance of the current value.

## Open Questions

1. **Concrete signal mechanism.** Shaye Lankford agreed in principle (ClickUp, "Yesterday" per capture / prior to 2026-09-02) that the default should be visually distinguished, but has not named a mechanism and asked Dustin to propose one. Two candidate directions exist in the ticket changelog (Plan A — session-scoped marker that clears on deliberate re-selection; Plan B — always-on marker independent of selection history), plus a decision-support prototype (`PRDV-16461-default-collection-prototype.html`) built to let Shaye compare them directly. Owner: Dustin → Shaye, product decision. **Explicitly deferred by the user to right before full implementation** — this story stays `draft` and does not block job story 01 or the spec's core mapping work.
2. **Whether the marker persists through a deliberate re-pick of the same value.** If a user re-selects the same default collection on purpose, does it still read as "automatic," or does any deliberate interaction clear the marker regardless of resulting value? Tied to Open Question 1 — resolves with the same product decision.

## Story log

- **2026-09-03 — Phase 0 (draft):** Drafted from the Aug 27–present ClickUp UX-clarification thread, split out from job story 01 because this concern (a) was raised after the core AC were already settled, (b) has no confirmed mechanism, and (c) the user has explicitly said the UI signal can be decided last-minute before full implementation, so it must not gate the rest of the ticket. Both open questions are genuine product decisions, not code-discoverable facts — carried forward rather than resolved here.
