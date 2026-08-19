# Test plan — atlas/PRDV-16403

> Seeded from [PRDV-16403-investigation.md](../investigations/PRDV-16403-investigation.md) §9 on 2026-08-18. Refined by spec: **pending (Phase 3)**.

Status: **seeded**

Every scenario names the acceptance criterion it exercises, by story and criterion text. Where a scenario exists for coverage with **no criterion behind it**, it carries `[NO-CRITERION]` and says why.

## Scope and surfaces under test

- **New Callisto read endpoint** `GET /granting-client-access/contacts/contactId/:contactId/proceedingId/:proceedingId/warnings` — action, transaction script, repository (two queries: `Contact`→`Firm` via `account_id`; `Proceeding`→`Job`→`Case` via `job_id`/`case_id`), and the mapper that normalises empty-or-whitespace and `null` to `null`.
- **New Atlas panel** `RbWarningsPanel` + `useAccessManagerWarnings`, inside the existing `AccessManagerOverlay`, reached by **two** entry points (contact search; Client Access list row).
- **Tables read:** `contacts.warning`, `firms.warning`, `cases.warning`, `cases.remarks_html`. All replication-owned — no test writes them through the app.
- **Explicitly also under test:** that the overlay's existing left column and its `<Overlay :loading>` behaviour do **not** change.

## Happy path

- [ ] **HP-1** — Seed firm with `warning` set; contact with `warning` set and `account_id` → that firm; proceeding whose job has `case_id` → a case with `warning` and `remarks_html` set. Call the endpoint → 200 with the nested shape `{ case: { warning }, contact: { warning }, firm: { warning }, caseRemarks: { html } }`, all four populated. — *Story 01: "all four are readable while access is being set up".*
- [ ] **HP-2** — Open the Access Manager via **entry point 1** (contact search) → four sections render in order Case → Contact → Firm → Case Remarks. — *Story 01: "the four come in a fixed order".*
- [ ] **HP-3** — Open via **entry point 2** (Client Access list row, which fabricates its contact object) → same four sections, same values as HP-2 for the same contact. — *Story 01: entity pairing; also the surface that would expose concern C1.*
- [ ] **HP-4** — Each value belongs to the right entity: the case caution is the case behind the proceeding being viewed, the contact caution is the contact being granted, the firm caution is that contact's firm. — *Story 01: "the case caution belongs to the case behind the proceeding being viewed…".*
- [ ] **HP-5** — Change `contacts.warning` in the database, close the overlay, reopen the **same** contact → the new value appears with no page reload. — *Story 01: "what RB holds as of the moment they open the access work".*
- [ ] **HP-6** — Remarks containing colour, bold and font-size render with that emphasis visible. — *Story 03: "the emphasis … is still there".*
- [ ] **HP-7** — The panel offers no way to edit or persist any of the four. — *Story 01: "read-only … no way to change any of them from Atlas".* Note this is structurally guaranteed (replication-owned tables, no write path), so this asserts the UI does not imply otherwise.

## Negative paths

- [ ] **NP-1** — `contacts.warning = ''` and `firms.warning = ''` → both normalise to `null`; the panel renders the empty state, **not** blank space. — *Story 02: "told there is no warning information rather than left looking at nothing".*
- [ ] **NP-2** — `cases.warning IS NULL` and `cases.remarks_html IS NULL` → empty state using the **remarks-specific** wording, textually different from the caution wording. — *Story 02: "the wording for empty case remarks differs from the wording for an empty caution".*
- [ ] **NP-3 (load-bearing)** — Endpoint returns 500, and separately times out → the panel renders `warningsLoadError` and **never** an empty state. — *Story 02: "a failure to retrieve them is never presented as an empty record".* **This is the red→green anchor for the whole ticket:** it must fail if a failure is presented as emptiness.
- [ ] **NP-4** — On that failure the message stands **in place of** the four sections, not beside them. — *Story 02: "the failure message stands in place of the four, not alongside them".*
- [ ] **NP-5** — Unknown contact id → the documented status code, no stack trace, no internal detail in the body. **Blocked on decision D2** (400 vs 404 — the request asks for 404 but prescribes a validator that throws 400). Scenario is written; the expected code is a blank to fill at Phase 3.
- [ ] **NP-6** — Inactive contact (`is_active = false`) → same as NP-5. The validator's `findActiveById` treats inactive as missing.
- [ ] **NP-7** — Remarks containing `<script>`, an `onclick` handler, an `<iframe>`, an `<object>` and an `<embed>` → every one stripped; nothing executes; no console error. **Must be verified by hand in a real browser.** DOMPurify does not sanitize correctly under the test environment — probed directly, `<p>Safe</p><script>x=1</script>` returns `Safe<script>x=1</script>`, stripping the safe tag and keeping the script. The component spec therefore asserts only that RB html is always routed through the sanitizer and never bound raw; the stripping itself is unproven by any automated test in this repo. — *Story 03: "anything … that would act on its own … is gone before the Ops user sees any of it".*
- [ ] **NP-8** — Bad params (non-numeric `contactId`, non-numeric `proceedingId`) → 400 from the pipe. `[NO-CRITERION]` — framework-level input validation, no story criterion behind it; included because the sibling action's spec asserts it and parity is cheap.
- [ ] **NP-9** — A slow warnings fetch must **not** delay the overlay appearing or block the access work: assert `<Overlay>`'s `loading` prop is not fed by the warnings query. `[NO-CRITERION]` **pending decision D4** — becomes a Story 02 criterion if D4 lands on "non-blocking". Protect-the-neighbours check regardless.

