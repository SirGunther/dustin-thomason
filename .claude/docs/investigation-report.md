# Investigation Report: <short title>

> **What this is:** the delivered results of running the `investigate` method — findings and recommendation, plus the plan for what happens next. Use it as the shared reference for future discussions and decisions.
> **What this is not:** a plan *to* investigate. By the time this report exists, the investigating is done.
>
> **Reading order ≠ fill order.** The report reads verdict-first (bottom line up front), but it is filled in dependency order: instances → class → contract → root cause (class re-check) → solution → validation → verdict last.
>
> Copy this per investigation to `docs/investigations/<id>-<slug>.md`. Sections 0–10 are the findings; Section 11 is the emitted plan. Keep it updated as the source of truth while the work proceeds.

## Metadata
- **Status:** draft | investigating | planned | in-progress | done
- **Disposition:** proceed | proceed with conditions | blocked | rejected | needs more investigation
- **Date:**
- **Owner:**
- **Location:** `docs/investigations/<id>-<slug>.md`
- **Ticket:** <ClickUp link>
- **Domain:** software | workflow | policy | process | ...
- **References / evidence:** <primary sources — code paths, commits, docs, transcripts, clauses>

---

## 0. Verdict (bottom line up front — written last, read first)
<One paragraph: current viability, the strongest path forward, and — explicitly — what this is NOT yet (e.g. "viable, but not a production approval").>

- **Strongest path:**
- **Not yet proven / not approved:**

## 1. Problem class
> The single highest-leverage call in this report — everything below is checked against it. The class is derived from real instances (Section 2), held as provisional, and re-confirmed against root-cause evidence (Section 5). Get it wrong and the whole report solves the wrong problem.

- **Class the request assumed** (implied by how it was framed):
- **Confirmed class** (derived from instances, re-checked against root cause):
- **Reframed?** no — because: <argue why the assumed class held> | yes → from **<assumed>** to **<confirmed>**, triggered by: <what evidence flipped it, and at which step>
- **What the confirmed class implies** (how the solution space changes vs. the assumed class):

*Why this matters: a request framed as "data access — who can reach which systems" can turn out to be a knowledge-management problem — where the data lives and how people discover it. Same symptoms, different class, completely different solution. The framing was aimed at the wrong target, and everything downstream inherited the error.*

## 2. Problem statement (the raw facts — collected before classification)
- **Named instances** (specific people/cases, blocked right now, on real tasks):
- **One sentence** (a stranger could confirm or deny):
- **Distinct problems** (don't merge them):
- **Urgency** (date or trigger event when it bites next):
- **Wedge** (smallest reusable issue *within the confirmed class* that opens the space):

## 3. The contract (locked before any solutioning)
### Acceptance criteria
| Criterion | Status | What's needed to close it |
|-----------|--------|---------------------------|
|           | covered / needs-proof / documented / gap |  |

### Non-goals / out of scope
- <what this explicitly does NOT cover, and why — this is what prevents scope churn later>

## 4. What changed since the request was created
- **Shifted from:** <original framing> → **to:** <current framing>
  *(If the class itself changed, lead with that and point to Section 1 — it's the most important kind of shift.)*
- **What that buys us:**
- **What it still needs to prove:**

## 5. Why it exists
- **Origin traced to:**
- **Evidence** (primary-source pointers):
- **Class re-check:** held | flipped → <what the root-cause evidence showed; if flipped, confirm the wedge and acceptance criteria were redone>

## 6. Alternatives considered
> Pre-answers the future "why didn't we just X?"

| Alternative | Rejected because |
|-------------|------------------|
|             |                  |

## 7. Solution & stress-test
- **Proposed solution:**
- **Solves the confirmed class** (not the assumed one, not just this occurrence)?
- **Scale:**
- **Generalization** (abstract, or overreach?):
- **Fit** (conventions / philosophy):
- **Adjacent issues** (fix now vs. follow-up + effort tradeoff):
- **Sufficiency** (covers the pain that convened this, or a corner of it?):
- **Feedback speed** (how fast reality tells us we're wrong):
- **Happy-path story** (30 seconds — who does what, without whom):

## 8. Assumptions ledger
> Populated throughout the investigation as claims are made — not backfilled at the end. Each is a falsifiable claim with a test. "Confirmed directionally" still owes proof of performance, accuracy, and parity.

- **Claim:** <…>
  - **Status:** open | confirmed | confirmed directionally | revised | refuted
  - **Confirm/revise by:** <method / test>
- **Claim:** <…>
  - **Status:**
  - **Confirm/revise by:**

## 9. Validation plan
**Happy path**
- <the sequence that should work, step by step>

**Negative paths**
- <what must fail *visibly* rather than corrupt silently>
- <volume / limit / threshold breaches>
- <removed or trimmed dependencies proven non-required>
- <timing / refresh / latency bounds that must hold>

## 10. Decisions, recommendation & open variables
- **Decisions** (settled):
- **Recommendation** (what to do, in order):
- **Sequencing & gates:** <what proceeds first; what stays gated behind which proof or artifact — e.g. "Do not start Y until X proves parity, performance, ownership, and security controls">

### Open variables to collect
> Logged as they surfaced during the investigation. Assign an owner where possible.

- [ ] <value / mapping / threshold / owner / boundary> — owner:
- [ ] <…> — owner:

---

## 11. Plan — Next steps
*This is the emitted plan. The agent works it from here; check items off as they land.*

### Handoff table
| Action | Owner | Done-when (falsifiable) |
|--------|-------|-------------------------|
|        |       |                         |

### Checklist
#### Investigation
- [x] This report (Sections 0–10)

#### Project Spec
- [ ] Draft open questions / unknowns
- [ ] Create project spec

#### Development
- [ ] Create new branch
- [ ] Begin implementation

#### Testing & Validation
- [ ] Test and validate implementation locally

#### Deploy & PR
- [ ] Push to GitHub
- [ ] Deploy to sandbox + verify there
- [ ] Open PR
- [ ] Address feedback / wait for approval
- [ ] Merge to main
- [ ] Deploy to test

#### Ticket Closeout
- [ ] Update ClickUp: merged to test
- [ ] Set ticket to Ready for QA
- [ ] (If bug) Document root cause / why it slipped through

---

## 12. Definition of done (investigation gate)
Don't move past investigation until each is answered:
- [ ] **Class derived from instances, re-confirmed against root cause — and "reframed?" answered with a justification either way (Section 1)**
- [ ] Problem in one plain sentence
- [ ] Named blocked instance
- [ ] Date it bites next
- [ ] Wedge + why it's reusable within the confirmed class
- [ ] Acceptance criteria + non-goals locked before the solution was proposed
- [ ] Alternatives recorded with rejection reasons
- [ ] 30-second happy-path story
- [ ] Metric that proves it works + how fast it arrives
- [ ] Verdict + disposition stated
- [ ] Open variables each have an owner
- [ ] Tracked action with a falsifiable done-when
