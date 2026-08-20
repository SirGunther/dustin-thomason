# PRDV-16403 — Display Firm, Case, Contact & Case Remarks in Access Manager

## Ticket

- **ClickUp:** [PRDV-16403](https://app.clickup.com/t/43227262/PRDV-16403)
- **Parent epic:** [PRDV-14828](https://app.clickup.com/t/86aexmuhx) — View Warnings in Access Manager
- **Repo:** `atlas-front-end`, `callisto-back-end`
- **Branch:** _(not created — Phase 5 per orchestrate)_
- **PR:** _(link when opened)_
- **Validation review:** [`PRDV-16403/review/v0.1.0-PRDV-16403-display-warnings-in-access-manager-validation-review.md`](PRDV-16403/review/v0.1.0-PRDV-16403-display-warnings-in-access-manager-validation-review.md) — v0.1.0, overall status Pending
- **Orchestrated:** yes — ledger at `docs/atlas/PRDV-16403/orchestration.md`
- **Sprint:** 2026-17 (8/19–9/1) · Priority High · 3 points

---

## Requirements (verbatim)

_Captured from the active ClickUp page in a prior session; reproduced here unaltered from `docs/atlas/PRDV-16403/PRDV-16403-original-ticket.md`. Not paraphrased._

> ## Original Request
>
> **Story of epic PRDV-14828 — View Warnings in Access Manager**
>
> As an Ops Atlas user, I want to see firm, case, and contact warnings plus case remarks in the right-hand panel of the Access Manager, so that I can reference delivery details without opening RB.
>
> This story covers the **surfacing** work — the Callisto read endpoint + the Atlas FE panel — for all four sections. It does ** not** cover replicating the case fields into Callisto (PRDV-16391) or the DMS/IaC enablement (PRDV-16392).
>
> ## Acceptance Criteria
>
> - Right-hand panel of the Access Manager shows, in order: **Case Warning → Contact Warning → Firm Warning → Case Remarks**.
> - Case = Case Warning for the proceeding being viewed; Contact = warning for the contact being granted; Firm = warning for that contact's firm.
> - Case Remarks preserve HTML/CSS styling from RB, sanitized before render. **Survives:** inline `styles`, `<img>`, `<table>`, `<tr>`, `<td>`. ** Stripped:** `<script>`, event handlers (e.g. `onclick`), `<iframe>`, `<object>`, `<embed>`.
> - No images or tables are expected in the remarks field (confirmed with stakeholders). First iteration renders **text with CSS styling only** (color, bolding, font size); anything that survives sanitization renders as-is with no dedicated image/table styling support.
> - Styling matches [Figma](https://www.figma.com/design/RaMfbhcLeHdgF6svVOYusR/Planet-Depos-Atlas?node-id=10285-154183&t=Aj8onofQq8f3d32V-0) (Case Remarks not in Figma — confirm with Product).
> - Internal scroll bar when content exceeds panel height.
> - Read-only in Atlas from the corresponding RB fields.
> - Data fetched fresh each time the Access Manager opens (not cached mid-session).
> - If the warnings/remarks fetch fails (500 / timeout), the panel shows an error message **"Warnings/remarks failed to load"** in place of the sections.
> - Empty warning → title + "*No warning info*" (italic, 50% grey). Empty Case Remarks → "* No remarks info*" (intentional distinct wording — warnings and remarks are referenced differently by users).
>

_The full capture — Key facts, the Backend/Frontend file lists, sanitization guidance, dependencies, and the ClickUp comment thread that produced the empty-state and error copy — is in `docs/atlas/PRDV-16403/PRDV-16403-original-ticket.md`. It is immutable._

---

## Context

- **Authoritative parent-epic spec (found 2026-08-18):** `callisto-back-end/docs/specs/atlas-client-access/contacts/5-story-PRDV-14828-view-warnings-in-access-manager.md` — author **Derrick Dieso**, created 2026-07-27. Present on `origin/main` (`631ed42e`); **absent from the local callisto working tree**, which is on branch `PRDV-16313` (`c43be32c`). Read it from `origin/main` (`git show origin/main:<path>`) or check out `main`.
- **Spec provenance — stated plainly, because it was ambiguous for several turns (2026-08-18).** The **governing specification for this ticket is Derrick Dieso's** `5-story-PRDV-14828-view-warnings-in-access-manager.md` (created 2026-07-27), read in full from `origin/main`. The endpoint path, the file list, the DTO shape, the DOMPurify snippet and the *"mirror the grants stack"* instruction all originate there; the ClickUp ticket text is largely a restatement of it. **No specification for this ticket has been authored by the agent.** The nine Phase 1 findings are a **review of Derrick's document**, four of them saying it is wrong or stale. Whether Phase 3 produces a new spec or an **addendum** to his is decision **LD-008** — see `specs/PRDV-16403-locked-decisions.md`.
- **Spec placement convention** (`callisto-back-end/docs/specs/README.md`, `origin/main`): any BE / API / data work — mixed UI is fine — lives in the **Callisto repo** under `docs/specs/`; entirely-UI tickets go to the Atlas repo; *"Do not duplicate a spec across repos. Do not write new specs into the personal `wikis/systems/` vault."* This ticket has both BE and FE work, so its home is the Callisto repo, in the same folder as Derrick's spec.
- **PRDV-16392 has no specification anywhere.** Searched `origin/main` in both app repos and all of `larry-adams`: three references to it, no document. The references are the PRDV-16391 spec (L13, L76) and `larry-adams` `work breakdown structure/entity checklists/case_checklist.md:52`, which records it as *"ready for work"*. The 16391 spec also carries an **intake correction** worth knowing — the RB9 case fields are *already* replicated into Lagrange, so no `lagrange-back-end` change is needed; the only missing link is the DMS task mapping Lagrange → Callisto.
- **`larry-adams` no longer holds these specs.** `larry-adams/systems/neptune/callisto/README.md` records the GCA epic/story specs as moved into the implementing repos and says *"Do not add new specs here."* Mixed/BE goes to `callisto-back-end/docs/specs`; entirely UI goes to `atlas-front-end/docs/specs`. **This changes the Phase 3 review surface** relative to the prior PRDV flow, which PR'd specs into `larry-adams` — and the epic spec's author is Derrick Dieso rather than Larry Adams. So *who reviews this spec, and in which repo* is an open decision for Phase 3, not an assumption.
- ~~**Blocking dependency, verified in code:** `case.entity.ts` declares `@Entity('cases')` with **no** `warning` and **no** `remarks_html` column. Case Warning + Case Remarks return `null` until **PRDV-16391** lands. Contact + Firm ship immediately.~~ **— SUPERSEDED, see the correction below.**
- **CORRECTION (2026-08-18T21:10:00Z, Phase 1 recon): PRDV-16391 has already landed.** The struck claim above read the **local** callisto tree, which sits on branch `PRDV-16313` (`c43be32c`) — branched *before* the merge. On `origin/main`, commit `53d961ed` is an ancestor and migration `1786036989067-alter__add_warning_remarks__cases_table.ts` adds `cases.warning` (varchar **NULL**), `cases.remarks` (text NULL) and `cases.remarks_html` (text NULL); `Case` carries all three at L37-42. **The ticket's *Sequencing note* is therefore moot — all four fields build in one pass.** Contact + Firm are still live and unchanged (`contact.entity.ts` L88, `firm.entity.ts` L51), but note the **nullability asymmetry**: those two are NOT NULL varchar and may be `''`, while all three case columns are nullable — one mapper must absorb both contracts.
- **What is still open: PRDV-16392** (DMS CDC column mapping) governs whether real case data ever *arrives* in those columns. **Code unblocked, data not guaranteed** — a distinction the ticket never draws, and the root of finding F1 (a `null` that means both *RB holds nothing* and *DMS never mapped this*).
- **Before any implementation:** merge `origin/main` (`631ed42e`) into the working branch. Without it `Case.warning` / `Case.remarksHtml` do not exist to compile against, and `docs/specs/` is absent.
- **Prior orchestrated ticket touching `granting-client-access`:** PRDV-16312 (`docs/atlas/PRDV-16312/`) has a full artifact set including a coverage ledger — **primary consult target for the Phase 1 consult protocol.**
- **Figma:** [Access Manager frame](https://www.figma.com/design/RaMfbhcLeHdgF6svVOYusR/Planet-Depos-Atlas?node-id=10285-154183) — Case Remarks is **not** in Figma; the ticket says confirm with Product.
- **Feature flag:** the epic spec states all work is gated behind the existing `IS_GRANTING_CLIENT_ACCESS_ENABLED` (`atlas-front-end/src/callisto/auth/composables/featureFlags/useGrantingClientAccessFlag.ts`). **The ClickUp acceptance criteria never mention it** — reconcile in Phase 1.

### Touch points verified read-only (2026-08-18, no files written)

Baselines: `atlas-front-end` `main` at `02c98e1e`; `callisto-back-end` `PRDV-16313` at `c43be32c`.

**atlas-front-end** — `AccessManagerOverlay.vue` L318 has `data-testid="rb-warnings-panel"` on `section.rightColumn`, with the placeholder paragraph at L333-335 and the panel title plus close button in a sibling `<header>` at L319-332; props include `proceedingId: number` and `contact` (L24-32), `contactId` computed at L41. `queryKey.ts` holds 12 keys, none for warnings. `constants.ts` L164-169 is the mirror URL builder. `contactDeliverableTypeGrants.ts` is the `useApiRequest` plus `HttpMethod.GET` mirror. `common.json` at `callisto.accessManager` has 15 keys including `warningsTitle` and `warningsPlaceholder`, none of the seven new ones. `NotificationBody.vue` L32-43 is the DOMPurify plus `v-html` precedent, behind an `eslint-disable vue/no-v-html` pair. `dompurify ^3.2.6` is already a dependency (`package.json` L44). Sole overlay call site: `ProceedingDetailPage.vue` L744. Both `composables/` and `components/__specs__/` already exist.

**callisto-back-end** — mirror stack `contacts/application/controllers/actions/contact-deliverable-type-grants-action/` (4 files plus `__specs__/`); routes are declared on the **action** via `@ContactsController()` plus `@Get(...)`, not on the controller. All three GCA registries exist (`action.registry.ts` L12/L31, `repository.registry.ts` L10-12, `transaction-script.registry.ts`). `granting-client-access.module.ts` L52-64 `forFeature([... Contact, Firm])` — `Case`, `Job`, `Proceeding` absent, though `JobModule` and `ProceedingsModule` are already imported. `job.entity.ts` L31 `case_id integer nullable: true` confirms the LEFT JOIN; `proceeding.entity.ts` L25 `job_id integer` non-null confirms the INNER JOIN. `ValidateContactExists` is live in both existing contact transaction scripts.

### Deltas surfaced by that pass — carry into Phase 1

1. **Feature flag absent from the ClickUp ACs** while the epic spec makes it a blanket gate.
2. **The ticket's DOMPurify allowlist is narrower than DOMPurify's default.** `ALLOWED_TAGS` / `ALLOWED_ATTR` as written would strip `<a>`, `<ul>`/`<li>`, `<h1>`-`<h6>`, `<u>`, `<font>` and the `class` attribute, all of which the default keeps and all plausible in RB `RemarksHTML`. The default already strips everything the AC names as forbidden (`<script>`, event handlers, `<iframe>`, `<object>`, `<embed>`), so the explicit allowlist adds no security and subtracts fidelity from "text with CSS styling only". The epic spec uses the bare call.
3. **Panel-title ownership.** `warningsTitle` and the close button sit in the overlay's `<header>`, outside the placeholder paragraph. The new panel component must render section titles only, or the title double-renders.
4. **`warningsLoadError` copy exists only in ClickUp** (Shaye Lankford, 2026-08-17), not in the epic spec, which was created 2026-07-27 — an addendum, not a conflict.
5. **Naming.** The ticket says `ACCESS_MANAGER_WARNINGS_URL`; the repo convention for GET builders is `FETCH_*_URL`.

---

## Plans

_No Plans rows are maintained for this ticket._ It runs under the `orchestrate` skill, whose **No status bookkeeping** section replaces the Plans state machine: phase state lives in `docs/atlas/PRDV-16403/orchestration.md`, and each phase's approved plan is saved as its own frozen artifact (`investigations/PRDV-16403-recon-and-plan.md`, then `PRDV-16403-implementation-plan.md`). Read the ledger, not this table.

---

## Session log

_Newest first. Add one block before each commit (agents) or end of work session (you)._

### 2026-08-18T22:05:00Z — callisto-back-end, atlas-front-end (branch `PRDV-16403`)

- **Summary:** Phase 3 closed and the backend slice implemented. Dustin accepted **Derrick Dieso as design authority**, which locked three decisions and made the spec output an **addendum** rather than a new spec. Both repos branched off `main`; the callisto merge was mandatory since `Case.remarksHtml` does not exist on the prior branch. Backend endpoint complete and green; frontend data layer complete; **the panel component is deliberately not built** because LD-001 (empty-vs-unavailable copy) is still deferred pending Dustin's PRDV-16392 research, and LD-005/LD-006 also land there. Phase 4 **skipped on Dustin's instruction**.
- **Plan used:** the Phase 1 recon-and-plan (frozen) plus `specs/PRDV-16403-spec-addendum.md`. **No approved implementation plan exists** — Phase 4 was skipped, so there is no frozen record of approved sequencing.
- **Files — `callisto-back-end` (8 new, 6 modified):** new `contacts/domain/projections/access-manager-warnings.projection.ts`, `contacts/infrastructure/repositories/access-manager-warnings.repository.ts`, `contacts/domain/transaction-scripts/fetch-access-manager-warnings-ts/{*.transaction.script.ts,*.param.ts}` + `__specs__`, `contacts/application/controllers/actions/access-manager-warnings-action/{action,response.dto,mapper,swagger}` + 2 `__specs__`; modified `contacts.service.ts`, all three `registries/`, `granting-client-access.module.ts` (`Case`/`Job`/`Proceeding` into `forFeature`), and `contacts.service.spec.ts` (neighbour fix).
- **Files — `atlas-front-end` (4 new, 2 modified):** new `types/access-manager-warnings.ts`, `api/requests/accessManagerWarnings.ts`, `AccessManagerOverlay/composables/useAccessManagerWarnings.ts` + its `__specs__`; modified `api/constants.ts`, `api/queryKey.ts`.
- **Commits:** none — nothing committed or pushed.
- **Notes:** Three deviations from Derrick's spec, each flagged in the addendum for his response: **400 not 404** (his prescribed validator throws `BadRequestException`), **guard added** (`ProceedingsReadAuthGuard`, mirroring the guarded sibling — his spec is silent), and **`FetchClientAccessListAction` as the template** rather than the grants action he names, which has no mapper and no guard. `P3.spec-submit` is **not done** — Dustin owns delivering the addendum to Derrick, and no product code should be treated as reviewed until he responds.

#### Verification gates

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | callisto-back-end | pass (exit 0) | — |
| audit | `npm audit --audit-level=high` | atlas-front-end | pass (exit 0) | — |
| lint | `npm run lint` | callisto-back-end | pass (exit 0) | `eslint --fix` rewrote nothing beyond my own edits |
| lint | `npm run lint` | atlas-front-end | pass (exit 0) | Failed once on a prettier import-wrap warning under `--max-warnings 0`; fixed via `npm run lint:fix`, re-run clean |
| architecture | `npx jest src/__tests__/architecture.spec.ts` | callisto-back-end | pass | Confirms `no-orphans`, mapper layer, and no TS-to-TS call |
| tests | `npx jest --config jest-e2e.json --runInBand src/granting-client-access/contacts` | contacts module | pass — 14 suites, 57 tests | — |
| tests | `npx jest --config jest-e2e.json --runInBand src/granting-client-access` | whole GCA module | **2 suites fail** — 89 passed, 92 total | **Pre-existing, not mine.** `create-planet-suite-link` and `client-access-outbox.writer` fail on stale `@planetdepos/orbital-docking-protocol` exports. Proven pre-existing: both files are unmodified (`git status` clean for them), and intersecting the tsc-error file set with my changed-file set is **empty**. Baseline was 75 suites / 361 tests; now 92 / 469 |
| tests | `npx vitest run --maxWorkers 1 src/callisto` | atlas callisto tree | pass — 82 files, 752 tests | Includes the untouched `AccessManagerOverlay.spec.ts` (13 tests) still green |
| typecheck | `npx tsc --noEmit` | callisto-back-end | **fails on `main`** | **Not usable as a gate.** 11 files fail on the same stale ODP package. **Zero overlap with files this ticket touched** — verified by set intersection. Nothing this ticket added has a type error |
| tests | `npm run test:integration` | new repository spec | **untested** | Spec written (9 cases, both queries) and the four seeder extensions added. The runner cannot reach a local Postgres, so it exits before any assertion runs — nothing passed and nothing failed. The existing sibling spec is untested here for the same reason, which is how the cause was isolated to the environment |

#### Shipping checklist

- **Tests added/updated** — 4 new suites, 26 new tests (mapper 6, TS 8, action 4, composable 9 — happy, failure, edge, and the empty/whitespace/null normalisation across both column contracts). **Gap: the repository has no spec**, per the integration row above.
- **Regression impact** — one neighbour genuinely broke and was fixed: `contacts.service.spec.ts` failed on the new constructor dependency; provider added, module green. `AccessManagerOverlay.spec.ts` is **untouched and green** — the `warningsPlaceholder` assertion still passes because the overlay has not been modified yet. That spec update lands with the panel.
- **API docs** — updated: new swagger helper with `ApiOperation`, both `ApiParam`s, and 200/400/500 responses on the new `AccessManagerWarningsResponseDTO`. Documents 400 for a missing contact per deviation 1.
- **Conflicts / exceptions** — Phase 4 skipped on explicit instruction; downstream inputs named in the ledger. Test plan still `seeded`, not `refined` — NP-5's expected status code remains blank pending LD-002 confirmation. `tsc` unusable as a gate (pre-existing).

### 2026-08-18T21:25:00Z — dustin-thomason (docs only)

- **Summary:** Phases 1 and 2 of the orchestrated run. Phase 1 (Plan mode) ran the investigation method steps 1-7 read-only across `callisto-back-end`, `atlas-front-end` and `larry-adams`, plus a consult across all five prior coverage ledgers and — newly — `docs/atlas/reviews/`. Phase 2 emitted every artifact. **Headline: the ticket's stated blocker does not exist.** PRDV-16391 merged to `origin/main` (`53d961ed`), so all four fields build in one pass and the *Sequencing note* is moot; what remains is PRDV-16392, which governs data arrival, not code. Four of the ticket's own prescriptions are stale or self-contradictory (wrong mirror sibling, unreachable 404, unscrollable panel, two redundant cache options). Disposition **proceed with conditions**.
- **Plan used:** the Phase 1 recon-and-plan, saved verbatim and frozen at `investigations/PRDV-16403-recon-and-plan.md` (verified byte-identical to the approved plan).
- **Files:** `investigations/PRDV-16403-recon-and-plan.md`, `investigations/PRDV-16403-investigation.md`, `investigations/PRDV-16403-coverage-ledger.md`, `investigations/PRDV-16403-diagrams.md`, `testing/PRDV-16403-test-plan.md` (`seeded`), `PRDV-16403-why-these-changes.md`, `PRDV-16403-future-development-concerns.md`, `PRDV-16403-pr-draft.md` (unfilled shell), all three `stories/` files + index (revised, Phase 1 Story log entries), `orchestration.md`, and this changelog (corrected).
- **Commits:** none.
- **Notes:** **Two Phase 0 claims corrected in place, dated, originals left standing** — they had read the local callisto branch (`PRDV-16313`, `c43be32c`) as though it were current. Nine findings recorded; four concerns opened (**C1** firm-identity mismatch, **C2** unguarded sibling read action, **C3** inherited guard smell, **C4** manual verification blocked). Seven questions closed by evidence; **seven decisions (D1-D7)** carried with owners. The wedge was **revised on the record** once the blocker proved false. `original-ticket.md` untouched. WorkLists sync `skipped (no WorkLists card)`.

#### Shipping checklist

- **Tests run** — not relevant: docs-only session in `dustin-thomason`; no `package.json` at the repo root, so no lint/test/audit gate applies to this tree. **No gate was run in either implementation repo either, and none is claimed** — coverage-ledger area 8 records the architecture rules and test harness as *read, not executed*.
- **Tests added/updated** — not relevant: no behavior or product code changed. The test plan is `seeded` with 25 scenarios, each naming its criterion or flagged `[NO-CRITERION]`; nothing has been executed.
- **Regression impact** — isolated: every file written is new or is a `docs/atlas/` file this run created; the only pre-existing files edited are this changelog and `orchestration.md`, both in `dustin-thomason`. Nothing in either implementation repo was opened read-write — `git status` in `atlas-front-end`, `callisto-back-end` and `larry-adams` verified clean after the pass.
- **API docs** — not relevant: no HTTP surface exists yet. Route path/method, DTO shape and Swagger decorators in `callisto-back-end` were **read only** (coverage-ledger area 5) and are unchanged. The new surface is designed but not built.
- **Tooling gates** — not applicable: `dustin-thomason` has no `package.json` at the repo root.
- **Conflicts / exceptions** — (1) Folder convention `docs/atlas/PRDV-16403/` follows the disk precedent over the skill's nominal `tickets/<slug>/`; re-observed, already a cruft-check candidate on PRDV-16402. (2) The harness plan-mode workflow prompts for Plan-agent implementation design at its Phase 2; **deliberately skipped** — orchestrate Phase 1 emits recon findings, and implementation design belongs to orchestrate Phase 4 after the Phase 3 spec. (3) Long documents were written with the Write tool rather than Bash heredocs, which silently truncate past roughly 7KB and produced two failed writes before the cause was identified. (4) WorkLists sync skipped, no card.

### 2026-08-18T19:54:06Z — dustin-thomason (docs only)

- **Summary:** Phase 0 (Capture) completed for the orchestrated run. The ClickUp capture already existed from a prior session; this session added the orchestration ledger, this changelog, and three draft job stories with their index. Also completed a user-requested related-spec search and a read-only touch-point verification across both implementation repos — see **Context** above. **No implementation-repo file was touched and no branch was created.**
- **Plan used:** none — Phase 0 has no plan; Phase 1 produces the first one.
- **Files:** `docs/atlas/PRDV-16403/orchestration.md` (new), `docs/atlas/PRDV-16403-changelog.md` (new), `docs/atlas/PRDV-16403/stories/PRDV-16403-job-stories-index.md` (new), `docs/atlas/PRDV-16403/stories/PRDV-16403-job-story-01-reference-rb-notes.md` (new), `docs/atlas/PRDV-16403/stories/PRDV-16403-job-story-02-absent-vs-unavailable.md` (new), `docs/atlas/PRDV-16403/stories/PRDV-16403-job-story-03-remarks-read-as-written.md` (new).
- **Commits:** none yet.
- **Notes:** Original Request untouched. WorkLists board sync `skipped (no WorkLists card)` — no id was supplied and no card tooling is reachable this session; the id is never searched for, per `worklists-card-sync`.

#### Shipping checklist

- **Tests run** — not relevant: docs-only session in `dustin-thomason`; no `package.json` at the repo root, so no lint/test/audit gate applies to this tree.
- **Tests added/updated** — not relevant: no behavior or product code changed.
- **Regression impact** — isolated: every file written is new and lives under `docs/atlas/`; no existing file was edited, and nothing in either implementation repo was opened read-write. `git status` in `atlas-front-end`, `callisto-back-end`, and `larry-adams` is clean — all three verified after the session.
- **API docs** — not relevant: no HTTP surface exists for this story yet. Route path/method, DTO shape, and Swagger decorators in `callisto-back-end` were **read only** and are unchanged.
- **Tooling gates** — not applicable: `dustin-thomason` has no `package.json` at the repo root, so `npm run lint`, `npm audit`, and test scripts do not exist for this tree.
- **Conflicts / exceptions** — Folder convention: artifacts live at `docs/atlas/PRDV-16403/`, following the atlas precedent on disk (PRDV-16402, PRDV-16192, PRDV-14055) rather than the skill's nominal `docs/atlas/tickets/<slug>/`. Already logged as a cruft-check candidate on PRDV-16402; re-observed here. WorkLists sync skipped as noted above.

---

## Root cause analysis

_Not applicable — this is a new-capability story, not a defect._

---

## Attempt history

_None yet._

---

## Key technical learnings

1. The GCA epic/story specs moved out of `larry-adams` into the implementing repos (`callisto-back-end/docs/specs`, `atlas-front-end/docs/specs`). A local checkout sitting on a feature branch that predates the move will not show them — read from `origin/main`.
2. In `granting-client-access`, HTTP routes are declared on the **action** class (`@ContactsController()` plus `@Get(...)`), not on the controller. The controller is a decorator factory the actions attach to.

---

## Current state (as of 2026-08-18)

**Nothing implemented. No branch, no code, no tests — by design.**

Phase 0 of the orchestrated run is `done`; Phase 1 (Recon and plan, Plan mode) is next and has not started. On disk: the ClickUp capture, the orchestration ledger, this changelog, and three `draft` job stories. Both implementation repos are untouched — `atlas-front-end` is clean on `main` (`02c98e1e`), `callisto-back-end` is clean on `PRDV-16313` (`c43be32c`).

The read-only touch-point verification recorded in **Context** is recon input for Phase 1, **not** an approved plan. The five deltas listed there are open and unreconciled.

**Corrected 2026-08-18T21:10:00Z:** all four fields are buildable now — PRDV-16391 merged to `origin/main` and the three `cases` columns exist (see Context). The ticket's Sequencing note is moot. **PRDV-16392** (DMS CDC mapping) still governs whether real case data arrives, so the case values may read `null` in every environment; that is a data gap, not a code blocker.

Phase 1 also surfaced a live risk to **manual** verification (finding F9): `IS_GRANTING_CLIENT_ACCESS_ENABLED` must be on the Cognito user, PRDV-16312 already failed to make that stick, and the `CALLISTO_DEV_FEATURE_FLAG_OVERRIDES` workaround PRDV-15776 records **does not exist** — `IsFeatureAllowedTS` is Cognito-claims-only by explicit JSDoc and no override exists in either repo. Decision D7 owns unblocking it.

---

## New code introduced

_None yet._
