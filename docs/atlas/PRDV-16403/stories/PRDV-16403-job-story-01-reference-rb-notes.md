# Job story 01 — Reference the recorded notes without leaving the access work

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
| Motivation | *A [user type] doesn't want [undesired outcome].* | An Ops Atlas user doesn't want to hand a client access to deliverables without knowing the cautions already recorded against that case, that person, and their firm. |
| Context + Intent | *While [context], they want to [action].* | While setting up a client contact's access to a proceeding's deliverables, they want to read the cautions recorded against the case, the contact, and the firm, plus whatever remarks the case carries. |
| Obstacle + Desired Action | *Except that [obstacle], so they want to [action to rectify].* | Except that those notes only live in RB, so they want them shown in the same panel they're granting access from. |
| Resolution | *Now they'll be able to [positive outcome].* | Now they'll be able to grant access with the recorded cautions in front of them, without opening RB. |

---

## Revision Matrix

The story must be agnostic to system design.

| Component | Before | Issue named | After |
| --- | --- | --- | --- |
| Obstacle + Desired Action | Except that those notes only live in RB, so they want them shown in the same **panel** they're granting access from. | Solution-speak — "panel" names an interface element and fixes the design before the story is agreed. | Except that reaching those notes today means breaking off to pull up RB, so they want them at hand while they set the access up. |
| Context + Intent | While setting up a client contact's access to a proceeding's deliverables, they want to read the cautions recorded against the case, the contact, and the firm, plus whatever remarks the case carries. | Wordiness — two clauses doing one job. | While setting up a client contact's access to a proceeding's deliverables, they want to read every caution and remark already recorded against that case, that contact, and that contact's firm. |
| Motivation | *(unchanged)* | No design words present. | — |
| Resolution | *(unchanged)* | No design words present; "RB" is the external system of record, not a design element of ours. | — |

---

## Delivery Acceptance Statement (DAS)

*We know this story is considered complete when:*

- The case caution, the contact caution, the firm caution, and the case remarks are all readable while access is being set up for that contact on that proceeding.
- They come in one fixed order every time: case caution, then contact caution, then firm caution, then case remarks.
- Each caution is the one recorded for that exact thing — the case behind the proceeding being viewed, the contact being granted access, and that contact's firm.
- What the Ops user reads is what RB holds as of the moment they open the access work, not what it held earlier in their session.
- The Ops user cannot change any of it from Atlas.
- A note too long for the room it has can still be read all the way through, and reading it does not push the access work out of reach.

---

## Concatenated Story

An Ops Atlas user doesn't want to hand a client access to deliverables without knowing the cautions already recorded against that case, that person, and their firm. While setting up a client contact's access to a proceeding's deliverables, they want to read every caution and remark already recorded against that case, that contact, and that contact's firm. Except that reaching those notes today means breaking off to pull up RB, so they want them at hand while they set the access up. Now they'll be able to grant access with the recorded cautions in front of them, without opening RB.

---

## Final Review Matrix

| Original Sentence | Issue / Observation | Refined Sentence |
| --- | --- | --- |
| An Ops Atlas user doesn't want to hand a client access to deliverables without knowing the cautions already recorded against that case, that person, and their firm. | No issue found — names the user, the undesired outcome, and why it matters. | *(unchanged)* |
| While setting up a client contact's access to a proceeding's deliverables, they want to read every caution and remark already recorded against that case, that contact, and that contact's firm. | No issue found. | *(unchanged)* |
| Except that reaching those notes today means breaking off to pull up RB, so they want them at hand while they set the access up. | No issue found — experiential phrasing ("pull up", "at hand"), no design words. | *(unchanged)* |
| Now they'll be able to grant access with the recorded cautions in front of them, without opening RB. | No issue found — observable: someone can confirm the notes were readable without RB. | *(unchanged)* |
| The case caution, the contact caution, the firm caution, and the case remarks are all readable while access is being set up for that contact on that proceeding. | No issue found. | *(unchanged)* |
| They come in one fixed order every time: case caution, then contact caution, then firm caution, then case remarks. | Wordiness — "every time" is carried by "fixed". | The four come in a fixed order: case caution, contact caution, firm caution, case remarks. |
| Each caution is the one recorded for that exact thing — the case behind the proceeding being viewed, the contact being granted access, and that contact's firm. | Vague phrasing — "that exact thing" leaves the pairing unstated. | The case caution belongs to the case behind the proceeding being viewed, the contact caution to the contact being granted access, and the firm caution to that contact's firm. |
| What the Ops user reads is what RB holds as of the moment they open the access work, not what it held earlier in their session. | No issue found — observable: change a value, reopen, and check it moved. | *(unchanged)* |
| The Ops user cannot change any of it from Atlas. | Non-observable outcome — "cannot change" states an absence with nothing to check. | The notes are read-only to the Ops user: there is no way to change any of them from Atlas. |
| A note too long for the room it has can still be read all the way through, and reading it does not push the access work out of reach. | Wordiness, and "the room it has" is vague. | A note longer than the space available can still be read in full, and reading it does not displace the access work. |

