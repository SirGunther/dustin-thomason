# PRDV-16403 — Recon and plan (orchestrate Phase 1)

> **What this document is.** The findings this recon reached, plus the todos to emit them at Phase 2. It is **not** an implementation plan — that is Phase 4. Approving this approves the *findings and the emission list*, not a design.
>
> Saved verbatim as `docs/atlas/PRDV-16403/investigations/PRDV-16403-recon-and-plan.md` at Phase 2's first action, then frozen. Later deviation goes in the coverage ledger's reopen reason or the why-log, never into this file.

## Context

Ops Atlas users granting a client contact access to a proceeding's deliverables cannot see the RB-recorded warnings for the case, the contact, and the contact's firm, or the case remarks, without leaving Atlas and opening RB9. PRDV-16403 fills the right-hand panel of the Access Manager overlay with those four read-only values, via a new Callisto read endpoint.

The panel shell already exists and ships today carrying a placeholder that reads *"Warnings and notes will appear here in a future release."* This ticket is the promised release.

**Headline:** the plumbing is a mirror exercise with a known-good template and machine-enforced guardrails. The risk is entirely elsewhere — in one blocked-manual-verification problem (**F9**), one state-modelling ambiguity (**F1**), and four places where the ticket's own prescriptions are stale or wrong (**§0, F7, F8, F6**).

---

## 0. Corrections to the Phase 0 record — apply at Phase 2

Two claims written into `docs/atlas/PRDV-16403-changelog.md` and `orchestration.md` during Phase 0 are **wrong**. They came from the local `callisto-back-end` tree, which sits on branch `PRDV-16313` (`c43be32c`) — branched *before* the relevant merge.

| Claim as recorded | Truth |
| --- | --- |
| *"`case.entity.ts` declares `@Entity('cases')` with **no** `warning` and **no** `remarks_html` column."* | True of the local branch, **false of `origin/main`**, where `Case` carries `warning: string \| null`, `remarks: string \| null`, `remarksHtml: string \| null` (L37-42). |
| *"Case Warning + Case Remarks return `null` until PRDV-16391 lands. Contact + Firm ship immediately."* | **PRDV-16391 already landed.** Commit `53d961ed` is an ancestor of `origin/main`; migration `1786036989067-alter__add_warning_remarks__cases_table.ts` adds all three columns (`warning` varchar NULL, `remarks` text NULL, `remarks_html` text NULL). |

**Consequence:** the ticket's **"Sequencing note"** — land contact+firm first, add the case join when 16391 merges — is **moot**. All four fields build in one pass.

**What is still open:** **PRDV-16392** (DMS CDC column mapping) governs whether real case data ever *arrives*. Columns and entity are in place and the join works today, but values may read `null` in every environment until 16392 ships. **Code unblocked, data not guaranteed** — a distinction the ticket never draws.

**Also required before implementation:** take `origin/main` (`631ed42e`) into the working branch. Without it `Case.warning` / `Case.remarksHtml` do not exist to compile against, and `docs/specs/` is absent.

---

## 1. Consult protocol (ran before any investigative branch)

**Consulted** `docs/atlas/*/investigations/*-coverage-ledger.md` for `granting-client-access`, `contacts`, `firms`, `cases`, read endpoint, `AccessManager`, `src/callisto`, `dompurify`, `sanitize`, `v-html`, XSS, feature flag. Five ledgers exist; all five were read.

