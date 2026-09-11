# Job story 02 — Default-selection visual indicator

- **Ticket:** PRDV-16461
- **Project:** atlas
- **Date:** 2026-09-03
- **Source:** [PRDV-16461-original-ticket.md](../PRDV-16461-original-ticket.md) (Aug 27 – present comment thread)
- **Status:** accepted (Phase 5, 2026-09-08)

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

1. ~~**Concrete signal mechanism.**~~ **CLOSED 2026-09-08.** Ops named it: a **badge**, shown **only until the user changes the collection**. That selects Plan A (session-scoped marker) over Plan B (always-on). Recorded as LD-016, which supersedes LD-014.
2. ~~**Whether the marker persists through a deliberate re-pick of the same value.**~~ **CLOSED 2026-09-08.** "Only until changed" resolves it: any deliberate selection retires the badge, including re-picking the same value. The badge means "we chose this for you", so a deliberate choice ends it regardless of the resulting value.

## Story log

- **2026-09-08 — Phase 5 (ACCEPTED):** Ops named the mechanism — *"I like badge and only until changed"* — relayed by the user with a Figma mockup. Both open questions closed by that one decision; recorded as **LD-016**, which supersedes LD-014's out-of-scope ruling.
  - **No criterion changed.** All four were written to be mechanism-agnostic ("can tell... whether it was set automatically", "no longer reads as automatically-set"), so a badge satisfies them as written. This is what holding the story at `draft` bought: the yardstick was already correct and only needed a mechanism to become falsifiable.
  - **Criterion 4 constrains the implementation and held:** the badge communicates provenance only, and does not alter validity or submission. It composes with LD-005 rather than fighting it.
  - **Criterion 3 scope note:** the signal appears in the closed field (the emphasised pill) and on menu rows (the quiet marker on the base-case collection). It does not appear in recategorize, because no default is applied there — consistent with "wherever job story 01's auto-choice shows up", since there is no auto-choice to mark.
  - **Process miss, recorded:** the implementation landed before this story was accepted or LD-014 superseded. A reviewer flagged the code as contradicting approved scope, and was right to — the decision existed but the record did not.
- **2026-09-03 — Phase 3 (carried forward, deliberately NOT accepted):** Story 01 was accepted this phase; this one is **held at `draft` on purpose**. Its two open questions are genuine Product decisions with no code-discoverable answer, and the user has deferred the mechanism to just before implementation. Accepting a story whose acceptance criteria still depend on an unnamed mechanism would make the yardstick unfalsifiable.
  - **Owner carried forward:** Shaye Lankford / Product, for the signal mechanism and whether a deliberate re-pick of the same value still reads as defaulted.
  - **One boundary locked by LD-014:** whatever the indicator turns out to be, it must **not** affect validity or submission. A defaulted collection is already a valid selection (LD-005); the indicator communicates provenance only. That constraint is now fixed even though the mechanism is not.
  - Not gating this ticket. Implementation of story 01 proceeds without it.
- **2026-09-03 — Phase 1/2 (no change):** Reviewed against the investigation. **Nothing moved.** Both open questions remain genuine product decisions with no code-discoverable answer, so neither could be closed by evidence the way story 01's were. Confirmed the story stays independent of story 01: the interaction change story 01 gained (an explicit track-selection state for generic DnD) alters *when* a default appears, not whether a defaulted value is distinguishable from a chosen one — this story's criteria are unaffected by it. Still `draft`, still deferred to just before implementation per user direction, still not gating the spec.
- **2026-09-03 — Phase 0 (draft):** Drafted from the Aug 27–present ClickUp UX-clarification thread, split out from job story 01 because this concern (a) was raised after the core AC were already settled, (b) has no confirmed mechanism, and (c) the user has explicitly said the UI signal can be decided last-minute before full implementation, so it must not gate the rest of the ticket. Both open questions are genuine product decisions, not code-discoverable facts — carried forward rather than resolved here.
