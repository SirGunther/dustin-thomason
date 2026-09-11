# indexes

Four reverse lookups, all present from the start, all empty until nodes exist.

    specifications.yaml   rule to the nodes that cite it
    features.yaml         question to the node that owns the answer
    dependencies.yaml     node to what it affects and what it does not own
    traceability.yaml     task to rule to decision to test to review

An index that does not exist cannot report that it is empty, which is the same
reason every candidate subject under `specs/` ships as a file. Each of these
declares its source field, its regeneration rule, and `entries` holding nothing.

## specifications.yaml splits into three lists, not one

A node's `governs` list cites a rule ID, and that ID can point at a file whose
rule is written, a file whose rule is not yet written, or no file at all if the
rule file was renamed or deleted after being cited. `specifications.yaml`
separates these: `entries` for citations resolving to a written rule,
`entries_unwritten` for citations resolving to a `Status: Not written` stub, and
`orphaned` for citations resolving to nothing. Reporting these as one undivided
list would make a citation to a nonexistent rule indistinguishable from a
citation to a well-supported one.

## Every index is derived

None of these is authored by hand. Each one names the frontmatter field it reads
and is replaced wholesale when regenerated, never merged. A merge preserves a link
whose source has been removed, which is how a reverse index starts lying.

Regeneration is a procedure an agent runs, not a script, because the system is
operated by agents and a script adds a toolchain dependency the knowledge layer does
not otherwise have. The rule is written at the top of each file.

## The one thing that stays curated

`Known Consumers` in a spec file. `specifications.yaml` gives every consumer,
complete and unranked, which is what impact analysis needs. An integration needs the
one example worth copying, and choosing it is a judgment that cannot be derived.

## What blocks each one today

None of the four fill on the first node existing. `bootstrap-prompt.md` writes area
files with `governs`, `affects`, `not_owned`, `decisions`, and `invariants` all
empty, since nothing at instantiation has applied a rule, recorded a decision, or
found a dependency yet. `specifications.yaml`, `features.yaml`, and
`dependencies.yaml` fill once the first task has run `record-prompt.md` and
populated those fields on at least one node.

`traceability.yaml` additionally requires a completed context artifact and a
completed QA review to join, since its rows are task to rule to decision to test
to review. Decision and invariant identifiers are defined in `../identifiers.md`.