| Ledger | Outcome |
| --- | --- |
| **PRDV-16312** | **Found + reused** — GCA module/registry/architecture/transaction/spec-convention ground (areas 1-7, 10). Area 9 (dependency state) **not reopened** — already corrected as stale by 16313. Its `IS_GRANTING_CLIENT_ACCESS_ENABLED` manual-test blocker **reopened under condition 2** → became **F9**. |
| **PRDV-16313** | **Found + heavily reused** — GCA action/service/guard shape, architecture fitness rules, module dependency direction, `AuthUser` conventions, spec conventions (areas 1, 4-7, 9-11). Its *"no feature flags in `granting-client-access`"* claim **reopened and corrected**: `IS_CLIENT_ACCESS_OUTBOX_ENABLED` shipped via PRDV-16310, resolved in `ContactsService`. |
| **PRDV-16402** | **Found + reused** — Atlas `src/callisto/api/constants.ts`, the Vue Query `staleTime` convention, repository-naming precedents, backend flag-resolution pattern (areas 6-8, 16-18). |
| **PRDV-14055** | **Found + reused narrowly** — the shared `common.json` i18n namespace (the same file this ticket extends) and Atlas `__specs__` conventions. Baseline `ef217844` is ~13 months stale; re-verify anything leaned on. |
| **PRDV-16192** | **Found, not reopened** — different subsystem (Europa / `src/europa/`). Only the *projection → DTO → responder* triad transfers as pattern: *"Any new field must be added at all three layers."* |
| **`docs/atlas/reviews/`** — **not ledger-formatted, so the ledger grep missed it** | **Found + reused.** The PRDV-16310 / 16315 PR reviews are the **only** prior coverage of `granting-client-access/contacts/` anywhere. Reused for its write-side call graph, the flag precedent, type-placement rules, and the whole-module test-gate baseline (`npx jest --config jest-e2e.json --runInBand src/granting-client-access` → 75 suites, 361 tests, pass). **Add this folder to the consult glob permanently.** |

**No frontier item in any ledger is this ticket.** Two merely touch it: 16313's *"other five unbuilt epic events"* (same module, scope boundary) and its *"`trackTypeId` guard mismatch"* — the latter does **not** apply here, because the guard precedent this ticket should follow is the read-side `ProceedingsReadAuthGuard`, not `UpdateDeliverableFileAuthGuard`.

**Virgin ground, confirmed by grep across all of `docs/`:** no prior ticket investigated a GCA **read** endpoint, the `contacts`/`firms`/`cases` entity columns, the `AccessManagerOverlay` tree, or HTML sanitization / DOMPurify / `v-html` / XSS as a behaviour. The only sanitization hits anywhere are two npm-audit dependency mentions (PRDV-15619, PRDV-16150). `NotificationBody.vue` — the single precedent — has never been investigated by any ticket.

`dnu/` folders excluded throughout, including `docs/atlas/PRDV-16312/dnu`.

---

## 2. Step 1 — Raw facts

| Item | Finding |
| --- | --- |
| Problem, one sentence | An Ops Atlas user setting up a client contact's deliverable access cannot see the warnings recorded in RB against the case, the contact, or the contact's firm, nor the case's remarks, without leaving Atlas and opening RB9. |
| Named blocked instance | **None. Say so plainly.** The ClickUp thread names Derrick Dieso, Shaye Lankford, Anastasiya Savchuk and Michael Carrigan — all as *participants deciding copy and scope*, not blocked users on real tasks. No Ops user, case, or occasion is named anywhere. The problem is asserted, not evidenced. |
| Urgency / next bite | **2026-08-19** — Sprint 2026-17 (8/19–9/1) opens tomorrow; High priority, 3 points, assigned. Concrete, unlike the instance. |
| Distinct problems | Three, not one. Split into job stories 01 (reach), 02 (absent-vs-unavailable), 03 (fidelity) at Phase 0. |

### Problem Check lens — a finding per flag, each grounded in a trimmed quote

| Flag | Finding | Evidence (trimmed quote from the request) |
| --- | --- | --- |
| **Asked** | Surface four read-only values in an existing panel, ordered, so the user need not open RB. | *"I want to see firm, case, and contact warnings plus case remarks in the right-hand panel … so that I can reference delivery details without opening RB."* |
| **Answered** | The request answers far more than it asks — endpoint path, every file, the DTO shape, the sanitize config, the cache options. Criteria and implementation are fused, so a reviewer cannot tell which constraints are *requirements* and which are *one author's design*. Recon has since shown **four** of those prescriptions stale or wrong (§0, F6, F7, F8). | *"New read-only endpoint under `granting-client-access/contacts`, mirroring the `fetch-contact-deliverable-type-grants` stack (action → service → transaction script → repository → projection → mapper → DTO → swagger)."* |
| **Should-ask** | Nothing asks what an Ops user **does differently** once they read a warning. "Reference" is the only stated use; no criterion connects a warning to the grant being made. This feature informs but never intervenes — possibly correct, never asked. | *"so that I can reference delivery details without opening RB."* |
| **Conflation** | Warnings and remarks are bundled as one thing — one endpoint, one panel, one failure message — while differing in type (plain text vs HTML), in source (three entities vs one), in column nullability (**F5**), and in empty-state wording. The request **acknowledges the difference and bundles them anyway**. | *"(intentional distinct wording — warnings and remarks are referenced differently by users)"* beside a single *"Warnings/remarks failed to load"*. |
| **Thin** | "Delivery details" is broader and vaguer than the four values delivered, is never defined, and is the stated justification for the whole story. | *"so that I can reference delivery details without opening RB."* |
| **Off** | One criterion cannot be checked for one of the four things it governs, and says so in its own parenthesis. An internal contradiction, not a note. | *"Styling matches Figma … (Case Remarks not in Figma — confirm with Product)."* |

