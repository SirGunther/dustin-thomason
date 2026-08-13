> **UNFILLED SHELL — staged at Phase 2, body written at Phase 5.**
> Headings and placeholders only. Do not fill before the change is implemented and verified: scope can still move at Phases 3–4, and the Description/Test Evidence must reflect what was actually built and observed, not what was planned. Test evidence is assembled from `testing/PRDV-16313-testing-implementation.md`.

# PRDV-16313: Emit file.renamed.v1 on deliverable rename

_(Provisional title — confirm the subject line at Phase 5 against the final diff; keep the descriptive part to five to seven words after the ticket prefix.)_

## ClickUp

<!-- https://app.clickup.com/t/43227262/PRDV-16313 -->

<!-- Note for the PR author: unlike the sibling PRDV-16312, the ClickUp acceptance criteria
     and the wiki spec's acceptance criteria are IDENTICAL — verified at Phase 1. There is no
     criteria-level conflict to explain away.

     What DOES need explaining is the wiki spec's Technical Design, which the diff departs
     from on three counts. A reviewer comparing the diff against the spec will otherwise read
     each departure as an error. Cover all three in the Description, not here. -->

## Description

<!-- Fill at Phase 5. Frame as Problem → Requirement → Solution.

     MUST state, because a reviewer holding the spec will otherwise flag each as a mistake:

     1. WHY THE EMIT SITE MOVED. The spec says "inject CLIENT_ACCESS_OUTBOX into the rename
        transaction script." No such script exists in granting-client-access; the only rename TS
        lives in proceedings, is shared by three HTTP surfaces, has no AuthUser, and would be a
        module cycle. AND the obvious adaptation — a new RenameDeliverableFileTS delegating to
        ProceedingAggregator — fails `transaction-scripts-no-aggregators` at severity: 'error'.
        Hence an assembler. Name the fitness rule by name; it is not obvious.

     2. WHY THERE IS NO EXPLICIT TAG CHECK. The spec asks for one, justified by "the rename
        endpoint may serve non-deliverable files as well." It does not —
        ProceedingFileMustBeDeliverableValidator has 403'd them since commit 4d284978
        (PRDV-15776). AC3 is met structurally. Say so, and say that the literal form was
        considered and rejected as a provably unreachable branch (locked decision D3 —
        this is the one item the reviewer may reasonably overrule).

     3. WHY A TRANSACTION APPEARS THAT THE SPEC NEVER MENTIONED. Without it, a failed outbox
        write leaves the file renamed and no event emitted — permanently, silently, with design
        Q5 forbidding the reconciler that would repair it. That is the exact defect this ticket
        exists to remove. Also state that the audit SQS dispatch deliberately stayed OUTSIDE
        the boundary, and why (not rollbackable; would newly let an SQS outage roll back renames).

     ALSO CALL OUT:
     - Zero files touched under src/proceedings/** or src/proceeding-job-submission/**. That is
       the neighbour-protection proof, not a claim — the shared TS keeps four dependencies and
       no outbox port, so surfaces B and C are incapable of emitting.
     - The deterministic-id collision (concern C7): a duplicate id silently UPDATEs rather than
       raising. DO NOT assert this as fact unless report assumption A3 was demonstrated against
       real Postgres. If it was not, say "read from library source, not observed."
     - The two recorded-not-fixed defects, with links: C1 (AJSF rename of a deliverable — no
       user, no validator, no audit, no event; ruled out of scope on workflow grounds) and
       C2 (extensionless filenames get the old name appended — pre-existing; this ticket makes
       it visible to Dione without causing it).
     - That job story 01 criterion 1 is knowingly not fully met because of C1, and was NOT
       reworded to fit the build.

     Rationale for changes discovered during testing belongs here, never as a source comment
     (build guardrails §7). -->

## Test Evidence

<!-- Fill at Phase 5 from testing/PRDV-16313-testing-implementation.md — scenario-first.

     The manual evidence is a SQL result grid, not a screenshot of Atlas: nothing changes in
     the UI, and a screenshot of the unchanged screen proves nothing. Test plan M-1 through M-4.

     Name the three load-bearing steps and their outcomes:
       M-1 the feature works at all;
       M-3 the no-op rename emits NOTHING (quietest failure mode — a spurious event asserting
           a database write that never happened);
       M-4 a submission rename emits ZERO rows (proves the emission did not leak onto the
           shared transaction script).

     EC-5 is blocked by design (sub-millisecond interleaving is not practically reproducible) —
     say so with its residual risk; do not silently drop it.

     Do not substitute a passing unit suite for the manual outbox-row observation. -->

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | | | | |
| lint | | | | |
| architecture | | | | |
| tests | | | | |

<!-- The architecture row is NOT boilerplate on this ticket. Two severity: 'error' rules
     selected this design, and the assembler shape is legal by READING the rules rather than
     executing them. This gate is what turns report assumption A6 from "confirmed
     directionally" into confirmed. Report the exact command. -->

## Commit hash

<!-- Single fenced block containing only the 40-character hash. -->

```
```

## Checklist

<!-- Reconcile against the repo's .github/pull_request_template.md at Phase 5 —
     this shell is derived from the workflow playbook, not from that template. -->

- [ ] Tests added or updated (name the suite)
- [ ] Regression impact stated, with the isolating boundary named
- [ ] API docs — checked; record the surface examined even when unchanged (expected: no HTTP contract change — route, method, DTO, status and auth decorators all untouched; say so, naming what was checked)
- [ ] Tooling gates run in order: audit → lint → **architecture** → tests
- [ ] Changelog session log written before the commit
- [ ] Acceptance criteria walked against what shipped — including the two that are knowingly not met (job story 01 criterion 1 via C1; criteria 1–4 observability via the RabbitMQ descope)
- [ ] Spec reviewer responded before product code was written (`P5.spec-approved`) — or a waiver recorded naming who authorised it and the residual risk
