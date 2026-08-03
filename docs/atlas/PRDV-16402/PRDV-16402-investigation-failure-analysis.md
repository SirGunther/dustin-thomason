---
ticket: PRDV-16402
tags: [atlas, investigation, method-failure, rule-evidence]
author: Dustin Thomason
created: 2026-07-29
modified: 2026-07-29
---

# PRDV-16402 — Investigation failure analysis

> **Why this exists:** during this ticket the agent stated three things as fact that were not verified. Dustin's assessment: **third consecutive day** this class of failure has occurred, costing hours of review time and hundreds of dollars in conversation cost. This document is the **evidence** that the investigation instruction set needs to be more robust, and it names the specific rule changes that would have prevented each failure.
>
> **This is not an apology document.** It is a defect report against the method.

---

## The failures, in order

### Failure 1 — Invented a notification email and built a recommendation on it

**What was claimed.** That the completed-upload path "emails the team that a new file arrived," and therefore a late-failing outbox write would cause a duplicate email and a double conversion on user retry. This was presented as review finding **F1**, ranked "change before re-landing," and written into a ready-to-paste PR comment.

**What was actually verified.** That `ProceedingFileUploadDispatcher` publishes a message to an outbound SQS queue (`SQS_PROCEEDING_FILE_UPLOAD_URL_OUTBOUND`). **Nothing about an email.** The consumer of that queue lives outside `callisto-back-end` and was never opened.

**The inference chain that should have stopped.** "Dispatches a proceeding-file-upload event" → "notifies the team" → "sends an email" → "the user sees a failure and re-uploads" → "so they get two emails." Four inferential steps, zero of them evidenced, presented in the register of fact.

**What the correct approach was.** The claim "a notification is sent to the team" is a **workflow fact about a system outside the repo under investigation.** Per `source-truth`, that is a stop-and-ask, not an infer: *"the completed path publishes to an outbound SQS queue; I can't see what consumes it — does that notify anyone?"* Dustin would have answered in one line ("there are emails for submissions, I'm not sure about individual files"), and F1 would never have been written.

**Compounding error.** The recommendation also asserted user behaviour ("she uploads it again, because the app told her it failed"). Human-workflow behaviour is never inferable from code. It is always a question.

---

### Failure 2 — Called PRDV-16398 unshipped by trusting its ticket ledger instead of the source

**What was claimed.** That Nova ignores `videoTranscodeValue` and applies `template1` to everything, that PRDV-16398 was "unshipped — Phase 5 in-progress, uncommitted, blocked on the HandBrake Video Mix preset from ops," and therefore this ticket's acceptance criterion **could not be verified end to end**. This became review finding **F6** and was called "the one finding that survives" — the entire basis of a `proceed with conditions` disposition and a recommended AC split with Product.

**What was actually true.** PRDV-16398 **merged to Nova `main`** as commit `4128419` *"PRDV-16398: Apply selected video transcode preset (#15)."* Nova's `main` has `transcode-preset.registry.ts` with `resolveTranscodePreset(value)` keyed on the strings `'Standard'` and `'Video Mix'`, both `standard-depo.preset.ts` and `vid-mix.preset.ts`, `TranscodeStep.apply(input, output, transcodeValue)` taking the value, and the wiring `video-job.assembler.ts:66` → `video-conversion.service.ts:124`. The acceptance criterion is **fully verifiable**.

**Where the bad data came from.** `docs/nova/tickets/nova-applies-selected-transcode-preset/orchestration.md`, whose Phase 5 row still reads `in-progress` and *"Not committed — npm audit exits 1."* **The ledger was never updated after the work merged.** The agent read the ledger, treated it as current, and never opened Nova's source — despite the ledger's own Consulted section explicitly recording that Nova's behaviour was *"reused, not re-derived."* The staleness risk was written down and then ignored.

**What the correct approach was.** A changelog or ledger records **what was true when it was written**. For any claim that gates a decision — a disposition, an AC, a blocker — it is an *index to the evidence*, not the evidence. The correct move was one command: `git log origin/main -- <the file the ledger says is broken>`. That is seconds of work and would have flipped the verdict.

---

### Failure 3 — Buried the answer in 58KB of code-speak, which is what let 1 and 2 survive

**What happened.** Dustin's actual question was *"can we just do what Larry suggested?"* The answer needed was one sentence: **the conversion preset is chosen once on the job submission form, and this change reads it from there.** Instead the artifacts ran to ~180KB across nine files, and it took five rounds of pushback to extract that sentence — with Dustin explicitly saying the output was "completely indecipherable."

