# Investigation method — software lens

> **Status:** adopted (2026-07-18) — the mandatory software-lens questions in Phase 1 of the `orchestrate` skill (`../skills/orchestrate/SKILL.md`); also usable standalone alongside `agents/skills/investigation/SKILL.md`. These are questions the base method does **not** force, that a real software investigation needs.
> **Companion:** [investigation-question-coverage.md](./investigation-question-coverage.md) audits the questions we already had; this doc holds the net-new ones.

## The organizing idea: ground *sideways*, not just down and up

The method already grounds in two directions:

- **Downward** — "show me the instance." (Step 1: named, blocked, real.)
- **Upward** — "does it solve the class?" (Steps 2/5.)

Software bugs need a **third direction — sideways/outward, across the code surface.** Instance-and-class framing can't see that code has a *surface* (every call site that can reach the behavior), a *contract* (an authoritative layer someone else owns), *neighbors* (other behavior sharing the same code path), and a *detection net* (the tests/types/review that were supposed to catch this). The class of PRDV-16047 was obvious in one sentence; the entire investigation was sideways work. The four candidates below are that missing axis. They're worth asking on any change that touches shared code or crosses a layer boundary — not just bugs.

---

## Candidate 1 — Contract / source-of-truth alignment

- **What we mean to ask:** What is the authoritative definition of this behavior, and who owns it (a backend guard, an API contract, a DB constraint, a shared type, a spec)? Does the layer we're changing **mirror it exactly**? Where could the two **drift apart again** later?
- **Why it's useful:** A large share of software defects are not logic errors — they're one layer disagreeing with the layer that actually decides. If you don't name the authority and check the mirror, you "fix" the symptom on the wrong side and it silently re-drifts.
- **Where it attaches:** SKILL Step 4 (trace why it exists) → after finding origin, identify the authority and verify the mirror. Report: fold into §5 (Why it exists) or a new "Contract alignment" line in §7.
- **16047 evidence:** the whole root cause — the frontend gated withdraw on `SUBMISSION_PROCEEDING_FILES_<TRACK>` while the backend guard (`MultiDeliverableFileAuthorizeRole`) authorizes on `CLIENT_DELIVERABLE_PROCEEDING_FILES_<TRACK>`. The fix was "make the FE mirror the BE authority exactly"; the durable risk is re-drift.
- **Done-when / artifact:** the authoritative source is named with a pointer; the changed layer is shown to match it (ideally byte-identical, as with the resource-key strings); the re-drift risk is noted.

## Candidate 2 — Exhaustive surface enumeration (blast radius)

- **What we mean to ask:** What are **all** the call sites / entry points / consumers this change touches — and **how do we know the list is complete** (grep for callers, type/usage references, i18n keys, route/registry entries)?
- **Why it's useful:** The method's Step 6 already says "prove the defect isn't leaking out to somewhere we haven't modeled" — but as a *principle*, not a forced artifact. An un-enumerated surface is exactly where a fix half-lands: you patch the obvious path and miss the twin. Requiring the list + a completeness claim is what turns the principle into a catch.
- **Where it attaches:** SKILL Step 6 (make the enumeration an explicit output of the negative-path work). Report: a "Affected surfaces" list in §7 or §9.
- **16047 evidence:** the withdraw action had **three** entry points (row-single, row-batch, and the FAB). The FAB had *no* permission check at all and was the easiest to miss — it only surfaced because the entry points were enumerated and the plumbing (`useUnapproveFlow`, imported by exactly two tables) was traced to prove the list was complete. A feared 4th surface (a `deliverables.bulkActions` i18n key) was checked and confirmed non-existent.
- **Done-when / artifact:** an enumerated list of every surface that can reach the behavior, plus a one-line statement of how completeness was established ("`useUnapproveFlow` imported only by X and Y; grep of `withdraw*` i18n keys yields exactly these three").

## Candidate 3 — Protect-the-neighbors (regression proof)

- **What we mean to ask:** What existing behaviors share this code path and **must not change**? How did we verify they stayed identical?
- **Why it's useful:** Distinct from "adjacent issues" (which is about *new* problems worth fixing) and from negative paths (which prove the *new* behavior fails visibly). This is the opposite duty: name the neighbors on the shared path and prove they didn't move. It's the "absence of change verified against a concrete surface" discipline — the thing that stops a fix from quietly regressing a sibling.
- **Where it attaches:** SKILL Step 5 (Fit) or Step 6. Report: a "Unchanged surfaces (verified)" line in §9.
- **16047 evidence:** the withdraw items shared the `canModifyDeliverableApproval` flag with **Approve**, and had a deliberate **audio "cannot withdraw" tooltip**. The fix had to leave Approve gating (submission resource) and the audio disabled+tooltip untouched — both were named and asserted (Approve verified unchanged; audio preserved via the `v-if` audio special-case + a menu spec).
- **Done-when / artifact:** each shared-path neighbor named, with the concrete check that confirmed it's unchanged (a test, a preserved branch, an asserted prop).

## Candidate 4 — Detection gap (why the net missed it)

- **What we mean to ask:** Why wasn't this already caught — no test, a permissive/`any`-typed seam, a review blind spot, an untested component? (Bugs only.)
- **Why it's useful:** The answer *designs the regression test you add.* "Why it exists" (Step 4) explains the defect's origin; this explains the **detection** failure, which is a different and equally actionable finding. Currently it lives only as a bug-closeout checkbox in the report DoD, too late to shape the fix.
- **Where it attaches:** SKILL Step 4 checkpoint (for the software branch). Report: a line under §5.
- **16047 evidence:** the shared `canModifyDeliverableApproval` flag conflated two backend-distinct permissions, and `ProceedingFileRowActionsMenu` had **no** spec at all — so nothing could have caught the drift. That gap is exactly what the new `useProceedingFilePermission.spec.ts` (submission-only → `false`) and the first menu spec now close.
- **Done-when / artifact:** a one-line detection-failure cause, tied to the specific test/type/guard added to close it.

---

## Two refinements (sharpen existing steps rather than add sections)

- **Red→green regression test.** Step 6 should ask for the test that **fails before / passes after**, encoding the exact defect — not just "a testing strategy." This is what makes the fix's proof durable and prevents silent re-drift. (16047: the `useProceedingFilePermission` drift case.)
- **Reproduction recipe + preconditions.** The software branch should ask for the role / data-state / feature-flag / environment needed to observe the defect. "Actor / action / moment" (Step 5) is adjacent but not the SE "how do I see this locally, and what's gated" recipe — the absence of which is exactly what ballooned 16047 into a separate local-testability question.

## Also flagged (from the coverage checklist, if we ever promote them)

- **P→R→S as an explicit ordered narrative** — components exist across Steps 1/3/5 but aren't ordered/named; personal-vs-general-skill decision.
- **A transcript/discussion evidence sub-branch** — the four extraction outputs exist; the "mine a meeting transcript" lens doesn't. Low priority.
