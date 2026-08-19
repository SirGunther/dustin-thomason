# Job stories — atlas/PRDV-16403

Source: [PRDV-16403-original-ticket.md](../PRDV-16403-original-ticket.md)

Drafted at Phase 0 of the orchestrated run (see [orchestration.md](../orchestration.md)) from the verbatim request alone; **all three revised at Phase 1** against the recon findings. These own *what done means* for this ticket; the Phase 3 spec cites them and does not amend them. They are `accepted` at Phase 3, once their open questions close against the locked decisions.

| # | Story | User type | Criteria | Open questions | Status | File |
| --- | --- | --- | --- | --- | --- | --- |
| 01 | Reference the recorded notes without leaving the access work | Ops Atlas user | 6 | 3 open · 2 closed | draft | [file](./PRDV-16403-job-story-01-reference-rb-notes.md) |
| 02 | Tell "nothing recorded" apart from "nothing arrived" | Ops Atlas user | 6 | 3 open · 1 closed | draft | [file](./PRDV-16403-job-story-02-absent-vs-unavailable.md) |
| 03 | Read the case remarks the way they were written | Ops Atlas user | 5 | 3 open · 2 closed | draft | [file](./PRDV-16403-job-story-03-remarks-read-as-written.md) |

Status vocabulary: `draft` / `accepted` / `superseded (see dnu/)`.

## Why the request split into three

The ClickUp request reads as one story, but it carries three distinct undesired outcomes, and a compound motivation is the signal to split:

- **01** — the Ops user has to break off and open RB to learn what cautions exist. The problem is *reach*.
- **02** — the Ops user cannot tell "no caution recorded" from "the cautions did not load", and acts on the wrong one. The problem is a *false negative*, and it is the only one of the three where the failure is silent.
- **03** — the case remarks arrive as formatted content that can either lose its emphasis or carry something that acts rather than reads. The problem is *fidelity, safely*.

Criteria 01 could plausibly be met while 02 and 03 both fail, which is the test that they are genuinely separate.

**Phase 1 vindicated the split.** Read as one story, 02's empty-state criteria look like polish. Read alone, they are the ticket's sharpest correctness problem — see below.

## Phase 1 reconcile — what moved

**Seventeen criteria, all unchanged.** Nothing the recon surfaced invalidated one. Five of the twelve original open questions closed; one was rewritten because its premise was false; one new question was added.

| Question | Outcome at Phase 1 |
| --- | --- |
| OQ-01.4 — does reopening the same contact refetch? | **Closed by evidence.** Yes, every open — the overlay unmounts on close and remounts on open, so `refetchOnMount: 'always'` fires on the fresh mount. |
| OQ-01.1 — is a distinct permission needed? | **Split.** Fact half closed: two gates already exist (the GCA flag at the parent, and `ProceedingsReadAuthGuard` on the sibling read endpoint). Decision half carried as **D3**. |
| OQ-02.3 — whole-set or per-item failure? | **Closed by evidence.** Partial failure is not representable — one endpoint, one query, one response. |
| OQ-03.1 — which formatting must survive? | **Closed by user ruling (2026-08-18):** out of scope. Recorded, not deleted. |
| OQ-03.2 — do images and tables occur? | **Closed** against the request's own text. |
| OQ-01.2 — ship the case fields readable-but-empty, or wait? | **Rewritten — its premise was false.** PRDV-16391 had already merged, so the columns exist. The surviving question points at **PRDV-16392** and is narrower: not *whether to ship*, but *what to display*. Now **D1**. |
| OQ-03.5 — pass a DOMPurify config at all? | **New at Phase 1.** The repo has one `v-html` site passing no config, and a rule discouraging `v-html`. Now **D6**. |

## Open questions at a glance — nine, mapped to locked decisions

| Question | Stories | Decision | Owner |
| --- | --- | --- | --- |
| What do the case fields display while PRDV-16392 is unshipped? The system **cannot** distinguish "RB holds nothing" from "never mapped" — both are `null` — so the specified "No warning info" copy would state something false in every environment. | 01, 02 | **D1** | Product |
| Does the new read endpoint carry `ProceedingsReadAuthGuard`? Recommendation: yes, mirroring the guarded sibling. | 01 | **D3** | Dustin |
| Does a fetch failure block completing the access work? The epic spec says non-blocking; the **verbatim request is silent**, so it was never imported as a criterion. | 02 | **D4** | Product / Dustin |
| Is there agreed styling for Case Remarks at all — and does "50% grey" mean the `0.38` token the overlay actually uses? | 01, 03 | **D5** | Product / design |
| Should a DOMPurify config be passed, given no in-repo precedent and a rule discouraging `v-html`? | 03 | **D6** | Dustin |

D2 (400 vs 404) and D7 (unblocking manual verification) are implementation and process decisions with no criterion behind them; they live in the [recon-and-plan](../investigations/PRDV-16403-recon-and-plan.md) §7 rather than here.

A **talking points list** — grouped for UI/UX, Backend and Frontend — is available on request.
