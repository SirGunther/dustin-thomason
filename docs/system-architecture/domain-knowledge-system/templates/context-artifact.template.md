# Context artifact template

The output of running `../selection-prompt.md` for one task, saved to
`artifacts/context/<task-id>.md`. It is the input to implementation and later to
`../qa-prompt.md`, and it is retained after the task completes so a later reviewer
can compare what was known when the task was done against what is known now.

## Fields

```yaml
task: {{task id}}
feature: {{one sentence description of what is being built}}
acceptance_criteria:
  - {{criterion}}

specifications:
  - id: {{RULE-ID}}
    source: {{specs/<discipline>/<subject>.md}}
    revision: {{sha this rule was at when selected}}
    reason_selected: >
      {{the one-sentence reason from selection-prompt.md step 2}}
    status: {{Active | Not written}}

domain_nodes_visited:
  - id: {{area or area.feature}}
    source: {{domains/<path>.md}}
    reached_via: {{a rule's known consumers | a criterion match | Not owned | Affects}}
    status: {{In use | Proposed}}

existing_decisions:
  - {{AREA-D-NNN}}

invariants_in_scope:
  - id: {{AREA-I-NNN}}
    proven_by: {{test name or file}}

ambiguity:
  - {{a point where two rules or two nodes could both apply and nothing decided between them}}

uncovered_criteria:
  - {{a criterion no file name covered}}

over_pull:
  - {{a file opened that no criterion needed}}

open_questions:
  - {{something the pull could not resolve}}

provenance:
  application_revision: {{sha}}
  knowledge_revision: {{sha}}
```

## On completion

Append after implementation lands:

```yaml
implemented_in:
  repository: {{application repository}}
  commit: {{sha}}

documented_in:
  repository: {{knowledge repository, if separate from the application}}
  commit: {{sha}}
```

## Where each field comes from

| Field | Produced by |
| --- | --- |
| `acceptance_criteria` | Given to the selection prompt, copied verbatim |
| `specifications` | Selection prompt steps 2 and 4 |
| `domain_nodes_visited` | Selection prompt steps 5 and 6 |
| `existing_decisions`, `invariants_in_scope` | Read from the frontmatter of each visited node |
| `ambiguity`, `uncovered_criteria`, `over_pull` | Selection prompt step 7 |
| `open_questions` | Anything selection could not resolve, including an ambiguity left for a person to decide |
| `provenance` | The application and knowledge repository revisions at the time the pull ran |
| `implemented_in`, `documented_in` | Recorded once by `../record-prompt.md`, after the code and the node updates are both committed |

An artifact missing a field is not filled in retroactively from memory. A field
with nothing to report is recorded as empty, not omitted, so a later reviewer can
tell the difference between nothing found and the check never having run.
