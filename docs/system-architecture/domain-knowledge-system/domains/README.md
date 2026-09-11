# domains

A domain is a meaningful area of the system (§3.2). A feature is a bounded piece of
concrete product behavior within it (§3.3). Domain and feature knowledge record how
this system applied the rules in `specs/` and why, and never restate the rules
themselves (§5).

## Naming is the retrieval mechanism, the same as specs

One area or feature per file. The file name states the area or feature. Acceptance
criteria are matched against these names directly, the same way they are matched
against `specs/` file names (see `../selection-prompt.md`, step 1). A domain
concept described only in prose inside another file's body is not reachable by that
matching step.

## Universal area stubs

This folder ships with a starting set of area stub files for product areas that
recur across a large fraction of applications: `accounts.md`, `sessions.md`,
`permissions.md`, `notifications.md`, `search.md`, `settings.md`, `onboarding.md`,
`billing.md`, `import-export.md`, `files.md`, `messaging.md`, `reporting.md`,
`integrations.md`, `scheduling.md`, `audit-log.md`. Each carries `Status: Not
written` and a one-line scope, the same convention as a `specs/` stub, so that an
area this system does not have still exists as a reportable gap rather than a
silent absence.

Delete the ones that do not apply to this system during instantiation
(`../TEMPLATE-USAGE.md`). The areas this list does not cover, because they are
specific to this one application, are named once by
`../bootstrap-prompt.md`, not pre-written here.

## Shape

    domains/
    ├── <area>.md                       an area with no child features yet
    └── <area>/
        ├── knowledge.md                what applies across features in this area
        └── features/
            └── <feature>.md            one bounded behavior

Start every area as a single file. It becomes a folder when a child feature earns
its own file.

## When a child feature earns its own file

At least one of:

- a decision with a rejected alternative,
- an invariant that a named test actually asserts,
- a recorded regression.

Below that bar the knowledge stays as a section in the area file. This is the guard
against reproducing the source tree in prose (§32), and it is also why
`bootstrap-prompt.md` never writes a feature file directly: at instantiation, no
candidate has a decision, a tested invariant, or a regression yet, so nothing
clears this bar.

## Status

A node's frontmatter `status` is `Proposed` while it was written by
`bootstrap-prompt.md` and no task has selected it yet, and `In use` once a task
has. A node left `Proposed` after several tasks have run without selecting it is
reported by the bootstrap prompt's diff mode as over-decomposition, the
domains-side equivalent of a specification file no criterion needed.

## Node shape

Every node file follows
[feature-node.template.md](../templates/feature-node.template.md): Governs,
Decisions, Invariants, Not owned, Affects, History.

Four fields exist because they cannot be rebuilt from the repository. Invariants,
because code shows what it does and never what must not stop being true. Decisions,
because a rejected alternative leaves no trace. Not owned, because a deliberate
exclusion is absent from the code. History, because an abandoned attempt is recorded
nowhere else.

Purpose, interfaces, an implementation map, and a standalone test map are omitted on
purpose. All four are recoverable by reading the repository, and a stored copy goes
stale faster than the code it describes. Implementation locations are resolved at
task time and are evidence, never a boundary on what may be read.

## Edge cases and known limitations

§24's feature template lists Edge Cases and Known Limitations as their own
sections. This node shape does not carry either as a separate section, because
each reduces to a field this shape already has:

- An edge case that must continue to hold is an invariant.
- An edge case that is deliberately left unhandled is a decision, with the choice
  to leave it unhandled recorded as the decision and the alternative of handling
  it recorded as rejected.
- A known limitation is a decision with a rejected alternative: the limitation is
  what was decided, and what removing it would have required is the rejected
  alternative.

## The `answers` field is a discriminator, not the selection key

A node's frontmatter `answers` list is used only to choose between sibling node
files inside an area a task has already selected by folder or file name. It is not
what makes a domain area findable in the first place; that is the file name, per
the naming rule above. Routing selection primarily through `answers` was tried and
rejected: a free-text question invented per node matches an acceptance criterion on
fewer shared words than the file's own subject name does, no two authors phrase the
same question identically, and a missing question produces no file the way a
missing rule subject does under `specs/`.
