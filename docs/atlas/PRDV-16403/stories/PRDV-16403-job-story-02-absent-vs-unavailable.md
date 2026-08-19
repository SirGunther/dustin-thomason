# Job story 02 — Tell "nothing recorded" apart from "nothing arrived"

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
| Motivation | *A [user type] doesn't want [undesired outcome].* | An Ops Atlas user doesn't want to read silence as "no caution recorded" when the truth is that the cautions never arrived. |
| Context + Intent | *While [context], they want to [action].* | While setting up a client contact's access to a proceeding's deliverables, they want to tell an empty record apart from a failed one. |
| Obstacle + Desired Action | *Except that [obstacle], so they want to [action to rectify].* | Except that a blank section looks exactly like a broken one, so they want the empty state and the error state spelled out in different words. |
| Resolution | *Now they'll be able to [positive outcome].* | Now they'll be able to trust an empty answer as genuinely empty, and know to try again when it isn't. |

---

## Revision Matrix

The story must be agnostic to system design.

| Component | Before | Issue named | After |
| --- | --- | --- | --- |
| Obstacle + Desired Action | Except that a blank **section** looks exactly like a broken one, so they want the **empty state** and the **error state** spelled out in different words. | Solution-speak — "section", "empty state", and "error state" are all interface vocabulary; they name a design rather than the user's problem. | Except that having nothing to report and failing to fetch look identical from where the Ops user sits, so they want to be told plainly which of the two happened. |
| Context + Intent | *(unchanged)* | No design words present. | — |
| Motivation | *(unchanged)* | No design words present. | — |
| Resolution | *(unchanged)* | No design words present. | — |

---

## Delivery Acceptance Statement (DAS)

*We know this story is considered complete when:*

- When no caution is recorded, the Ops user is told there is no warning information rather than left looking at nothing.
- When no case remarks are recorded, the wording the Ops user reads differs from the caution wording, because Ops users refer to warnings and remarks as different things.
- The Ops user can still tell which of the four the message belongs to, even when it has nothing to report.
- When the notes cannot be fetched, the Ops user is told they failed to load, and is never shown an empty result standing in for a failure.
- The failure message takes the place of the notes rather than sitting beside a misleadingly blank set of them.

---

## Concatenated Story

An Ops Atlas user doesn't want to read silence as "no caution recorded" when the truth is that the cautions never arrived. While setting up a client contact's access to a proceeding's deliverables, they want to tell an empty record apart from a failed one. Except that having nothing to report and failing to fetch look identical from where the Ops user sits, so they want to be told plainly which of the two happened. Now they'll be able to trust an empty answer as genuinely empty, and know to try again when it isn't.

---

## Final Review Matrix

| Original Sentence | Issue / Observation | Refined Sentence |
| --- | --- | --- |
| An Ops Atlas user doesn't want to read silence as "no caution recorded" when the truth is that the cautions never arrived. | No issue found — names a concrete false conclusion, not a feeling. | *(unchanged)* |
| While setting up a client contact's access to a proceeding's deliverables, they want to tell an empty record apart from a failed one. | No issue found. | *(unchanged)* |
| Except that having nothing to report and failing to fetch look identical from where the Ops user sits, so they want to be told plainly which of the two happened. | No issue found — states the confusion without naming an interface element. | *(unchanged)* |
| Now they'll be able to trust an empty answer as genuinely empty, and know to try again when it isn't. | No issue found — observable: the Ops user can say which case they are in. | *(unchanged)* |
| When no caution is recorded, the Ops user is told there is no warning information rather than left looking at nothing. | No issue found — checkable against a record with an empty caution. | *(unchanged)* |
| When no case remarks are recorded, the wording the Ops user reads differs from the caution wording, because Ops users refer to warnings and remarks as different things. | Wordiness — the reason belongs in the story, not the criterion. | The wording for empty case remarks differs from the wording for an empty caution. |
| The Ops user can still tell which of the four the message belongs to, even when it has nothing to report. | Vague phrasing — "which of the four" does not say how. | Each of the four stays labelled with what it is, including when it has nothing to report. |
| When the notes cannot be fetched, the Ops user is told they failed to load, and is never shown an empty result standing in for a failure. | Wordiness — two criteria in one line. | When the notes cannot be retrieved, the Ops user is told they failed to load. |
| *(split from the line above)* | A failure must never be indistinguishable from an empty record — that is the whole story, so it earns its own line. | A failure to retrieve them is never presented as an empty record. |
| The failure message takes the place of the notes rather than sitting beside a misleadingly blank set of them. | Wordiness. | The failure message stands in place of the four, not alongside them. |