**Why this is a correctness failure and not a style one.** Code-speak *hid* Failures 1 and 2. "The completed path dispatches the legacy SQS proceeding-file-upload event, then writes the outbox row" is a sentence that can be written without noticing you don't know what the SQS consumer does. The plain-language version — "the team gets emailed" — cannot: written that way, the missing evidence is obvious on sight. **Plain language is a verification mechanism, not a presentation preference.** Technical register let an unverified claim pass as a verified one.

**Same mechanism on Failure 2.** "Nova's `TranscodeStep` hardcodes `template1`" reads as an established code fact. "Nobody can pick Video Mix — everything comes back Standard" invites the immediate response *are you sure, when did you last look?* — which was exactly the right question.

---

## Root cause common to all three

**The agent treated derived artifacts as primary sources.** A prior coverage ledger, a service name, and a dispatcher's method name were all read as evidence. None is. Every one of the three failures is the same move: *a plausible reading of a secondary artifact, promoted to fact, then built upon.*

Compounding it: the method has a **strong `source-truth` stop rule but no trigger that fires on this shape.** The existing rule is written for *missing* artifacts ("if the artifact is not in context, STOP"). All three failures had an artifact in context — it was just **stale, or about something adjacent, or not the thing the claim needed.** The rule as written does not catch that, which is why it did not fire three days running.

---

## Proposed rule changes (the point of this document)

Each maps to a failure above and would have prevented it.

### 1. `source-truth` — add a staleness trigger for derived artifacts

**Add:** a changelog, coverage ledger, orchestration ledger, or session log is an **index to evidence, not evidence.** Before any claim sourced from one becomes load-bearing for a disposition, blocker, acceptance criterion, or recommendation, **re-verify it against the primary source** — and say which you did.

> Good: "The 16398 ledger says Nova ignores the value; verified against `nova-back-end origin/main` — the registry exists, the ledger is stale."
> Bad: "Nova ignores the value (per the 16398 coverage ledger)."

Cheapest possible form: when a ledger claims code is broken or unshipped, run `git log origin/main -- <path>` before repeating it.

### 2. `investigation` — cross-repo and cross-system claims are stop-and-ask, never inferred

**Add:** any claim about behaviour **outside the repo under investigation** — what consumes a queue, what an email does, what a downstream service acts on — is a **fact-to-discover only if the source is reachable.** If it is not reachable, it is a **question for the user**, never an inference. Naming a dispatcher, queue, or event does not establish what it causes.

### 3. `investigation` — human-workflow behaviour is always a question

**Add:** what a user *does* in response to system behaviour (retries, re-uploads, monitors, ignores) is never derivable from code. Do not build a recommendation on assumed user behaviour. Ask, or drop the finding.

### 4. New standing rule — plain-language-first, as verification

**Add:** state every finding in **one or two plain sentences a non-engineer could confirm or deny, before** writing the technical version. If the plain sentence cannot be written without an unevidenced leap, **the finding is not ready** — that is the signal, not a formatting nit. Lead with the plain version; go to file-and-line only when asked why.

### 5. `investigation` — separate "is this a defect?" from "is this a risk I noticed?"

**Add:** every finding carries an explicit **"does the system work without this change? yes / no"**. Findings answering *yes* may not be ranked as required changes. This is the scope-creep guard: F1 (speculative), F2 (test-only, behaviour-neutral), F3–F5 (nits) were **all** presented alongside real findings under one "review findings" heading, which is how five optional items came to read as blockers.

### 6. `orchestrate` — closing a phase must update the ledgers it read

**Add:** when a ticket's work merges, its own orchestration ledger and changelog **must** be updated to say so. Failure 2 was directly caused by PRDV-16398's ledger still reading `in-progress` after merge. A stale ledger is not a neutral omission — it actively misleads the next ticket that consults it. **Action taken:** a correction note has been added to that ledger.

---

## Cost

Three days of the same failure class. On this ticket specifically: five rounds of pushback to reach a one-sentence answer; a `proceed with conditions` disposition and a recommended Product conversation, both of which were wrong; two fabricated or stale claims staged inside a ready-to-paste PR comment that would have gone out under Dustin's name; and ~180KB of artifacts to answer "can we ship Larry's branch?" — where the answer was **yes, as-is**.

## What the correct output would have looked like

> Larry already built this — branch `origin/PRDV-16402`, commit `d97b1c4e`. It merged and was reverted 7 minutes later because he merged before review by mistake, not for any technical reason; CI was clean and no one objected.
>
> The conversion preset is chosen once on the job submission form. His change reads it from there and sends it to Nova, which picks the matching preset. Nova's side shipped in PRDV-16398.
>
> I reviewed it and found nothing that has to change. Two optional nits if you want them. **Recommend re-landing as-is.**

Six sentences. Everything else this ticket produced was either supporting detail nobody asked for, or wrong.
