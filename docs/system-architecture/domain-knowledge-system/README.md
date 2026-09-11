# Domain Knowledge System

This folder is a knowledge layer for one application. It exists so that an agent
with no memory of past conversations about this system can still assemble correct
context for a task, implement it, record what it learned, and have that work
reviewed, using only the files here.

If `../domain-knowledge-system.md` is reachable from this copy, it is the full
methodology and the source of the section numbers cited below. If it is not
reachable, because this folder has moved into an application repository, everything
required to operate the tree is in this file and the ones it points to.

## The two rules that make retrieval work

**One subject per file, and the file name states the subject.** The file name is
the retrieval key. A rule or a domain area buried in a file whose name does not
announce it is unreachable. Adding knowledge about a new subject means adding a
file, not appending to a nearby one.

**Every candidate subject exists as a file, even before its content is written.**
The name has to be visible in a directory listing, because that listing is what a
task's requirements are matched against. A subject with no file cannot be selected,
and its absence produces no signal. A stub answers with `Status: Not written`,
which turns a missing rule or a missing area into a reported gap instead of a
silent omission.

## What each folder holds

| Folder | Holds |
| --- | --- |
| `specs/` | Reusable rules, one subject per file, grouped by discipline |
| `domains/` | Per-area and per-feature knowledge: how this system applied the rules and why |
| `artifacts/` | Per-task context artifacts and QA reviews, retained after completion |
| `indexes/` | Derived reverse lookups: rule to citing nodes, question to owning node, node to what it affects, task to decision to test to review |
| `templates/` | The entry shapes for a rule, a node, a context artifact, a QA review, a regression |

`identifiers.md` defines how every rule, decision, invariant, and review is named,
and every other file that cites one depends on it.

## What an agent does, by task

| Task | Run | Produces |
| --- | --- | --- |
| Starting a feature with acceptance criteria | `selection-prompt.md` | A context artifact under `artifacts/context/`, listing selected rules and nodes, uncovered criteria, over-pull, and open questions |
| After implementing | `record-prompt.md` | Decisions and invariants written into the relevant node files, with IDs |
| Reviewing a completed task | `qa-prompt.md` | A QA review under `artifacts/qa/`, checked against the context artifact and the implementation |
| Instantiating this folder for a new system | `TEMPLATE-USAGE.md`, then `bootstrap-prompt.md` | The deletions and area naming that adapt this template to one application |

The order for a single ticket is selection, then implementation, then recording,
then review. `completeness-checks.md` states what `record-prompt.md` and
`qa-prompt.md` each check for before treating a task as complete.

## What this template deliberately omits

`PHILOSOPHY.md`, `ROADMAP.md`, and `CHANGELOG.md`. Roadmap and pending decisions
live beside the code in the application repository, the project changelog follows
the existing project documentation convention, and philosophy lives in the
methodology document referenced above rather than being restated per project.
