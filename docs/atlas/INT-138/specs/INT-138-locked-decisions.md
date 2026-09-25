# Locked decisions — atlas/INT-138

> The locked-decision ledger for INT-138, per `agents/docs/qa-to-spec-traceability.md`. A decision here is no longer an open option. A later conflict is resolved by the latest explicit user correction, unless the user reopens the decision.
> Sources: [original ticket](../INT-138-original-ticket.md), [investigation report](../investigations/INT-138-investigation.md) (§8, §10, §13), [job story 01](../stories/INT-138-job-story-01-categorization-audit.md), and this Phase 3 grill.

## Question gates

### Resolved without asking (the answer already exists)

| Gate | Proposed question | Existing answer check | Current behavior evidence | Outcome |
| --- | --- | --- | --- | --- |
| G-01 (D6) | Is deliverable-type categorization all of INT-138? | **Answered by the ticket.** Every acceptance criterion names only categorization: "Ops can view a log in Europa for **deliverable type categorization**"; "A new Event Type is created for this action: **Categorize**". "Key actions related to Client Access" is the story's motivation, not a criterion | Grants, rename, approve and unapprove already emit audits (report F2) | Not asked → **LD-001** |
| G-02 (D3) | Should the Path show old→new values? | **Answered by the ticket.** The path format gives exactly one value per line: "Deliverable Type: \[deliverable type\]", "Collection: if applicable, \[collection\], if not, "N/A"" | Every FILE event already stores `oldState` and `newState`, and Europa shows `newState.path` first (`search-audit-events-paginated.transaction.script.ts:78-82`) | Not asked → **LD-002** |
| G-03 (D4) | Does "Filepath" mean the storage key or something readable? | **Implied by existing behavior.** Every FILE event's Path today is `file.filePath`, the storage key. The readable name is already its own Resource column. The ticket's "Filepath: \[file path\]" names that same value | `proceeding-file-to-audit.converter.ts:18-37`; `auditEventColumns.ts:30-46` | Not asked → **LD-003** |
| G-04 (D7) | What is the target date? | **Doesn't affect the design.** The ticket states none, and no spec section depends on a date | — | Not asked → **LD-004** |
| G-05 | One event per file, or one per batch? | **Answered by evidence plus criterion 7.** Europa shows only resource `[0]` | `search-audit-events-paginated.transaction.script.ts:57, 98-100` | Not asked → **LD-005** |
| G-06 | Dispatch inside or after the transaction? | **Implied by existing behavior.** Upload, approve and unapprove all dispatch after the TS returns, and the depcruise rule forbids a TS importing an aggregator | report §13; `transaction-scripts.rules.ts` | Not asked → **LD-006** |
| G-07 | Does Europa change? | **Answered by evidence.** It has no enum, an exact-match filter, and passes `newState.path` through | report F3, §8 | Not asked → **LD-007** |
| G-08 | Where does the spec live? | **Answered by repo rule.** Any ticket with backend work goes in `callisto-back-end/docs/specs/`, FE section included | `atlas-front-end/docs/specs/README.md:5-12`; `callisto-back-end/docs/specs/README.md` | Not asked → **LD-008** (the project folder is still asked, see Q4) |

### Asked (genuine decisions)

| Gate | Question | What happened | Outcome |
| --- | --- | --- | --- |
| Q1 (D1) | Which actions should log a Categorize record? It was offered with options that left some categorization changes (unapprove, the system path) unlogged | **User correction, 2026-09-23:** "this is an audit process, are you kidding me right now?" This question should not have been asked, because the feature's purpose already answers it. An audit trail records **every** change, so excluding any action that changes a file's categorization contradicts the requirement. **Gate miss:** the "existing answer check" should have looked at what the ticket is (an audit log of "who, what, when"), not only at its literal wording | Not a preference → **LD-009**. Two more questions answered by the same principle were withdrawn before asking → **LD-010**, **LD-011** |

