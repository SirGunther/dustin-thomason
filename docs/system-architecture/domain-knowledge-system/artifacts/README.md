# artifacts

Per-task records. These accumulate as work happens and are retained after it
completes (§27), so a later reviewer can compare what was known then against what is
known now.

    artifacts/
    ├── context/          the assembled input a task was performed from
    ├── qa/               the independent review of that task's trace
    ├── tickets/          links the task and review ids that belong to one ticket
    ├── regressions/      defects entering through the same tree, per §19
    └── investigations/   see below

All five exist from the start, empty, for the same reason the four indexes exist:
a folder that does not exist cannot report that it is empty.

## context/ and qa/

`context/` holds the output of the selection prompt: the criterion-to-file table,
the nodes visited with the pointer that led to each, the open questions, and both
revisions (§21). It is the object QA reads, rather than a conversation. Shape:
`../templates/context-artifact.template.md`.

`qa/` holds trace review rather than code review (§14, §15): whether the right
rules were selected, whether each cited revision is current, whether every
decision states a why and a rejected alternative, whether every invariant names a
test that exists, and whether every node touched by the change appears in the
context artifact. Shape: `../templates/qa-review.template.md`.

## tickets/

A file per ticket, holding the list of task ids and review ids recorded under it.
Most tickets need this only once, when the first context artifact for that ticket
is produced; it becomes useful once a ticket has gone through remediation (§18,
phase 8) and has more than one context artifact or QA review, since `context/` and
`qa/` are keyed by task id rather than by ticket id.

## regressions/

One file per defect, shape `../templates/regression.template.md`. A regression
records what invariant it violated, what rule that invariant derives from, why
existing evidence failed to catch it, and what new knowledge the fix produced.

## investigations/

The founding document lists this folder (§23) without defining what an entry in it
contains; no section of that document gives it a template the way it gives
`qa-review.md`, `regression.md`, or a decision an explicit shape. Its content is
left undefined here rather than invented, until a real investigation needs a place
to be recorded and its shape can be drawn from that actual case.
