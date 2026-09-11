# Selection prompt

System-agnostic. Use verbatim. It names no project, so it does not need editing
between systems.

```text
Feature: <one sentence>
Acceptance criteria: <numbered list>

1. List the folder and file names under specs/ and domains/. Do not open anything.
2. For each acceptance criterion, name every file, under either folder, whose
   subject that criterion depends on. Give one sentence saying why.
3. Open only the files you named.
4. From each opened rule (a file under specs/), take the rule, its applicability,
   its verification expectation, its revision, and the features listed as known
   consumers.
5. Open those known-consumer features, plus any domain file named directly in
   step 2. From each, take Governs, Decisions, Invariants with the named tests,
   and History.
6. Follow Not owned and Affects to the nodes they name. Repeat step 5 until a hop
   names no unvisited node.
7. Report:
   - a table of criterion, files, and the reason for each pairing
   - the revision recorded for each selected rule
   - any point where two rules or two nodes could both apply and nothing in this
     pull decides between them
   - any file you opened whose Status is "Not written" or "Proposed"
   - any criterion no file name covers
   - any file you opened that no criterion needed
```

## Why the report lines matter

A selected rule file marked `Status: Not written` is a rule the criteria need and
the system does not have. A selected domain file marked `Status: Proposed` is an
area a bootstrap pass named but no task has used yet. A criterion with no file at
all means the subject itself is unrecognized, which is the more serious case. A
file with no criterion means the pull was too wide.

The revision recorded for each selected rule is what a later pass compares against
that rule's current revision to detect whether the pull is stale. Reporting an
unresolved choice between two rules or two nodes as ambiguity, rather than picking
one, keeps the guess out of the pull and puts the decision where it belongs, with
whoever wrote the acceptance criteria.

All six report lines are checkable by a reviewer who knows nothing about the
feature, which is what makes the method auditable.

## Where inference happens

Step 2 is the only place matching occurs, and it matches acceptance criteria
against folder and file names under both `specs/` and `domains/`. Every step after
it follows pointers that the previous step named. That confines judgment to one
auditable place, which is why step 2 requires a stated reason per pairing.