**Not flagged:** the survives/stripped sanitization lists. Read closely the request resolves its own apparent tension — *"anything that survives sanitization renders as-is with no dedicated image/table styling support"* is a scope statement. Per the user's 2026-08-18 ruling, formatting the spec does not name is **out of scope** and is not to be reopened.

---

## 3. Step 2 — Classification (re-checked at Step 4, confirmed)

**Class the request assumes:** *new capability* — build an endpoint, build a panel. Its effort narrative is all plumbing.

**Class derived from the instances:** **completion of a deliberately deferred read path.** Everything exists except the wire between:

- the panel shell ships today with a placeholder promising this exact feature (`AccessManagerOverlay.vue` L318-335);
- the overlay already receives every input the endpoint needs — `proceedingId`, `contact.id` (L24-32, L41);
- all four data columns now exist in Callisto, CDC-replicated from RB9 (§0);
- the read stack to copy exists in the same module — with a **closer sibling than the one the ticket names** (F7).

**The reclassification is load-bearing.** It moves the centre of gravity off the plumbing and onto six findings below, none of which is where the ticket puts its detail.

**Wedge:** the sanitised-render + empty/error-state panel. Smallest piece that forces the whole vertical open (endpoint → normalisation → freshness → render); the only part with **no in-repo precedent and no prior investigation** (§1, F4); and reusable — any future RB-sourced rich text in Atlas inherits it.

> **Wedge revision, logged as a course change:** the first draft of this recon proposed *"ship Contact + Firm first"*. That was the wedge only while §0's blocker was believed real. It is withdrawn.

---

## 4. Step 3 — Contract

**Acceptance criteria** are owned by the three job stories (17 criteria), not by this document. The Phase 3 spec cites them; it does not amend them.

**Non-goals** (from the request): editing warnings or remarks in Atlas; the DMS/IaC mapping (PRDV-16392); dedicated image or table styling support; any change to the permission model; formatting the request does not name (user ruling, 2026-08-18). **Removed from non-goals:** replicating the case columns — PRDV-16391 already did it.

---

## 5. Step 4 — Why it exists, and the software lens

**Origin, documented not inferred.** The parent-epic spec names the prerequisite: PRDV-14820 *"provides the `AccessManagerOverlay` two-column layout and the right-hand `rb-warnings-panel` placeholder this story fills."* A deliberate IOU being paid.

### Candidate 1 — Contract / source-of-truth alignment

Authority is **RB9**, mirrored twice before Atlas sees it:

```
RB9 (Contacts.Warning, Firms.Warning, Cases.Warning, Cases.RemarksHTML)
  --ETL-->      Lagrange
  --DMS CDC-->  Callisto (contacts.warning, firms.warning, cases.warning, cases.remarks_html)
  --new DTO-->  Atlas
```

Sources: `larry-adams/data-manual/rb9-replicated-timestamps.md` (canonical), `callisto-back-end/docs/data/replicated-rb9-data.md`, the PRDV-16391 spec's mapping table.

