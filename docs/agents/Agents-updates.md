# Consolidated updates to source rules

## 1) Precedence / scope clarification
Update the personal-methodology rule to state explicitly:

- Repo-specific `.cursor/rules/**` win for repo behavior and technical conventions.
- `dustin-thomason` rules win for personal workflow habits only when they do not conflict.
- Repo wins for:
  - architecture and layering
  - testing harness and test placement conventions
  - file placement and module structure
  - API / Swagger / DTO / contract conventions
  - branch / commit / PR formats required by that repo
- `dustin-thomason` wins for:
  - changelog location
  - session memory
  - cross-repo personal workflow habits
- If a direct conflict materially changes behavior, note that exception in the changelog.
- Do not note conflicts when rules were compatible in practice.

## 2) AGENTS.md authority clarification
Make explicit in the relevant rule or workflow doc:

- `AGENTS.md` is generated output only.
- Never edit `AGENTS.md` directly.
- All behavioral changes must be made in source `.mdc` files.
- Regeneration scripts will overwrite direct edits to `AGENTS.md`.

## 3) Canonical checklist / record location
Update the changelog rule and any referencing rules to state:

- When a changelog exists, it is the canonical record.
- Final chat wrap-up may summarize, but is not the source of truth.
- PRDV work -> canonical record in `dustin-thomason/docs/<system>/PRDV-XXXXX-changelog.md`
- Personal project work -> canonical record in that project changelog under `docs/<project>/`
- Trivial `dustin-thomason`-only doc tweaks with no changelog -> final wrap-up may be the only record

## 4) Shipping checklist structure
Define one shared checklist vocabulary in the changelog rule as the source of truth.

Rules:
- Use a standardized checklist structure.
- Checklist is required for sessions that materially change code or behavior.
- Append the checklist at the end of the session entry.
- Keep the session narrative first.
- Do not allow open-ended omission based on agent preference or assumption.
- A heading may be omitted only when its trigger is absent or an explicit exception applies.
- Omitted headings mean not relevant.
- If a triggered heading is not performed, the exception must be recorded explicitly.
- Do not pad entries with irrelevant noise.

Checklist is not required for:
- trivial planning-only sessions
- note-taking
- minor docs with no behavior impact

## 5) Checklist source of truth
Place the canonical checklist definition in the changelog rule only.
Other rules should reference it rather than repeating it.

## 6) Checklist trigger / exception model
Define explicit default triggers and exceptions instead of relying on open-ended judgment.

### Tests
- Default: required when behavior, logic, or a bug fix changed.
- Exception only when the documented test-blocker rule applies.

### Regression impact
- Default: required whenever shared infrastructure, cross-cutting behavior, or adjacent surfaces were touched.
- Exception only when the change is strictly isolated and the session note says why.

### API docs
- Default: required whenever HTTP contract or API metadata changed.
- Exception only when there was no contract / API-surface change.

### Tooling gates
- Default: required whenever the repo provides applicable lint/test/audit gates for the touched work.
- Exception only when:
  - the repo lacks that gate, or
  - the work is truly outside that gate’s scope, or
  - a documented blocker prevented running it
- Tooling gates are verification steps, not optional confidence checks.
- Confidence or intuition is never a substitute for running the gate.

### Conflicts / exceptions
- Required whenever a normal rule was skipped, blocked, or overridden.

Posture:
- do the check by default
- skip only by explicit exception
- never silently assume “it should be fine”

## 7) Test exception clarification
Update build-implementation-guardrails to define valid exceptions narrowly:

A test exception is valid only when at least one of these is true:
- the repo has no runnable test harness for that layer
- adding the first meaningful test would require significant scaffolding unrelated to the change
- the touched code is purely wiring/config/docs with no meaningful behavior to assert
- an existing repo rule explicitly waives tests for that category

When using an exception, record:
- why tests were blocked
- what risk remains uncovered
- the smallest follow-up task that would unlock coverage

## 8) Graceful degradation by layer
Clarify that graceful handling is layer-specific:

- Backend / HTTP:
  - assert controlled status codes and error shapes
  - avoid leaking raw internals
- Frontend / UI:
  - assert user-visible error handling when applicable
  - examples: onError behavior, fallback rendering, disabled states, toast/message handling
- Domain / utility / mapper code:
  - assert deterministic failure behavior or explicit fallback only if the unit is supposed to provide it

Do not require UI-style assertions for backend-only work or HTTP-style assertions for pure utility code.

## 9) Context-fanout fallback
Update context-fanout to state:

- If subagents are available, use them for qualifying read-only parallel exploration.
- If subagents are not available, perform the same exploration serially in the parent context.
- Lack of subagent support is not a reason to skip needed exploration.
- Return concrete artifacts either way.

## 10) Git branch clarification
Update git-commit-workflow to state:

- Default push target is the current working branch.
- Feature branches are normal and expected when the repo/task uses them.
- Use `main` only when the repo workflow is direct-to-main or the user explicitly says so.
- Avoid implying `main` is preferred in branch-based workflows.

## 11) Commit subject clarification
Update commit message guidance:

- Keep the short word-count rule for readability.
- Aim for five to seven words in the descriptive subject text.
- Exceed that only when absolutely necessary.
- Ticket prefix does not count toward that limit.
- The descriptive text should focus on the surface change, not implementation detail.

## 12) Rule language semantics
Use a consistent vocabulary across rules:

- **must / required** = mandatory unless an explicit exception applies
- **default / normally** = expected baseline, but context may change it
- **may / can** = optional
- Avoid soft wording in mandatory instructions.

## 13) Exception reporting requirements
When an exception is invoked, the record must include:

