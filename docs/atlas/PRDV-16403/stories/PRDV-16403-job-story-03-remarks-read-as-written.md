# Job story 03 — Read the case remarks the way they were written

| Field | Value |
| --- | --- |
| Ticket | PRDV-16403 |
| Project | atlas |
| Parent epic | PRDV-14828 — View Warnings in Access Manager |
| Drafted | 2026-08-18 |
| Status | `draft` |
| Source | [PRDV-16403-original-ticket.md](../PRDV-16403-original-ticket.md) |

> Drafted at Phase 0 from the verbatim request alone; **revised at Phase 1** against the recon findings — see the Story log at the foot of this file.

---

## Story Matrix

| Component | Framework Language | Story Sentence |
| --- | --- | --- |
| Motivation | *A [user type] doesn't want [undesired outcome].* | An Ops Atlas user doesn't want the case remarks arriving stripped of the emphasis that tells them which part matters. |
| Context + Intent | *While [context], they want to [action].* | While reading a case's remarks before granting a client access, they want the emphasis whoever wrote them put there to survive the trip. |
| Obstacle + Desired Action | *Except that [obstacle], so they want to [action to rectify].* | Except that the remarks come across from RB as raw markup that can carry executable content, so they want it rendered in a sanitized wrapper. |
| Resolution | *Now they'll be able to [positive outcome].* | Now they'll be able to read the remarks the way they read in RB, and trust that reading them cannot harm anything. |

---

## Revision Matrix

The story must be agnostic to system design.

| Component | Before | Issue named | After |
| --- | --- | --- | --- |
| Obstacle + Desired Action | Except that the remarks come across from RB as **raw markup** that can carry **executable content**, so they want it **rendered in a sanitized wrapper**. | Solution-speak — "raw markup", "executable content", and "rendered in a sanitized wrapper" are all implementation vocabulary, and the last one names the mechanism rather than the need. | Except that the remarks were written with formatting that can also hide instructions meant to run rather than be read, so they want to see them as written with anything that could act on its own taken out first. |
| Motivation | *(unchanged)* | No design words present. | — |
| Context + Intent | *(unchanged)* | No design words present; "RB" is the external system of record. | — |
| Resolution | *(unchanged)* | No design words present. | — |

---

## Delivery Acceptance Statement (DAS)

*We know this story is considered complete when:*

- The emphasis whoever wrote the remarks applied — colour, bolding, size — is still there when the Ops user looks at them.
- Anything in the remarks that would act on its own rather than simply be read is gone before the Ops user sees any of it.
- Remarks that arrive with no formatting at all still read as ordinary text.
- The remarks stay inside the room they were given and do not disturb the rest of the access work.
- Nothing the remarks carry can reach out and change how the rest of Atlas looks or behaves.

---

## Concatenated Story

An Ops Atlas user doesn't want the case remarks arriving stripped of the emphasis that tells them which part matters. While reading a case's remarks before granting a client access, they want the emphasis whoever wrote them put there to survive the trip. Except that the remarks were written with formatting that can also hide instructions meant to run rather than be read, so they want to see them as written with anything that could act on its own taken out first. Now they'll be able to read the remarks the way they read in RB, and trust that reading them cannot harm anything.

---

## Final Review Matrix

| Original Sentence | Issue / Observation | Refined Sentence |
| --- | --- | --- |
| An Ops Atlas user doesn't want the case remarks arriving stripped of the emphasis that tells them which part matters. | No issue found — the undesired outcome is concrete and checkable. | *(unchanged)* |
| While reading a case's remarks before granting a client access, they want the emphasis whoever wrote them put there to survive the trip. | No issue found — experiential register, no design words. | *(unchanged)* |
| Except that the remarks were written with formatting that can also hide instructions meant to run rather than be read, so they want to see them as written with anything that could act on its own taken out first. | Wordiness — long, though every clause is load-bearing; shortening it loses either the risk or the desired action. | Except that the same formatting can hide instructions meant to run rather than be read, so they want to see the remarks as written with anything that could act on its own taken out first. |
| Now they'll be able to read the remarks the way they read in RB, and trust that reading them cannot harm anything. | Emotional abstraction — "trust" is a feeling; the checkable part is that nothing acts. | Now they'll be able to read the remarks the way they read in RB, with nothing in them able to act on the reader. |
| The emphasis whoever wrote the remarks applied — colour, bolding, size — is still there when the Ops user looks at them. | No issue found — directly checkable against a remark carrying each. | *(unchanged)* |
| Anything in the remarks that would act on its own rather than simply be read is gone before the Ops user sees any of it. | No issue found — observable by feeding in a remark that tries to act and confirming it does not. | *(unchanged)* |
| Remarks that arrive with no formatting at all still read as ordinary text. | No issue found. | *(unchanged)* |
| The remarks stay inside the room they were given and do not disturb the rest of the access work. | Vague phrasing — "the room they were given" is unstated. | However wide or long the remarks are, they do not push the rest of the access work out of place. |
| Nothing the remarks carry can reach out and change how the rest of Atlas looks or behaves. | Wordiness, and it overlaps the "act on its own" line above. | Formatting carried by the remarks changes only the remarks, not anything else the Ops user is looking at. |