## Locked-decision ledger

| ID | Locked decision | Source | Supersedes or rejects | Spec destination |
| --- | --- | --- | --- | --- |
| LD-001 | INT-138's scope is **deliverable-type categorization only**. Other Client Access actions are out of scope | Ticket acceptance criteria (G-01) | Closes story OQ-09 / report D6 | Spec §Scope, §Non-goals |
| LD-002 | The Path **shows the categorization as it is after the action**, one value per line, in the ticket's format. `oldState.path` carries the prior categorization in the same format (or `Deliverable Type: N/A`, `Collection: N/A` when there was none) so it's stored for later use, but it isn't displayed | Ticket "Path format" (G-02); existing `oldState`/`newState` convention | Rejects old→new display. Closes story OQ-03 / report D3 | Spec §Converter, §Europa (unchanged) |
| LD-003 | `Filepath` = `file.filePath` (the storage key), matching every existing FILE audit event | Existing behavior (G-03) | Rejects a readable/derived path. Closes story OQ-05's decision half / report D4 | Spec §Converter |
| LD-004 | No target date. The design doesn't depend on one | Ticket is silent (G-04) | Closes report D7 | Ledger note only |
| LD-005 | **One audit event per categorized file**, each with exactly one FILE resource. No multi-resource batch events | Evidence (G-05); story criterion 7 | Rejects the batch-event alternative (report §6) | Spec §Dispatch |
| LD-006 | Dispatch happens in the **service, after the transaction script returns**, never inside the TS | Existing behavior plus depcruise rule (G-06) | Rejects the in-transaction alternative (report §6) | Spec §Dispatch |
| LD-007 | **Europa is unchanged.** No enum, DTO, projection or swagger change | Evidence (G-07) | Rejects "Europa builds the path" (report §6) | Spec §Europa |
| LD-008 | The spec lives in `callisto-back-end/docs/specs/<clickup-project-kebab>/`, with the Atlas FE section inside it | Repo rule (G-08) | — | Spec location |
| LD-009 | **Every action that sets, changes or clears a file's deliverable type or collection produces a Categorize record, one per file:** <br/>• upload into Client Deliverables when a type is set (path A); <br/>• approve v1 and v2 (B/C); <br/>• recategorize (D), including a change to the collection only; <br/>• unapprove (E), which clears the categorization, so its record reads `Deliverable Type: N/A` / `Collection: N/A`; <br/>• the system Planet Summary creation (F), where no person is involved, so it is recorded with the system as the actor. <br/>No record is produced when **no** categorization happens: an upload with no type, and legacy approve (G), which sets no type. That isn't an exclusion — nothing was categorized | User correction on Q1: an audit trail captures every change. Ticket: "the 'who, what, when' for these critical functions" | **Rejects** "recategorize only" and "exclude unapprove/system" (the recon's recommendation, report §10 D1). Closes story OQ-01 and OQ-02's decision half | Spec §Scope, §Dispatch (one subsection per path), §Converter (clear state) |
| LD-010 | The event type is **`CATEGORIZE`**, the ticket's own name, written in the upper case every Atlas and Europa event type uses (all displayed raw). It is not the past-tense `CATEGORIZED` the recon recommended | Ticket: "A new Event Type is created for this action: **Categorize**". qa-to-spec: don't re-ask what the ticket locks | **Rejects** `CATEGORIZED` (report §10 D2 recommendation). It deviates from the sibling types' past tense, and the ticket wins. Closes story OQ-10 | Spec §Event type, §Atlas; story criterion 3 |
| LD-011 | **No backfill.** Only categorizations made after release produce records | Audit integrity: Callisto keeps no who/when history for past categorizations (report §8, §13), so any backfilled record would be reconstructed, not observed. An audit log must not contain invented entries | **Rejects** backfill. Closes story OQ-07's decision half / report D5 | Spec §Non-goals |