---

## User Story

An Ops Atlas user doesn't want to hand a client access to deliverables without knowing the cautions already recorded against that case, that person, and their firm. While setting up a client contact's access to a proceeding's deliverables, they want to read every caution and remark already recorded against that case, that contact, and that contact's firm. Except that reaching those notes today means breaking off to pull up RB, so they want them at hand while they set the access up. Now they'll be able to grant access with the recorded cautions in front of them, without opening RB.

---

## Acceptance Criteria

- The case caution, the contact caution, the firm caution, and the case remarks are all readable while access is being set up for that contact on that proceeding.
- The four come in a fixed order: case caution, contact caution, firm caution, case remarks.
- The case caution belongs to the case behind the proceeding being viewed, the contact caution to the contact being granted access, and the firm caution to that contact's firm.
- What the Ops user reads is what RB holds as of the moment they open the access work, not what it held earlier in their session.
- The notes are read-only to the Ops user: there is no way to change any of them from Atlas.
- A note longer than the space available can still be read in full, and reading it does not displace the access work.

---

## Open Questions

Revised at Phase 1. Two closed by evidence, one rewritten because its premise was false, two carried as genuine decisions.

| # | Question | Status | Owner |
| --- | --- | --- | --- |
| OQ-01.1a | Is there already a permission gate on reading these notes? | **Closed — resolved by evidence (Phase 1).** Two exist. The overlay is entirely behind `IS_GRANTING_CLIENT_ACCESS_ENABLED` at the parent (`ProceedingDetailPage.vue` L755), and the closest sibling read endpoint carries `@UseGuards(ProceedingsReadAuthGuard)`. A redundant flag check inside the overlay would break `AccessManagerOverlay.spec.ts`. | — |
| OQ-01.1b | Given those, does the new read endpoint carry `ProceedingsReadAuthGuard`? | **Open — decision D3.** The guarded sibling is precedent; the grants sibling the ticket names is unguarded. Recommendation: yes. | Dustin |
| OQ-01.2 | ~~Case caution and case remarks have no data behind them yet — ship readable-but-always-empty, or wait?~~ **Premise was false.** PRDV-16391 merged; all three `cases` columns exist. Rewritten: what do the case fields show while **PRDV-16392** (DMS mapping) is unshipped and they therefore read `null`? | **Open — decision D1.** Narrower than as drafted: not *whether to ship*, but *what to display*. | Product |
| OQ-01.3 | Is the case remarks styling agreed anywhere? | **Open — decision D5**, merged with OQ-03.4. The request says the design omits Case Remarks and to confirm with Product. | Product |
| OQ-01.4 | Does reopening for the *same* contact re-read RB, or only switching contact? | **Closed — resolved by evidence (Phase 1).** Yes, every open. The overlay renders under `v-if="isGcaEnabled && accessManagerContact"` and `handleAccessManagerAfterLeave` nulls the contact, so it **unmounts on close and remounts on open**; `refetchOnMount: 'always'` fires on the fresh mount regardless of `staleTime`. | — |

## Story log

### 2026-08-18 — Phase 1 (Recon and plan) — revised in place (status stays `draft`)

**Criteria: unchanged.** Nothing the recon surfaced invalidated a criterion. The freshness criterion — *"what RB holds as of the moment they open the access work"* — is now known to be **structurally satisfied** by the overlay's unmount/remount cycle rather than by cache configuration, which changes how it will be *proven*, not what it requires.

**Open questions moved:** OQ-01.4 **closed** by evidence (F2). OQ-01.1 **split** — the fact half closed (two gates already exist), the decision half carried as D3. OQ-01.2 **rewritten**: its premise (*"no data behind them yet"* because the columns were missing) was **false** — PRDV-16391 had already merged. The surviving question is narrower and now points at PRDV-16392. OQ-01.3 carried as D5.

**Why the rewrite rather than a close:** the question was asking the right thing for the wrong reason. Dropping it would have lost a real problem — two of four fields will read empty in every environment until the DMS mapping ships — so it was re-pointed rather than deleted.


### 2026-08-18 — Phase 0 (Capture) — drafted

Drafted from the verbatim request alone, per the orchestrate Phase 0 obligation. Split out of the single ClickUp story because the request carries three distinct undesired outcomes; this one owns *having the notes at hand at all*. The absent-versus-unavailable problem went to [story 02](./PRDV-16403-job-story-02-absent-vs-unavailable.md) and the remarks-fidelity problem to [story 03](./PRDV-16403-job-story-03-remarks-read-as-written.md). Four open questions carried, none decided by inference.
