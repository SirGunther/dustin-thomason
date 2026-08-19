# Locked decisions — atlas/PRDV-16403

Q-and-A traceability ledger for Phase 3. Each decision carries its options, the evidence behind them, a recommendation where the code settles the argument, and where the answer lands in the spec. Rows are answered **one at a time**; an unanswered decision stays `open` rather than being guessed.

**Every decision has a plain-language name.** The `LD-###` label exists only so other artifacts can cross-reference something stable — the name is what the decision actually is.

Status vocabulary: `open` · `deferred (reason)` · `locked` · `rejected`

> **Provenance note.** The content below was reviewed in an external web artifact on 2026-08-18 and **migrated here at the user's instruction** — ticket artifacts belong in this repo, per the orchestration's repo-boundary rule. The web copy is being deleted; this file is the single source of truth for the decisions. Nothing was left only in the artifact.

---

## Summary

| LD | Decision (plain language) | Status | Owner | Blocks |
| --- | --- | --- | --- | --- |
| 001 | What the Case Warning and Case Remarks sections display before the replication mapping ships | **deferred** — user researching | Product | the panel's copy |
| 002 | Whether a missing or inactive contact returns 400 or 404 | **provisional** — 400, flagged for Derrick | Dustin | — |
| 003 | Whether the new endpoint carries an authorization guard | **provisional** — guard added, flagged | Dustin | — |
| 004 | Whether a failed warnings fetch stops the user finishing the access work | **locked** — non-blocking | Derrick's spec | — |
| 005 | How Case Remarks is styled, and what "50% grey" means in real tokens | **provisional** — overlay's own token, flagged | Dustin | — |
| 006 | Whether to pass a sanitiser allowlist, or call it bare | **locked** — bare call | Derrick's spec | — |
| 007 | How manual verification gets unblocked, or whether this ships unproven | open | Dustin / Product | any claim a criterion was demonstrated |
| 008 | Whether Phase 3 writes a new spec or an addendum to Derrick's | **locked** — addendum | Dustin | — |

---

## Authority ruling — 2026-08-18

**Dustin accepted Derrick Dieso as the design authority for this ticket**, on the reading that his spec is valid and the investigation supplies clarifications rather than a competing design. That ruling settles three decisions outright and supplies a defensible default for three more.

**Verification verdict, stated plainly: his spec is valid with four named exceptions.** It cannot be confirmed valid as a whole, because two of the four change observable behaviour rather than only documentation:

| # | Exception | Kind | Consequence |
| --- | --- | --- | --- |
| 1 | The dependency it calls blocking has already merged; its *Sequencing note* is void | **stale, no behaviour change** | Build all four fields in one pass |
| 2 | *"Reuse `ValidateContactExists` for 404"* — that validator throws 400 | **self-contradictory; observable** | The HTTP contract changes whichever half is dropped |
| 3 | *"Mirror `fetch-contact-deliverable-type-grants`"* — that sibling has no mapper, no guard, and the loose pipe | **wrong template; guard is observable** | Authorization behaviour depends on which sibling is followed |
| 4 | Internal scroll is required, but the target container is `overflow: hidden` | **omission; observable** | The criterion fails silently without a new inner element his spec does not mention |

Exceptions 2, 3 and 4 are **deviations from his document**, not clarifications of it, and each is flagged below for his confirmation. That is the honest scope of "just make the clarifications" — three of them are corrections he has not yet seen.

**Settled outright by his authority** (his spec states these; no deviation):

- **LD-004 → non-blocking.** His spec §4: *"non-blocking inline error (must not block the access flow)"*. The ClickUp text's silence is what left it open; his document answers it.
- **LD-006 → bare sanitiser call.** His spec §5 uses `DOMPurify.sanitize(props.html ?? '')` with **no config object**. This coincides with the evidence-based recommendation and with Dustin's out-of-scope ruling on unnamed formatting. The ticket's explicit allowlist is **not** his design — it was added in the ClickUp restatement.
- **LD-008 → addendum, not a new spec.** Carries only the delta.

