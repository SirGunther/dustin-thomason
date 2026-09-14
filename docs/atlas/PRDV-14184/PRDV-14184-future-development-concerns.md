---
ticket: PRDV-14184
tags: [atlas, callisto, proceedings, validation, concerns]
author: Dustin Thomason
created: 2026-09-11
modified: 2026-09-13
---

# PRDV-14184 — Future-development concerns (proceeding-name uniqueness)

> **Context:** PRDV-14184 is a focus/affordance ticket on the two Proceeding create surfaces. While enumerating those surfaces, the investigation read both components' duplicate-name validation and the backing DB constraint, and found them in three-way disagreement. None of it is in scope for a focus change.
> **Purpose of this document:** a dated, code-verified record that these risks were identified and raised — for team discussion and, where needed, escalation.
> **Constructive path forward:** a small companion ticket that (a) fixes the misnamed constraint to actually be case-insensitive, following the `records` table's existing correct pattern, and (b) aligns both client-side checks to whatever the constraint then enforces. Neither is coupled to PRDV-14184 and either can ship independently.

## Executive summary (for escalation)

**A uniqueness constraint on `callisto.proceedings` is named `UQ_proceeding_value_per_job_case_insensitive` but is not case-insensitive.** It is a plain `UNIQUE ("value", "job_id")`, which Postgres enforces case-sensitively. The correct implementation for exactly this requirement already exists one table over, on `records`, using a functional unique index on `LOWER("value")`.

**Why it matters even if rare — the fallout, not the probability.** Two proceedings on the same job can differ only by capitalisation ("Deposition of J. Smith" and "deposition of j. smith"). Proceedings are the organising unit that deliverable files, client access grants, and submissions hang off, so a near-duplicate is not a cosmetic annoyance: it is a second container that looks like the first one in a list, and files can be filed against the wrong one by a user who cannot visually distinguish them. Recovery means moving files between proceedings after the fact, not editing a label. Separately, anyone reading the schema sees a constraint name asserting a guarantee the database does not provide — the name is actively misleading to the next developer, which is how this kind of thing survives review twice.

**Compounding it, the two create surfaces disagree with each other and neither is authoritative.** The Job Submission form rejects case-variant duplicates client-side; the Job Detail overlay accepts them. So the same input succeeds or fails depending on which screen the user happened to use — and the stricter screen is stricter than the database itself.

**Decision requested**, from whoever owns the Callisto proceedings schema:
- **(a)** Fix the constraint to match its name — drop and recreate as a functional unique index on `LOWER("value")`, mirroring `records` — then make both client checks case-insensitive to match. Requires a data audit first: existing case-variant rows would violate the new index.
- **(b)** Keep the database case-sensitive and **rename** the constraint to stop it lying, then relax the Job Submission form's check to match. Cheapest, and honest, but leaves the near-duplicate exposure open.
- **(c)** Accept as-is and record it. Not recommended — the misleading name alone will cost someone an investigation later, as it did this one.

## Concern 1 — The proceedings uniqueness constraint does not do what its name says

The migration adds a plain multi-column unique constraint while naming it `_case_insensitive`. In Postgres, `UNIQUE ("value", "job_id")` compares `value` with the column's collation, case-sensitively. Nothing in the schema lowercases either side.

This is demonstrably a copy of the *name* without the *mechanism*: the `records` table had the same requirement and solved it correctly **eight timestamps earlier**, by explicitly dropping the plain constraint and creating `UNIQUE INDEX … (LOWER("value"), "job_id")`. The proceedings migration's own docblock says only "Adds unique constraint on (value, job_id)" — the docblock is accurate and the constraint name is not.

- **Evidence (verified 2026-09-11, `callisto-back-end@d84a4628`):**
  - `src/typeorm/migrations/1766801287907-alter__add_unique_value_job_id__proceedings_table.ts:13` — `ADD CONSTRAINT "UQ_proceeding_value_per_job_case_insensitive" UNIQUE ("value", "job_id")`
  - `src/typeorm/migrations/1758811836915-alter__add_case_insensitive_unique_constraint__records_table.ts:16-19` — the correct pattern, on the sibling table
  - `src/shared/shared-entities/entities/proceedings/proceeding.entity.ts:17` — the entity mirrors the misleading name
- **What would resolve it:** option (a) or (b) above. Either closes the lie; only (a) closes the exposure.

## Concern 2 — The two Proceeding create surfaces enforce different duplicate rules

Both surfaces validate duplicate names client-side, and they do not agree. Because the server-side error path only surfaces a `DuplicateProceedingError` when the DB constraint actually fires, the *client* check is effectively the rule users experience — and it differs by screen.

| Surface | Check | Relative to the DB |
| --- | --- | --- |
| `NewProceedingsOverlay.vue:65-67` (Job Detail) | case-**sensitive** (`proceeding.trim() === trimmedValue`) | matches actual DB behavior |
| `AddProceedingForm.vue:51-55` (Job Submission) | case-**insensitive** (`.toLowerCase()` both sides), and also checks `existingProceedings` | **stricter than the DB** |

The job-submission surface therefore blocks input the database would accept, while the job-detail surface permits input that creates the near-duplicate in Concern 1. The divergence is invisible to a user, who simply learns that "it lets me do it here but not there."

- **Evidence (verified 2026-09-11, `atlas-front-end@420c395a`):** `NewProceedingsOverlay.vue:65-67`; `AddProceedingForm.vue:51-64`; server-side error mapping at `create-proceedings.transaction.script.ts:42-54`
- **What would resolve it:** align both checks to whichever rule the constraint decision (Concern 1) settles on. Worth doing in the same companion ticket, since deciding one without the other just moves the inconsistency.

