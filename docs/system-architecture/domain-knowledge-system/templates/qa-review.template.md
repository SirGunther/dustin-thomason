# QA review template

The output of running `../qa-prompt.md` against one completed task, saved to
`artifacts/qa/<review-id>.md`. QA reviews the trace recorded for a task, not the
code directly (§14, §15): whether the right rules were found, whether decisions
are documented and consistent with those rules, whether the invariants still hold,
and whether the knowledge layer itself was updated.

## Inputs read

A review reads exactly these, and nothing pulled independently:

```yaml
review_id: {{QA-REVIEW-ID}}
task: {{task id}}
context_artifact: artifacts/context/{{task id}}.md
implementation_diff: {{commit range or PR link}}
updated_nodes:
  - {{domains/<path>.md, as changed by this task}}
tests: {{test files touched or added}}
test_results: {{pass/fail summary}}
```

## Checks

Each check records a verdict of `pass`, `fail`, or `not applicable`, and for `fail`
the specific evidence, not a restatement of the check.

```yaml
checks:
  - id: requirements-addressed
    question: Was every acceptance criterion in the context artifact addressed?
    verdict: {{pass | fail | not applicable}}
    evidence: {{which criterion, if fail}}

  - id: specifications-correct
    question: Were the specifications selected in the context artifact the
      correct ones for this task?
    verdict:
    evidence:

  - id: specifications-not-omitted
    question: Is there a specification, findable by the same file-name matching
      the selection prompt uses, that was not selected but should have been?
    verdict:
    evidence:

  - id: decisions-documented
    question: Does every implementation choice this task made appear as a
      decision in the node it touched?
    verdict:
    evidence:

  - id: decisions-consistent-with-specs
    question: Does each recorded decision's Governs citation actually support the
      decision, rather than merely being nearby?
    verdict:
    evidence:

  - id: implementation-matches-decisions
    question: Does the diff do what the recorded decisions say it does?
    verdict:
    evidence:

  - id: invariants-still-valid
    question: Do the invariants already recorded on touched nodes still hold
      after this change?
    verdict:
    evidence:

  - id: tests-exist
    question: Does every invariant this task introduced or touched name a test
      that exists?
    verdict:
    evidence:

  - id: test-behavior-matches-documentation
    question: Does the named test actually assert what the invariant claims,
      rather than merely sharing its name?
    verdict:
    evidence:

  - id: new-assumptions-documented
    question: Is every assumption this task made, beyond what the context
      artifact already recorded, written into the node as a decision or an open
      question?
    verdict:
    evidence:

  - id: cross-domain-interfaces-valid
    question: Do the Affects and Not owned entries on touched nodes still
      describe the relationship correctly after this change?
    verdict:
    evidence:

  - id: domain-knowledge-updated
    question: Were the touched nodes' Decisions, Invariants, or History updated
      to reflect this task, not left as they were before it?
    verdict:
    evidence:

  - id: generalization-promoted
    question: If a decision recorded here applies to more than one node, was it
      promoted to a specification rather than left duplicated?
    verdict:
    evidence:

  - id: specification-change-reviewed
    question: If a specification file changed, does specifications.yaml's
      reverse index show every node it governs was reviewed against the new
      revision?
    verdict:
    evidence:

  - id: documentation-implementation-consistent
    question: Does anything written in the touched nodes describe behavior the
      diff does not actually produce?
    verdict:
    evidence:
```

## Completeness

Run `../completeness-checks.md`'s four detections against this task and record
the result here rather than in a separate file.

```yaml
completeness:
  implementation_without_decision: {{none found | list}}
  invariant_without_test: {{none found | list}}
  specification_changed_consumers_unreviewed: {{none found | list}}
  behavior_changed_history_not_updated: {{none found | list}}
```

## Outcome

```yaml
outcome: {{accepted | findings raised}}
findings:
  - {{finding}}, routed to: {{node or task that must address it}}
```

If `findings raised`, the task returns to implementation per §18 Phase 8 and this
review is re-run after remediation, as a new `review_id`, not by editing this one.

## Reverse reference

Append this review's ID to `reviewed_by` in the frontmatter of every node listed
under `updated_nodes` above. This is §16's `reviewed-by` edge.
