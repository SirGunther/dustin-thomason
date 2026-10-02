# INT-141 — Audit log entries for AJSF proceeding creation

## Ticket

- **Ticket:** INT-141 _(link not captured)_
- **Repo:** `callisto-back-end`, `europa-back-end`, `atlas-front-end`
- **Branch:** `INT-141` _(not cut yet; cut from `INT-138` in all three repos, LD-011)_
- **PR:** _(link when opened)_
- **Artifacts:** [INT-141/](INT-141/) — ticket body [INT-141.md](INT-141/INT-141.md), [locked decisions](INT-141/specs/INT-141-locked-decisions.md), [spec](INT-141/specs/INT-141-spec.md)

---

## Requirements (verbatim)

> # Audit log - create a proceeding (AJSF)
>
> As an Ops manager, I want to be able to review an audit log of key actions related to Client Access, so that I can see the "who, what, when" for these critical functions.
>
> * * *
>
> ## Acceptance Criteria
>
> -   Ops can view a log in Europa for AJSF proceeding creation
> -   The log displays the following details:
>     -   user info
>     -   date/time
>     -   **AJSF proceeding creation** actions taken
> -   Event Type for this action is: **Created**
> -   The **Proceeding** Resource type is added to the Resource Type drop down in Europa
>     -   (this should already exist, it's just not visible)
> -   Path format:
>     -   Path: \[path\] (date/job ID/proceeding ID)
>     -   Proceeding Name: \[proceeding name\]
> **Dev Note:**
>
> Two endpoints exist for this.
>
> **AJSF** - jobSubmissionService.createProceedings (use this one for this ticket)
>
> **File Navigator** - proceedingsService.createProceedings

---

## Context

- Builds on INT-138 (Europa labelled-path branch and `toDisplayValue`; Atlas path splitter and multi-line template), which is not on `main`. See [INT-138-changelog.md](INT-138-changelog.md).
- Sibling tickets: INT-139 (`RECATEGORIZE`, [INT-139-changelog.md](INT-139-changelog.md)) and INT-140 (File Navigator proceeding creation, out of scope here; same aggregator and transaction script).
- **User direction (2026-09-29):** stay within scope; the work extends what has already begun.
- **User direction (2026-09-29, carried from INT-139):** ignore docs in the other repos; code is the source of truth.

---

## Plans

| Added | Plan (path or link) | Status | One-line approach |
| ----- | ------------------- | ------ | ----------------- |
| 2026-09-29 | [INT-141/specs/INT-141-locked-decisions.md](INT-141/specs/INT-141-locked-decisions.md) | `active` | AJSF `createProceedings` sends one `CREATED`/`PROCEEDING` record per proceeding with path `<MMYYYY>/<jobId>/<proceedingId>`; europa-back-end builds `Path \| Proceeding Name`; atlas-front-end lists `PROCEEDING` and renders the two lines |
| 2026-09-29 | [INT-141/specs/INT-141-spec.md](INT-141/specs/INT-141-spec.md) | `active` | Implementation spec from the ledger (write-spec skill; shaped on the INT-138 spec in callisto `docs/specs/`). Best-effort delivery, locked (LD-016). To move into callisto `docs/specs/` when `INT-141` is cut |

---

## Attempt history

- 2026-09-29: the first investigation report claimed europa-back-end would reject a resource with `oldState: null`. A runtime check of the real schema refuted it (ledger E8); LD-005 was revised to rest on the `CREATED` convention only.
- 2026-09-29 (ledger review): four ledger decisions did not hold against code. LD-012 covered only SQS send errors, not dispatcher and assembler rejections after the commit (E18). LD-014 accepted a display a proceeding name could spoof with a second `Path` field (E20). LD-005 kept the proceeding name in `resourcePath` and `resourceBucket` (E21). The path-builder class was left to a spec that did not exist (E22). All four revised; best-effort delivery raised as gate G-11 (E19).

---

## Session log

_Newest first._

### 2026-09-29T21:36:59Z — dustin-thomason (spec review reconciled)

- **Summary:** applied the spec review. Locked best-effort delivery (ledger LD-016, gate G-11 closed by the review) and replaced the spec's open question with a Known limitations section; guaranteed delivery is tracked separately under INT-138 concern C2. Added an acceptance-criteria trace, including date/time (Callisto `createdAt`, kept by Europa's Mongoose timestamps, shown in the Atlas Date column), and a Date-column assertion to the manual test. Removed the `path` + `oldValue` converter case. Replaced the INT-138 dependency path with the GitHub link on `origin/INT-138`.
- **Plan used:** the spec row above.
- **Files:** `docs/atlas/INT-141/specs/INT-141-spec.md`, `docs/atlas/INT-141/specs/INT-141-locked-decisions.md`, this changelog.
- **Commits:** none. No app-repo code changed.