- **The read-only criterion is structural, not a policy choice.** `Contact`, `Firm` and `Case` all extend `ImportedBaseEntity` — rows are written by replication, never by the app. Callisto has no write path, so Atlas cannot have one. Record it as a structural guarantee rather than testing it as UI behaviour.
- **F5 — the three warning columns are not shaped alike, and one mapper must absorb the difference.** `contacts.warning` and `firms.warning` are **NOT NULL `varchar`**, may be `''`. `cases.warning` is **nullable `varchar`**; `cases.remarks_html` **nullable `text`**. Normalisation must collapse *both* `null` and empty-or-whitespace across two different column contracts. The request says only *"Mapper normalizes empty/whitespace → `null`"* and never mentions the asymmetry.
- **F3 — the firm whose warning is shown and the firm name it is shown under are resolved by two different paths, and nothing reconciles them.** Backend picks the firm via `firm.id = contact.account_id`, with **no FK** on that column (a dangling `account_id` is how the existing integration spec tests the no-firm case). The frontend never knows a firm id at all: `ContactSearchItem` carries only `firmName: string | null`; `ClientAccessFirm` carries `name`, `streetAddress`, `city`, `state` — **no id**. So the panel would label a warning fetched for firm *A* with a name obtained separately. For a *warning*, mislabelling the firm is substantive, not cosmetic. **First entry for the concerns register.**

### Candidate 2 — Surface enumeration (blast radius)

Two entry points, differing in a way that matters:

| # | Trigger | Handler | Contact object |
| --- | --- | --- | --- |
| 1 | Contact search panel — granting a new contact | `handleAddContactFromSearch` (`ProceedingDetailPage.vue` L103) | a real `ContactSearchItem` from the search response |
| 2 | Client Access list row — editing existing access | `handleEditAccessFromList` (L114) | **a synthetic `ContactSearchItem` assembled from a `ClientAccessContact`** |

**Completeness claim:** `isAccessManagerOpen` declared L101, set `true` in exactly two places (L106, L117); other writes are the close handler (L121) and the `after-leave` reset (L123-126). Overlay rendered from exactly one call site (L744-756). Grep of `isAccessManagerOpen|accessManagerOpen|showAccessManager|openAccessManager` across `src/` returns only `ProceedingDetailPage.vue`. The list of two is complete.

Both paths must be exercised: path 2 fabricates its contact and is the likelier source of an **F3** mismatch.

### Candidate 3 — Protect-the-neighbours

| Neighbour | Why it shares the path | Concrete check |
| --- | --- | --- |
| **`AccessManagerOverlay.spec.ts` L177-188** | Asserts on `data-testid="rb-warnings-panel"` **and** the `warningsPlaceholder` i18n key. Retiring that key, or moving the testid onto the new component, **breaks this test** | A named, deliberate spec update — not an incidental edit |
| **`<Overlay :loading="isLoading">`** (`AccessManagerOverlay.vue` L151) | `isLoading` today aggregates only `useAccessManager`'s queries. Folding warnings-loading in would let a slow warnings fetch **block the entire access UI**, defeating the non-blocking intent | Warnings loading renders *inside* the panel; assert `Overlay`'s `loading` prop unchanged |
| The overlay's left column (`useAccessManager`) | Same overlay, same `modelValue` lifecycle | `useAccessManager.spec.ts` + overlay spec green with no assertion edits beyond the one above |
| `warningsTitle` + the overlay close button | They live in the `<header>` **outside** the placeholder being replaced (L319-332) | New component renders section titles only; assert the panel title appears exactly once and close still works |
| Every provider in `granting-client-access.module.ts` | Adding `Case`, `Job`, `Proceeding` to `forFeature` is module-wide | Module compiles; GCA suite green against the 75-suite / 361-test baseline; `npm run test:architecture` green |

### Candidate 4 — Detection gap

**Not applicable — new capability, not a defect.** No net should have caught it. Recorded rather than omitted, per the lens.

### The findings that actually carry risk

