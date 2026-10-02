# Testing implementation — atlas/INT-138

> Scenario-first record of what was stress-tested while implementing the INT-138 spec, and the changes each scenario forced. This is content for the PR comment, not for source comments. Plan: [INT-138-test-plan.md](./INT-138-test-plan.md). Spec: callisto `INT-138-spec` working tree (copy at [../specs/INT-138-spec.md](../specs/INT-138-spec.md)).

## Branches (local, not pushed)

| Repo | Integration branch | Pieces merged |
| --- | --- | --- |
| callisto-back-end | `INT-138` @ `9d4ce4e9` | `INT-138-audit-core` (`c0eab69f`), `INT-138-planet-summary` (`f8bf0534`, `dd86d1ff`), `INT-138-gca-dispatch` (`14ac1634`, `d794fc5d`), plus review commit `32d51293` |
| atlas-front-end | `INT-138` @ `e5a29a4a` | `INT-138-atlas` (`82f087c2`) |
| europa-back-end | — | unchanged (LD-007) |

## Scenarios stress-tested

### 1. A recategorize produces a record for every file (the original defect)
- **Why it matters:** it is the only categorization path that wrote no audit at all.
- **Held:** a red→green test. The recategorize service spec failed 6 of 11 tests on the old service (no dispatch, and `processedFiles` leaked into the response), and all 11 pass after the change. The response is exactly `{ processedFileIds }`.
- **No change forced.**

### 2. Batch operations give one record per file, including files that share one attachment
- **Why it matters:** Europa shows only the first resource of an event (criterion C7).
- **Held:** the recategorize TS and service specs dispatch per processed file (2 files on 1 attachment → 1 write, 2 records), and approve v1/v2 dispatch per processed file.
- **No change forced.**

### 3. The path reads exactly `Filepath | Deliverable Type | Collection`, with N/A where empty
- **Why it matters:** criteria C4, C5 and C8 depend on the exact string Atlas splits.
- **Held:** the converter spec covers set, change, clear, no collection, and blank or whitespace names, and it never produces an empty segment. A compile-time probe confirmed that a legacy `ProceedingFileAuditParams` can no longer carry `CATEGORIZE`.
- **No change forced.**

### 4. The Planet Summary record names the requester, never the Mercury echo — **new scenario**
- **Why it matters:** the completion event's `createdUserIdentity` is the transcript's creator, not the requester (criterion C9).
- **Held:** the fixtures set `command.createdUserIdentity = 'mercury-echo'` and the job's creator to `'requester-1'`. The dispatched identity is the requester's, with `ipAddress` and `userAgent` = `system`.
- **Change forced (spec Part C):**
  - Observed: the spec had the completion service inject the requester converter.
  - Expected: services may not import converters (depcruise `services-no-converters`, `fitness-functions-rules/architecture-rules/services.rules.ts:30-36`; a probe service failed the rule).
  - Fix: `ResolveTranscriptSummaryProcessingContextAssembler` applies the converter, and the context carries `requesterAuditUser`.
  - Files: `resolve-transcript-summary-processing-context.assembler.ts`, `transcript-summary-processing-context.ts`, `process-proceeding-transcript-summary-completed.service.ts`.
  - The spec is updated.

### 5. A failed audit never fails the business action
- **Why it matters:** the write has already committed by the time the audit is sent.
- **Held:**
  - A name-lookup failure is logged and the request still returns its normal result, with the sibling `APPROVED`/`CREATED`/`UNAPPROVED` still sent (all five GCA services).
  - A failed Planet Summary audit logs a WARN, still sends the other files' records, returns `success: true`, and triggers no cleanup.
- **Change forced (spec Part B):**
  - Observed: the spec asked for a warning per unresolved id.
  - Fix: one warning per repository kind, listing the ids. It carries the same information in fewer log lines.
  - File: `file-categorization-audit.assembler.ts`.
  - The spec is updated.

### 6. Neighbors stay unchanged
- **Why it matters:** the shared files select gained two columns, and existing audits and outbox payloads share these code paths.
- **Held:**
  - The GET files listing converter spec asserts the exact output keys.
  - The Dione outbox converter and TS specs stay green without edits.
  - The existing `APPROVED`/`CREATED`/`UNAPPROVED`/`RENAMED` assertions are unchanged.
  - The neighbor audit sub-domain specs (cases, proceeding audit, job submission, permissions) pass.

