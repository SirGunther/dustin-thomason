---
# Machine-readable header. Every index under indexes/ derives from these fields, so
# a field left out removes this node from that index rather than producing an error.
id: {{area}}.{{feature}}
kind: area | feature
area: {{area}}

# Proposed: written by bootstrap-prompt.md, no task has selected it yet. In use:
# a task has routed here. A node left Proposed after several tasks have run is
# reported as over-decomposition (see ../bootstrap-prompt.md).
status: Proposed | In use

# Set only when this feature moved to a different area after its decision and
# invariant IDs were allocated. The area prefix in those IDs is not updated to
# match; see ../identifiers.md, "Moving a feature between areas".
moved_from: {{prior area, or omit this field}}

# One-line questions this node answers. Used only to choose between sibling node
# files inside an area a task has already selected by folder or file name. This is
# not the primary selection mechanism: domains are selected by listing folder and
# file names, the same way specs are (see ../selection-prompt.md, step 1).
answers:
  - {{question this node answers}}

# Rules that constrain this node, with the revision it was last reviewed against.
# Source for specifications.yaml.
governs:
  - id: {{RULE-ID}}
    revision: {{sha at last review}}

# Nodes whose invariants this node's behavior can move. Source for dependencies.yaml.
affects:
  - {{node id}}

# What a sibling owns instead. Source for dependencies.yaml.
not_owned:
  - {{node id}}

# Identifiers declared in the body below, so an index can point at one. IDs are
# scoped to the area, not to this individual node file: {{AREA}}-D-{{NNN}} and
# {{AREA}}-I-{{NNN}}. See ../identifiers.md, "Decision and invariant IDs", for why
# area scope survives a later split into feature files and node scope does not.
decisions:
  - {{AREA}}-D-{{NNN}}
invariants:
  - {{AREA}}-I-{{NNN}}

# QA review IDs that have reviewed this node. This is the reverse reference for
# the reviewed-by edge (section 16). Appended by qa-prompt.md; do not edit by hand.
reviewed_by:
  - {{QA-REVIEW-ID}}

application_revision: {{sha}}
knowledge_revision: {{sha}}
---

# {{Area or Feature}}

Both revisions above are required. A node whose application revision falls behind
while its implementation sites changed is suspect, which is the only available signal
that a decision quietly stopped being true.

## Governs

For each rule listed in the frontmatter, why it bites on this node. Say what makes
this node fall inside the rule's applicability, not what the rule says.

    {{RULE-ID}}: {{why this rule reaches this node}}

## Decisions

What was decided, why, and what was rejected. The rejected alternative is the part
that appears in no test and no code. IDs are area-scoped: `{{AREA}}-D-{{NNN}}`. Each
entry uses the full shape in
[decision-entry.template.md](decision-entry.template.md), not a shortened version
of it.

## Invariants

Each statement paired with the test that proves it. An invariant with no named test
is an unverified claim. IDs are area-scoped: `{{AREA}}-I-{{NNN}}`.

    {{AREA}}-I-{{NNN}}
    Must remain true: {{what}}
    Proven by: {{test name or file}}

## Not owned

For each node listed in the frontmatter, what it owns that this node does not. This
is what keeps an implementation from landing in the wrong place.

## Affects

For each node listed in the frontmatter, which of its invariants this node's behavior
can move. A node touched by a change but absent from the context artifact is a
recorded retrieval miss and becomes a new entry here.

## History

Failed attempts and abandoned approaches. Regressions, with the invariant id each one
violated and why existing evidence failed to detect it. Change lists stay in git; this
section holds what git cannot show.
