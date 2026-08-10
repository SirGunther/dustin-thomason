> **UNFILLED SHELL — staged at Phase 2, body written at Phase 5.**
> Headings and placeholders only. Do not fill before the change is implemented and verified: scope can still move at Phases 3–4, and the Description/Test Evidence must reflect what was actually built and observed, not what was planned. Test evidence is assembled from `testing/PRDV-16312-testing-implementation.md`.

# PRDV-16312: Emit file.created.v1 on client-deliverable upload-complete

_(Provisional title — confirm the subject line at Phase 5 against the final diff; keep the descriptive part to five to seven words after the ticket prefix.)_

## ClickUp

<!-- https://app.clickup.com/t/43227262/PRDV-16312 -->

<!-- Note for the PR author: the ClickUp description asks for two events. It is stale.
     The wiki spec and design doc specify one. Say so explicitly in the Description
     so a reviewer comparing the diff against ClickUp does not read the single
     emission as an incomplete implementation. See concern C2. -->

## Description

<!-- Fill at Phase 5. Frame as Problem → Requirement → Solution.
     Must state: one event, not two; why (design Q15/Q21 — collection identity travels
     inline via deliverableCollectionId + deliverableCollectionValue, Dione upserts);
     and that no created-vs-found branch was added because the value is sent regardless.
     Rationale for changes discovered during testing belongs here, never as a source comment. -->

## Test Evidence

<!-- Fill at Phase 5 from testing/PRDV-16312-testing-implementation.md — scenario-first.
     Include the AC6 dev-queue observation (test-plan M1) or state plainly that it was
     blocked and why. Do not substitute a passing unit suite for AC6. -->

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | | | | |
| lint | | | | |
| tests | | | | |

## Commit hash

<!-- Single fenced block containing only the 40-character hash. -->

```
```

## Checklist

<!-- Reconcile against the repo's .github/pull_request_template.md at Phase 5 —
     this shell is derived from the workflow playbook, not from that template. -->

- [ ] Tests added or updated (name the suite)
- [ ] Regression impact stated, with the isolating boundary named
- [ ] API docs — checked; record the surface examined even when unchanged
- [ ] Tooling gates run in order: audit → lint → tests
- [ ] Changelog session log written before the commit
- [ ] Acceptance criteria walked against what shipped