### 7. Atlas lists and renders CATEGORIZE, and nothing else changes
- **Why it matters:** criteria C3, C4 and C6; the `PERMISSIONS_UPDATED` render must stay the same.
- **Held:** 15 new tests. A mutation check put the old `=== 'PERMISSIONS_UPDATED'` condition back and the 4 CATEGORIZE path cases failed.
- **Change forced (spec Part D):**
  - Observed: the spec's `[...MULTI_PART_PATH_TYPES].sort()` failed `vue-tsc` with TS2802, because the repo compiles to the ES5 default target.
  - Fix: `Array.from(MULTI_PART_PATH_TYPES).sort()`, the pattern used at `src/callisto/auth/composables/permissions/useProceedingFilePermission.ts:33`.
  - Test-only change; the spec is updated.

### 8. The convention checks actually run on Windows — **new scenario (tooling)**
- **Why it matters:** the pre-commit hook relies on these checks.
- **Observed:** on Windows, `npm run test:conventions` printed "The system cannot find the path specified" and exited 0. The find-based checks were not scanning anything.
- **Fix (verification only, no product change):**
  - The six find-based checks were re-run with `COMSPEC` set to Git Bash: real scans, zero path errors, and the new files included.
  - `architecture.spec.ts`, by contrast, fails under that same `COMSPEC`, so it runs under the default shell.
- Recorded as concern C12.

## Convention review (2026-09-25 to 26): scenarios the review added, and the changes they forced

Reviewed against every rule set: callisto `.cursor/rules` (9 files), atlas `.cursor/rules` (8 files), and `dustin-thomason/docs/reviewers`. Every finding was verified in code before it was fixed.

### 9. A failed dispatch on a Client Access path never fails the request, and never hides other files' records — **new scenario**
- **Observed:** each of the five services caught only a failed name lookup. A rejected dispatch would have failed a committed request, and a `false` result was silently dropped.
- **Expected:** the same behavior as the Planet Summary path.
- **Fix:** one `DispatchFileCategorizationAuditTS` replaces five identical helpers. It warns per event on `false` or a throw, keeps dispatching the others, and never rejects. Its spec covers the empty, happy, lookup-fails, dispatch-rejects, `false`, non-Error and no-identity cases.

### 10. An approve records the real previous categorization — **new scenario**
- **Observed:** approve hard-coded `previous: null`, which would claim "no prior categorization" without checking.
- **Fix:** the approve TS reads the prior categorization before its setters, and `previous` comes from that read.

### 11. A value containing `|` can't add a display line — **new scenario**
- **Observed:** Atlas splits on `' | '`, and the label's `': '` supplies the space before each value. So a value starting with `| ` would also have created a separator.
- **Fix:** Callisto shows every `|` inside a value as `¦` in the display path only; `resourcePath` keeps the exact key. Atlas pins the `¦` form as three lines.

### 12. A path segment with no label renders as plain text — **new scenario**
- **Observed:** the template bolded the whole value and added a stray `: `. An empty `PERMISSIONS_UPDATED` path showed a lone `:`.
- **Fix:** `splitPathSegments` plus separator constants. Segments are derived in `displayRows`, and the template only iterates. Labelled `PERMISSIONS_UPDATED` output is byte-identical (checked with a side-by-side innerHTML probe).

### 13. The GCA port can't drift from the aggregator it's bound to — **new scenario**
- **Observed:** Nest doesn't type-check `useExisting`.
- **Fix:** a spec assignment pins the aggregator to the port type. Changing the port's return type to `Promise<string>` made type-check fail with 5 errors.

**Structural fixes with no behavior change** (rules cited in the chat report):
- services inject a TS, not an assembler;
- a predicate for the "record is due" rule;
- a separate `applyCategorized` port method;
- a one-object converter input;
- label constants;
- `readonly` params;
- shared file projections;
- branded ids;
- `filter`/`map` in place of `push` loops;
- a recategorize projection converter;
- the requester converter moved and renamed (`FileDerivationJobToAuditUserConverter`);
- a shared `UNKNOWN_IDENTITY_VALUE`;
- no `let` reassignments;
- functions under 20 statements;
- typed test helpers in place of `as` casts;
- random test data;
- `// Arrange` blocks;
- ticket references removed from code.

## Not yet exercised

- **Live end-to-end** (test plan M-1 to M-6): Callisto → SQS → Europa → Atlas.
  - **Blocked:** Callisto's audit producer targets real AWS SQS, which needs fresh AWS credentials from Planet Portal SSO (`docs/atlas/local/callisto-local.mdc:10,50`).
  - **Risk:** the cross-service contract is proven in code and unit tests only. That covers the byte-identical `CATEGORIZE` literal, Europa accepting the six identity fields, and the three-line render.
  - **Follow-up:** run M-1 to M-6 with credentials, or in sandbox after deploy.
- **The migration against a real database:** not run. The DDL is a single nullable `ADD COLUMN`, and naming passes `test:migration-naming`.