## Edge cases

- [ ] **EC-1** — Contact whose `account_id` dangles (no matching firm row) → firm section shows its empty state; no error, no crash. *There is no FK on `account_id`; the existing integration spec models "no firm" exactly this way.* — *Story 02 empty-state criteria.*
- [ ] **EC-2** — Proceeding whose job has `case_id = NULL` → both case sections empty; contact and firm still populate. — *Story 02 empty-state criteria; exercises the LEFT JOIN.*
- [ ] **EC-3** — Whitespace-only warning (`'   '`) → normalises to `null`, same as empty. Covers the **F5** asymmetry: `contacts`/`firms` are NOT NULL varchar and may be `''`, while the `cases` columns are nullable, so one mapper absorbs both contracts.
- [ ] **EC-4** — Remarks with no formatting at all → still readable as ordinary text. — *Story 03: "remarks that arrive with no formatting at all still read as ordinary text".*
- [ ] **EC-5** — Remarks ~50× the panel height → the panel scrolls internally and the access work stays reachable. **Fix is in:** `RbWarningsPanel` now owns a scrolling body element, because the parent `.rightColumn` is `overflow: hidden` and clips. — *Story 03: "however wide or long the remarks are, they do not push the rest of the access work out of place"; Story 01's long-note criterion.*
- [ ] **EC-6** — Remarks carrying a very wide unbroken string or a wide table → contained; does not widen the overlay or disturb the left column. — *Story 03: "formatting carried by the remarks changes only the remarks".*
- [ ] **EC-7** — Rapid close-then-reopen, faster than the overlay's transition → no stale contact's warnings shown, no request for a null `contactId`. Exercises the async `after-leave` reset against the `enabled` guard (see the sequence diagram). `[NO-CRITERION]` — a race the criteria do not name; surfaced by the Phase 1 lifecycle trace.
- [ ] **EC-8** — Switch contact **while the overlay is open** (if reachable) → the query key changes and the previous contact's warnings never display. Guards the same failure as `gcTime: 0`. — *Story 01 freshness criterion.*
- [ ] **EC-9** — Neighbour regression: existing `useAccessManager.spec.ts` and `AccessManagerOverlay.spec.ts` stay green, the latter with **one named, deliberate** update where it asserts the retired `warningsPlaceholder` key at L186. `[NO-CRITERION]` — protect-the-neighbours; no story criterion, but omitting it is how the placeholder retirement breaks a test silently.

## Manual verification (required whenever a human runs a step)

> **Read this first.** Manual verification is **currently blocked** — see concern **C4** and decision **D7**. `IS_GRANTING_CLIENT_ACCESS_ENABLED` must be on the Cognito user, there is no env override (`IsFeatureAllowedTS` is Cognito-claims-only by explicit JSDoc), and a prior ticket's attempt to set it did not survive re-login. **Do not mark any manual step passed until the flag is genuinely on.** If the ticket ships without these steps, say so plainly in the PR rather than leaving it implied.

**Before / after**

