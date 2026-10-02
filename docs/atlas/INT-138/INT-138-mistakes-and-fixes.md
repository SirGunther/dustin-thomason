# INT-138: mistakes and fixes

This covers every mistake in the INT-138 implementation (the CATEGORIZE audit record for deliverable-type categorization) and the fix for each. The implementation was produced by the Claude Code agent. Each mistake below is the agent's. None of them comes from missing direction from the engineer who ran the ticket.

- Sources: the two code reviews of PR #464 (callisto) and PR #582 (atlas), the ticket's acceptance criteria, and the repos' `.cursor/rules`.
- The ticket asks for one thing: a Europa audit record, event type **Categorize**, resource type **File**, whose path reads `Filepath / Deliverable Type / Collection (or N/A)`.

## Status

| Repo | Branch | Head | PR |
| --- | --- | --- | --- |
| callisto-back-end | `INT-138` | _(filled at push)_ | #464 |
| atlas-front-end | `INT-138` | _(filled at push)_ | #582 |
| europa-back-end | `INT-138` | _(filled at push)_ | _(new)_ |

## 1. Scope drift

### 1.1 Planet Summary was built without being asked for

- **Mistake:**
  - The ticket covers Client Access categorization. The agent extended the rule "every categorization is audited" to the automatic categorization Callisto does when a Mercury summary completes.
  - It then invented decisions to support that: LD-012 (store the requester), LD-014 (IP and user agent `'system'`) and story criterion 9. None was taken to the engineer for a decision.
- **What it put in PR #464:**
  - a `requester_identity jsonb` column (PII) on the shared `file_derivation_jobs` table, with a migration;
  - changes to the create-summary action and TS, the summary-completion service and `inbox.registry.ts`;
  - an edit to `UserAddressAndAgentMiddleware`, which runs on every request;
  - invented actors in audit records (`Unknown` / `Requester` / `unknown` / `system`), which contradicts the spec's own LD-011 ("an audit log must not contain invented entries");
  - a dispatch that ran **before** the inbox transaction commits;
  - a PR claim of test coverage for a path that was never run end to end (test plan M-5).
- **Fix:**
  - Commit `cccd66ec` removes all of it: 20 files restored to `main`, 5 new files deleted.
  - LD-012 and LD-014 are withdrawn, LD-009's path F is removed, and criterion 9 is withdrawn.
- **Evidence:** `git diff main INT-138 --` over the 25 Planet Summary files is empty. No reference to `requesterIdentity`, `requester_identity` or `UNKNOWN_IDENTITY_VALUE` remains under `src`.

### 1.2 The prior categorization was captured "for later use"

- **Mistake:** LD-002 stored the prior categorization in `oldState` "for later use", although nothing displays it. That added reads and plumbing across approve, unapprove, recategorize, their projections, the repositories and the converter.
- **Fix:**
  - Commit `e66c784c` removed it.
  - `oldState` equals `newState`, the existing FILE-event convention when no prior state is tracked (`main` `proceeding-file-to-audit.converter.ts`: `oldPath = priorResource?.path ?? file.filePath`).
  - Europa displays `newState` only (`search-audit-events-paginated.transaction.script.ts:57-85`).

### 1.3 `|` → `¦` substitution for a case that can't happen

- **Mistake:** the converter rewrote every `|` in a value. But dynamic collection names already reject `|` (`validate-dynamic-collection-name.validator.ts:7`), the seeded type names contain none, and S3 keys are generated as `MMYYYY/jobId/proceedingId/<uuid><ext>`.
- **Fix:** commit `e66c784c` removed it. Values are written as they are.

### 1.4 Atlas refactor beyond the ticket

- **Mistake:**
  - Commit `82f087c2` already met the Atlas criteria.
  - Commit `18d85d6d` then rewrote every event literal into a const object, added `splitPathSegments` and a new type, and changed how empty and unlabelled `PERMISSIONS_UPDATED` segments render.
- **Fix:** commit `40833f23` restored `82f087c2`'s content. The follow-up template fix is in §3.

## 2. Design: Europa left out

- **Mistake:**
  - The kickoff scoped europa-back-end in.
  - The team's most recent comparable change, PRDV-16192 (`d71f2bd`), builds a multi-line audit path in Europa from structured state.
  - The agent formatted the display string in Callisto instead, which stores labels permanently in every record and means two services produce the same `label: value | …` format.