## Concern 3 — Two near-duplicate proceeding forms with independently drifting logic

Concern 2 is a symptom of this. `NewProceedingsOverlay.vue` and `AddProceedingForm.vue` are parallel implementations of the same feature — same `ref([''])` + `push('')` repeater, same 20-row cap, same min-3/max-128/invalid-character rules, same trim-and-emit save — written separately and already drifted (duplicate-check casing; the form additionally validates against `existingProceedings`; the overlay alone offers row removal).

PRDV-14184 will touch both, which is the concrete cost: every change to this feature is made twice, and the two copies have already proven they drift when that happens. Flagged, **not** proposed — consolidating them is a materially larger change than any ticket that has touched them so far, and it would need its own investigation into whether the differences are accidental or deliberate.

- **Evidence (verified 2026-09-11, `atlas-front-end@420c395a`):** `NewProceedingsOverlay.vue:29-127` vs `AddProceedingForm.vue:25-112` — compare `validateProceeding`, `canAddMore`, the append handlers, and the reset/save paths
- **What would resolve it:** an investigation ticket asking whether the two surfaces should share a composable (validation + row state) and which behavioral differences are intentional. Not a refactor to be attempted incidentally.

### Addendum 2026-09-11 (Phase 3) — this ticket knowingly adds a fourth duplicated element

`LD-002` in the [locked-decision ledger](./specs/PRDV-14184-locked-decisions.md) commits PRDV-14184 to **inlining** the focus logic in both components rather than extracting it. That is a deliberate, risk-accepted choice and it makes this concern incrementally worse: ref-collection plus deferred focus becomes the fourth thing these two files each implement separately, after row state, validation, and the row cap.

The reasoning for accepting it: the two AC-1 triggers are genuinely different code (S1 watches a `modelValue` prop; S2 toggles a local ref inline in its template), so extraction would share roughly four lines while adding indirection; `atlas-front-end-patterns.mdc:766` scopes composable extraction to *complex* logic; and the repo has four one-off `.focus()` sites with zero extracted helpers.

**The residual risk is specific:** if the two surfaces' focus behavior later needs to diverge or be corrected, it must be corrected twice, and nothing in the code links the two copies. The honest mitigation is not extraction-under-pressure inside a 1-point ticket — it is that the consolidation investigation named above should now treat focus as a fourth item in its inventory, not three. `LD-002` is explicitly marked reversible at spec review.

## Concern 4 — the Job Detail restriction gate is cosmetic (surfaced in spec review, 2026-09-11)

`AddNewProceeding.vue` computes a `disabled` value from **both** `canCreateProceedings` and `hasRestrictionActionAccess` (the job-restriction check), but then binds it only to `:class`:

```
:class="[styles.newProceedingButton, { disabled }]"      // L46 - styling only
@click="canCreateProceedings ? (showNewProceedingsOverlay = true) : null"   // L48
```

The value never reaches the button's `disable` prop, and the click handler tests `canCreateProceedings` **alone**. So on a restricted job the **New proceeding** button renders in a disabled style while remaining fully clickable, and the overlay opens. `hasRestrictionActionAccess` currently governs nothing but appearance.

Two things worth separating. The **restriction bypass** is a real authorization weakness on the client, though its blast radius is bounded by the server: creating a proceeding still goes through `POST` and Callisto's own guard, so this is not by itself a path to unauthorized writes. The **UI dishonesty** is the part that bites sooner — a control that looks disabled and is not teaches users the styling is meaningless, and it is exactly the sort of thing that gets read as "the check exists" during a later review.

- **Evidence (verified 2026-09-11, `atlas-front-end@420c395a`):** `AddNewProceeding.vue:33-35` (the computed), `:46` (bound to `:class`), `:48` (click handler). Compare `AddProceedingForm.vue:118`, which **does** bind `:disable` properly.
- **Why it is not fixed in PRDV-14184:** a focus/affordance ticket is the wrong vehicle for changing who can open a create surface. Correcting the gate changes behavior for restricted jobs and needs its own acceptance criteria and test coverage. PRDV-14184 does not widen access — it leaves the set of users who can open each container exactly as it was.
- **What would resolve it:** pass `disabled` to the button's `disable` prop and include `hasRestrictionActionAccess` in the click guard, with a spec case per branch. Small change; needs a ticket so the behavior change is visible to QA.

## Decision history

- **2026-09-13** — Concern 4 added from **spec review** on PR #572: a reviewer found that the S1 restriction check is bound to `:class` only. The spec had asserted that focus runs only after a container the user was permitted to open — an overstatement, now corrected in the spec.
- **2026-09-11** — Concerns raised during PRDV-14184 Phase 1/2 investigation while enumerating proceeding-name create surfaces. An initial pass asserted the DB constraint was case-insensitive based on its name and concluded the overlay was the surface out of step; reading migration `1766801287907` refuted that and reversed the conclusion. The corrected finding is recorded in the investigation report §7 and coverage-ledger area 9. No decision requested of anyone yet — this document is the raising.

## Open questions to settle

1. Should the proceedings constraint be made genuinely case-insensitive (option a) or honestly renamed (option b)? — owner: **Callisto proceedings schema owner / lead dev**
2. Does production contain existing case-variant proceeding rows that would block option (a)? — owner: **whoever can query the environment** (a `SELECT LOWER(value), job_id, COUNT(*) … HAVING COUNT(*) > 1` audit)
3. Are the behavioral differences between the two create surfaces deliberate? — owner: **Ops / product**