- **F9 — manual verification of this ticket is blocked today, and a prior ticket already failed at it.** PRDV-16312's test plan records an acceptance criterion *"not demonstrated — blocked on the GCA feature flag"*, because `IS_GRANTING_CLIENT_ACCESS_ENABLED` is absent from the local Cognito user's `custom:feature-flags`, and *"Setting it did not survive a re-login in the attempt made — unresolved."* PRDV-15776's changelog appears to offer a workaround (`CALLISTO_DEV_FEATURE_FLAG_OVERRIDES=…`). **Traced to source: that workaround does not exist.** `IsFeatureAllowedTS` carries an explicit JSDoc — *"Feature access follows **Cognito token claims only** (`identity.featureFlags`). There is no server-side env override; flags must be assigned in Cognito/Atlas for every environment including local."* — and grep for `DEV_FEATURE_FLAG_OVERRIDES|FEATURE_FLAG_OVERRIDE` across `atlas-front-end` returns nothing; `useFeatureFlags` simply fetches the list from Callisto. **So the only path is a Cognito attribute assignment that has already proven not to stick.** This gates Phase 5, not the build, and it is the single most likely reason this ticket ships unproven.
- **F1 — `null` means two different things and the system cannot tell them apart.** All four fields arrive as `string | null`, and `null` is produced both by *"RB holds nothing"* and by *"DMS never mapped this column"* (PRDV-16392, §0). The request's criterion — empty → *"No warning info"* — would therefore state something **false** for the case fields in every environment until 16392 ships. **The structure cannot answer this:** the DTO has exactly one representation for both states, so distinguishing them is a change, not a lookup. The *decision* is Product's; the *fact* that it cannot currently be distinguished is settled.
- **F2 — the freshness requirement is already satisfied by the overlay's lifecycle, and only one of the three proposed cache options does any work.** The overlay renders under `v-if="isGcaEnabled && accessManagerContact"` (L755) and `handleAccessManagerAfterLeave` nulls `accessManagerContact` (L123-126) — so **it unmounts on close and remounts on open**. `refetchOnMount: 'always'` therefore fires every open regardless of `staleTime`. The option that earns its place is **`gcTime: 0`**, which stops a previous contact's warnings flashing before the refetch resolves — and `gcTime` appears **nowhere** in the repo. `staleTime: 0` is redundant against the remount. Closes story OQ-01.4 by evidence: reopening for the same contact *does* refetch.
- **F4 — the sanitised render establishes new precedent on two counts.** Exactly **one** `v-html` and **one** `DOMPurify.sanitize` exist in the repo (`NotificationBody.vue` L32-43), passing **no config object**; an allowlist would be the first. And `.cursor/rules/planetdepos-quasar.mdc` L214 says *"Avoid `v-html` when possible"* — this work brushes a repo rule and should say so rather than quietly proceed. `vue/no-v-html` is a warning from `flat/recommended`, suppressed by a paired HTML-comment block. Note the ticket cites `dompurify ^3.2.6` while the lockfile resolves **3.4.11**.
- **F6 — the panel cannot scroll where the request assumes it can.** `.rightColumn` is `overflow: hidden`, not `auto`. *"Internal scroll bar when content exceeds panel height"* requires a **new inner element** with `flex: 1; min-height: 0; overflow-y: auto`; without it content clips silently. Separately the empty-state criterion says *"italic, 50% grey"*, but the in-overlay precedent is `rgba($schemes-on-surface, 0.38)` and the italic precedents elsewhere use `$schemes-on-surface-variant` with no alpha — "50%" matches no existing token.

### Refinement — reproduction recipe and preconditions

A tester needs: `IS_GRANTING_CLIENT_ACCESS_ENABLED` on the Cognito user (**see F9**); a role reaching the Access Manager; a contact with non-empty `contacts.warning`; that contact's firm with non-empty `firms.warning`; a proceeding whose job has non-null `case_id`; and for the case fields, **PRDV-16392 shipped**. Backend proof additionally needs real Postgres — repository specs are `*.integration.spec.ts`, run by `npm run test:integration` and **excluded from `npm test`**.

**Seeder work is unavoidable and the request never mentions it:** `seedContact` and `seedFirm` hardcode `warning` to `''` with no override; `seedProceeding` creates its `jobs` row with **no `case_id`**; and **no `case.test-seeder.ts` exists at all.**

---

## 6. Architecture constraints — machine-enforced, and they bind the design

`npm run test:architecture` shells out to dependency-cruiser and runs via `pretest`, so these are not advisory:

- **A transaction script may not call another transaction script** (`severity: error`). Contact+Firm keys off `contactId`; Case keys off `proceedingId` via Proceeding→Job→Case — two queries. So **one TS calling one repository twice**, or two repositories. One TS calling two TSs fails the build.
- **A repository may not import a mapper**; **`domain/` may not import a `*.response.dto.ts`**. The mapper lives in the **application** layer and the **action** maps — as `FetchClientAccessListAction` does, not as the ticket's *"…repository → projection → mapper → DTO"* ordering implies.
- **`ContactsService` may not import the mapper** (`services-no-mappers`). It *may* resolve feature flags — that is the sanctioned layer (`IS_CLIENT_ACCESS_OUTBOX_ENABLED` precedent, PRDV-16310).
- **`no-orphans` is `severity: error`** — a new file unreachable by imports fails the build. A missing registry entry is a build failure, not just a DI error.
- **GET handlers start with `Fetch`, not `Get`** — the spec's `FetchAccessManagerWarningsAction` complies.
- **No `Dto` in any name under `domain/`**; projections in `domain/projections/`; TS input a colocated `*.param.ts`. Importing `case.entity.ts` from `granting-client-access` **is** allowed — that module is in `NON_DOMAIN_MODULES`.
- `forFeature` **must** gain `Case`, `Job`, `Proceeding` for entity-class joins — neither `JobModule` nor `ProceedingsModule` re-exports `TypeOrmModule`. Avoidable only via the table-name-string join style already used in `ProceedingRepository.findProceedingDetailById`.

**Two more corrections to the ticket's prescriptions:**

- **F7 — the ticket names the wrong sibling to mirror, on three counts.** It says mirror `fetch-contact-deliverable-type-grants`. That action has **no mapper** (its projection is structurally identical to its DTO), **no `@UseGuards`**, and the loose `ParseIntPipe`. The warnings endpoint needs a nested DTO, a mapper, and — on precedent — a guard. The right template is **`FetchClientAccessListAction`**: nested nullable-object DTO, application-layer mapper (`toFetchClientAccessListResponseDTO`), `@UseGuards(ProceedingsReadAuthGuard)`, and `new ParseIntPipe({ errorHttpStatusCode: 400 })`.
- **F8 — the ticket's 404 is unreachable by the means it prescribes.** It says *"reuse `ValidateContactExists` for 404"*. That validator throws **`BadRequestException` (400)**, and the existing grants TS spec asserts exactly that. Reusing it yields 400; getting 404 means not reusing it. The request contradicts itself inside one clause and one half has to go.

---

## 7. Step 7 reconcile — facts resolved by evidence, decisions isolated

**Resolved this phase — no longer questions:**

| Was | Resolution |
| --- | --- |
| Do the case columns exist? Is 16391 a blocker? | **Merged.** All three columns on `origin/main` (§0). Only 16392 governs data arrival. |
| Is there a dev override for the GCA feature flag? | **No.** Cognito claims only, per `IsFeatureAllowedTS` JSDoc; no override in either repo (**F9**). |
| Story OQ-01.4 — does reopening for the same contact refetch? | **Yes**, by unmount/remount, independent of cache options (F2). |
| Story OQ-02.3 — is a partial failure representable? | **No.** One endpoint, one query, one response — all four fail together. The singular failure copy is correct. |
| Story OQ-01.1, fact half — is there already a permission gate? | **Yes, two.** The overlay is entirely behind `IS_GRANTING_CLIENT_ACCESS_ENABLED` at the parent (L755), and the closest sibling read endpoint carries `@UseGuards(ProceedingsReadAuthGuard)`. A redundant flag check inside the overlay would break `AccessManagerOverlay.spec.ts`. |
| Is `forFeature` widening required? | **Yes** for entity-class joins (§6). |
| Does `firmName` derive from the same join the warnings query uses? | **Partially — `ClientAccessListRepository` does** (`leftJoin(Firm, 'firm', 'firm.id = contact.account_id')`). The **search** path is unconfirmed, and entry point 1 feeds from it → the one frontier item. |

**Genuine decisions remaining, each with an owner:**

