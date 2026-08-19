# Investigation Report: Display Firm, Case, Contact & Case Remarks in Access Manager

## Metadata

- **Status:** done
- **Disposition:** **proceed with conditions**
- **Date:** 2026-08-18
- **Owner:** Dustin Thomason
- **Location:** `docs/atlas/PRDV-16403/investigations/PRDV-16403-investigation.md` — this path **overrides** the template's default `docs/investigations/` for orchestrated tickets
- **Ticket:** [PRDV-16403](https://app.clickup.com/t/43227262/PRDV-16403) · parent epic [PRDV-14828](https://app.clickup.com/t/86aexmuhx)
- **Domain:** software
- **References / evidence:**
  - `atlas-front-end` @ `main` `02c98e1e`; `callisto-back-end` @ `PRDV-16313` `c43be32c`, with `origin/main` at `631ed42e`
  - Parent-epic spec `callisto-back-end/docs/specs/atlas-client-access/contacts/5-story-PRDV-14828-view-warnings-in-access-manager.md` (Derrick Dieso, 2026-07-27) — read from `origin/main`
  - PRDV-16391 spec (sibling `6-story-…`), commit `53d961ed`, migration `1786036989067-alter__add_warning_remarks__cases_table.ts`
  - `larry-adams/data-manual/rb9-replicated-timestamps.md`; `callisto-back-end/docs/data/replicated-rb9-data.md`
  - Approved recon: [PRDV-16403-recon-and-plan.md](./PRDV-16403-recon-and-plan.md) (frozen)
  - Traversal record: [PRDV-16403-coverage-ledger.md](./PRDV-16403-coverage-ledger.md)

---

## 0. Verdict (bottom line up front)

The work is viable and largely mechanical on the backend, but the ticket's own instructions cannot be followed as written: **four of its prescriptions are stale or self-contradictory**, and its stated blocker no longer exists. PRDV-16391 has already merged, so all four fields build in one pass and the ticket's *Sequencing note* should be struck. What replaces the blocker is smaller but real — **PRDV-16392** (DMS CDC mapping) governs whether case data ever *arrives*, which means two of the four fields will read empty in every environment for now, and the empty-state copy the ticket specifies would assert something false while that is true. Separately, **manual verification is blocked today** by a Cognito feature-flag problem a prior ticket already failed to solve, and the workaround its changelog records does not exist in either repo.

- **Strongest path:** build all four fields against `FetchClientAccessListAction` as the template (not the grants action the ticket names), settle D1 on empty-vs-unavailable copy before the panel is written, and treat automated coverage as the primary proof while D7 chases the flag.
- **Not yet proven / not approved:** no code exists; the spec has not been written or reviewed; the reviewer and review surface are undecided (the `larry-adams` route is closed and the epic spec's author is Derrick Dieso, not Larry Adams); and **no acceptance criterion has been demonstrated against a running system.** This is a green light to design, not to ship.

## 1. Problem class

**Assumed class:** *new capability* — build an endpoint, build a panel. That is how the request is framed and where all its detail goes.

**Confirmed class:** **completion of a deliberately deferred read path.** Reframed at Step 2 and re-confirmed at Step 4 against root-cause evidence.

Every part exists but the wire between them: the panel ships today carrying a placeholder that promises this exact feature (`AccessManagerOverlay.vue` L318-335); the overlay already receives `proceedingId` and `contact.id` (L24-32, L41); all four data columns exist in Callisto, CDC-replicated from RB9; and a four-layer read stack sits in the same module. The origin is documented, not inferred — the epic spec names PRDV-14820 as *"provid[ing] the `AccessManagerOverlay` two-column layout and the right-hand `rb-warnings-panel` placeholder this story fills."*

**Why the reframe is load-bearing:** it relocates the risk. The plumbing the request details is the part with a known-good template *and* machine-enforced fitness functions. The risk sits in four places the request barely touches — a state ambiguity it cannot see (F1), a freshness requirement it over-specifies (F2), a render path with no in-repo precedent (F4), and a scroll requirement its target element structurally cannot satisfy (F6). **Solution-space implication:** mirror the sibling exactly and spend the thinking on state modelling, not on architecture.

## 2. Problem statement (raw facts, collected before classification)

- **Named instances:** **none — and this is a real gap.** The ClickUp thread names Derrick Dieso, Shaye Lankford, Anastasiya Savchuk, Michael Carrigan and Kat Giangiulio, all as participants deciding copy and scope. No Ops user, case, or occasion is named anywhere. **The problem is asserted, not evidenced.** Per the method: no named instance means no confirmed problem, so this is recorded rather than papered over. The counterweight is that the panel's own placeholder is an admission by the previous ticket that the need was already agreed.
- **One sentence:** An Ops Atlas user setting up a client contact's deliverable access cannot see the warnings recorded in RB against the case, the contact, or the contact's firm, nor the case's remarks, without leaving Atlas and opening RB9.
- **Distinct problems** (three — see the job stories): **reach** (the notes are only in RB); **false negative** (empty is indistinguishable from failed-to-load, and the user acts on the difference); **fidelity, safely** (remarks are formatted content that can lose meaning or carry something that acts).
- **Urgency:** **2026-08-19** — Sprint 2026-17 (8/19–9/1) opens tomorrow. High priority, 3 points, assigned. Concrete, unlike the instance.
- **Wedge:** the **sanitised-render plus empty/error-state panel**. Smallest piece that forces the whole vertical open, the only part with no in-repo precedent *and* no prior investigation by any ticket, and inherited by any future RB-sourced rich text in Atlas. *(Revised on the record — the first wedge, "ship Contact + Firm first", was withdrawn once the blocker proved false. See the why-log.)*

### Problem Check

- **Asked:** surface four read-only values in an existing panel, in order, so the user need not open RB — *evidence:* "I want to see firm, case, and contact warnings plus case remarks in the right-hand panel … so that I can reference delivery details without opening RB."
- **Answered:** far more than is asked. The request fixes the endpoint path, every file to create, the DTO shape, the sanitize config and the cache options, so criteria and implementation are fused and a reviewer cannot tell requirement from one author's design — *evidence:* "New read-only endpoint under `granting-client-access/contacts`, mirroring the `fetch-contact-deliverable-type-grants` stack (action → service → transaction script → repository → projection → mapper → DTO → swagger)." Four of those prescriptions turn out stale or wrong (§4, F6, F7, F8).
- **Should-ask:** nothing asks what an Ops user **does differently** once they read a warning — *why:* it decides whether this is purely informational or must influence the grant. "Reference" is the only stated use and no criterion connects a warning to the access being granted. The feature informs but never intervenes; that may be correct, but it was never asked.
- **Conflation:** warnings and remarks are bundled as one thing — one endpoint, one panel, one failure message — while differing in type (plain text vs HTML), source (three entities vs one), column nullability (F5) and empty-state wording. The request **acknowledges the difference and bundles them anyway** — *evidence:* "(intentional distinct wording — warnings and remarks are referenced differently by users)" sitting beside a single "Warnings/remarks failed to load". Solving one does touch the other: they share the query, so they share the failure.
- **Thin:** "delivery details" — the stated justification for the whole story, broader and vaguer than the four values delivered, and never defined — *evidence:* "so that I can reference delivery details without opening RB."
- **Off:** a criterion that cannot be checked for one of the four things it governs, and says so in its own parenthesis — *evidence:* "Styling matches Figma …" → "(Case Remarks not in Figma — confirm with Product)."

**Deliberately not flagged:** the survives/stripped sanitization lists. Read closely the request resolves its own apparent tension — "anything that survives sanitization renders as-is with no dedicated image/table styling support" is a scope statement. Raised with the user, who ruled it out of scope (2026-08-18). Not manufacturing a flag to look thorough.

## 3. The contract

### Acceptance criteria

The 17 criteria are owned by the [job stories](../stories/PRDV-16403-job-stories-index.md), not by this report. Coverage against them:

| Criterion group | Status | What's needed to close it |
| --- | --- | --- |
| Story 01 — four values readable, fixed order, correct entity pairing | **needs-proof** | Endpoint + panel; assert order and pairing in specs |
| Story 01 — freshness ("what RB holds as of the moment they open") | **documented** | Structurally satisfied by the overlay's unmount/remount (F2); assert the mount fires a fetch |
| Story 01 — read-only in Atlas | **covered** | Structural: `Contact`/`Firm`/`Case` extend `ImportedBaseEntity`; Callisto has no write path, so Atlas cannot have one |
| Story 01 — long note readable without displacing the access work | **gap** | `.rightColumn` is `overflow: hidden` (F6) — needs a new inner scroll element |
| Story 02 — empty state distinguishable, distinct remarks wording | **needs-proof** | Panel work + i18n keys |
| Story 02 — failure never presented as empty; message replaces the four | **needs-proof** | Depends on D4 (blocking or not) |
| Story 02 — case fields must not assert "no warning info" falsely | **gap** | **Blocked on D1.** The DTO cannot distinguish "RB empty" from "never mapped" (F1) |
| Story 03 — emphasis survives; nothing acts; plain text still reads | **needs-proof** | Sanitised render + specs; bare DOMPurify already strips everything named forbidden |
| Story 03 — remarks contained, affect only themselves | **needs-proof** | CSS containment in the new panel module |

### Non-goals / out of scope

- Editing warnings or remarks in Atlas — read-only from RB, and structurally so.
- **PRDV-16392** (DMS CDC mapping) — governs data arrival; not this ticket.
- Dedicated image or table styling support — explicitly first-iteration-excluded.
- Any change to the permission model.
- Formatting the spec does not name (links, lists, headings, underline) — **user ruling, 2026-08-18**; not to be reopened.
- **Removed from non-goals:** replicating the case columns. PRDV-16391 already did it.

## 4. What changed since the request was created

**Lead with the reclassification** (§1), then the two factual shifts:

1. **The blocker dissolved.** The request says *"`cases.warning` and `cases.remarks_html` are added by PRDV-16391; this story wires them but they return `null` until 16391 lands. Contact + Firm ship immediately."* PRDV-16391 **has landed** — `53d961ed` is an ancestor of `origin/main`, migration `1786036989067` adds `warning` (varchar NULL), `remarks` (text NULL) and `remarks_html` (text NULL), and `Case` carries all three at L37-42. The *Sequencing note* is moot. **The Phase 0 record of this ticket asserted the opposite and has been corrected in place**, dated — it had read the local branch, which predates the merge.
2. **The copy grew after the spec was written.** `warningsLoadError` ("Warnings/remarks failed to load") comes from Shaye Lankford's 2026-08-17 ClickUp comment; the epic spec was created 2026-07-27 and does not contain it. An addendum, not a conflict.

## 5. Why it exists

**Origin:** PRDV-14820 built the overlay's two-column layout and the `rb-warnings-panel` placeholder, and the epic spec names this story as the one that fills it. A deliberate IOU, scoped as a follow-up from the start — not an oversight and not a defect.

**Contract / source-of-truth alignment.** The authority is RB9, mirrored twice before Atlas sees it: RB9 → Lagrange (ETL) → Callisto (DMS CDC) → Atlas (new DTO). Sources: `rb9-replicated-timestamps.md`, `replicated-rb9-data.md`, the PRDV-16391 mapping table. Two consequences:

- **Read-only is structural.** `Contact`, `Firm` and `Case` all extend `ImportedBaseEntity` — rows are written by replication, never by the app.
- **F5 — the columns are not shaped alike.** `contacts.warning` and `firms.warning` are NOT NULL `varchar` and may be `''`; `cases.warning` is nullable `varchar`; `cases.remarks_html` is nullable `text`. One mapper must collapse both `null` **and** empty-or-whitespace across two different column contracts. The request says only *"Mapper normalizes empty/whitespace → `null`"* and never mentions the asymmetry.

**Detection gap: not applicable** — new capability, not a defect. No net should have caught it. Recorded rather than omitted, per the software lens.

**Diagrams:** current-vs-target, the source chain, and the open/close/refetch sequence are in [PRDV-16403-diagrams.md](./PRDV-16403-diagrams.md) — linked, not embedded.

## 6. Alternatives considered

| Alternative | Rejected because |
| --- | --- |
| Extend `fetch-contact-deliverable-type-grants` to also return warnings | Conflates two aggregates, breaks a live DTO contract, and couples the panel's freshness needs to the grants query's caching |
| Four separate endpoints, one per value | Four round trips per panel open, and the AC treats the four as one atomic failure unit — the singular error copy would become a lie |
| Resolve warnings on the frontend from already-loaded contact data | **Structurally impossible, not merely awkward.** No FE type carries a warning field, and neither `ContactSearchItem` nor `ClientAccessFirm` carries a firm **id** at all — so the firm's warning is unreachable from the client |
| Two transaction scripts, one per query (contact+firm, case) | `transaction-scripts-no-other-transaction-scripts` is `severity: error`; a TS may not call a TS. One TS calling one repository twice is the legal shape |
| Table-name-string joins to avoid widening `forFeature` | Viable — precedent exists in `ProceedingRepository.findProceedingDetailById` — but entity-class joins are the module's dominant style. Recorded as the fallback if the `forFeature` change proves contentious |

## 7. Solution & stress-test

- **Proposed solution:** one read-only endpoint mirroring **`FetchClientAccessListAction`** (nested nullable-object DTO, application-layer mapper, `@UseGuards(ProceedingsReadAuthGuard)`, strict `ParseIntPipe`), one repository holding both queries, one transaction script, and on the frontend a `useAccessManagerWarnings` composable plus an `RbWarningsPanel` component with its own scroll container and sanitised remarks render.
- **Solves the confirmed class?** Yes. It completes the deferred path rather than inventing a parallel one, and when PRDV-16392 ships, the case fields need **zero** new code.
- **Scale:** one row per open, two indexed lookups, no fan-out. Non-issue.
- **Generalization:** deliberately none on the backend. The one abstraction worth making is the sanitised-render wrapper, which is the wedge precisely because the next RB-sourced rich-text surface will want it.
- **Fit:** strong, with one caveat — `.cursor/rules/planetdepos-quasar.mdc` L214 says *"Avoid `v-html` when possible"*. This work brushes that rule and should say so explicitly rather than proceed quietly (D6).
- **Adjacent issues:** **F3** (firm-identity mismatch) is recorded as a concern, not fixed here — fixing it means adding a firm id to two FE types and their projections, which is wider than this ticket. Two pre-existing smells (the unguarded grants-fetch action; 16313's `trackTypeId` guard mismatch) are noted and deliberately untouched.
- **Sufficiency:** covers the reach problem fully. Covers the false-negative problem **only if D1 is settled** — otherwise it ships copy that asserts something false for two of four fields.
- **Feedback speed:** **slow, and that is the main risk.** Automated tests are fast; the manual path is blocked (F9), and the case fields cannot be observed with real data at all until PRDV-16392. A wrong empty-state decision could sit unnoticed for weeks.
- **Happy-path story (30 seconds):** an Ops user opens the Access Manager on a proceeding for a client contact. The right-hand panel shows the case caution, the contact's caution, the firm's caution and the case remarks, in that order, as they read in RB moments ago. Where nothing is recorded, it says so. They grant the access and never open RB9. **Without whom:** without RB9's data being replicated (PRDV-16391, PRDV-16392) there is nothing to show; without PRDV-14820's overlay there is nowhere to show it.

## 8. Assumptions ledger

- **Claim:** The case columns do not exist and PRDV-16391 blocks this story. — **Status: refuted.** Refuted by `git merge-base --is-ancestor 53d961ed origin/main` (exit 0) and by reading the entity on `origin/main`. The claim came from reading the local branch. Corrected in the ledger and changelog.
- **Claim:** Reopening the overlay for the same contact refetches. — **Status: confirmed.** The overlay renders under `v-if="isGcaEnabled && accessManagerContact"` and `handleAccessManagerAfterLeave` nulls the contact, so it unmounts on close; `refetchOnMount: 'always'` fires on the fresh mount independent of `staleTime`. (**F2**)
- **Claim:** A partial failure of the four values is representable. — **Status: refuted.** One endpoint, one query, one response — all four fail together, so the singular error copy is correct.
- **Claim:** A permission gate already exists. — **Status: confirmed.** Two: the GCA flag at the parent (`ProceedingDetailPage.vue` L755) and `@UseGuards(ProceedingsReadAuthGuard)` on the sibling read endpoint.
- **Claim:** Adding `Case`/`Job`/`Proceeding` to `forFeature` is required. — **Status: confirmed** for entity-class joins; neither `JobModule` nor `ProceedingsModule` re-exports `TypeOrmModule`. Avoidable only via table-name-string joins.
- **Claim:** `ValidateContactExists` yields the 404 the request asks for. — **Status: refuted.** It throws `BadRequestException`; the existing grants TS spec asserts exactly that. (**F8**)
- **Claim:** `.rightColumn` can scroll. — **Status: refuted.** It is `overflow: hidden`; long content clips silently. (**F6**)
- **Claim:** A dev override exists for the GCA feature flag. — **Status: refuted.** `IsFeatureAllowedTS` carries an explicit JSDoc — *"Cognito token claims only … There is no server-side env override"* — and grep for `FEATURE_FLAG_OVERRIDE` across `atlas-front-end` returns nothing. PRDV-15776's recorded workaround does not exist. (**F9**)
- **Claim:** `firmName` on the FE derives from the same `contact.account_id → firm.id` join the warnings query would use. — **Status: confirmed directionally.** True of `ClientAccessListRepository` (verified). **The search path is unverified**, and entry point 1 feeds from it. Owes a read of the search-contacts projection → frontier item.
- **Claim:** Passing a DOMPurify allowlist improves safety over the bare call. — **Status: refuted as stated.** Bare `DOMPurify.sanitize` already strips every construct the AC names as forbidden, so an allowlist adds no security; it only narrows what survives. (**F4**)

## 9. Validation plan

**Happy path**

1. Seed a firm with a non-empty `warning`; a contact with a non-empty `warning` and `account_id` pointing at it; a proceeding whose job has a non-null `case_id`; that case with `warning` and `remarks_html` set.
2. `GET /granting-client-access/contacts/contactId/:id/proceedingId/:id/warnings` → 200 with all four populated and the nested shape.
3. Open the Access Manager for that contact via **entry point 1** (contact search). Panel shows four sections in order Case → Contact → Firm → Case Remarks.
4. Repeat via **entry point 2** (Client Access list row) — the path that fabricates its contact object.
5. Change the contact's warning in the database, close and reopen: the new value appears without a page reload.
6. Remarks carrying colour, bold and size render with that emphasis intact.

**Negative paths**

- Contact with `warning = ''` and firm with `warning = ''` → both normalise to `null` and render the empty state, **not** blank space.
- Case with `warning = NULL` and `remarks_html = NULL` → empty state with the **remarks-specific** wording, distinct from the caution wording.
- Contact whose `account_id` dangles (no matching firm) → firm section renders its empty state, no error, no crash. *(This is how the existing integration spec models "no firm" — there is no FK.)*
- Proceeding whose job has `case_id = NULL` → case sections empty, contact and firm still populated.
- Unknown or inactive contact → the documented status code, **once D2 settles whether that is 400 or 404**. Must not leak a stack trace.
- Endpoint 500 or timeout → panel renders `warningsLoadError`, **never** an empty state. This is the red→green anchor: the test must fail if a failure is presented as emptiness.
- Remarks containing `<script>`, an `onclick` handler, an `<iframe>`, an `<object>` and an `<embed>` → all stripped; nothing executes.
- Remarks 50× longer than the panel → the panel scrolls internally and the access controls stay reachable (**this fails today** without the new scroll container — F6).
- A slow warnings fetch must **not** delay the overlay appearing or block the access work — assert `Overlay`'s `loading` prop is not fed by the warnings query.
- Neighbour: existing `useAccessManager.spec.ts` and `AccessManagerOverlay.spec.ts` stay green, the latter with one **named, deliberate** update where it asserts the retired `warningsPlaceholder` key.

## 10. Decisions, recommendation & open variables

**Decisions (settled by this investigation):** the class is a deferred-read-path completion, not a new capability; the mirror target is `FetchClientAccessListAction`, not the grants action; all four fields build in one pass because PRDV-16391 merged; the wedge is the sanitised-render + empty/error-state panel; formatting not named in the spec is out of scope.

**Recommendation, in order:**

1. Merge `origin/main` into the working branch — nothing compiles against `Case.warning` without it.
2. Settle **D1** (empty vs unavailable copy) and **D2** (400 vs 404) before the spec is written; both change observable behaviour.
3. Write the spec against the job stories, submit it to its reviewer, and **do not write product code until the reviewer responds.**
4. Build the backend slice, then the panel, with the scroll container designed in from the start rather than retrofitted.
5. Extend the seeders (`warning` overrides on contact and firm, `caseId` on proceeding, a new case seeder) — unavoidable and unmentioned by the request.

**Sequencing & gates:** do not start the panel until D1 and D5 are answered — both determine what it renders. Do not claim any acceptance criterion demonstrated until either the Cognito flag is resolved (**D7**) or the criterion is proven by automated test with the gap stated. Do not treat Phase 4's plan approval as spec approval.

### Open variables to collect

- [ ] **D1** — what the case fields display while PRDV-16392 is unshipped. *The structure cannot answer this:* the DTO has exactly one representation (`null`) for both "RB holds nothing" and "never mapped", so distinguishing them is a change, not a lookup — owner: **Product**
- [ ] **D2** — 400 or 404 for a missing or inactive contact; the request cannot have both — owner: **Dustin / spec reviewer**
- [ ] **D3** — does the endpoint carry `ProceedingsReadAuthGuard`? Recommend yes — owner: **Dustin**
- [ ] **D4** — does a fetch failure block completing the access work? Epic spec says non-blocking; the verbatim request is silent — owner: **Product / Dustin**
- [ ] **D5** — Case Remarks styling, absent from Figma; and whether "50% grey" means the `0.38` token the overlay actually uses — owner: **Product / design**
- [ ] **D6** — pass a DOMPurify config at all, given no precedent and a repo rule discouraging `v-html` — owner: **Dustin**
- [ ] **D7** — how manual verification gets unblocked: who assigns the Cognito flag and makes it survive re-login, or whether this ships on automated tests alone with the gap stated — owner: **Dustin / Product**
- [ ] **Spec reviewer and review surface** — the `larry-adams` route is closed by that repo's own README, and the epic spec's author is Derrick Dieso. The user is resolving this — owner: **Dustin**

---

## 11. Plan — Next steps

### Handoff table

| Action | Owner | Done-when (falsifiable) |
| --- | --- | --- |
| Merge `origin/main` into the callisto working branch | Dustin | `git show HEAD:src/cases/domain/entities/case.entity.ts` contains `remarksHtml` |
| Settle D1 and D2 | Product / Dustin | Both appear as `LD-###` rows in the Phase 3 locked-decision ledger |
| Write the spec and submit it to its reviewer | Dustin | The spec exists **and** its delivery to the reviewer is recorded in the ledger with form and date |
| Reviewer responds | Reviewer | A merged PR, a comment, or an explicit go-ahead, recorded in the ledger — **gates all product code** |
| Verify the search-contacts `firmName` derivation (frontier) | Dustin | The projection's join clause is quoted in the coverage ledger |
| Extend the integration seeders | Dustin | `npm run test:integration` passes a case with a non-empty `cases.warning` |
| Resolve or waive D7 | Dustin | Either an Ops-flagged Cognito user demonstrably surviving re-login, or a recorded waiver naming the uncovered risk |

### Checklist

#### Investigation

- [x] Consult protocol ran before any branch opened; result recorded in the coverage ledger
- [x] Problem Check run with a finding per flag, each on a trimmed quote
- [x] Step 7 reconcile — every code-discoverable question resolved by evidence
- [x] Software lens — all four candidates addressed (Candidate 4 N/A with reason)

#### Project Spec

- [ ] Spec written against the job stories, Problem → Requirement → Solution
- [ ] Reviewer and review surface decided
- [ ] Spec submitted and response recorded

#### Development

- [ ] `origin/main` merged into the working branch
- [ ] Backend slice on the `FetchClientAccessListAction` template
- [ ] Panel with its own scroll container
- [ ] Seeders extended

#### Testing & Validation

- [ ] Every §9 negative path has a test
- [ ] `npm run test:architecture` green
- [ ] `npm run test:integration` green for the new repository
- [ ] Atlas specs green, with the one named `AccessManagerOverlay.spec.ts` update

#### Deploy & PR

- [ ] PR draft filled from the testing-implementation doc
- [ ] Gates reported with exact command, scope and result

#### Ticket Closeout

- [ ] Every acceptance criterion walked against what shipped
- [ ] F9 outcome stated plainly — demonstrated, or shipped with the gap named

## 12. Definition of done (investigation gate)

| Question | Answer |
| --- | --- |
| Confirmed problem class, and any reframing | Completion of a deliberately deferred read path; reframed from *new capability* at Step 2, re-confirmed at Step 4 |
| The problem in one plain sentence | §2 |
| A named blocked instance | **None — recorded as a gap**, not manufactured |
| The date it bites next | 2026-08-19, sprint open |
| The wedge and why it is reusable | Sanitised-render + empty/error-state panel; inherited by any future RB-sourced rich text |
| Acceptance criteria and non-goals | §3, owned by the job stories |
| 30-second happy-path story | §7 |
| The metric that proves it works, and how fast it arrives | Automated: the negative-path suite, fast. Manual: **blocked (F9)** — the honest answer is that reality will be slow to tell us we are wrong |
| Verdict and disposition | **Proceed with conditions** (§0) |
| Owners for the open variables | §10 — all eight assigned |
| Tracked action with a falsifiable done-when | §11 handoff table |
