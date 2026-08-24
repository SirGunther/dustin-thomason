# PRDV-16403 — Display Firm, Case, Contact & Case Remarks in Access Manager

## Ticket

- **ClickUp:** [PRDV-16403](https://app.clickup.com/t/43227262/PRDV-16403)
- **Parent epic:** [PRDV-14828](https://app.clickup.com/t/86aexmuhx) — View Warnings in Access Manager
- **Repo:** `atlas-front-end`, `callisto-back-end`
- **Branch:** `PRDV-16403` in both `atlas-front-end` and `callisto-back-end` — pushed 2026-08-24
- **PR:** [atlas-front-end #563](https://github.com/planetdepos/atlas-front-end/pull/563) · [callisto-back-end #431](https://github.com/planetdepos/callisto-back-end/pull/431) — both open, no reviewers requested
- **Validation review:** [`PRDV-16403/review/v0.1.0-PRDV-16403-display-warnings-in-access-manager-validation-review.md`](PRDV-16403/review/v0.1.0-PRDV-16403-display-warnings-in-access-manager-validation-review.md) — v0.1.0, overall status Passed — cleared to ship
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

### 2026-08-24T17:05:00Z - atlas-front-end + callisto-back-end (branch `PRDV-16403`) - SHIPPED

- **Summary:** Dustin closed the three open review items and directed the ticket to ship. Both repos committed, pushed, and PR'd. **This is the ship entry**; the entry below it covers the code work that preceded it.
- **The three items, as Dustin resolved them:**
  - **D8 - closed.** Derrick Dieso confirmed **400 is correct** directly to Dustin in conversation. The other two deviations (added `ProceedingsReadAuthGuard`, `FetchClientAccessListAction` as template) change no HTTP contract; recorded, not blocking.
  - **D9 - ships as-is, stated in the PR** rather than gated on a product decision. Interim behaviour written into both PR bodies: Contact and Firm warnings are live today; Case warnings reads "None" and Case remarks reads "No remarks info" in every environment until PRDV-16392 maps the data; no code change needed when it lands.
  - **D10 - passed by code, and the earlier "incomplete" call was retracted.** "Grants" meant access-grant rows in the **local dev database**, empty after a rebuild, so the Client Access list had no row to click - a local test-data gap, not a codebase gap. Both entry points assign the same `accessManagerContact` prop (`ProceedingDetailPage.vue:99-118`), `ClientAccessContact.contactId` is a contact id, and the panel reads only `contact.id` + `proceedingId`, so the two paths cannot diverge.
- **Audit gate waived on Dustin's explicit instruction.** The high findings are known and pre-existing across these repos; `--no-verify` used on both commits at his direction. Recorded here because it is a deliberate override of `git-commit-workflow`, not an oversight.
- **`package-lock.json` deliberately left out of the Callisto commit.** Its diff is purely `"peer": true` flag churn from a local `npm install` - no dependency added, no resolved version changed - and folding it in would have put a second narrative in the commit.
- **Commits:**
  - `callisto-back-end` - `2ab33cd4a0e5a5907e6316efc45589f48c4cd7a1` - *PRDV-16403: Add access manager warnings read endpoint*
  - `atlas-front-end` - `98299b1c8906af3c6635502411f9d376dd324a20` - *PRDV-16403: Display RB warnings in access manager*
- **PRs (no reviewers requested on either):**
  - [callisto-back-end #431](https://github.com/planetdepos/callisto-back-end/pull/431)
  - [atlas-front-end #563](https://github.com/planetdepos/atlas-front-end/pull/563)
- **Both PRs cross-reference each other and say to land together** - the Atlas panel is dead without the Callisto endpoint.
- **PR bodies rewritten 2026-08-24 after Dustin rejected the first pass as overbuilt.** Validated against real merged PRs in both repos (`atlas-front-end` #560/#555/#554, `callisto-back-end` #429/#427/#425). House style is short: bare ClickUp URL, the job story plus a couple of sentences on what changed, then screenshots or brief bullets of what was checked. **Commit hashes, gate tables, gate commands, Problem/Requirement/Solution headings and caveat catalogues do not belong in a PR body** - they belong here. Recorded in `PRDV-16403-pr-draft.md` so the next ticket does not repeat it.
- **What the trimmed bodies keep, because a reviewer cannot infer it:** the interim case-section behaviour, the 400-not-404 deviation and Derrick's confirmation, that case values repeat per proceeding by design, and that sanitisation was checked in a browser because DOMPurify misbehaves under the test environment. **What moved out of them and lives only here:** gate results, the untested Callisto integration spec, the unusable `tsc` gate, the two pre-existing GCA suite failures, the red audit, and the unperformed D4 browser check.
- **Neither PR has screenshots**, which is the evidence this team expects; the checklist boxes are unchecked on both until Dustin adds them.

#### Verification gates

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| lint | `npm run lint` | callisto-back-end | pass (exit 0) | `eslint --fix` rewrote nothing |
| lint | `npm run lint` | atlas-front-end | pass (exit 0) | - |
| typecheck | `npx vue-tsc --noEmit` | atlas-front-end | pass (exit 0) | - |
| tests | `npx vitest run --maxWorkers 1` | atlas-front-end, full suite | pass - 127 files, 1117 passed, 4 skipped | - |
| audit | `npm audit --audit-level=high` | both repos | **waived** | Known pre-existing high findings; waived on Dustin's explicit instruction, `--no-verify` on both commits |
| tests | - | callisto-back-end | **not re-run this session** | No Callisto file changed since the 2026-08-18 run recorded below (14 suites / 57 tests green on the contacts module). Lint re-run and clean against the pushed tree |

#### Shipping checklist

- **Tests run** - see table. Atlas full suite green against the exact tree that was pushed.
- **Tests added/updated** - covered by the entry below; nothing further added in this pass.
- **Regression impact** - no code changed in this pass; it is commit, push and PR only. The preceding entry carries the regression analysis.
- **API docs** - swagger helper shipped with the Callisto commit: `ApiOperation`, both `ApiParam`s, and 200/400/500 on `AccessManagerWarningsResponseDTO`, documenting 400 per the confirmed deviation.
- **Conflicts / exceptions** - audit gate waived and `--no-verify` used, both on explicit instruction, recorded above. Two verification gaps ship open and are named in the PR bodies: the D4 browser check against a real refused connection, and DOMPurify's stripping (no automated coverage under happy-dom; verified by hand in a browser).

### 2026-08-24T16:20:00Z - atlas-front-end (branch `PRDV-16403`)

- **Summary:** Chased down the D4 discrepancy - the prior session's claim that the "Warnings/remarks failed to load" message was *"in the code and covered by the component spec"* while never inducing a real failure. The claim was half true, and the false half hid a real defect. **The failure path had never been executed anywhere.** `RbWarningsPanel.spec.ts` is handed an `error` **prop** and never runs a query; `useAccessManagerWarnings.spec.ts` mocks `useQuery` outright and never returns an error from it; `AccessManagerOverlay.spec.ts` mocks the composable. Nothing connected a rejected request to the rendered message. Building that connection surfaced a genuine defect and three false-passing specs.
- **The defect (fixed):** the warnings query took vue-query's default `retry: 3`, which **compounds** with the three transient-network retries `globalApi/apiClient.ts` already performs. A refused connection becomes 4 query attempts x 4 requests = **16 requests**, and the panel holds a spinner for roughly **35s** (4 x 7s axios backoff + 7s query backoff) before the failure wording can appear; a plain 500 takes ~7s. Measured, not inferred - a scratch harness showed the error surfacing at t=7s after 4 fetch calls for a 500. Fixed with `retry: 1`, matching the `retry: 1` the other Callisto read queries use, which bounds the wait to vue-query's single 1s backoff.
- **Four false-passing specs (fixed):**
  - `RbWarningsPanel.spec.ts` stubbed `q-banner` as `true`, which **swallows the banner's default slot**. It asserted the error *element* existed but could never see the message inside it - a wrong i18n key would have passed. The stub now renders its slot, plus an assertion on the wording.
  - `AccessManagerOverlay.spec.ts` mocked the composable with plain `{ value: null }` literals instead of refs. **Vue only unwraps refs**, so `error` arrived at the panel as a truthy object and the overlay spec rendered the *failure banner* in every one of its tests while asserting it proved the panel body. It passed only because `rb-warnings-panel-body` renders in every branch. The mock now returns real refs and the assertion names the branch.
  - `useAccessManagerWarnings.spec.ts`'s error test was **vacuous** - the `useQuery` mock hard-coded `error: ref(null)`, so "the exposed error stays null" asserted `null === null` and the `instanceof Error` narrowing had zero coverage. The mock's refs are now drivable and the narrowing is tested both ways.
  - `AccessManagerOverlay.spec.ts`'s *"the warnings query does not feed the overlay loading state"* test asserted the **absence of `warningsPlaceholder`** - a locale key that no longer exists anywhere in `src/`. It could never fail. Replacing it needed two passes: asserting the body still renders was **also** vacuous, because the spec's `OverlayStub` ignores its `loading` prop, and a deliberate mutation coupling `isWarningsLoading` into the overlay's `:loading` still passed. It now asserts `findComponent({ name: 'Overlay' }).props('loading')` directly, which does catch that mutation.
- **New coverage:** `__specs__/AccessManagerWarningsFailurePath.spec.ts` (6 tests) drives a rejected request through the **real** query client, composable, panel, and locale file, asserting the literal string "Warnings/remarks failed to load" renders, no section heading does, and neither empty-state wording appears. It also asserts the *success* path renders both empty wordings through the same wiring, so their absence during a failure is not vacuous, and it bounds the attempt count at 2.
- **Every fix was mutation-checked.** Reverting `retry: 1` fails 4 tests; renaming the i18n key fails 2; coupling `isWarningsLoading` into the overlay's `:loading` fails 1. None of the three was caught by the suite as it stood before this session.
- **Files - `atlas-front-end` (1 new, 4 modified):** new `AccessManagerOverlay/__specs__/AccessManagerWarningsFailurePath.spec.ts`; modified `composables/useAccessManagerWarnings.ts` (`retry: 1` plus rationale comment), `composables/__specs__/useAccessManagerWarnings.spec.ts`, `components/__specs__/RbWarningsPanel.spec.ts`, `__specs__/AccessManagerOverlay.spec.ts`.
- **Commits:** none - nothing committed or pushed in either repo.
- **Notes:** No production behaviour changed beyond the retry bound. The D4 **browser** check stays open: only a real refused connection through `apiClient` exercises that layer, and the timing is only observable in a browser. Its step in the review now says to expect a few seconds of spinner first, so a tester does not misread the wait as a failure of the check.

#### Verification gates

| Gate | Command | Scope | Result | Exception / risk |
| ---- | ------- | ----- | ------ | ---------------- |
| audit | `npm audit --audit-level=high` | atlas-front-end | **fail (exit 1)** - 15 vulns, 12 high | **Pre-existing, not mine.** Every high finding is transitive `undici` via `npm` and `semantic-release`. No dependency was added or changed this session - `package.json` and `package-lock.json` are unmodified in `git status`. The 2026-08-18 entry recorded this gate green, so this is advisory drift, not a regression from this work. **Blocks commit under `git-commit-workflow` until triaged or waived.** |
| lint | `npm run lint` | atlas-front-end | pass (exit 0) | Failed once on a prettier wrap warning under `--max-warnings 0`; fixed with `npx eslint --fix` on that file, re-run clean |
| tests | `npx vitest run --maxWorkers 1` | atlas-front-end, full suite | pass - 127 files, 1117 passed, 4 skipped | Run after lint, against the final tree |
| tests | `npx vitest run --maxWorkers 1 src/callisto/pages/JobProceedingPages/ProceedingDetailPage/components/AccessManagerOverlay` | Access Manager overlay tree | pass - 10 files, 84 tests | 83 before this session |
| typecheck | `npx vue-tsc --noEmit` | atlas-front-end | pass (exit 0) | - |
| tests | - | callisto-back-end | **not run** | **Out of scope:** this session changed no Callisto file. `git status` on that repo is identical to the state the 2026-08-18 entry left it in, so its gates are unchanged and those results stand |

#### Shipping checklist

- **Tests added/updated** - 1 new suite (6 tests) covering the failure path end to end; 3 existing suites corrected across 4 assertions that were passing without proving anything. Happy, failure, recovery-on-retry, and retry-bound cases all asserted.
- **Regression impact** - full Atlas suite run, 127 files green. The only production change is `retry: 1` on a query used solely by `RbWarningsPanel`; the isolating boundary is the composable, which has exactly one caller (`AccessManagerOverlay.vue` L69-72) and feeds only that panel. `useAccessManager`'s own queries were deliberately left on their defaults - out of this ticket's scope.
- **API docs** - not relevant: no HTTP contract touched. The endpoint path, DTO shape, and swagger decorators live in `callisto-back-end`, which this session did not modify; route, method, and response shape checked and unchanged.
- **Tooling gates** - audit fails pre-existing (see table); lint, typecheck, and the full test suite pass.
- **Conflicts / exceptions** - the D4 browser check remains unperformed and is honestly recorded as such in the review doc; the automated result is labelled "**This is not the browser check**" there so it cannot be mistaken for one.

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

## Current state (as of 2026-08-24 - shipped)

**Shipped. Both repos committed, pushed, and PR'd on 2026-08-24. Awaiting review.**

| Repo | Commit | PR |
| ---- | ------ | -- |
| `callisto-back-end` | `2ab33cd4a0e5a5907e6316efc45589f48c4cd7a1` | [#431](https://github.com/planetdepos/callisto-back-end/pull/431) |
| `atlas-front-end` | `98299b1c8906af3c6635502411f9d376dd324a20` | [#563](https://github.com/planetdepos/atlas-front-end/pull/563) |

**Land them together** - the Atlas panel is dead without the Callisto endpoint, and both PR bodies say so.

All ten review objectives Passed. D8 closed on Derrick's direct confirmation that **400 is correct**; D9 ships as-is with its interim behaviour written into both PRs; D10 passed **by code** - the two Access Manager entry points assign the same contact prop, so they cannot diverge, and the empty Client Access list was local test data rather than a code gap. The empty-warning wording ships as **"None"** (Figma) rather than the ClickUp AC's "No warning info", on Dustin's call.

**What the feature does today, until PRDV-16392 ships:** Contact warnings and Firm warnings show real data. Case warnings reads **"None"** and Case remarks reads **"No remarks info"** in every environment, because the three `cases` columns exist and are read but nothing writes to them yet. **No code change is needed when 16392 lands** - both sections populate on their own.

**Two verification gaps shipped open, named in the PR bodies rather than left implied:** the D4 **browser** check against a genuinely refused connection, and **DOMPurify's stripping**, which has no automated coverage because it misbehaves under happy-dom - verified by hand in a browser on 2026-08-24 instead. The Callisto repository integration spec (9 cases) is committed but has never run; its queries were verified against real Postgres by hand.

**Known-red and deliberately waived:** `npm audit --audit-level=high` across both repos, on pre-existing transitive findings. Waived on Dustin's explicit instruction; `--no-verify` used on both commits. Also pre-existing and unrelated: `npx tsc --noEmit` fails on Callisto `main` (11 files, stale `@planetdepos/orbital-docking-protocol`, zero overlap with this ticket) and two `granting-client-access` suites fail on the same package.

**Next:** add screenshots to both PRs and check the boxes, then review. The D4 browser check when convenient.

---

## New code introduced

_None yet._