**Provisional, implemented and flagged for Derrick** (his spec is silent or self-contradictory, so authority cannot settle them; the default below is taken to keep moving, and each is called out in the addendum):

- **LD-002 → 400.** His spec asks for 404 *and* names the mechanism that yields 400. The mechanism is the more specific instruction, every sibling behaves this way, and the existing sibling spec already asserts it. **Flagged as deviation 1.**
- **LD-003 → add `ProceedingsReadAuthGuard`.** His spec is silent, and "mirror the grants stack" implies no guard. Adding one is a change to his design, taken because the same-scope sibling read is guarded and authorization is the wrong thing to leave to inference. **Flagged as deviation 2.**
- **LD-005 → the overlay's existing empty-state token.** His spec does not style Case Remarks. Using `rgba($schemes-on-surface, 0.38)` invents no new value. **Flagged as deviation 3.**

**Still genuinely open:**

- **LD-001** — deferred, Dustin researching the DMS dependency. Blocks only the two case sections' empty-state wording. The panel will be built to take empty-state text per section so either answer drops in without restructuring — the decision is deliberately kept late-binding rather than pre-empted by shipping option (a).
- **LD-007** — a delivery condition, not a spec matter. Unchanged.

---

## LD-001 — What the Case Warning and Case Remarks sections display before the replication mapping ships

**Status:** `deferred` — the user is researching the PRDV-16392 dependency (2026-08-18). Explicitly deferred, not skipped.
**Owner:** Product · **Supersedes if answered:** the ticket's criterion *"Empty warning → title + 'No warning info'"*, as applied to the two case sections only · **Spec destination:** empty-state behaviour section; job story 02's empty-wording criterion.

Both case fields return empty in every environment until PRDV-16392 maps the columns from Lagrange into Callisto. The response has exactly one representation — `null` — for two different truths: *RB genuinely holds nothing*, and *we never asked RB*. Shipping the ticket's wording prints a false statement on a panel whose whole purpose is conveying accurate cautions.

**Verified:**

- The columns **do** exist — PRDV-16391 merged, commit `53d961ed`, migration `1786036989067`. The ticket's claim that they are missing is stale.
- RB → Lagrange replication **already covers these fields**; no `lagrange-back-end` work is needed. Only the Lagrange → Callisto DMS mapping is missing.
- **No specification for PRDV-16392 exists anywhere** — searched `origin/main` in both repos and all of `larry-adams`. Three pointers to it, no document.

| # | Option | Trade-off |
| --- | --- | --- |
| a | Ship the wording as specified | Zero extra work, self-correcting once the mapping lands — but untrue until then |
| b | Distinct "not yet available" wording | Honest. Costs two i18n strings and some way to know which state we are in, since the response cannot tell us |
| c | Hide the two case sections entirely | Says nothing false, but breaks the required four-section order |
| d | ~~Block this ticket on the mapping~~ | **Rejected** — the mapping is itself blocked, and contact and firm warnings are ready now |

### What still needs establishing (the research block)

1. Is PRDV-16392 shipped, in flight, or unstarted? ClickUp reads "ready for work" per `larry-adams` `work breakdown structure/entity checklists/case_checklist.md:52`. **If it lands before this ticket, LD-001 disappears entirely.**
2. Who owns the DMS task change, and is it IaC-managed (a PR someone can point at) or console-configured?
3. Is a spec for PRDV-16392 expected before the work happens, given none exists?
4. Once mapped, do **empty** RB9 case warnings arrive as `''` or `NULL`? `contacts.warning` and `firms.warning` are NOT NULL varchar and may be `''`, while `cases.warning` is nullable — the mapper must collapse both, and the empty-state copy depends on which arrives.

---

## LD-002 — Whether a missing or inactive contact returns 400 or 404

