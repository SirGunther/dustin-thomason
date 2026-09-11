# Identifiers

How every citable thing in this tree is named. Every other file that cites a
decision, an invariant, or a rule depends on the rules in this file.

## Rule IDs

A rule ID is derived from its file path. No sequence number is added.

Transform: take the file's stem (the name without `.md`), uppercase it, keep every
hyphenated word. Prefix it with the discipline code below.

    specs/ui-ux/overlays.md          ->  UX-OVERLAYS
    specs/accessibility/keyboard-only.md   ->  A11Y-KEYBOARD-ONLY
    specs/qa/keyboard-coverage.md    ->  QA-KEYBOARD-COVERAGE

The transform keeps every character of the stem on purpose. Singularizing or
abbreviating collides distinct subjects: `ui-ux/keyboard.md`,
`accessibility/keyboard-only.md`, and `qa/keyboard-coverage.md` must not all reduce to
`KEYBOARD`. An ID that resolves to more than one file cannot be cited reliably.

### Discipline prefixes

| Folder | Prefix |
| --- | --- |
| `ui-ux` | `UX` |
| `accessibility` | `A11Y` |
| `architecture` | `ARCH` |
| `backend` | `BE` |
| `data` | `DATA` |
| `security` | `SEC` |
| `qa` | `QA` |

### No sequence number

A rule ID never carries a counter such as `-001`. One file holds exactly one rule
(`specs/README.md`), so the file's own name already identifies it uniquely. A second
rule about a related subject is a second file, with its own name and its own ID:
`specs/ui-ux/overlays.md` and `specs/ui-ux/overlays-dismissal.md` are two rules, two
files, two IDs. A counter would permit two rules to share one file, which
`spec-entry.template.md` prohibits, and it would stop the filename from identifying
exactly one rule, which is what the selection prompt depends on.

### Stub IDs

A stub carries an ID from the moment its file exists, because the ID is derived from
the path and needs no written content. A node can therefore cite a rule that has not
been written yet. `indexes/specifications.yaml` records that case under
`entries_unwritten` rather than omitting it.

### Withdrawal, not deletion

A rule that no longer applies is marked `Status: Withdrawn` in its file
(`spec-entry.template.md`), not deleted. The file remains in the directory listing,
which records that the subject was considered and rejected rather than never
considered. Deletion of a rule file is permitted only during instantiation
(`TEMPLATE-USAGE.md`), before any node can have cited it.

### Renaming a rule file

A rule ID changes if its file is renamed, because the ID is the path. Every node
citing the old ID becomes an orphaned citation, which
`indexes/specifications.yaml`'s regeneration procedure reports under `orphaned:`
rather than silently dropping. Fixing an orphaned citation means updating the citing
node's `governs` entry to the new ID.

## Decision and invariant IDs

A decision or invariant ID is scoped to the area, never to the individual node file.

    SESSIONS-D-004
    SESSIONS-I-003

### Why area scope, not node scope

`domains/README.md` documents the tree's lifecycle: an area starts as a single file
and becomes a folder once a child feature earns its own file. If a decision's ID were
scoped to the node, extracting that decision into a new feature file would force
renumbering it, and a context artifact recorded before the split would then resolve
its citation to a different decision than the one it captured. An area-scoped ID
survives the split unchanged, because the feature file is carved out of the area but
the area's namespace does not change.

### Allocation

The next number for an area is one greater than the highest number already used by
that area's decisions or invariants, found by reading the frontmatter of every node
file under that area, including any feature files it has been split into. This
requires no central registry, only a read of one folder.

### Moving a feature between areas

A feature's decision and invariant IDs keep their original area prefix when the
feature moves to a different area. The node's frontmatter gains a `moved_from` entry
naming its original area. An ID whose prefix no longer matches its current folder is
visible and resolves correctly; renumbering it would make it invisible and resolve
incorrectly, since the same failure identified for rule renames applies here too.

## Where each identifier is declared

| Identifier | Declared in | Format defined in |
| --- | --- | --- |
| Rule ID | The rule's own file, in its heading | This file, Rule IDs |
| Node ID | The node's frontmatter, `id:` field | `feature-node.template.md` |
| Decision ID | The node's frontmatter `decisions:` list and its Decisions section | This file, Decision and invariant IDs |
| Invariant ID | The node's frontmatter `invariants:` list and its Invariants section | This file, Decision and invariant IDs |
| QA review ID | The review's own file | `qa-review.template.md` |
| Regression ID | The regression's own file | `regression.template.md` |