### 2026-09-29T21:28:15Z — dustin-thomason (spec)

- **Summary:** wrote the INT-141 implementation spec from the ledger with the write-spec skill. It follows callisto `docs/specs/README.md` conventions and the INT-138 spec's Part A/B/C shape. It adds the class code, module wiring, spec-test cases, neighbors that must not change, rollout, manual end-to-end steps and an estimate. Checked the design against callisto's enforced dependency rules (`services-no-converters`; `domain-module-boundary` allows cross-module `*.port.*` imports).
- **Plan used:** the ledger row above; new spec row added.
- **Files:** `docs/atlas/INT-141/specs/INT-141-spec.md`, the ledger's open items, this changelog.
- **Commits:** none. No app-repo code changed.
- **Notes:** the spec is written on G-11 option (a) and carries it as Q-1. It stays in dustin-thomason until the `INT-141` branch exists (INT-139 precedent). Its callisto home is `docs/specs/`, which that README names for any ticket with back-end work.

### 2026-09-29T21:02:18Z — dustin-thomason (ledger review reconciled)

- **Summary:** checked each point of the ledger review against code. Confirmed all four issues and the gap. Revised LD-005 (`resourcePath` = proceeding path, `resourceBucket` = `''`), LD-007 and LD-014 (two-segment split for `CREATED` + `PROCEEDING` rows, so a name cannot add a field), and LD-012 (the service catches and logs every post-commit audit error). Added LD-015 (`JobSubmissionProceedingAuditAssembler`, location and API) and named the LD-008 port. Opened G-11 for the delivery guarantee, tied to INT-138 concern C2.
- **Plan used:** the ledger row above.
- **Files:** `docs/atlas/INT-141/specs/INT-141-locked-decisions.md`, this changelog.
- **Commits:** none. No app-repo code changed.
- **Notes:** the spoof and two-segment behaviour were checked by running the Atlas splitter logic on sample names (ledger E20).

### 2026-09-29T20:45:17Z — dustin-thomason (investigation, locked decisions)

- **Summary:** investigated INT-141 against the INT-138 branches. Confirmed the existing proceeding audit chain (`RENAMED`), `PROCEEDING` and `CREATED` literals, and the INT-138 display pieces. Re-verified each finding from current code with evidence (E1–E17) and wrote the locked-decision ledger (LD-001 to LD-014).
- **Plan used:** none before this session; the ledger row above is new.
- **Files:** `docs/atlas/INT-141/specs/INT-141-locked-decisions.md`, this changelog.
- **Commits:** none. No app-repo code changed.
- **Notes:** E8 refuted the earlier `oldState: null` claim by validating against the real europa-back-end `AuditEventSchema` (no database; ts-node script in the session scratchpad, not in any repo). E9 records the port-versus-direct-injection counter-evidence behind LD-008.

---

## Current state (as of 2026-09-29)

- Locked decisions written and reconciled against the ledger and spec reviews of 2026-09-29. Every gate is locked; best-effort delivery (LD-016), with guaranteed delivery tracked separately under INT-138 concern C2.
- Spec written and revised (`INT-141/specs/INT-141-spec.md`); not yet in callisto `docs/specs/`.
- No `INT-141` branch in any repo. No code written.