**Status:** `open` · **Owner:** Dustin, or the spec reviewer · **Rejects:** one half of the ticket's own clause · **Spec destination:** HTTP surface section; swagger `@ApiResponse` decorators.

The ticket asks for 404 and, in the same clause, says to reuse `ValidateContactExists` to get it. That validator throws `BadRequestException` (400). Following the instruction produces 400; getting 404 means not following it. The existing sibling transaction-script spec already asserts `BadRequestException`, so changing the behaviour is not free.

| # | Option | Trade-off |
| --- | --- | --- |
| a | **Accept 400 and correct the spec** — *recommended* | Reuses the validator as instructed, matches every sibling endpoint, no new code. The spec sentence is what was wrong |
| b | Honour the 404 | Requires a new not-found check and a deliberate divergence from both sibling endpoints |

---

## LD-003 — Whether the new endpoint carries an authorization guard

**Status:** `open` · **Owner:** Dustin · **Rejects (if a):** the ticket's instruction to mirror the unguarded endpoint · **Spec destination:** authorization section; the action's decorators.

The ticket says mirror `fetch-contact-deliverable-type-grants`, which has **no** `@UseGuards`. Its neighbour `fetch-client-access-list.action.ts` — same module, same users, same proceeding scope — carries `@UseGuards(ProceedingsReadAuthGuard)`. Copying the ticket's choice propagates the gap to a second endpoint.

| # | Option | Trade-off |
| --- | --- | --- |
| a | **Add `ProceedingsReadAuthGuard`** — *recommended* | Follows the guarded sibling. One decorator, one import |
| b | Leave it unguarded, as the ticket says | Consistent with the endpoint being copied, inconsistent with its neighbour. The unguarded sibling is separately recorded as concern C2 |

---

## LD-004 — Whether a failed warnings fetch stops the user finishing the access work

**Status:** `open` · **Owner:** Product, with Dustin · **Spec destination:** error-handling section; job story 02.

Derrick's spec asserts the error must be non-blocking. The ClickUp text is silent, so it was never imported as an acceptance criterion — job story 02 carries it as a question. There is a structural reason to care either way: `<Overlay :loading="isLoading">` currently draws only from the left column's queries, and wiring the warnings fetch into it would block the whole access flow behind a slow request.

| # | Option | Trade-off |
| --- | --- | --- |
| a | **Non-blocking, per Derrick's spec** — *recommended* | The user can still grant access with the panel showing an error. Keep the warnings query out of the overlay's loading state |
| b | Blocking | Defensible if reading a caution is mandatory before granting — but nobody has asked for that, and it lets a transient outage stop work |

---

## LD-005 — How Case Remarks is styled, and what "50% grey" means in real tokens

**Status:** `open` · **Owner:** Product and design · **Spec destination:** SCSS module section.

Two gaps in one decision. The ticket's own criterion admits Case Remarks is absent from Figma and says to confirm with Product. Separately, its empty-state instruction — *italic, 50% grey* — matches no token in the codebase: the overlay's existing empty state uses `rgba($schemes-on-surface, 0.38)`, and the italic precedents elsewhere use `$schemes-on-surface-variant` with no alpha.

| # | Option | Trade-off |
| --- | --- | --- |
| a | **Use the overlay's own existing empty-state token** — *recommended* | Consistent with the component it lives in, invents no new value. Treats "50%" as approximate intent rather than spec |
| b | Get a design for Case Remarks first | Correct, and what the ticket asks for. Adds a dependency on design availability |

---

## LD-006 — Whether to pass a sanitiser allowlist, or call it bare

**Status:** `open` · **Owner:** Dustin · **Spec destination:** Case Remarks rendering section.

The ticket prescribes an explicit allowlist. The evidence says it buys nothing: the bare `DOMPurify.sanitize` call already strips every construct the criteria name as forbidden — `<script>`, event handlers, `<iframe>`, `<object>`, `<embed>` — while the allowlist as written would additionally drop links, lists, headings and underline, which nobody decided to drop. The user's 2026-08-18 ruling that formatting the spec does not name is **out of scope** makes the bare call the consistent choice.

