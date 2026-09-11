# Instantiating this template

Read this before copying the folder. Delete this file once instantiation is done;
`README.md` is the file that stays.

## Steps

1. Copy this whole folder to `docs/<project>/`.
2. Delete this file (`TEMPLATE-USAGE.md`). Keep `README.md`.
3. Delete discipline folders under `specs/` the system has no surface for. A
   headless service has no `specs/ui-ux/` and no `specs/accessibility/`.
4. Delete specification stub files that will never apply. What remains, still
   marked `Status: Not written`, is this system's set of named gaps.
5. Under `domains/`, delete universal area stubs that do not apply to this system.
   Run `bootstrap-prompt.md` once against the target application's source to name
   the areas the universal list does not cover.
6. Replace a specification stub with a real rule when an acceptance criterion
   selects it. Write a decision or invariant into a domain node the same way, using
   `identifiers.md` for how to derive or allocate its ID.

Instantiating is a deletion and one bootstrap pass, not an authoring pass.

## What is universal versus what gets named per project

`specs/` ships pre-written subject stubs because UI/UX, accessibility, architecture,
backend, data, security, and QA subjects come from a discipline vocabulary that
exists independently of any project.

`domains/` ships a smaller set of pre-written area stubs, because some product areas
recur across a large fraction of applications (`accounts`, `sessions`,
`notifications`, `settings`, and so on), listed in `domains/README.md`. The areas
specific to one system, such as `inference` or `wiring`, are not universal and are
not pre-written. `bootstrap-prompt.md` names those, once, from the target
application's contracts, routes, and test names, not from its directory layout.