---

## User Story

An Ops Atlas user doesn't want the case remarks arriving stripped of the emphasis that tells them which part matters. While reading a case's remarks before granting a client access, they want the emphasis whoever wrote them put there to survive the trip. Except that the same formatting can hide instructions meant to run rather than be read, so they want to see the remarks as written with anything that could act on its own taken out first. Now they'll be able to read the remarks the way they read in RB, with nothing in them able to act on the reader.

---

## Acceptance Criteria

- The emphasis whoever wrote the remarks applied — colour, bolding, size — is still there when the Ops user looks at them.
- Anything in the remarks that would act on its own rather than simply be read is gone before the Ops user sees any of it.
- Remarks that arrive with no formatting at all still read as ordinary text.
- However wide or long the remarks are, they do not push the rest of the access work out of place.
- Formatting carried by the remarks changes only the remarks, not anything else the Ops user is looking at.

---

## Open Questions

Revised at Phase 1. One closed by user ruling, one closed by the request's own text, two carried as decisions.

| # | Question | Status | Owner |
| --- | --- | --- | --- |
| OQ-03.1 | Which formatting must survive, exactly? The survives-list and stripped-list are not complementary. | **Closed — user ruling, 2026-08-18.** Not a gap. Formatting the spec does not name is **out of scope** for this iteration and is not to be reopened. Recorded as a closed question rather than deleted, so a later reader can see it was raised and decided. | — |
| OQ-03.2 | Do images and tables actually occur in this data? | **Closed — answered by the request itself.** *"No images or tables are expected in the remarks field (confirmed with stakeholders)"*, and *"anything that survives sanitization renders as-is with no dedicated image/table styling support"* is a scope statement, not a contradiction. Nothing further is owed. | — |
| OQ-03.3 | When a remark's own colour makes it unreadable against Atlas, whose styling wins? | **Open — decision D5**, folded with the styling question. | Product |
| OQ-03.4 | Is there any agreed styling for the remarks at all? | **Open — decision D5**, merged with OQ-01.3. Phase 1 added a second, smaller instance of the same class: the empty-state criterion says *"italic, 50% grey"*, but the in-overlay precedent is `rgba($schemes-on-surface, 0.38)` and the italic precedents elsewhere use `$schemes-on-surface-variant` with no alpha — so "50%" matches no existing token. | Product / design |
| OQ-03.5 | **New at Phase 1.** Should a DOMPurify config be passed at all? | **Open — decision D6.** The repo has exactly **one** `v-html` and **one** `DOMPurify.sanitize` (`NotificationBody.vue` L32-43), passing **no** config, and `.cursor/rules/planetdepos-quasar.mdc` L214 says *"Avoid `v-html` when possible"*. Passing an allowlist would set new precedent in a repo whose only rule on the subject discourages the technique. | Dustin |

## Story log

### 2026-08-18 — Phase 1 (Recon and plan) — revised in place (status stays `draft`)

**Criteria: unchanged.** All five survive the recon intact. What changed is how much is known about *proving* two of them.

**Open questions moved:** OQ-03.1 **closed** by the user's ruling — the survives/stripped asymmetry is out of scope, and the closure is recorded rather than the question deleted, so the reasoning stays visible. OQ-03.2 **closed** against the request's own text. OQ-03.3 and OQ-03.4 carried as D5. **OQ-03.5 added** — whether to pass a DOMPurify config at all (D6).

**One criterion is harder to satisfy than it looked, and one is easier.** *"However wide or long the remarks are, they do not push the rest of the access work out of place"* now has a known obstacle: `.rightColumn` is `overflow: hidden`, so long content **clips silently** rather than scrolling, and satisfying this needs a new inner element with `flex: 1; min-height: 0; overflow-y: auto` (F6). Conversely *"anything that would act on its own… is gone"* is closer to free than assumed — bare `DOMPurify.sanitize` already strips every construct the request names as forbidden, which is what makes D6 a real question rather than a formality.

**This story owns the wedge.** Phase 1 named the sanitised-render plus empty/error-state panel as the wedge for the whole ticket, because it is the only part with **no in-repo precedent and no prior investigation by any ticket** — a grep across all of `docs/` found zero prior coverage of sanitization, DOMPurify, `v-html` or XSS as a behaviour anywhere.


### 2026-08-18 — Phase 0 (Capture) — drafted

Drafted from the verbatim request alone. Split from the single ClickUp story because the remarks are the only one of the four that arrives as formatted content, and reading them faithfully is a different outcome from having them present at all — the request devotes two of its criteria and a whole ClickUp exchange (Derrick Dieso, 2026-08-11, enumerating survives/stripped) to it.

OQ-03.1 is the sharpest one: the survives/stripped lists in the request are not complementary, so a literal reading silently drops formatting nobody decided to drop. Recorded as a question rather than resolved, per the rule against deciding by inference — it needs real remarks data to settle, which Phase 1 should look for.
