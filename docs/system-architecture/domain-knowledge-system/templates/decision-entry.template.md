# Decision entry template

The shape of one entry in a node's Decisions section (§25). A decision is not a
standalone file; it is written inside the node file it belongs to, using this
shape, and cited elsewhere by its ID (`../identifiers.md`).

## Fields

```yaml
{{AREA-D-NNN}}: {{short title}}

status: {{Proposed | Accepted | Superseded by {{AREA-D-NNN}}}}

context: >
  {{the situation that required a decision to be made}}

applicable_specifications:
  - {{RULE-ID}}

decision: >
  {{what was decided}}

why: >
  {{the reason, stated so the reader understands what would go wrong under the
  rejected alternative without having to infer it}}

rejected: >
  {{the alternative that was not chosen, and why it was rejected}}

implementation:
  - {{file where this decision was realized, at the time the decision was made}}

verification:
  - {{AREA-I-NNN, or a test name}}

consequences: >
  {{a side effect or tradeoff accepted by making this decision}}

supersedes: {{prior decision id, or none}}
```

## Nine fields from the founding document, one addition

Status, Context, Applicable Specifications, Decision, Why, Implementation,
Verification, Consequences, and Supersedes come from §25. `rejected` is an
addition: the founding document's decision template does not have a field for the
alternative that was not chosen. It is kept because the alternative is exactly the
kind of knowledge that leaves no trace in the code or in a test, which is the same
reasoning `domains/README.md` gives for why the node shape has a Decisions field
at all.

## `implementation` is a point-in-time record, not a maintained map

`domains/README.md` states that the node shape has no persistent implementation
map, because a stored map goes stale as the code changes and would need constant
upkeep to stay correct. This field is different: it records where the decision was
realized at the time the decision was made, as historical evidence that the
decision was implemented at all. A later reader does not treat it as a claim about
where the code is now; the current location, if needed, is found by reading the
repository.

## Where Applicable Specifications differs from the node's Governs list

A node's frontmatter `governs` list is every rule that constrains the node.
`applicable_specifications` on one decision is the subset of those rules this
particular decision applies, which matters once a node has more than one decision
governed by different rules.
