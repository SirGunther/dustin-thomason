# Record prompt

Run after implementation is finished and its tests pass, using the context
artifact `selection-prompt.md` produced for the same task. This is the write-back
counterpart to selection: selection assembles what a task needs to know before
work starts, and this prompt records what the task learned after work finishes.

## The prompt

```text
Task: {{task id}}
Context artifact: artifacts/context/{{task id}}.md
Implementation diff: {{commit range}}
Test results: {{pass/fail summary}}

1. For each node visited in the context artifact, and for any node the diff
   touches that the context artifact did not list, do the following.

2. Write one decision entry, using templates/decision-entry.template.md, for
   each implementation choice this task made that was not already recorded on
   that node. Allocate its ID per identifiers.md: one greater than the highest
   {{AREA}}-D-{{NNN}} already used in that area.

3. Write one invariant entry for each behavior this task requires to remain
   true going forward, naming the test that proves it. Allocate its ID the same
   way, using the {{AREA}}-I-{{NNN}} series.

4. If a decision just written applies to a node not currently governed by the
   same rule, or reveals a dependency not already listed, add an entry to that
   node's Affects or Not owned list rather than leaving the dependency
   unrecorded.

5. If a decision just written would also govern a second node, unconnected to
   this task, apply the two-consumer test in specs/README.md: write it as a new
   specification file and have both nodes' Governs cite it, rather than leaving
   it duplicated as two separate decisions.

6. If anything attempted during this task was abandoned, record it in that
   node's History, stating what was tried and why it did not work.

7. Update the context artifact: append implemented_in and documented_in, per
   templates/context-artifact.template.md's "On completion" section.

8. Regenerate specifications.yaml, features.yaml, and dependencies.yaml using
   the procedure stated at the top of each file.

9. Run completeness-checks.md's four detections against this task.

10. Confirm every question in the founding document's completion definition
    (section 34) is answerable from the files now in the tree, without
    reference to this task's conversation. Report any that is not.
```

## Why every node touched gets the same treatment, not only the ones selection found

Step 1 includes a node the diff touches that the context artifact did not list.
`selection-prompt.md`'s report already names this case as over-pull when a file
was opened and not needed; the reverse case, a node the implementation actually
touched but the pull never opened, is a retrieval miss. `domains/README.md`'s
Affects field exists to hold that discovery once it is found, and step 4 is where
it gets written down instead of staying invisible.

## Why generalization is checked before recording is considered finished

Step 5 is not optional cleanup. `specs/README.md` states that a rule with two or
more consistent consumers belongs in `specs/`, not duplicated across nodes. Skipping
this step is how the same decision ends up recorded twice, independently, on two
nodes with no reference between them.

## What "complete" means

Step 10 is the exit condition for this prompt, not a separate step done later. A
task is not finished because the code works and tests pass; it is finished when
the questions in section 34 can be answered from the tree alone. If one cannot be
answered, the task returns to steps 2 through 6 rather than being reported as
recorded.