**Context:** the repo has exactly **one** site rendering raw HTML (`NotificationBody.vue` L32-43) and it passes no configuration. `.cursor/rules/planetdepos-quasar.mdc` L214 says *"Avoid `v-html` when possible"* — this work brushes that rule either way and should say so out loud rather than proceed quietly.

| # | Option | Trade-off |
| --- | --- | --- |
| a | **Bare call, matching the existing precedent** — *recommended* | Same safety, no invented narrowing, consistent with the out-of-scope ruling |
| b | Explicit allowlist as the ticket specifies | Sets new precedent and silently drops formatting that was never discussed |

---

## LD-007 — How manual verification gets unblocked, or whether this ships unproven

**Status:** `open` · **Owner:** Dustin, with Product · **Spec destination:** not a spec section — a delivery condition. Tracked as concern **C4**.

The feature sits behind `IS_GRANTING_CLIENT_ACCESS_ENABLED`, which has no override: `IsFeatureAllowedTS` documents this in its own JSDoc — Cognito token claims only, no server-side env override, assign it in Cognito for every environment including local. PRDV-16312 hit this wall, shipped an acceptance criterion undemonstrated, and recorded that setting the flag *did not survive a re-login*. The workaround PRDV-15776's changelog documents **does not exist in either codebase** — verified by grep.

This is the one item that should influence whether the ticket is called done, because everything risky here is visual: empty versus failed, section order, internal scrolling, formatted rendering. Automated tests cover each in isolation and none proves a person can read a warning in a browser.

| # | Option | Trade-off |
| --- | --- | --- |
| a | **Provision the flag properly** — *recommended* | Unblocks this ticket and every future one behind the same flag. Needs Cognito access and an answer to why it did not stick |
| b | Ship on automated coverage, stating the gap | Legitimate only if said plainly in the PR — *"no criterion was demonstrated against a running system"* — not implied by silence |
| c | ~~Add a local override~~ | **Rejected** — contradicts the documented design and weakens a production authorization path |

---

## LD-008 — Whether Phase 3 writes a new spec or an addendum to Derrick's

**Status:** `open` · **Owner:** Dustin · **Spec destination:** determines the spec artifact's own form and location.

Derrick Dieso's `5-story-PRDV-14828-view-warnings-in-access-manager.md` already describes this work down to the file list, and `docs/specs/README.md` forbids duplicating a spec. A new document would either repeat his or contradict it. An addendum carries only the delta — the four places his document is wrong, plus the findings it never covered — which is both smaller and the thing that actually needs his response.

**Where specs live now** (`callisto-back-end/docs/specs/README.md`, `origin/main`):

- Any BE / API / data work, even with UI attached → **the Callisto repo**, `docs/specs/`.
- Entirely-UI tickets → the Atlas repo (the README says `og-atlas-front-end`; its own links point at `atlas-front-end`, so the prefix is stale).
- *"Do not duplicate a spec across repos. Do not write new specs into the personal `wikis/systems/` vault."*
- This ticket has both BE and FE work, so its home is the Callisto repo — the same folder Derrick's spec already sits in.

| # | Option | Trade-off |
| --- | --- | --- |
| a | **Addendum against Derrick's spec** — *recommended* | Smaller, avoids duplication, puts exactly the contested points in front of the person who owns the design |
| b | A new story spec for this ticket | Cleaner if PRDV-16403 is genuinely a separate story rather than the same work renumbered — but risks two documents disagreeing |

---

## Decision-dependency map — what can be built before these are answered

The open decisions cluster in **one file**, the panel component. This is the split, and it is what makes a head start possible.

### Buildable now — no open decision (12 items)

