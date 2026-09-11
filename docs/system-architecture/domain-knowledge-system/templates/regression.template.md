# Regression template

A defect enters the tree through this shape, saved to
`artifacts/regressions/<id>.md` (§19). Its purpose is to let a later task start
from what is already known about the failure rather than re-deriving it, and to
record why the evidence that existed did not catch it.

## ID

Use an existing ticket or issue number if one exists. Otherwise allocate
`BUG-{{NNN}}`, one greater than the highest number already used in
`artifacts/regressions/`.

## Fields

```yaml
id: {{BUG-NNN, or an existing ticket id}}

description: >
  {{the observed defect, stated as what happened, not as what should have
  happened instead}}

violates: {{AREA-I-NNN}}

invariant_text: >
  {{copy the invariant statement from the node, so this record does not depend
  on the node's wording staying unchanged}}

derived_from: {{RULE-ID}}

implemented_by:
  - {{file where the violated behavior lives, at the time this regression was
    recorded}}

previously_verified_by: {{test name, or "no test existed"}}

discovered_by: {{the test that caught this regression, or "manual report" if no
  test caught it}}

why_evidence_failed_to_detect_this: >
  {{required. state whether no test covered this case, a test covered it but
  did not run, a test ran but asserted the wrong thing, or the invariant itself
  was not yet recorded when this behavior was introduced}}

status: {{open | resolved}}

resolved_by:
  task: {{task id, once resolved}}
  context_artifact: {{artifacts/context/<task-id>.md}}
  qa_review: {{artifacts/qa/<review-id>.md}}

new_knowledge_recorded:
  - {{a new decision, a new invariant, a new test, or a correction to the
    violates chain above, produced because of this regression}}
```

## `previously_verified_by` and `discovered_by` answer different questions

`previously_verified_by` names the test that existed before this regression and
was supposed to cover this behavior. `discovered_by` names what actually caught
this regression when it happened. These are the same test only when a test
existed, ran, and correctly failed. When they differ, the difference is itself
evidence for `why_evidence_failed_to_detect_this`: a test existed but was not run,
a different test caught it by side effect, or no test existed and a person found
it manually.

## Why `why_evidence_failed_to_detect_this` is required, not optional

§19 states that a regression should ask why existing evidence failed to detect it,
and that the answer becomes new durable knowledge. A regression record with every
other field filled in but this one left blank documents the failure without
documenting the gap in the tree that let the failure through, which is the
condition most likely to let the same regression recur.

## What happens to the chain once this is resolved

The `violates`, `derived_from`, and `implemented_by` fields are read, not
rewritten, once the regression is filed. If the fix changes which invariant was
actually violated or which rule it derives from, that correction is recorded under
`new_knowledge_recorded`, and the original fields are left as they were understood
at the time of filing, so the record shows how the understanding of the defect
changed rather than only its final, corrected form.