- why the normal step was not done
- what exact check or action was skipped
- what risk remains or what follow-up would resolve it

Do not allow vague exception notes like only “blocked” or “N/A”.

## 14) Not relevant vs blocked
Define and enforce the distinction:

- **Not relevant** = the trigger was absent
- **Blocked / exception** = the trigger was present, but the action was not completed
- A blocked item must never be recorded as N/A
- If something was not done, the record must say why

## 15) Regression isolation evidence
If an agent records a change as strictly isolated, it must briefly name the boundary that makes it isolated.

Examples:
- confined to a private helper with no caller contract change
- test-only change with no production code change
- copy/text-only UI change with no behavior or state logic change
- repo-local doc/config change outside runtime behavior

“isolated” by itself is not sufficient.

## 16) Regression exception evidence
If regression-impact work is omitted under the isolation exception, the record must state:

- the specific boundary that isolates the change
- why that boundary prevents effect on adjacent callers, shared infrastructure, or neighboring surfaces

## 17) API docs exception evidence
If an agent records “no API surface change,” it must briefly name the checked surface.

Examples:
- existing route path/method unchanged
- DTO shape unchanged
- status/auth decorators unchanged
- internal service/refactor only, no controller contract change

“No API surface change” by itself is not sufficient.

## 18) Tooling gate exception evidence
If an agent records a tooling gate as not applicable or out of scope, it must name:

- the specific gate
- why the work was outside that gate’s scope

Examples:
- `npm audit` not applicable because repo has no `package.json`
- lint gate not applicable because the touched files are outside the linted workspace
- test gate not applicable because the repo defines no test script for that layer

“Not applicable” by itself is not sufficient.

## 19) Verify absence of change against concrete surfaces
Absence of change must be verified against a concrete surface, not inferred from intent.

Rules:
- “I only refactored”
- “I only touched internals”
- “This should not affect anything”

are not sufficient by themselves.

The agent must name the checked surface and confirm it stayed unchanged.

Examples:
- regression: adjacent callers/shared surfaces checked and unchanged
- API docs: route, DTO, auth/status metadata checked and unchanged
- tooling: applicable gates identified and either run or explicitly excepted with reason

## 20) Tests: run vs add/update
Split the tests rule into two distinct obligations.

### Running tests
- Default: required at the end of the session when the repo has applicable test gates for the touched work.
- Exception only by explicit blocker or true out-of-scope condition.
- “Small tweak” is not a valid reason to skip running applicable test gates.

### Adding or updating tests
- Default: required when behavior changed, a bug was fixed, or coverage for the touched behavior did not already exist.
- If no new tests were added, the agent must name the existing suite or assertions that already cover the changed behavior, or use the documented exception path.

## 21) Verification gate reporting
For tests, lint, and audit, require auditable reporting.

Rules:
- Record the exact gate command run.
- Record the scope it covered.
- “Tests passed,” “lint passed,” or “audit passed” by itself is not sufficient.

Applies to:
- tests
- lint
- audit

## 22) Use repo-standard gate commands
When a repo provides a standard verification command, use that command by default.

Rules:
- Do not substitute an ad hoc weaker or narrower command unless the standard command is unavailable or blocked.
- A substitute command is allowed only when it preserves the intent of the repo-standard gate for the changed scope.
- Convenience alone is not a valid reason to substitute.

If a substitute is used, record:
- why the repo-standard command was not used
- why the substitute still verifies the relevant scope adequately
- what, if anything, remains unverified

## 23) Verification-gates reporting table
Preferred reporting format for verification gates is a markdown table.

Table should capture, as applicable:
- gate
- exact command
- scope
- result
- exception / risk

Requirement:
- Table is preferred by default.
- Table is required when multiple gates or any exceptions are reported.

## 24) Verification gate ordering
Use a fixed execution and reporting order:

- audit
- lint
- tests

Rationale:
- audit first to catch shipment blockers early
- lint second because it may mutate files
- tests last against the post-lint tree

## 25) Nonstandard sequencing
Do not add pedantic rerun requirements beyond the normal order.

Rules:
- tests should run after lint against the final post-lint state
- require extra reruns only when a gate was run before a later file-mutating step in a nonstandard flow

## 26) Out-of-scope evidence
If an agent records something as out of scope, it must define the scope boundary and explain why the skipped check or action falls outside it.

“Out of scope” by itself is not sufficient.

## 27) Session-end verification vs exploratory runs
Distinguish official verification from exploratory runs.

Rules:
- only session-end verification counts as the official compliance record
- exploratory runs may be mentioned, but do not replace the final gate result
- the recorded gate result must reflect the final post-change state

## 28) Final-state reporting only
Verification reporting must reflect the final post-change state only.

Rules:
- do not cite an earlier green run if later edits were made afterward
- if the final state differs from the earlier plan or intermediate run, report the final state

## 29) Truthfulness / evidence standard
Add an explicit reporting-integrity rule.

Rules:
- agents must not claim a file was changed, a command was run, or a result was observed unless it actually happened
- status reporting must be grounded in observable evidence
- if no file changed, the agent must not imply that it did
- if a command was not run, the agent must not present it as completed
- if intended work was not completed, the agent must say so directly

Distinguish clearly among:
- **planned** = intended but not done
- **attempted** = tried but not completed
- **completed** = actually changed/performed
- **verified** = completed and then confirmed by an applicable check

## 30) UTC timestamps for session entries
Changelog/session entries that record implementation activity must include a UTC timestamp.

Rules:
- use a single canonical format: ISO 8601 UTC with trailing `Z`
- example: `2026-05-29T21:14:00Z`
- timestamp should reflect when the entry was recorded