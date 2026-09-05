# artifacts

Per-task records. These accumulate as work happens and are retained after it
completes (§27), so a later reviewer can compare what was known then against what is
known now.

    artifacts/
    ├── context/    the assembled input a task was performed from
    └── qa/         the independent review of that task's trace

`context/` holds the output of the selection prompt: the criterion-to-file table, the
nodes visited with the pointer that led to each, the open questions, and both
revisions (§21). It is the object QA reads, rather than a conversation.

`qa/` holds trace review rather than code review (§14, §15): whether the right rules
were selected, whether each cited revision is current, whether every decision states
a why and a rejected alternative, whether every invariant names a test that exists,
and whether every node touched by the change appears in the context artifact.

Add `investigations/` and `regressions/` when the first of each occurs.
