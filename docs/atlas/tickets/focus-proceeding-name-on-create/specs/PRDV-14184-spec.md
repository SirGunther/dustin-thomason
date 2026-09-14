# Spec pointer — PRDV-14184

**The spec is not in this folder. It lives in the implementation repo, deliberately.**

> **Canonical spec:** `atlas-front-end/docs/specs/atlas-maintenance/proceedings/PRDV-14184-focus-proceeding-name-on-create.md`
> **Indexed at:** `atlas-front-end/docs/specs/README.md`

## Why it lives there

`atlas-front-end/docs/specs/README.md` routes spec homes by ticket shape:

> - Entirely UI ticket → **this repo**, `docs/specs/`.
> - Ticket has any Callisto BE / API / data work → **`callisto-back-end` `docs/specs/`**, including the FE section. Do not copy that spec here.

PRDV-14184 is entirely UI — the investigation ruled `callisto-back-end` out on evidence (the proceeding name is client-supplied on both create DTOs with no server-side default, so no contract, DTO, guard, or Swagger surface changes). So `atlas-front-end` is its home, and the top-level folder is the kebab-cased ClickUp **Project Name**, `atlas-maintenance`.

This also satisfies the orchestrate skill's Phase 3 requirement that a spec be **submitted through the surface the team actually reviews on** — for a shared-repo spec that means a branch and a PR, not a file sitting in a personal docs folder.

**Precedence note:** the orchestrate layout would place this at `specs/<slug>-spec.md` in the ticket folder. The app repo's documented file placement wins, per `personal-methodology` → *Precedence* ("Repo-specific `.cursor/rules/**` win for repo behavior and technical conventions… file placement and module structure"). Recorded here rather than resolved silently.

## What stays in this folder

- [`PRDV-14184-locked-decisions.md`](./PRDV-14184-locked-decisions.md) — the full `LD-001`–`LD-008` ledger with question gates. The spec's `Locked Decisions From Q and A` section summarizes it and links back here.