| Layer | Item |
| --- | --- |
| git | Merge `origin/main` into the Callisto branch — required before anything compiles against `Case.warning` |
| BE | Repository with both queries — the joins are settled by evidence, including which is INNER and which is LEFT |
| BE | Projection and Result types |
| BE | Transaction script — every path except the not-found status code (LD-002) |
| BE | Mapper: `null`, empty and whitespace all collapse to `null`, across two different column contracts |
| BE | Response DTO shape — specified by Derrick and unchallenged |
| BE | Registry entries and module wiring (`Case`, `Job`, `Proceeding` into `forFeature`) |
| test | Seeder extensions: `warning` overrides on contact and firm, `caseId` on proceeding, and a case seeder that does not exist yet |
| FE | Types file, request function, URL builder, query key |
| FE | The data-fetching composable — including `gcTime: 0`, the one cache option that does work |
| test | Backend unit and integration specs for all of the above |
| test | Composable spec asserting the query key, `enabled` guard and refetch behaviour |

### Blocked (7 items)

| Blocked by | Item |
| --- | --- |
| LD-001 | The panel's empty-state wording for the two case sections |
| LD-005 | The panel's styling and which grey token the empty state uses |
| LD-006 | How the remarks HTML is sanitised before render |
| LD-002 | The not-found status code — touches the script, the swagger helper and three tests |
| LD-003 | One decorator on the action |
| LD-004 | Whether a failed fetch stops the user finishing the access work |
| LD-008 | Which spec artifact Phase 3 produces, and therefore who reviews it |

### The process gate, which is not a decision

The orchestration forbids product code until the spec's reviewer has responded. **If Derrick's spec is accepted as authoritative, that gate is arguably already satisfied for everything it covers** — and what needs his response is only the delta, the four places the findings say his document is wrong. That is the fastest legitimate route to a head start, and LD-008 is what settles it.

---

## Question gates resolved

Every decision above passed the gate *"is this genuinely a decision, or a fact I should go find?"* Seven questions failed that gate during Phase 1 and were resolved by evidence instead of being asked. Recorded so nobody re-asks them:

| Question that was **not** asked | Resolved by |
| --- | --- |
| Do the `cases` warning and remarks columns exist? | PRDV-16391 merged — `53d961ed` is an ancestor of `origin/main`; migration `1786036989067` |
| Does reopening the overlay for the same contact re-read the data? | Yes, every open — the overlay unmounts on close (`v-if` on `accessManagerContact`, nulled in `after-leave`), so `refetchOnMount: 'always'` fires on a fresh mount |
| Can some of the four values fail while others succeed? | No — one endpoint, one query, one response |
| Is there already a permission gate? | Two: the GCA feature flag at the parent, and `ProceedingsReadAuthGuard` on the sibling read endpoint |
| Must `Case`, `Job` and `Proceeding` be added to `TypeOrmModule.forFeature`? | Yes for entity-class joins — no upstream module re-exports `TypeOrmModule` |
| Is a dev override available for the GCA feature flag? | No — `IsFeatureAllowedTS` JSDoc says Cognito claims only; no override in either repo |
| Does the frontend's firm **name** come from the same join as the firm's **warning**? | Yes — both `ContactsRepository` and `ClientAccessListRepository` use `leftJoin(Firm, 'firm', 'firm.id = contact.account_id')`. Closed the last frontier item and downgraded concern C1 |

## Rejected paths

Recorded so they are not re-proposed:

- **Extending the existing grants endpoint to also return warnings** — conflates two aggregates and breaks a live DTO contract.
- **Four separate endpoints, one per value** — four round trips per panel open, and the criteria treat the four as one atomic failure unit.
- **Resolving warnings on the frontend from already-loaded data** — structurally impossible: no frontend type carries a warning field, and neither carries a firm id.
- **Two transaction scripts, one per query** — `transaction-scripts-no-other-transaction-scripts` is `severity: error`; the legal shape is one script calling one repository twice.
- **Adding a local feature-flag override** to unblock manual testing — contradicts the explicit JSDoc and weakens a production authorization path.
