# {{PROJECT}} pending decisions

This is the central queue for choices {{PROJECT}} intentionally postpones. It covers product
behavior, libraries, storage, adapters, and acceptance thresholds. **Accepted** decisions
belong in [`ROADMAP.md`](ROADMAP.md) under *Decisions resolved*; this file holds only what is
unresolved or deferred.

It lives beside the code on purpose, so implementation cannot bypass a deferred choice.

## How to use this register

1. Add a row **before** an unresolved choice is hidden inside implementation.
2. Continue with the documented safe default only while the decision trigger has not been
   reached.
3. When a trigger is reached, pause, gather the named evidence, and ask if the choice
   materially affects product direction, data safety, cost, or lock-in.
4. On resolution, mark the row `Resolved`, record the result and date, and move the accepted
   decision into `ROADMAP.md`. Do not delete its history from this file.
5. A library may not be added merely because it is the popular choice. It must own a declared
   boundary and be replaceable behind it.

Statuses are `Open`, `Deferred`, `Evidence needed`, or `Resolved`.

## Active decision queue

| ID | Phase | Status | Decision | Safe default until trigger | Decision trigger / required evidence |
| --- | --- | --- | --- | --- | --- |
| `XXX-001` | _phase_ | Open | _The question, stated so that either answer is a real option._ | _What the code does in the meantime — a behavior, not "TBD". If there is no safe default, the choice is not actually deferrable._ | _The concrete event that forces the decision, and what evidence must exist by then. "When we get to it" is not a trigger._ |

## Resolved decisions

| ID | Resolved | Decision | Record |
| --- | --- | --- | --- |
| _`XXX-001`_ | _{{DATE}}_ | _What was decided_ | _Link to the `ROADMAP.md` row or architecture doc that now owns it_ |
