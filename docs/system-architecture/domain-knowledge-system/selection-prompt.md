# Selection prompt

System-agnostic. Use verbatim. It names no project, so it does not need editing
between systems.

```
Feature: <one sentence>
Acceptance criteria: <numbered list>

1. List the folder and file names under specs/. Do not open anything.
2. For each acceptance criterion, name the files whose subject that criterion
   depends on. Give one sentence saying why.
3. Open only the files you named.
4. From each, take the rule, its applicability, its verification expectation,
   and the features listed as known consumers.
5. Open those features. Take their Decisions, Invariants with the named tests,
   and History.
6. Follow Not owned and Affects to the nodes they name. Repeat step 5 until a
   hop names no unvisited node.
7. Report:
   - a table of criterion, files, and the reason for each pairing
   - any file you opened whose Status is "Not written"
   - any criterion no file name covers
   - any file you opened that no criterion needed
```

## Why the report lines matter

A selected file marked `Status: Not written` is a rule the criteria need and the
system does not have. A criterion with no file at all means the subject itself is
unrecognized, which is the more serious case. A file with no criterion means the
pull was too wide.

All three are checkable by a reviewer who knows nothing about the feature, which is
what makes the method auditable.

## Where inference happens

Step 2 is the only place matching occurs, and it matches acceptance criteria against
folder and file names. Every step after it follows pointers that the previous step
named. That confines judgment to one auditable place, which is why step 2 requires a
stated reason per pairing.
