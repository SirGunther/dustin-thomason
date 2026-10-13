# INT-142 spec: response to review (2026-10-12)

**Spec:** [INT-142-spec.md](INT-142-spec.md) · **Ledger:** [INT-142-locked-decisions.md](INT-142-locked-decisions.md), section "Spec review, 2026-10-12" · **Evidence IDs** (E-xx) refer to the ledger's Evidence table.

> **Outcome (2026-10-12):** you chose option A for both questions and accepted R-2. Both decisions are locked: Q-01 → LD-018 (conditional double-quoting; any name containing `,`, `›` or `"` is quoted and embedded quotes are doubled) and Q-02 → LD-019 (accepted, documented limitation). The spec is updated to match: B.2 `toQuotedName`, quoting cases in B.3, the quoted example, and manual step 8. The provisional markers are removed and the header reads "Implementation readiness: ready". The ledger's "Spec review, 2026-10-12" section records the evidence (D-1 to D-4). The text below is the request as sent.

Thank you for the review. One finding is resolved. The other two need a product decision, and we would like your view on the best practice before we lock them.

| Finding | Status |
| --- | --- |
| R-1 (Blocker): Q-01 open while the spec hard-codes a format; ambiguous for collection names containing `,` or `›` | **Open.** The spec now marks the format as provisional everywhere and lists what it blocks. Question 1 below |
| R-2 (Medium): `N/A` for an empty list needs product confirmation | **Resolved.** See [R-2](#r-2-resolved) |
| R-3 (Low): a `\|` inside a case or proceeding name breaks the five-part display | **Open.** Recorded as Q-02. Question 2 below |

---

## Question 1 (R-1, Q-01): how should a list of names be written in one display segment?

**What can appear in a name (E-20):**

- **Deliverable type names** are seed-only. Callisto has no code that writes them, and no seeded name contains `,`, `›`, `|`, `:` or `"`.
- **Static collection names** are seeded and contain none of those characters either.
- **Dynamic collection names** are entered by users. They reject `\ / : * ? " < > | %`, so they **can** contain `,` and `›` but **never** `"`.

**How Atlas shows it:** the path is split on `' | '`. Each segment is shown as a bold label, then the text after the segment's first `': '`, as plain text on its own line.

**The options:**

- **A. Quote only when needed (our current recommendation).** Write each item as `Collection › Type`, or just the type when the grant has no collection, and join items with `, `. A name that contains `,` or `›` is wrapped in double quotes. Because no name can contain `"`, a quoted name can't be misread, and no seeded name ever shows quotes.
  ```
  Access granted: MP4 Video › DepoView, Planet Draft
  Access revoked: "Smith, Day 1" › Rough Draft
  ```
- **B. No escaping.** Same format with no quoting. A custom collection with a comma or `›` in its name reads ambiguously:
  ```
  Access revoked: Smith, Day 1 › Rough Draft
  ```
  This could be read as two items: `Smith` and `Day 1 › Rough Draft`.
- **C. A structural alternative**, for example one segment per item (`Access granted: …` repeated). That changes the ticket's five-part path, so we haven't proposed it.

**Our question:** for display text that joins user-entered names, is conditional double-quoting (CSV style, option A) the practice you'd recommend? Or would you prefer always quoting, backslash escaping, or a structural change?

**Effect of the answer:** only europa-back-end's list formatter (spec B.2) changes, plus its expectations in B.3, the displayed example and manual steps 2, 3 and 5. Everything else in the spec can be built now. The text is built when a record is read, so the format can change later without touching stored records.

---

## Question 2 (R-3, Q-02): accept a `|` in a name as a display limitation, or neutralise it?

**How a `|` can get into a name (E-21):**

- **Proceeding names:** File Navigator create and rename reject `|` on the server (`@NoSpecialChars()`), and both Atlas proceeding forms reject it too. The AJSF create API checks only that each value is a string, so a direct API call is the only way.
- **Case short names:** these are written outside Callisto, which has no create or update path for them. Nothing checks them.
- **Existing behaviour:** Atlas splits every multi-part path (`PERMISSIONS_UPDATED`, `CATEGORIZE`, `RECATEGORIZE`, `CREATED` + `PROCEEDING`) the same way, so they all share this limitation today.

**The options:**

- **A. Accept and record it (our recommendation).** No code change. The spec's Known limitations section records it with the evidence above.
- **B. Neutralise it in europa-back-end.** Replace `|` with `¦` in the case, proceeding and list values before building the path, so the display is always five parts. The text shown then differs slightly from the stored name.
- **C. Split by label in Atlas** for this event type, using the five fixed labels. This guarantees the layout without changing what is shown, but adds parsing logic that no other event type has.

**Our question:** is a display limitation that every multi-part event type already shares acceptable here, or do you consider sanitising at render time (B) or label-aware parsing (C) the better practice?

---

## R-2 (resolved)

- **Precedent (E-22):** europa-back-end's `toDisplayValue` already shows `N/A` for any null, empty or whitespace-only value, because Atlas would otherwise show a bold label with nothing after it. INT-138 LD-013 and INT-139 LD-008 lock the same behaviour for an action that changes nothing.
- **Product owner:** the user ruled the pending PO clarification not relevant (2026-10-12).
- **In the spec:** new decision S-09 names this precedent as the accepted resolution. A list that is empty after a save, for example `Access revoked` on a save that only grants, reads `N/A`.
- **Several contacts in one save:** this can't happen. The save request carries exactly one `contactId` and one `proceedingId`, so the QA comment's second question has no case to cover.

---

## Other updates since your review

**Spec ([INT-142-spec.md](INT-142-spec.md)):**

- **New "Implementation readiness" note** in the header: everything except the list formatter and the list text can be built now.
- **Format marked provisional** in the displayed example, B.2, B.3 and the manual end-to-end steps.
- **New decision S-09:** `N/A` for an empty list (R-2).
- **"Open questions (with the reviewer)"** now lists Q-01 and Q-02, with a column showing what each one blocks.
- **Q-01's recommendation** now quotes any name containing `,` or `›`. It was previously unquoted.
- **Known limitations** now gives the specific ways a `|` can get into a name, and the quoting caveat.
- **Complexity flags** updated for Q-01 and Q-02.

**Ledger ([INT-142-locked-decisions.md](INT-142-locked-decisions.md)):**

- New Q-02 gate.
- An update note on Q-01.
- Evidence E-20 to E-22.
- User directions for 2026-10-12.
- A "Spec review, 2026-10-12" section: each finding with its context, evidence and status, plus your assessment.
- Open items updated.

**Unchanged:** the architecture you approved, which is structured state from Callisto, text built in europa-back-end when a record is read, and constants-only changes in Atlas. The scope is unchanged too.
