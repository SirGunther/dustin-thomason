# {{PROJECT}} roadmap

This file tracks feature scope, completed work, product decisions, and future
considerations. Chronological history lives in the canonical record at `{{DOCS_PATH}}`
(see [`DOCS.md`](DOCS.md)); choices deliberately left open live in
[`DECISIONS-PENDING.md`](DECISIONS-PENDING.md).

_One-line description of {{PROJECT}}._

**Current phase:** _e.g. POC 1 — look and feel only._

---

## Completed

_Checked items only. Something belongs here once it works, not once it is written._

- [x] _First landed capability_

## Confirmed working — do not regress

_Reviewed hands-on {{DATE}}. Called out as working; must survive later work._

- [x] _Item the user explicitly approved_

---

## _Feature area_

_One section per coherent area. Mix landed and pending items so the shape of the area is
visible in one place._

- [x] _Landed_
- [ ] _Next_

---

## Decisions resolved

Settled. Do not reopen without new evidence.

| Decision | Resolved | Rationale |
| --- | --- | --- |
| _What was decided, stated as the rule it now is_ | {{DATE}} | _Why, and what evidence settled it. A rationale that cannot be checked later is not a rationale._ |

---

## Deferred

_Wanted, deliberately not now. Different from `DECISIONS-PENDING.md`: these are known
features whose timing is deferred, not open questions about direction._

- [ ] _Item_

## Optional future hardening

- [ ] _Item that is not on the path but is worth recording_

---

## Build constraints

_Not tasks. Constraints on how the tasks above get built. Anything cheap to honor now and
expensive to retrofit belongs here rather than in a checklist, because a checklist item gets
ticked once and a constraint has to hold every time._

**_Constraint._** _Why it exists, and what honoring it looks like in this codebase._
