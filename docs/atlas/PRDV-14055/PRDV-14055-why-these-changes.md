---

## title: "PRDV-14055 — Why these changes"

Atlas · Upload Manager  
`PRDV-14055`

# Why these changes were needed

The ticket asked for one thing — make the upload count go **up** instead of down. Implementing it surfaced that the work was actually a mix: **one requested behavior change, two pre-existing bugs it exposed, and one robustness gap** the offline requirement forced us to close.

- **1** requested change
- **2** bug fixes
- **1** capability gap

## Requested change

### The first number counts up, not down

**Before**

"Uploading N of M" showed N = files *remaining*, so it counted down as uploads finished.

**After**

N = completed + in-progress uploads, counting up to the total; failures stay counted so it never drops back.

**Why:** a decreasing number read to Ops as files being *removed from the queue or failing*, not completing. This is the behavior the ticket (and Product) asked for — a deliberate UX change, not a defect.

## Bug fix — pre-existing



### Failed uploads were invisible and could hang the manager

**Before**

A chunk, completion, 0-byte, or network failure was recorded only in local component state — never on the shared upload item. The count, progress bar, and "all complete" check couldn't see it, no toast fired, and the manager could sit on "Uploading N of M" indefinitely.

**After**

A failure is written to the upload item, shows the error row, fires one file-named toast, is counted, and lets the batch resolve.

**Why:** a genuine latent bug — failures were silent and could dead-end the batch. It didn't show under normal use, so it surfaced while wiring up the count change (a 0-byte file was the trigger the reviewer raised). Fixing it is what makes failures *known and testable*.

## Bug fix — pre-existing



### An all-failed batch never closed

**Before**

The auto-close only ran when the batch had at least one *successful* upload, so an all-failed batch showed "Closing in 5s" but stayed open forever.

**After**

Every terminal batch — success, mixed, or all-failed — runs the 5-second closeout.

**Why:** a dead-end state left by a success-only guard. Once failures became terminal (above), removing that guard was the natural fix.

## Capability gap



### A stalled or offline upload had no way to give up

**Before**

Nothing bounded an upload request. If the network dropped mid-batch, an in-flight request could never settle — holding one of the two upload slots and hanging the batch (it only unstuck when a debugger happened to attach).

**After**

A 10-second watchdog races each request against a deadline, aborts it on expiry, and marks the file terminal — so its slot frees and the batch resolves on its own.

**Why:** not a bug in existing code so much as a *missing capability* — the app had no timeout/deadline for a request that never resolves. The offline acceptance criterion required it. It fails gracefully (mark, count, toast, resolve); it deliberately does *not* add retry or resume.

## Why it shipped together

These weren't scope creep — they were the conditions for proving the count is correct. The acceptance criteria are defined partly in terms of terminal states: the number counts up *to the total*, ends *equal*, and *never drops back on failure*. None of that is observable if a failed or stalled upload leaves the batch hanging on "Uploading N of M" with no resolution. Making failures visible and letting the batch resolve is what let us verify the count end-to-end. Without them the implementation might have functioned — but we couldn't have shown it was complete or correct.

## Scope

Everything is confined to the Callisto Upload Manager — no API, backend, schema, or shared-config changes. The watchdog was first drafted touching the global API layer; we narrowed it back into the upload layer once we confirmed the abort-based deadline alone was sufficient. Triton has the same issues and is tracked as a separate follow-up.

---

Net: a small UX request became the occasion to fix two latent bugs and close a robustness gap — leaving upload progress honest and failures visible.

Verified: lint · type-check · unit suites green + manual runtime evidence · [atlas-front-end #548](https://github.com/planetdepos/atlas-front-end/pull/548)