| | Before | After |
| --- | --- | --- |
| Access Manager right-hand panel | A single line of grey text: "Warnings and notes will appear here in a future release." | Four titled sections — Case Warning, Contact Warning, Firm Warning, Case Remarks — each with a value or an italic grey empty-state line |
| Panel heading and close button | "Warnings and notes" heading with an X button | **Identical.** They live in the overlay's own header, outside the replaced content |
| Left column (tracks and deliverable types) | Track list with its own loading and error states | **Identical.** No change intended; a slow or failed warnings fetch must not affect it |
| Case warnings and Case remarks content | n/a | **Empty by default** until the replication mapping ships, because nothing populates those columns yet. **Inject values by hand to verify the feature** — see manual step 8. What these two should say while unpopulated is still an open decision |

**Preconditions**

1. Callisto running locally with a database that has the `origin/main` migrations applied (including `1786036989067`).
2. Atlas running locally, logged in as a user whose Cognito `custom:feature-flags` includes `IS_GRANTING_CLIENT_ACCESS_ENABLED`. **This is the blocked step (C4).**
3. Seed data per HP-1: a firm with a warning, a contact with a warning whose `account_id` points at it, and a proceeding whose job has a `case_id`.
4. **Baseline reading before acting:** open the Access Manager on that proceeding and confirm the placeholder text is present — that is the "before" evidence.

**Steps**

1. Navigate to the proceeding detail page → Client Access tab.
2. Open the Access Manager via the **contact search** panel for the seeded contact (entry point 1).
3. Read the right-hand panel; capture it with all four section titles in frame.
4. Close the overlay. Open it again from the **Client Access list row** for the same contact (entry point 2). Confirm identical content.
5. With the overlay closed, update the contact's warning in the database, then reopen for that same contact and confirm the new text appears.
6. Repeat step 2 for a contact with an empty warning and a dangling `account_id`, and confirm both empty states.
7. Stop Callisto, then open the Access Manager, and confirm the failure message appears **instead of** the four sections.
8. **Inject case values by hand**, since the replication mapping has not shipped and nothing populates them. Run the insert below, reopen the Access Manager, and confirm Case warnings and Case remarks now show those values rather than "None" and "No remarks info".
9. **With the injected remarks still in place, verify sanitisation in the browser** — replace the remarks value with markup that tries to act (a `<script>`, an `onclick`, an `<iframe>`) and confirm nothing executes and the tags do not reach the page. This step cannot be delegated to the test suite, per NP-7.
10. Replace the injected remarks with a very long value and confirm the panel scrolls internally while the Save and Cancel buttons stay reachable.

**Evidence**

```sql
-- confirm the seeded state before step 2
SELECT c.id, c.full_name, c.warning AS contact_warning, c.account_id,
       f.name AS firm_name, f.warning AS firm_warning,
       cs.warning AS case_warning, cs.remarks_html
FROM callisto.contacts c
LEFT JOIN callisto.firms f ON f.id = c.account_id
LEFT JOIN callisto.proceedings p ON p.id = :proceedingId
LEFT JOIN callisto.jobs j ON j.id = p.job_id
LEFT JOIN callisto.cases cs ON cs.id = j.case_id
WHERE c.id = :contactId;
```

```sql
-- step 8: inject case warning and remarks, which replication does not yet supply.
-- Find the case behind the proceeding first, then set both columns.
UPDATE callisto.cases
SET warning = 'Protective order in place - do not release to opposing counsel',
    remarks_html = '<p style="color:red"><strong>Rush</strong> delivery agreed with counsel.</p>'
WHERE id = (
  SELECT j.case_id FROM callisto.proceedings p
  JOIN callisto.jobs j ON j.id = p.job_id
  WHERE p.id = :proceedingId
);
```

```bash
# the endpoint on its own, independent of the UI
curl -s -H "Authorization: Bearer $TOKEN" \
  "$CALLISTO/granting-client-access/contacts/contactId/$CONTACT_ID/proceedingId/$PROCEEDING_ID/warnings" | jq
```

**Pass / fail**

