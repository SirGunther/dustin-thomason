# Investigation coverage ledger — the visited-state map

Use this instruction when an investigation begins, resumes, or hands off. The ledger is a durable record of **where the agent has already looked, how deeply, and what it learned there** — coverage AND outcome, not just conclusions.

The problem it solves: an agent that forgets its visited set repeatedly traverses the same branches, consumes enormous context, and still believes it is making progress. Compaction turns deep investigation into repeated exploration. Without the coverage half, a later agent sees only "the database may be involved" and reopens every file; with it, the agent sees the adapter was already inspected, which methods were checked, and why it was ruled out.

**Relationship to [qa-to-spec-traceability.md](./qa-to-spec-traceability.md):** complementary halves of the same don't-redo principle. That workflow preserves **decisions** (what was answered, locked, and where it lands in the spec). This ledger preserves **traversal** (where the agent looked in code and what it found or ruled out). This is the traversal counterpart to its reconcile-before-asking rule. Do not merge the two artifacts.

## Output location

```text
docs/<Project>/tickets/<ticket-slug>/investigations/<ticket-slug>-coverage-ledger.md
```

One ledger per ticket. Do **not** maintain a single ever-growing project-wide coverage document — at scale that document becomes its own million-token problem. Discovery across tickets is grep-based (see the consult protocol).

## Core rules

- Record coverage **as you investigate**, not retroactively. An entry costs one table row at the moment of inspection; reconstructing it later costs a re-read.
- Every entry is keyed to a **commit** (short SHA) and date. "This function was investigated" is only reusable while the code is materially unchanged; an inspection against commit A does not silently govern commit B.
- Every entry carries a **status** from the fixed vocabulary below. No free-form status values.
- The **Not yet inspected** section is mandatory. It is the frontier — the most valuable part of the ledger for whoever resumes.
- Entries are structured tables and bullets, never prose narratives. The investigation report tells the story; the ledger is the index.

## Status vocabulary

| Status | Meaning |
| --- | --- |
| `fully-inspected` | Examined completely for the stated question; findings recorded |
| `partial` | Examined, but stated aspects remain unchecked (name them in Notes) |
| `ruled-out` | Examined and eliminated as a cause/factor for the stated question |
| `contributing` | Examined and confirmed as a contributing condition |
| `not-inspected` | Identified as relevant but not yet examined (lives in the frontier section) |

## Consult protocol (before opening a new investigative branch)

Before investigating area X:

1. **Search prior ledgers** for X and its surrounding subsystem:

   ```powershell
   # from the repo holding docs/<Project>/
   Get-ChildItem docs/<Project>/tickets/*/investigations/*-coverage-ledger.md
   # then grep those files for the file path, symbol, or subsystem name
   ```

2. **If already covered, reuse the prior result** — cite the ledger entry instead of re-reading the code.
3. **Reopen only if** at least one holds:
   - new evidence contradicts the prior finding;
   - the code changed since the recorded commit (`git log <sha>..HEAD -- <path>` is non-empty);
   - the prior inspection was `partial` for the aspect now in question;
   - the current question concerns a **different behavior** than the one inspected.
4. **Record why it was reopened** in the new ledger's entry (`Reopened: <reason>`). Re-checking without a stated reason is the exact waste this ledger exists to stop.

**Mandatory consult log line:** the ledger's `Consulted` section must record what was searched and what came of it — even when nothing was found. This line is the auditable evidence that the consult happened. Example: `Consulted: docs/WorkLists/tickets/*/investigations/*-coverage-ledger.md for "cardActions"; found duplicate-card-option ledger; reused its ruled-out entry for dal.js.` or `Consulted: <glob>; none found.`

## Ledger template

```markdown
# Coverage ledger — <Project>/<ticket-slug>

Investigation question: <one sentence — the behavioral question this coverage is FOR>
Repo(s): <repo names>  ·  Baseline commit: <short SHA>  ·  Started: YYYY-MM-DD

## Consulted

- <glob searched> for "<terms>" — <found + reused | found + reopened (reason) | none found>

## Areas examined

### 1. <area — file, module, table, endpoint>

| Field | Value |
| --- | --- |
| Inspected | <functions / callers / columns / queries — the concrete items> |
| Findings | <what was found, one clause per finding> |
| Status | fully-inspected / partial / ruled-out / contributing |
| Commit | <short SHA> · YYYY-MM-DD |
| Evidence | <file:line refs, grep results, test names> |
| Notes | <partial: what remains unchecked · reopened: reason> |

### 2. <next area>

...

## Not yet inspected (frontier)

- <area> — <why it's relevant / what question it would answer>
```

## What belongs here

- Files, functions, callers, adapters, schemas, tables, constraints, queries, logs, tests, and call paths examined — with the specific items named.
- What was found, ruled out, or left unresolved in each area.
- Completeness claims and how they were established ("`useUnapproveFlow` imported only by X and Y — grep clean").
- The frontier: relevant areas not yet examined.

## What does not belong here

- The investigation narrative, verdict, or recommendation (that is the investigation report).
- Locked decisions from Q and A (that is the qa-to-spec-traceability ledger).
- Speculation without an inspection behind it.

## Definition of done

The ledger is serving its purpose when a future agent can answer, without re-reading code: Has this subsystem been inspected at all? Was this file inspected? Was this symbol inspected **for this particular question**? Was it inspected at a commit that still matches the current code?
