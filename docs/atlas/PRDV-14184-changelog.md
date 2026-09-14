# PRDV-14184 — Focus Proceeding name field on create

## Ticket

- **ClickUp:** [PRDV-14184](https://app.clickup.com/t/43227262/PRDV-14184)
- **Repo:** `atlas-front-end`
- **Branch:** `PRDV-14184-spec` (spec review); implementation branch not yet created
- **PR (spec):** https://github.com/planetdepos/atlas-front-end/pull/572

---

## Requirements (verbatim)

_Paste from ClickUp, spec, or the user's first description. Do not paraphrase on first capture._

> As an Ops Atlas user, I want the focus to be on the Proceeding Name field after Create, so that I don't have to click twice (once to "add new" and then another to select the text box) to start naming a new Proceeding Name.
>
> Acceptance Criteria (verbatim from ClickUp):
> - When users create a new Proceeding the proceeding name field is highlighted by default so users don't have to first click into the field to begin typing.
> - When uses add an additional proceeding, the following proceeding name field is also highlighted by default so users don't have to first click into the field to begin typing.

Full capture: [docs/atlas/tickets/focus-proceeding-name-on-create/PRDV-14184-original-ticket.md](./tickets/focus-proceeding-name-on-create/PRDV-14184-original-ticket.md)

---

## Context

_Optional: related tickets, environment, files to avoid, spec paths, team decisions._

- Orchestrated via the `orchestrate` skill — ledger at [docs/atlas/tickets/focus-proceeding-name-on-create/orchestration.md](./tickets/focus-proceeding-name-on-create/orchestration.md).
- Repository scope per the WorkLists item: `atlas-front-end` (UI change) and `callisto-back-end` (scope named, not yet confirmed as touched — Phase 1 recon will confirm whether any backend change is actually needed for a client-side focus behavior).
- WorkLists card: `todo-1789145480003-4fc6a07d`.

---

## Plans

_Lives in **dustin-thomason** only. Reference plans here so future agents do not repeat abandoned approaches. **Larry-adams** paths are **read-only links** to coworker specs — never create or push changelog/plan files there._

| Added | Plan (path or link) | Status | One-line approach |
| ----- | ------------------- | ------ | ----------------- |
| YYYY-MM-DD | _Cursor plan, in-session label, or read-only `larry-adams/...` spec path_ | `active` \| `implemented` \| `superseded` \| `abandoned` | _What this plan proposed_ |

**Status:**

- **active** — current direction; check here before a new plan
- **implemented** — shipped (link session log / commits); keep for history
- **superseded** — replaced by a newer plan row; do not retry without user ask
- **abandoned** — tried or rejected; see **Attempt history** for why

When a Cursor/agent **plan** is generated for this ticket, add a row the same day (path, export, or short title + where it lives). If work followed a plan only loosely, say so in **Session log** → **Plan used:**.

---

## Session log

_Newest first. Add one block before each commit (agents) or end of work session (you)._

### 2026-09-13T00:00:00Z — atlas-front-end (Phase 3 — spec review round 4)

- **Summary:** Reviewer revised the assessment to **approve with one test-plan correction**; implementation design accepted as accurate and in scope. Two defects, both in the proposed tests, neither in production code. **(1)** The spec required a test proving focus "survives row removal" while LD-007 deliberately gives removal no focus behavior — the test asserted a requirement the spec does not make. Replaced with **remove-then-append asserting the active element is the newly appended input**, which covers the real risk (positional keys + `splice` → stale index) as an AC-2 assertion. NP-3 narrowed to what removal owns (no error, no stale-ref exception). **(2)** `document.activeElement.isConnected` was used as the proof of a live ref — but `document.body.isConnected` is `true` and focus falls back to `<body>` when the focused node is removed, so it passed in exactly the failure it was meant to catch. Identity against the expected element is now the assertion. **Notable:** that vacuous assertion sat inside the spec's own **anti-vacuity** section — the assertions written to stop focus tests passing without proving focus.
- **Files:** `atlas-front-end/docs/specs/atlas-maintenance/proceedings/PRDV-14184-focus-proceeding-name-on-create.md`; `testing/PRDV-14184-test-plan.md` (NP-3, AV-2, pass/fail table, test map)
- **Verification gates:** lint `npm run lint` → pass (exit 0). Audit unchanged (failing, waived, docs-only). Tests not applicable — no executable code changed.
- **Commits:** `d496e353`; response posted to PR #572.
- **Notes:** Reviewer dropped the `autofocus` wording and the authorization/DB observations as documentation-only; both retained in the spec as recorded context. **Spec is ready from my side.** Still no product code. **Phase 4 remains blocked on the Product decision for surface scope (LD-012)** — S1 is unaffected and ready to implement on approval; S2 conditional. Paused here at the user's instruction.

### 2026-09-13T00:00:00Z — atlas-front-end (Phase 3 — spec review round 3)

- **Summary:** Three findings, all **self-contradictions** left by partial edits in rounds 1-2. **(1) Scope said open, table said closed.** The spec's own LD summary table stopped at LD-008 and never received LD-009-012, so LD-001 still read "Both surfaces in scope" while the prose said Product must confirm, and the file plan listed S2 unconditionally. LD-001 struck through, LD-009-012 added, S2 files marked CONDITIONAL. **(2) Three-way trigger conflict.** The Requirement said focus follows visibility, the Design said it follows the user's request, and the Risks table still demanded the discarded `editing && showAddForm` watcher plus a test proving re-entry focuses. Settled on the explicit-open contract and propagated through requirement, solution, risks, tests, and the living why-doc wedge (which was the original source of the visibility framing). **(3) S2 test scope over-broad.** LD-004 required characterizing the whole component; the guardrail actually says "comprehensive across **the seams you influence**" and I had dropped the qualifier. Narrowed to open/append actions, ref lifecycle, and permission gating, with an explicit exclusion list; the missing characterization suite spun out to `agents/docs/cleanup-candidates.md`.
- **Files:** `atlas-front-end/docs/specs/atlas-maintenance/proceedings/PRDV-14184-focus-proceeding-name-on-create.md`; in dustin-thomason — `specs/PRDV-14184-locked-decisions.md` (LD-004 revised + gate correction), `testing/PRDV-14184-test-plan.md`, `PRDV-14184-why-these-changes.md` (wedge), `agents/docs/cleanup-candidates.md`
- **Verification gates:** lint `npm run lint` → pass (exit 0). Audit unchanged (failing, waived, docs-only). Tests not applicable — no executable code changed.
- **Commits:** `ce0cb91e`; response posted to PR #572.
- **Notes:** **Pattern worth naming across three rounds:** every round-3 finding was a claim invalidated by an earlier round's fix that I did not sweep for. Fixing a decision now means sweeping every artifact that restates it — the spec carries the same decisions in prose, a summary table, a file plan, a risk table, and a test section. Still no product code. Still blocked on Product for surface scope.

### 2026-09-13T00:00:00Z — atlas-front-end (Phase 3 — spec review round 2)

- **Summary:** Five more findings, all valid, two of which changed conclusions. **(1) The scope argument was invalid and is withdrawn.** I had claimed screen-neutral acceptance criteria logically mandate every create surface; they do not — silence about screens is not universality. The ticket also carries **unread UI context** (a 10:23 comment whose attachment was never retrieved), which I had recorded at Phase 0 and argued past anyway. Surface scope is now an **open Product decision (LD-012)**; LD-001 superseded; accepted job story 01 retired unchanged to `dnu/` and superseded by draft story 02 carrying the reopened question (criteria themselves unchanged). **(2) The focus trigger narrowed from visibility to user action (LD-011, supersedes LD-009).** Round 1's widening to `editing && showAddForm` still missed step navigation — Pending gates the section behind `v-show="currentStep === 5"`, Submitted behind `v-if="form"`, above the two known gates. The set is unbounded and route-dependent, so AC-1 now fires on the create/append actions only; re-entering an already-open form deliberately does **not** focus, since that would steal focus during navigation. Round 1's "hole" is therefore correct behavior, and the test plan asserts the absence. **(3) Three smaller fixes:** backend claims relabelled background (not readable from this PR), test cleanup now unmounts wrappers before clearing the DOM, stale frontmatter corrected.
- **Files:** `atlas-front-end/docs/specs/atlas-maintenance/proceedings/PRDV-14184-focus-proceeding-name-on-create.md`; in dustin-thomason — `specs/PRDV-14184-locked-decisions.md` (LD-011, LD-012, self-correction note), `stories/` (01 → `dnu/`, 02 drafted, index), `dnu/README.md` (new), `testing/PRDV-14184-test-plan.md` (HP-8 inverted, AV-3/AV-6), `PRDV-14184-why-these-changes.md`
- **Verification gates:** lint `npm run lint` → pass (exit 0). Audit unchanged (still failing, still waived, docs-only). Tests not applicable — no executable code changed.
- **Commits:** `f375f4d685d4c803f3df12c948f7ecdded2fbcf1`; response posted to PR #572.
- **Notes:** Still **no product code**. **Now blocked on a Product answer** for surface scope before implementation can start — the first genuine external dependency in this ticket, and the correction to my earlier claim that none existed.

### 2026-09-13T00:00:00Z — atlas-front-end (Phase 3 — spec review round 1)

- **Summary:** Spec PR [#572](https://github.com/planetdepos/atlas-front-end/pull/572) returned **not approved as written** with five findings. All five verified against the code and addressed. **One was a genuine design hole:** S2's AC-1 trigger was hung on the Add Proceeding click, but the rows sit behind **two** independent gates (`v-if="editing"` wrapper + `v-if="showAddForm"` card), and `editing` is a live prop from `FileUploadSectionCore.vue:308` — so leaving and re-entering editing mode remounts the inputs with `showAddForm` still true, giving no click and no focus. Trigger changed to watch the conjunction (LD-009). **Four were my errors:** the authorization claim (the S1 `disabled` computed is bound to `:class` only, never the button's `disable` prop — so the restriction check is cosmetic; corrected and raised as Concern 4, **not fixed here**, LD-010); the S1 test count (14, not 9); the plain-array rationale (Vue's public-instance proxy returns `true` for `__v_skip`, so `reactive()` skips it — the justification was simply wrong); and the spec citing private, unreachable artifacts as authoritative, which made the acceptance criteria unverifiable from the PR. Criteria are now reproduced verbatim in the spec.
- **Files:** `atlas-front-end/docs/specs/atlas-maintenance/proceedings/PRDV-14184-focus-proceeding-name-on-create.md`; in dustin-thomason — `specs/PRDV-14184-locked-decisions.md` (LD-009, LD-010), `testing/PRDV-14184-test-plan.md` (HP-8, AV-6, stale scope text), `PRDV-14184-future-development-concerns.md` (Concern 4), `PRDV-14184-why-these-changes.md` (Phase 3 review course change)
- **Verification gates:** lint `npm run lint` → pass (exit 0). audit unchanged from the previous entry (still failing, still waived, docs-only). tests not applicable — no executable code changed.
- **Commits:** `975ea3f536d89d2a13d98950038b545b049ffa12` pushed to `PRDV-14184-spec`; review response posted as a PR comment.
- **Notes:** Still **no product code written**. The reviewer left LD-002 (inline vs extract) explicitly open; flagged back to them as reversible. Phase 5 remains gated on spec approval.

### 2026-09-11T00:00:00Z — atlas-front-end (Phase 3 — Probe and spec)

- **Summary:** Locked eight decisions, accepted job story 01, wrote the spec, refined the test plan. **All four questions drafted for grill-me closed on evidence without escalation** — scope (LD-001) from the acceptance criteria themselves, extract-vs-inline (LD-002) from repo conventions plus the fact that the two surfaces' AC-1 triggers are different code, the assertion mechanism (LD-003) from the absence of any repo rule sanctioning jest-dom, and coverage depth (LD-004) from `build-implementation-guardrails` §1, which already mandated it. **Two significant Phase 3 findings:** (1) investigation assumption A5 (`nextTick` vs `setTimeout`) closed on Vue/Quasar source evidence rather than deferred to trial — the overlay panel animates `transform` only and `vShow.updated` clears `display` before `nextTick` resolves, so no magic delay enters the diff (LD-006); (2) the existing S1 spec **stubs `q-input` with no `focus()` method**, which would have made every focus test pass vacuously — so the stub is dropped in favor of real Quasar (LD-005), and in the process one existing test was found to be passing for the wrong reason.
- **Plan used:** Phase 3 plan approved in-session (locked decisions → story acceptance → spec → test-plan refinement)
- **Files:** `atlas-front-end/docs/specs/atlas-maintenance/proceedings/PRDV-14184-focus-proceeding-name-on-create.md` (new), `atlas-front-end/docs/specs/README.md` (index entry); in dustin-thomason — `specs/PRDV-14184-locked-decisions.md` (new), `stories/` (accepted), `testing/PRDV-14184-test-plan.md` (refined), `PRDV-14184-why-these-changes.md`, `PRDV-14184-future-development-concerns.md` (Concern 3 addendum), `orchestration.md`
- **Verification gates (spec commit, atlas-front-end):**

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | atlas-front-end | **FAIL (exit 1)** — 11 high, 12 moderate, 1 low, 0 critical | **WAIVED by user, 2026-09-11, for this docs-only commit.** Findings: axios, tar, undici, postcss, js-yaml, nanoid, browserslist, brace-expansion, immutable, ip-address, npm — all pre-existing on `main`, all `fixAvailable: true`. **Why waived:** the commit contains one Markdown spec and one README index line; it ships no executable code and cannot introduce or worsen any finding. **Residual risk:** all 11 high-severity vulns remain open on `main` and are untouched by this ticket; `npm audit fix` is available but belongs in its own ticket because it mutates `package-lock.json` and needs a full test run to verify. |
| lint | `npm run lint` | atlas-front-end (`eslint . --max-warnings 0`) | pass (exit 0) | — |
| tests | — | — | not run | **Not applicable:** no executable code changed. The spec commit touches `docs/specs/**` only; no unit under test was added or modified. Test obligations for this ticket attach to Phase 5, where the refined test plan governs. |
- **Commits:** `e9844c5d974cdf3406acd91ea2d2c6a983875b17` on branch `PRDV-14184-spec`; spec PR [#572](https://github.com/planetdepos/atlas-front-end/pull/572) opened, **no reviewer requested** per git-commit-workflow.
- **Notes:** **No product code written.** Spec is entirely-UI so it lives in `atlas-front-end/docs/specs/` per that repo's README routing (Callisto has no work). Two proof obligations deliberately carried to Phase 5: a real-browser smoke test of AC-1 on S1 (happy-dom never evaluates `display`/`visibility` in `focus()`, so no unit test here can catch the no-op), and confirming the S1 spec is green on `main` before touching production code.

### 2026-09-11T00:00:00Z — atlas-front-end / callisto-back-end (Phase 1–2 — Recon and investigation report)

- **Summary:** Phase 1 recon (approved) and Phase 2 report emitted. **Key finding: this is not the one-line change it looks like.** Exactly two surfaces render an empty proceeding-name input — `NewProceedingsOverlay.vue` (Job Detail) and `AddProceedingForm.vue` (Job Submission, on both the Pending and Submitted routes) — and each carries both acceptance-criteria moments (initial `ref([''])` row, `push('')` append). The naive fix (Quasar's `autofocus`, as used in 7 places incl. the proceeding *rename* dialog) **cannot work on the overlay surface**: `Overlay.vue` hides with `v-show` and `AddNewProceeding.vue` mounts the overlay unconditionally, so its input mounts once at Job Detail page load *while hidden* and never remounts on open. Recommended fix is event-driven imperative focus (`ref` + `QInput.focus()`) from the two lifecycle moments, uniform across both surfaces. Callisto ruled **out of scope** on evidence: proceeding `value` is client-supplied on both create DTOs with no server-side default, so no contract, DTO, guard or Swagger surface changes. **Incidental defect found and recorded (not fixed):** the `proceedings` uniqueness constraint is named `..._case_insensitive` but implemented as a plain case-**sensitive** `UNIQUE ("value","job_id")`, while the sibling `records` table implements real case-insensitivity correctly — and the two Atlas create surfaces' duplicate checks disagree with each other as a result. Raised in the concerns doc; deliberately kept out of this ticket.
- **Plan used:** `investigations/PRDV-14184-recon-and-plan.md` (approved Phase 1, saved verbatim, frozen)
- **Files:** `docs/atlas/tickets/focus-proceeding-name-on-create/` — `investigations/PRDV-14184-recon-and-plan.md`, `investigations/PRDV-14184-investigation.md`, `investigations/PRDV-14184-coverage-ledger.md`, `investigations/PRDV-14184-diagrams.md`, `PRDV-14184-why-these-changes.md`, `PRDV-14184-future-development-concerns.md`, `testing/PRDV-14184-test-plan.md`, `PRDV-14184-pr-draft.md` (shell), `stories/` (reconciled), `orchestration.md`
- **Commits:** none — docs-only; **no product code touched in either repo**
- **Notes:** A claim I made mid-phase (that the DB constraint was case-insensitive, inferred from its name) was **refuted** by reading the migration; corrected in report §7 and coverage-ledger area 9, and logged as a Phase 2 course change in the why doc. Four decisions remain open for Phase 3 grill-me: in-scope surfaces, extract-vs-inline, the focus assertion mechanism, and whether `AddProceedingForm` gets a full spec. Next: Phase 3 (Probe & spec).

### 2026-09-11T00:00:00Z — atlas-front-end (Phase 0 — Capture)

- **Summary:** Orchestration Phase 0 completed. Found `original-ticket.md` already captured (verbatim request + ClickUp AC) at a non-canonical path from a prior session; relocated to the canonical `docs/atlas/tickets/focus-proceeding-name-on-create/` layout with no content change. Drafted job story 01 (Focus proceeding name field) through the full job-story sequence, with two open questions carried to investigation (focus-vs-select semantics; scope of "additional proceeding" entry points). Scaffolded this changelog and the orchestration ledger. Aligned repos: `atlas-front-end` switched from `PRDV-16461-implementation` to `main` and fast-forwarded; `callisto-back-end` confirmed already on `main` (has pre-existing unrelated local modifications — left untouched).
- **Plan used:** none / ad-hoc (Phase 0 capture, no implementation plan yet)
- **Files:** `docs/atlas/tickets/focus-proceeding-name-on-create/PRDV-14184-original-ticket.md` (moved), `.../orchestration.md` (new), `.../stories/PRDV-14184-job-story-01-focus-name-field.md` (new), `.../stories/PRDV-14184-job-stories-index.md` (new), `docs/atlas/PRDV-14184-changelog.md` (new, this file)
- **Commits:** none yet — docs-only, no commit made this session
- **Notes:** Next is Phase 1 (Recon and plan, Plan mode) per the orchestrate skill.

---

## Root cause analysis

_Optional — fill when debugging._

---

## Attempt history

_Optional — one subsection per failed or partial approach._

### Attempt 1 — short label (commit `abc1234` optional)

**What:**

**Result:**

---

## Key technical learnings

1. 

---

## Current state (as of 2026-09-11)

_What is merged / on branch / reverted / still pending._

Phases 0–2 done (capture, recon, investigation report). **No code changed in either repo**; everything so far is documentation under `docs/atlas/tickets/focus-proceeding-name-on-create/`. `atlas-front-end` is on `main` (up to date at `420c395a`); `callisto-back-end` is on `main` at `d84a4628` with pre-existing unrelated local changes not touched by this ticket. No branch created yet for PRDV-14184 — that happens in Phase 4/5 per `new-branch-get-started`.

Investigation verdict: **proceed with conditions.** The fix is imperative focus on collected per-row refs across two surfaces; callisto is out of scope. Three conditions must close before merge — the in-scope-surfaces decision, whether `nextTick` suffices through the overlay's `v-show` + `<Transition>` (browser-verified, not tuned), and the spec assertion mechanism (no focus test exists anywhere in the repo today). Next: Phase 3 (Probe & spec, Working mode).

---

## New code introduced

_Optional — new modules, composables, endpoints._