| Step | Passes | Fails |
| --- | --- | --- |
| M-1 (steps 2-3) | Four sections, in order Case → Contact → Firm → Case Remarks, values matching the SQL | Wrong order, a missing section, or a value that does not match the SQL — meaning the join or the section mapping is wrong |
| M-2 (step 4) | Entry point 2 shows identical content to entry point 1 | Different firm name or warning between entry points — **this is concern C1 landing**, and it means a warning is mislabelled |
| M-3 (step 5) | The updated warning appears on reopen | Stale text — freshness is broken and the user may act on an outdated caution |
| M-4 (step 6) | Empty states render with distinct caution/remarks wording; no crash on the dangling firm | Blank space instead of an empty state — the user reads "no warning" from an absence that was never stated |
| M-5 (step 7) — **load-bearing** | `warningsLoadError` replaces the four sections | An **empty** panel on a failed fetch. This is the defect the whole story exists to prevent: the user concludes there are no warnings when the truth is that nothing loaded |

| M-6 (step 8) | Injected case warning and remarks both display | Still showing the empty wording — the query or the mapping is wrong, not the pipeline |
| M-7 (step 9) | Nothing executes; the script, handler and iframe are absent from the page | Anything runs, or the markup reaches the DOM. **This is the only proof of sanitisation that exists** |
| M-8 (step 10) | Panel scrolls; Save and Cancel stay reachable | Content clips with no scrollbar, or the buttons are pushed out of reach |

**M-5 is the load-bearing step.** Its failure means absence and failure are indistinguishable to the user — the exact false negative job story 02 was written for.

## Test map

| Repo | Suite | Asserts |
| --- | --- | --- |
| callisto-back-end | `contacts/infrastructure/repositories/__specs__/access-manager-warnings.repository.integration.spec.ts` (new) | HP-1, NP-1, EC-1, EC-2, EC-3 — real Postgres; **requires new seeder overrides** (`warning` on contact and firm, `caseId` on proceeding) and a new `case.test-seeder.ts`, none of which exist today |
| callisto-back-end | `.../access-manager-warnings-action/__specs__/access-manager-warnings.mapper.spec.ts` (new) | NP-1, EC-3 — empty, whitespace and `null` all collapse to `null` across both column contracts |
| callisto-back-end | `.../fetch-access-manager-warnings-ts/__specs__/…spec.ts` (new) | HP-1 happy path; NP-5, NP-6 missing/inactive contact |
| callisto-back-end | `.../access-manager-warnings-action/__specs__/fetch-access-manager-warnings.action.spec.ts` (new) | DTO shape; NP-8 bad params; guard presence if D3 lands on yes |
| atlas-front-end | `AccessManagerOverlay/composables/__specs__/useAccessManagerWarnings.spec.ts` (new) | HP-5, EC-8, EC-7 — capture the `useQuery` config and assert `queryKey`, `enabled`, and `gcTime: 0`, per the `useDeliverableTypesByContext.spec.ts` pattern rather than the AccessManager ones (which do not assert refetch) |
| atlas-front-end | `AccessManagerOverlay/components/__specs__/RbWarningsPanel.spec.ts` (new) | HP-2, HP-4, HP-6, HP-7, NP-1, NP-2, NP-3, NP-4, NP-7, EC-4, EC-5, EC-6 |
| atlas-front-end | `AccessManagerOverlay/__specs__/AccessManagerOverlay.spec.ts` (**existing — one deliberate update**) | EC-9, NP-9 — panel is wired in, `Overlay`'s `loading` prop unchanged, and the retired `warningsPlaceholder` assertion at L186 replaced |
| atlas-front-end | `composables/__specs__/useAccessManager.spec.ts` (**existing — must stay green unchanged**) | EC-9 neighbour proof |

## Gates

| Gate | Command |
| --- | --- |
| audit (callisto) | `npm audit --audit-level=high` |
| lint (callisto) | `npm run lint` |
| architecture (callisto) | `npm run test:architecture` — **`severity: error` rules bind this design**; a missing registry entry fails `no-orphans` |
| tests (callisto, unit) | `npm test -- --runInBand src/granting-client-access` — baseline to beat: **75 suites, 361 tests** passing |
| tests (callisto, integration) | `npm run test:integration` — **required for the new repository spec; excluded from `npm test`** |
| audit (atlas) | `npm audit --audit-level=high` |
| lint (atlas) | `npm run lint` |
| tests (atlas) | `npx vitest run --maxWorkers 1 src/callisto` |

## Results log (filled at execution)

_Not executed. Status is `seeded`; nothing has been run and no gate result is claimed._
