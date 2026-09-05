# domains

A domain is a meaningful area of the system (§3.2). A feature is a bounded piece of
concrete product behavior within it (§3.3). Domain and feature knowledge record how
this system applied the rules in `specs/` and why, and never restate the rules
themselves (§5).

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
against reproducing the source tree in prose (§32).

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
