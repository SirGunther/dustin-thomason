---
paths:
  - "docs/WorkLists/**/*"
  - "**/WorkLists/**/*"
---
<!-- generated from rules/worklists-card-sync.md by scripts/sync-rules.ps1; edit the source, not this file -->

# WorkLists card sync (dustin-thomason)

**How you get here.** The real trigger is being handed a WorkLists card id, or being asked to update a ticket's card, checklist or Current Step — none of which is a file path, so the globs above are only a backstop. The routing that actually matters is the `personal-methodology` intent table (always on) and the `orchestrate` skill's *Keeping the WorkLists card current* section.

**What a caller must give you:** the **card id**, and the **ticket id the card should carry** so the guard can verify you are on the right card. Nothing else — endpoints come from `GET http://localhost:3010/openapi.json`.

Read this when an agent is expected to keep a WorkLists ticket card current as it works — the card body's progress sections and the checklist rows in its note. Load it **before** the first write, not after.

Endpoints and payload shapes are **not** restated here; they drift. `GET http://localhost:3010/openapi.json` is the live contract. This rule owns the behavior: when to write, what may be written, and when to stop.

## The card id comes from one of exactly two places

| Path | Who supplies the id | When |
| --- | --- | --- |
| **A — the card exists** | The user does | They paste it at kickoff (the card menu has a **Copy Card ID** action). Record it in the ticket's ledger and never ask again |
| **B — no card yet** | **Nobody.** The agent creates the ticket from the designated card template and takes the new id out of the creation response | Recorded in the ledger exactly as a user-supplied id would be, and **reported back** |

**Never search for the card.** Not by ticket id, not by title, not by "the one that looks right." On one real card the title says `PRDV-16313` while its link says `PRDV-16312` — a text match there writes to the wrong ticket. Being told the id, or creating the card yourself, removes that failure entirely.

**Say which path you took.** On path B, name the id you created. Otherwise a card that appeared cannot be told apart from one that was already there.

## Marking rows is judgement, not lookup

Nothing ties a checklist row to a phase. The checklist's **format** is the contract — a heading with task rows under it — so what you get is the rows as currently written, and what you must do is reason about them.

For each row in the sections your phase covers:

| Question | Answer from |
| --- | --- |
| What does this row ask for? | The row's own text |
| Did this phase actually produce it? | The phase's real outputs — artifacts on disk, gate results, the ledger, the test plan's results log |
| Can I point at what satisfies it? | If not, **leave it unmarked** |

**Leaving a row unmarked is always safe. Marking one wrongly is not.** "This phase usually does that" is not evidence.

**Report every row you left unmarked.** A phase that marked nothing and a phase that wrote correctly look identical otherwise.

**A row you cannot interpret is not an error.** Skip it, note it, carry on with the rows you can substantiate. Only a note with no checklist structure at all stops the write.

**Any checklist shape works.** Reworded rows, reordered rows, hand-added rows, a shape you have never seen — all normal. Nothing is stored against a row, so nothing goes stale.

## Read and write in one exchange

Rows are addressed by **section name plus row label exactly as read**, together with the `lastModified` value read in the same exchange.

That is what makes matching on text safe here: if the note moved in between, the write is rejected before any matching happens. **Re-read before every write.** Labels remembered from an earlier phase, or from your own notes, break the guarantee.

**Batch by phase.** One request carrying every row the phase completed, not one request per row.

## What may be written

| Action | Permitted |
| --- | --- |
| Mark a row complete | Yes — with evidence |
| Leave a row unmarked | Yes, always safe. Report it |
| Un-mark a row | Yes, with a recorded reason. **Never** as a side effect of a re-run; a re-run over a completed phase is a no-op |
| Fill a detail line under a row | Yes, from a fact the phase recorded. **Never fabricated** — a made-up timestamp is worse than a blank one, because a blank is visibly incomplete |
| Set `currentStep` | Yes, at **phase start** |
| Set `nextUp`, `waitingOn` | Yes, at phase completion (`waitingOn` also when a phase begins blocked) |
| Set `workAhead` | **No.** The user's field |
| Set card status | Only the unambiguous transitions below |
| Add or remove a checklist row | **No.** The agent changes state, never structure |
| Move the card between columns | **No.** Columns are sprint-based, not phase-based; a phase transition implies nothing about which sprint a card belongs to |
| Create or delete a card or note | Only path B's ticket creation |

### `currentStep` is written at phase start

Not at completion. The field says what is happening **now**; writing it at completion means the card names the phase that just finished. Rows and `nextUp` still land at completion.

Plan-mode phases cannot write, so their phase-start value is deferred to the next working phase's first action — the same deferral already used for their ledger entries.

### Status transitions

Only where the mapping is unambiguous. Everything else encodes the user's judgement, not a phase fact.

| Phase | Sets status to |
| --- | --- |
| Report emitted | `In Progress`, and only if it is currently `Unrefined` or `Ready` |
| PR opened | `In Review` |
| Closeout | leave it alone |

**Never** set `Done`, `Blocked`, or `Icebox`.

## Guards — every one is a stop, and every stop notifies

| Guard | Trigger | Do |
| --- | --- | --- |
| Ticket-id mismatch | The card's title does not carry the expected ticket id | Stop. Report both values. Write nothing |
| Card not found | The id does not resolve | Stop. Report the id. Write nothing |
| No checklist structure | No note on the card has a heading with rows under it | Stop. Report. Write nothing |
| Row missing or ambiguous | A named row is not found, or a label appears twice in one section | Stop. Name the row. Your read and the stored note disagree — **re-read**, do not resend the same body |
| Conflict | The precondition rejected the write | Re-read once, retry once. On a second rejection **stop and report** |

**Retry once, then surface.** A loop that retries until it wins is indistinguishable from silently overwriting someone's edit.

**A stop notifies.** Run the `agent-completion-notification` script naming the phase and the guard, because an unattended run's stop otherwise lives only in a transcript nobody is reading — which is precisely when the work was delegated.

**A skip is not a stop.** If the WorkLists server is not running, record the skip in the ledger, do **not** notify, and let the phase complete. The board reflects the work; it does not gate it.

## Do not

- Do not search for the card.
- Do not mark a row you cannot point at evidence for.
- Do not fabricate a detail-line value.
- Do not reuse row labels read in an earlier exchange.
- Do not un-mark a row as a by-product of re-running a phase.
- Do not add, remove or reorder checklist rows.
- Do not move a card between columns.
- Do not retry a rejected write more than once.
- Do not let a board write failure block the ticket work.
