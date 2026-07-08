# Power Platform to AWS Investigation

Status: Draft investigation package  
Date prepared: 2026-07-06  
Primary artifact: Decision memo

This folder implements the Power Platform to AWS investigation plan for ADB, OJB, and the Lagrange/AWS/Postgres fallback.

## Contents

- [Decision memo](decision-memo.md): recommendation, decision criteria, and track-by-track findings.
- [Source matrix](source-matrix.md): internal and vendor sources used or still needed.
- [Architecture map](architecture-map.md): current state, near-term recovery, and fallback diagrams.
- [Risk register](risk-register.md): severity, evidence, mitigation, and owners.
- [OJB go/no-go checklist](ojb-go-no-go-checklist.md): reconnection readiness and rollback gates.
- [Stakeholder interview questions](stakeholder-interview-questions.md): questions for facts that cannot be proven from docs.

## Handling Notes

- No cutover or production changes are included here. This is fact-finding and decision support only.
- Credential-like strings and private connector URLs found in source notes were intentionally not copied into these artifacts.
- Items marked "Needs confirmation" require stakeholder or console validation before use in production decisions.
