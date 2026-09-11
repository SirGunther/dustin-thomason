# QA prompt

Run independently of the implementation (§14). The agent or model running this
prompt should not be the one that ran `selection-prompt.md` or
`record-prompt.md` for the same task, and does not re-derive context on its own;
it reads only the artifacts named below.

## The prompt

```text
Task: {{task id}}
Context artifact: artifacts/context/{{task id}}.md
Implementation diff: {{commit range}}
Updated nodes: {{domains/<path>.md list, from record-prompt.md's output}}
Tests: {{test files touched or added}}
Test results: {{pass/fail summary}}

1. Read the context artifact, the diff, the updated nodes, the tests, and the
   test results. Do not open a node the context artifact and the diff did not
   both point to; if you believe one is missing, record that as a finding
   rather than pulling it in.
2. Fill every check in templates/qa-review.template.md against these inputs.
   A verdict of fail requires the specific evidence: the criterion, the node,
   the decision, or the test in question, not a restatement of the check's
   question.
3. Run completeness-checks.md's four detections against the same inputs and
   record the result under Completeness.
4. Set outcome to accepted only if every check passed or was not applicable,
   and every completeness detection found nothing. Otherwise set outcome to
   findings raised and list each finding with the node or task that must
   address it.
5. Save the result to artifacts/qa/{{review-id}}.md using
   templates/qa-review.template.md.
6. Append this review's id to reviewed_by in the frontmatter of every node
   listed under updated_nodes.
```

## Why this prompt does not re-run selection

`selection-prompt.md`'s job is deciding what a task needs before implementation.
Re-running it here, after implementation, would let a review quietly redefine
what should have been pulled, based on hindsight, rather than checking what was
actually pulled and used. The review checks the trace that exists; it does not
produce a second, revised one.

## What happens on `findings raised`

Per section 18, phase 8, the task returns to `record-prompt.md`'s steps 2 through
6 to address each finding, then this prompt is run again, producing a new
`review-id` rather than editing the failed review. A review is a record of a
verdict at a point in time; changing it after the fact would remove the evidence
that the first review found a problem.