---

## User Story

An Ops Atlas user doesn't want to read silence as "no caution recorded" when the truth is that the cautions never arrived. While setting up a client contact's access to a proceeding's deliverables, they want to tell an empty record apart from a failed one. Except that having nothing to report and failing to fetch look identical from where the Ops user sits, so they want to be told plainly which of the two happened. Now they'll be able to trust an empty answer as genuinely empty, and know to try again when it isn't.

---

## Acceptance Criteria

- When no caution is recorded, the Ops user is told there is no warning information rather than left looking at nothing.
- The wording for empty case remarks differs from the wording for an empty caution.
- Each of the four stays labelled with what it is, including when it has nothing to report.
- When the notes cannot be retrieved, the Ops user is told they failed to load.
- A failure to retrieve them is never presented as an empty record.
- The failure message stands in place of the four, not alongside them.

---

## Open Questions

Revised at Phase 1. One closed by evidence, one reframed onto the real cause, two carried as decisions.

| # | Question | Status | Owner |
| --- | --- | --- | --- |
| OQ-02.1 | Does a failure to retrieve the notes stop the Ops user from finishing the access work, or is it non-blocking? | **Open — decision D4.** The parent-epic spec asserts non-blocking; the verbatim request is silent, so it was never imported as a criterion. Phase 1 added a structural reason to care: `<Overlay :loading="isLoading">` currently aggregates only the left column's queries, so folding warnings-loading into it would block the whole access UI and defeat the intent whichever way D4 lands. | Product / Dustin |
| OQ-02.2 | Is there a way to retry without abandoning the access work? | **Open — decision D4b**, folded under D4. | Product |
| OQ-02.3 | When some of the four load and others fail, is that a whole-set failure or a per-item one? | **Closed — resolved by evidence (Phase 1).** A partial failure is **not representable**: one endpoint, one query, one response, so all four succeed or fail together. The request's singular failure copy is correct, and no per-item error state is needed. | — |
| OQ-02.4 | Do the case caution and case remarks read as "nothing recorded", when in truth the data may never have been replicated? | **Open — decision D1, reframed.** As drafted this pointed at missing columns; **PRDV-16391 has merged, so the columns exist.** The real cause is **PRDV-16392** (DMS CDC mapping): until it ships, both case fields return `null`. Phase 1 proved the system **cannot distinguish** the two states — the DTO has exactly one representation for *"RB holds nothing"* and *"never mapped"* — so telling them apart is a change, not a lookup. Applying the "No warning info" wording today would state something false in every environment. | Product |

## Story log

### 2026-08-18 — Phase 1 (Recon and plan) — revised in place (status stays `draft`)

**Criteria: unchanged, and one of them got stronger.** *"A failure to retrieve them is never presented as an empty record"* was drafted as a guard against a plausible mistake. Phase 1 found it is the ticket's central defect risk: two of the four fields will legitimately be empty in every environment until PRDV-16392 ships, so the empty state is not an edge case here — it is the **default**, and the criterion is what stops it being read as truth.

**Open questions moved:** OQ-02.3 **closed** by evidence — a partial failure cannot occur. OQ-02.4 **reframed** off the merged PRDV-16391 and onto PRDV-16392, and upgraded from a wording question to a documented structural limitation (F1). OQ-02.1 and OQ-02.2 carried as D4.

**This story is why the split was worth doing.** Read as one story with story 01, the empty-state criteria look like polish. Read on their own, they are the ticket's sharpest correctness problem: the system cannot tell "nothing recorded" from "nothing mapped", and the copy the request specifies would assert the first while the second is true.


### 2026-08-18 — Phase 0 (Capture) — drafted

Drafted from the verbatim request alone. Split from the single ClickUp story: the request's empty-state and error-state criteria carry a different undesired outcome from *having the notes at all* — mistaking absence of data for absence of a warning is a false negative the Ops user acts on. Shaye Lankford's 2026-08-17 ClickUp comment is the origin of both the distinct empty wording ("They're thought of and referenced differently by different users") and the failure copy, so the two belong in one story.

OQ-02.1 is worth flagging: the parent-epic spec asserts the error must be non-blocking, but that assertion is **not** in the verbatim request, so it is carried as a question here rather than imported as a criterion. Phase 1 should reconcile it. OQ-02.4 is a defect risk the request does not see — recorded, not decided.
