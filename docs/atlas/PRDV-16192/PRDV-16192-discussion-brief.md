# PRDV-16192 — What we found, and what the room needs to decide

> **Audience:** QA, product, and engineering. This is the shareable source of truth coming out of the investigation.
> **Status:** investigation complete. **Nothing has been built.** No branch, no code, no spec.
> **Purpose:** establish what the problem actually is so we can agree on scope. Six decisions at the bottom need the group.
> **Backing detail:** [full investigation report](./investigations/PRDV-16192-investigation.md) · [what we looked at and ruled out](./investigations/PRDV-16192-coverage-ledger.md) · [diagrams](./investigations/PRDV-16192-diagrams.md) · [risks we're consciously leaving](./PRDV-16192-future-development-concerns.md)

---

## The short version

The ticket reports three problems with permission-change audit entries. **All three are the same problem**, and it is not where the ticket says it is.

The ticket points at Callisto, the service that *writes* the audit event. Callisto is doing very nearly the right thing. The information is being **thrown away later**, when Europa reads the event back out for the audit grid.

That distinction is the whole finding, and it changes the answer in one very useful way:

> **The data we're missing is already in the database.** Every permission-change event ever recorded already contains the resource key that the grid isn't showing. Nothing was lost when it was written — it's lost when it's read. So fixing the read side **repairs every historical audit entry**, going back to when the feature shipped. No data migration, no backfill, nothing to re-run.

An emit-side fix — the one the ticket implies — cannot do that. It would only improve entries created after it ships, and it still could not solve the biggest problem (below).

---

## What the ticket reported, and what's actually true

| # | Reported | What we found |
| --- | --- | --- |
| 1 | The Path column doesn't clearly show old/new permission state per resource key. | **Confirmed, and structural.** There is one column and the read picks exactly one value — either the new state or the old, never both. There is nowhere for "before → after" to go. Separately, that column is labeled "Path" but for permission events it contains a list of actions like `read, update`, because the permissions feature reused a field built for file paths. |
| 2 | No resource key indicator — the audit entry doesn't tell you which key changed; `resourceName` is the role name. | **Confirmed, and worse than reported.** Two separate causes. The one the ticket names is real: the Resource column shows the role name. The one it doesn't name is bigger — **when you change several resource keys in one save, only the first one appears at all.** The others aren't unlabeled; they're gone. If you change transcript track and video track together, the audit log shows one of them and gives no sign the other was touched. |
| 3 | Removing all CRUD renders blank in Europa; it should say something meaningful. | **Confirmed, plus a side effect.** The blank isn't only ugly. Because of how the fallback logic is written, an empty value doesn't fall through to the next-best value — it wins. So a fully-cleared permission set costs you the resource key too, which would otherwise still have been recoverable. |

### One correction worth surfacing at the meeting

The ticket proposes, for item 2: *"Changing multiple resource keys in one save produces one PERMISSIONS_UPDATED event with one entry per changed resource key."*

**That is already exactly what happens.** Callisto emits one event containing one entry per changed key, today. The reason you can't see them is that the read discards everything after the first entry. Nobody was wrong to propose it — the behavior just wasn't visible from where the ticket was written.

---

## Why it happened

The permissions audit was built by **reusing the audit event shape that already existed for files**. A file event has one resource, and describes it with a path and a bucket. A permission change has *many* resources — one per key you touched — and each has a before-and-after set of actions, which isn't a path at all.

The mapping was made by analogy: the role went into the "resource name" field, the resource key went into the "path" field, and the action lists went into the before/after state. That is coherent from the writing end, and it matches what the dev notes described.

What nobody checked was whether the **reading** end could express it. It can't — it was written when every event had exactly one resource, and it still assumes that.

### This isn't only a permissions problem

Case merges also produce one event with many resources — one per merged file. **The same line of code is already truncating those in production today**: merge ten files, see one. That's unrelated to permissions and predates this ticket. It's the clearest evidence that what we're looking at is a general weakness in the audit read path, not a permissions display bug.

---

## What we recommend

**Fix the read side** — Europa's projection and the Atlas audit grid — rather than changing what Callisto writes.

Reasoning, in order of weight:

1. **It's retroactive.** Every existing audit entry becomes readable. The emit-side fix leaves history broken permanently.
2. **It's the only option that solves problem 2.** No change to what Callisto writes can help, because the extra entries are discarded after they arrive.
3. **It fixes the case-merge truncation for free**, since it's the same code.
4. **It doesn't make the underlying mismatch worse.** The emit-side fix works by packing more meaning into fields that already mean the wrong thing.

The emit-side option is genuinely cheaper — one repo, no Europa or Atlas deploy — and if the group decides this is worth only that much effort for a Low-priority 5-pointer, that's a legitimate call. It just needs to be made knowingly: it would close item 3 and half of item 2, and would not close item 1 or the multi-key data loss.

**This recommendation is the investigation's, not a locked decision.** It's on the table for tomorrow, not settled.

---

## Decisions the group needs to make

| # | Decision | What hangs on it | Who |
| --- | --- | --- | --- |
| **D1** | **Fix the read side, the emit side, or both?** | Everything below. Recommendation above; the trade is retroactive-and-complete vs cheap-and-partial. | Product + eng |
| **D2** | **One grid row per audit event, or one per changed key?** | If one row per key: pagination counts currently describe *events*, so they'd have to change, and the grid's row identity would need rework. If one row per event: the per-key detail has to live inside the row — we already do expandable rows elsewhere in Atlas, so that's a known pattern. Note a case merge can contain a very large number of files, which argues against one row per resource. | Product + UX |
| **D3** | **Show the raw key (`SUBMISSION_PROCEEDING_FILES_TRANSCRIPT`) or a friendly label ("Transcript Track")?** | Friendly labels are **not currently possible without work**: the only label map we have gives the same label to two different keys — submission and client-deliverable transcript tracks are both "Transcript Track" — and it lives in a Callisto endpoint the audit page doesn't call. Raw keys are unambiguous and free; labels need the collision solved first. | Product |
| **D4** | **What should a fully-removed permission set actually say?** | The ticket suggests something like "removed create-read". Also worth settling whether this is wording the UI applies (works retroactively) or a value we store in the event (doesn't). | Product + QA |
| **D5** | **Do we fix the case-merge truncation in this ticket, or raise it separately?** | Same line of code, so folding it in is nearly free — but it widens testing and blast radius. Leaving it means knowingly shipping past a live prod defect in code we're editing. | Eng + product |
| **D6** | **Does "the solution may need to be discussed with IT" (Kat, Jul 16) gate this work?** | If yes, what does IT need to weigh in on — how the audit reads, or the permission model underneath it? | Kat / Larry / IT |

---

## Two things we found that are outside this ticket

Both are pre-existing, neither is caused by this ticket, and both concern the audit log being **wrong or missing without anyone noticing** — which matters more than usual for an audit log. Full write-ups with evidence and diagrams are in [future-development concerns](./PRDV-16192-future-development-concerns.md).

- **An audit record can be silently lost.** The permission change is saved first, then the audit event is sent to the queue without waiting for it, and a failure is written to the server console and otherwise ignored. If the queue is down, the permission change succeeds and no audit record is ever created. Nothing retries and nothing alerts.
- **Two people saving the same role at once produce a factually wrong trail.** The "before" state is read outside the transaction that writes the change. If two saves overlap, the second event reports a prior state that wasn't true when it ran. The permissions end up correct; the record of how they got there does not.

Our recommendation is to raise these as a companion ticket on audit reliability rather than absorb them here. Flagging them now so they're not discovered during a compliance review instead.

---

## What we have not proven

Worth stating plainly so nobody over-reads the confidence:

- **The retroactivity claim is verified in code, not against live data.** We can see that the resource key is written on every event and that nothing strips it in transit or storage. We have **not** yet opened a real audit document in a live environment to confirm it's there. That's a five-minute check and it should happen before anyone commits to the read-side approach on the strength of retroactivity.
- **The case-merge truncation is proven in code, not observed.** We haven't watched a real merge event render short in the grid.
- **Whether the empty-value behavior was intentional.** The code comment reads like a fallback chain, which suggests the empty string winning is an accident — but the author isn't on record. Low stakes: both readings point at the same fix.

## What happens next

Nothing is built until D1 and D2 are settled. After the discussion, this goes to a spec, then an implementation plan, then code — with a regression test that reproduces the exact defect (a two-key event where the first key was cleared) so this can't quietly come back.
