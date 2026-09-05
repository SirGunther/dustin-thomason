# Domain Knowledge System: template

Copy this folder to start the knowledge layer for a system.

    docs/<project>/

The methodology it implements is [domain-knowledge-system.md](../domain-knowledge-system.md).
Section numbers cited in these files refer to that document.

## How to use it

1. Copy this whole folder to `docs/<project>/`.
2. Delete `README.md` (this file) and keep `selection-prompt.md`.
3. Delete discipline folders the system has no surface for. A headless service has
   no `specs/ui-ux/` and no `specs/accessibility/`.
4. Delete subject files that will never apply. What remains, still marked
   `Status: Not written`, is this system's set of named gaps.
5. Replace a stub with a real rule when an acceptance criterion selects it.

Instantiating is a deletion pass, not an authoring pass.

## The two rules that make retrieval work

**One subject per file, and the file name states the subject.** The file name is the
retrieval key. A rule buried in a file whose name does not announce it is
unreachable. Adding a rule about a new subject means adding a file, not appending to
a nearby one.

**Every candidate subject exists as a file, even before its rule is written.** The
name has to be visible in a directory listing, because that listing is what
acceptance criteria are matched against. A subject with no file cannot be selected,
and its absence produces no signal. A stub answers with `Status: Not written`, which
turns a missing rule into a reported gap instead of a silent omission.

## What each folder holds

| Folder | Holds |
| --- | --- |
| `specs/` | Reusable rules, one subject per file, grouped by discipline |
| `domains/` | Per-area and per-feature knowledge: how this system applied the rules and why |
| `artifacts/` | Per-task context artifacts and QA reviews, retained after completion |
| `indexes/` | Reverse lookups, created only when reading folder names stops being enough |
| `templates/` | The entry shapes for a spec and a feature node |

## What this template deliberately omits

`PHILOSOPHY.md`, `ROADMAP.md`, and `CHANGELOG.md` from §23. Roadmap and pending
decisions live beside the code in the application repository, the project changelog
follows the existing `docs/<project>/` convention, and philosophy lives in the
methodology document rather than being restated per project.
