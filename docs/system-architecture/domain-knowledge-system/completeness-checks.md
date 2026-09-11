# Completeness checks

Four detections from section 29 of the founding document. `record-prompt.md` runs
these against its own task before treating that task as recorded, and
`qa-prompt.md` runs them again independently. Each detection compares two things
that should move together and reports when one moved without the other.

## The four checks

**Implementation changed, no decision updated.** Compare the files touched by the
diff against the Implementation field of every decision on the nodes the diff
touches. A file changed by the diff that appears in no decision's Implementation
field, on a node that has at least one decision already, is unrecorded.

**New invariant introduced, no test exists.** For every invariant on a touched
node, confirm its `proven_by` test name resolves to a test file that exists and
was run in the task's test results. An invariant whose named test is missing or
was not part of the run is unverified.

**Specification changed, downstream consumers not reviewed.** If a rule file
under `specs/` changed revision during this task, read `specifications.yaml`'s
`entries` for that rule id and confirm every node listed there has been reviewed
against the new revision, meaning its `governs` entry for that rule now records
the new revision. A node still recording the old revision has not been reviewed.

**Behavior changed, history not updated.** If the diff changes what a node's
existing decisions or invariants describe, rather than adding a new decision or
invariant, confirm that node's History records what the prior behavior was and
why it changed. A behavior change with no corresponding History entry looks, to a
later reader, like the node was always this way.

## What a detection produces

Each detection either finds nothing, in which case it contributes nothing to the
report, or it names the specific file, decision, invariant, or node it found
unrecorded. A detection never produces a pass by itself; the absence of a finding
is what a pass looks like, and `qa-prompt.md`'s Completeness section records that
absence explicitly rather than omitting the check.

## Why this exists separately from the QA checks in qa-review.template.md

The fifteen checks in `qa-review.template.md` ask whether the trace is correct:
whether the right rules were found, whether decisions match specifications,
whether tests match invariants. These four checks ask a narrower question: whether
the tree was updated at all in the places the diff touched. A task can pass every
one of the fifteen checks and still have left a touched node's History untouched,
which is what these four exist to catch.