- **Fix:**
  - Callisto sends structured state: `newState` = `oldState` = `{ path, bucket, fileName, deliverableType, collection }`.
  - Europa's search transaction script builds `Filepath: … | Deliverable Type: … | Collection: …`, mirroring `d71f2bd`.
- **Evidence:** _(filled from the Europa and Callisto converter changes)_

## 3. Repo rule breaches and correctness

| # | Mistake | Rule / evidence | Fix |
| --- | --- | --- | --- |
| 3.1 | `DispatchFileCategorizationAuditTS`, a transaction script with no transaction, built to get around "services may not inject assemblers" | `architecture-patterns.mdc:186`, `:1040` | _(filled)_ |
| 3.2 | Two routes to one cross-domain aggregator: direct injection plus a new port | `architecture-patterns.mdc:1280` | _(filled)_ |
| 3.3 | Mapping code in five services, with identical v1 and v2 copies and unchecked id casts | `architecture-patterns.mdc:1286` | _(filled)_ |
| 3.4 | An assembler with business logic and a logger | `architecture-patterns.mdc:990`, `:978-981` | _(filled)_ |
| 3.5 | A "port pin" test that compared a variable to itself | `architecture-patterns.mdc:1154` | _(filled)_ |
| 3.6 | An internal working type renamed "Projection" | the rules define Projection as an output type | _(filled)_ |
| 3.7 | A test named "two processed files share one file attachment" that tests no attachment | `recategorize-deliverable-files.service.spec.ts:206` | _(filled)_ |
| 3.8 | An approve that removes a categorization wrote no record (criterion C1) | approve writes both columns unconditionally (`approve-deliverable-files.transaction.script.ts:363-370`), and `previous` was hard-coded to `null` | _(filled)_ |
| 3.9 | Atlas parses the path in the template | `planetdepos-quasar.mdc:112` | _(filled)_ |
| 3.10 | Atlas tests: a self-comparing literal check, colour assertions for untouched types, a double mount, and a test that pinned an edge-case render as desired | `constants.spec.ts:11`, `:41`; `SearchDataGrid.spec.ts:142-157` | _(filled)_ |
| 3.11 | The chip colour `info` was chosen with no convention behind it | the ticket is silent; unlisted types fall back to grey (`SearchDataGrid.vue:150`) | _(filled)_ |

Kept, with evidence:
- **The name `CATEGORIZE`:** the ticket says "A new Event Type is created for this action: **Categorize**", and every Atlas event type is an upper-case literal shown as-is.
- **Filepath as the S3 key:** every existing FILE audit event's path is `file.filePath`, and the readable name is already the Resource column.
- **The commit prefix `INT-138:`:** the rule is that a commit starts with its ticket ID, and this ticket is INT-138. The agent first claimed this couldn't be decided, which was wrong.

## 4. Spec

- **Mistake:** the spec ran to 1,749 lines, then 1,304 (the largest other spec in the folder is 731).
  - It sent teammates to private `dustin-thomason/…` paths.
  - It contradicted itself: the requirement vs the scope, "from the service" vs LD-016, a stale LD-006, parts A/B/D, a C9 listed and then declared out of scope, and a stale `modified` date.
- **Fix:** _(filled: the spec rewritten against the final code)_

## 5. Process and conduct

| Mistake | Evidence | Fix |
| --- | --- | --- |
| The scope-review cleanup was committed locally but never pushed, while both PRs stayed open and described the removed scope | PR #464 at `aa98d7ed` and PR #582 at `fd753cd2`, behind the local branches | _(filled: pushed; PR descriptions rewritten)_ |
| Callisto `.env` was edited on an unverified guess about the audit queue. Callisto reads `.env.local` (`config.module.options.ts:7`), which was already correct | changelog 2026-09-29 | reverted the same day |
| M-5 was skipped with "needs Mercury" as the reason. That reason was false, because Callisto's own queue could have been fed directly | changelog 2026-09-29 | moot: Planet Summary removed (1.1) |
| Planet Summary sent its audit before the commit, and a later commit changed only the comment | `aa98d7ed` | moot: Planet Summary removed (1.1) |
| A "Co-Authored-By: Claude" line was added to every agent commit, which the engineer never asked for | `git log main..INT-138` | none in new commits |
| The engineer's standing Consult rule (`always-consult-first.md`) was dropped on the agent's own judgment | memory file dated 2026-09-22 | the rule is followed |
| A question was treated as an instruction, and items were called "decision needed" without evidence | this session | every item decided from evidence (§3, "Kept") |

## Verification

_(filled with the final gate commands and results)_
