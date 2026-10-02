# Why these changes — atlas/INT-138

> The living "Why" of this ticket. It was created in Phase 1, is updated every phase, and is finalized at close. It stays high-level: scenarios live in the testing-implementation doc, and the point-in-time classification lives in the [investigation report](./investigations/INT-138-investigation.md).

## Problem class (the core — what are we actually solving?)

**A gap in the audit events sent from existing write paths.** This is not a new log or a new view.

- The Europa audit log, its storage, its event-type filter and the `FILE` resource type already exist.
- What is missing is the **event**:
  - When a file's deliverable type or collection is set or changed, nothing records the type, the collection, who did it or when.
  - On the recategorize path, nothing is recorded at all.

This is the same class as PRDV-12578, which added the approve and unapprove audits. See report §1.

## The code at the root (what/where is the problem)

- `callisto-back-end` `src/granting-client-access/domain/services/recategorize-deliverable-files-service/recategorize-deliverable-files.service.ts:24-44`: `apply` calls the transaction script and returns. **No audit is dispatched.** The TS writes only the Dione outbox.
- `callisto-back-end` `src/proceedings/domain/sub-domains/proceeding-file-audit/domain/aggregators/proceeding-file-audit.aggregator.ts`: has no categorize dispatch method.
- `callisto-back-end` `src/audits/constants.ts:10-19`: `AUDIT_EVENT_TYPE` has no categorize literal.
- `callisto-back-end` `.../proceeding-file-to-audit.converter.ts:18-37`: the resource state carries only `{path, bucket, fileName}`. Neither type nor collection ever reaches the event.
- `atlas-front-end` `src/europa/utils/constants.ts:3-30`: the literal list behind the dropdown, and the chip colours.
- `atlas-front-end` `.../SearchDataGrid.vue:309-324`: the multi-line path render applies only to `PERMISSIONS_UPDATED`.

The full trace is in report §5.

## The problems we're solving

1. Categorizing a file's deliverable type leaves no audit record of what was set, by whom, or when.
2. Ops cannot narrow the audit log to categorization actions, because no such event type exists.

## Why-log (append per phase; label each entry)

### Phase 1 — 2026-09-23 — [NEW UNDERSTANDING]

- **Obvious:**
  - A new event type is needed.
  - The `FILE` resource type already exists in Callisto, Europa's filter values, and Atlas's `resourceTypes`.
- **Not obvious:**
  - **Europa's backend needs no change.** `type` is a free string throughout, and the filter is an exact, case-sensitive match. The "Event Type drop down in Europa" is a hand-maintained list in `atlas-front-end`. The ticket's wording suggests Europa work, and the evidence says otherwise.
  - **Recategorize is completely silent**, while approve and upload already audit (`APPROVED`, `CREATED`). Those audits predate deliverable types, so they carry no categorization.
  - **One event per file is forced by the display.** Europa's projection shows only resource `[0]` of an event, so a batch event would hide every file but the first.
  - **"Filepath" today is the S3 key.** The readable file name is shown separately, in the Resource column.
  - **Casing:** all 8 existing types are past-tense upper case and displayed raw. The ticket says "Categorize".
- **Noise / discarded:**
  - The Dione outbox `file.recategorized.v1` event looked relevant at first. It is a separate channel (Planet Portal sync), not the Europa audit.
  - PRDV-16192's `[0]` collapse fix stays out of scope, because one event per file makes it moot here.
- **Assumptions logged:** decisions D1–D8 (report §10). The two that gate the spec are D1 (which paths emit) and D2 (the literal and its display).

### Phase 2 — 2026-09-23

- Nothing moved. The report, coverage ledger, diagrams and test plan were emitted from the approved plan without changing the class or the root code.

### Phase 3 — 2026-09-23 to 2026-09-25 — [COURSE CHANGE]

- **What changed after learning more:** the recon had recommended leaving unapprove and the system Planet Summary path unlogged, to keep the change small. The user's correction ("this is an audit process") reversed that. An audit trail records every change, so all six paths that set, change or clear a categorization now emit (LD-009).
  - The same principle settled the literal: the ticket's own `CATEGORIZE` (LD-010).
  - It also ruled out backfill (LD-011): a reconstructed record isn't an audit record.
- **New understanding:** "who" on the system path means the person who requested the summary, captured when the request is made (LD-012). The categorization itself runs outside any user request, so its IP and user agent are `system` (LD-014).
- **Discarded:** the "which paths" question itself, which the purpose of the feature answered.

### Phase 5 — 2026-09-25 — [NEW UNDERSTANDING]

- **The spec held on behavior.** Implementation forced three wording or structure corrections, none of which changed behavior (see the testing-implementation doc, scenarios 4, 5 and 7):
  - the requester converter moved from the service into the context assembler, because services may not import converters;
  - one unresolved-id warning per repository kind instead of per id;
  - `Array.from` instead of spreading a `Set`, because of the ES5 target.
- **Tooling finding:** callisto's convention checks don't scan on Windows (concern C12).
- **Code change + why:**
  - the audit core gains a categorization event (missing capability);
  - five Client Access services and the Planet Summary completion now send it (missing capability; for recategorize it was a coverage gap);
  - Atlas lists and renders it (missing capability).

## Changes made — categorized (filled as implementation locks; subject to update)

_Not yet. Filled from Phase 5._

## Why it shipped together

_Phase 6._

## Scope

_Phase 6. The provisional boundary is report §3 non-goals._

## Net

_Phase 6._

## Verified

_Phase 6._