| # | Decision | Owner |
| --- | --- | --- |
| D1 | What the case fields display while PRDV-16392 is unshipped — *"No warning info"* would be false (F1) | Product |
| D2 | 400 or 404 for a missing/inactive contact — the request cannot have both (F8) | Dustin / spec reviewer |
| D3 | Does the endpoint carry `ProceedingsReadAuthGuard`, mirroring the guarded sibling? Recommend **yes** (F7) | Dustin |
| D4 | Does a fetch failure block completing the access work (story OQ-02.1)? Epic spec says non-blocking; the request is silent | Product |
| D5 | Case Remarks styling, absent from Figma; and *"50% grey"* vs the `0.38` token (F6) | Product / design |
| D6 | Pass a DOMPurify config at all, given no precedent and a rule discouraging `v-html` (F4) | Dustin |
| D7 | How F9 gets unblocked — who assigns the Cognito flag and makes it survive re-login, or whether this ships on automated tests alone | Dustin / Product |

---

## 8. Emission todos for Phase 2

1. **Apply §0's corrections** to `PRDV-16403-changelog.md` (Context, Current state) and `orchestration.md` (Phase 0 notes) — a dated correction, not a silent rewrite.
2. Save this plan verbatim to `investigations/PRDV-16403-recon-and-plan.md`; freeze it.
3. Create `PRDV-16403-why-these-changes.md` — class of problem per §3, plus the Phase 1 why-log entry recording the wedge revision and §0 as a course change.
4. Apply the staged job-story reconcile with a Phase 1 Story log entry per story touched:
   - **Story 01** — close OQ-01.4 (F2); split OQ-01.1 into resolved fact + D3; rewrite OQ-01.2, whose premise was §0's false blocker, into D1's narrower form.
   - **Story 02** — close OQ-02.3; reframe OQ-02.4 onto PRDV-16392 rather than a missing column; carry OQ-02.1 as D4.
   - **Story 03** — close OQ-03.1 as **out of scope** per the user's 2026-08-18 ruling; carry D5, D6.
5. Write `investigations/PRDV-16403-investigation.md` from the report template; §5 **links** the diagrams artifact, embeds nothing.
6. Materialise `investigations/PRDV-16403-coverage-ledger.md` — the §1 Consulted table first (including `docs/atlas/reviews/`), one row per area traversed, then the frontier: the unconfirmed search-path `firmName` derivation, `NotificationBody.vue` as uninvestigated ground, and Cognito flag provisioning (F9).
7. Produce `investigations/PRDV-16403-diagrams.md` — current-vs-target read path; the RB9→Lagrange→Callisto→Atlas chain with the two nullability contracts (F5); a sequence for the unmount/remount/refetch lifecycle (F2).
8. Seed `testing/PRDV-16403-test-plan.md` from report §9, each scenario naming the criterion it exercises, flagging that repository coverage needs `npm run test:integration` plus new seeder overrides, and recording **F9** as a live risk to manual demonstration.
9. Stage `PRDV-16403-pr-draft.md` as an **empty shell** — headings only.
10. Record concerns in `PRDV-16403-future-development-concerns.md` — **F3** first; also the unguarded grants-fetch action and the `trackTypeId` guard smell inherited from 16313's frontier, neither created nor widened by this ticket.
11. Append the Phase 2 changelog session log entry.

## Verification

This phase writes nothing, so verification is that the findings hold. Each is a one-line check:

| Finding | Check |
| --- | --- |
| §0 | `git merge-base --is-ancestor 53d961ed origin/main` exits 0; `git show origin/main:src/cases/domain/entities/case.entity.ts` shows three columns |
| F2 | `grep -rn "gcTime" src/` in `atlas-front-end` returns nothing |
| F4 | `grep -rn "v-html\|DOMPurify" src/` returns only `NotificationBody.vue` |
| F6 | `.rightColumn` in `AccessManagerOverlay.module.scss` reads `overflow: hidden` |
| F8 | `ValidateContactExists` throws `BadRequestException` |
| F9 | `IsFeatureAllowedTS` JSDoc says Cognito-only; `grep -rn "FEATURE_FLAG_OVERRIDE" ` in `atlas-front-end` returns nothing |
