---
ticket: PRDV-16216
tags: [neptune, callisto, nova, media-duration, transcode, concerns]
author: Dustin Thomason
created: 2026-07-15
modified: 2026-07-15
---

# PRDV-16216 — Future-development concerns (write-time copy vs read-time lookup)

> **Context:** Larry's PR ([larry-adams#24](https://github.com/planetdepos/larry-adams/pull/24), branch `PRDV-16216-b`) rewrites the spec from a **read-time lookup** (display fallback, DB untouched) to a **write-time copy** (persist the source file's `length` into the derived file's row at transcode completion). These are my concerns with persisting a copied value, framed around where the system is headed — not just what ships in this story.
>
> **Purpose of this document:** a dated, code-verified record that this risk was identified and raised — for discussion with the team and, where needed, escalation up the chain. Code findings below were verified directly against `nova-back-end` and `callisto-back-end` on **2026-07-15**, with file/line references.

---

## Executive summary (for escalation)

**The vulnerability:** Nova, our transcode pipeline, cannot detect a partially-failed transcode. If someone puts in a file that has a problem — corrupt, truncated — FFmpeg's default behavior is to transcode what it can, log a warning, and exit successfully. Nothing bubbles up. No notification goes anywhere. Nova checks only the exit code and never measures the output file. So a transcoded deliverable that is shorter than its source — missing a segment — flows through to operations as a normal success.

**The proposed implementation makes it worse.** The current plan for PRDV-16216 copies the source file's duration onto the transcoded file's database row. So when a broken, shorter file comes through, the database **declares it full-length** — Atlas mirrors the original file's length onto the broken file. That defeats the one check a QA or operations person could otherwise use to catch it immediately at a glance: comparing the two lengths. And this approach is not new — it was **evaluated and rejected in the written investigation record** (my 2026-07-14 investigation — see Decision history), which also paired any display with a validation companion and explicit product acceptance of the interim risk; the current proposal reinstates that approach with those safeguards removed and without engaging the documented rejection reasons.

**Why it matters even if it's rare:** this is not a probability argument — it's a fallout argument. These are legal videography deliverables. Say a two-hour deposition video ships missing a minute of testimony, and that minute mattered. Here's how it plays out: the person on the video team says "the system reported the lengths were the same — it showed everything was there." They get reprimanded for relying on it instead of checking the file. **But that falls on us too** — we introduced a feature they asked for, and we knowingly put a number in front of them that looks like a measured fact and isn't. They believed they could rely on it because we displayed it. "The system reported the correct length" is not a defense we ever want to use — or want thrown back at us while a teammate goes under the bus for trusting our number.

**Why this is coming up now:** in the review meeting covering what Nova does and what would be visible in Atlas, Leah (video team manager) immediately requested a duration display in Atlas. Before that, durations were manually validated outside the platform — download the file, check it, every single time. There was no shortcut. Displaying the duration *replaces* that workflow with an at-a-glance check, which makes the Length column a de facto verification surface. So the question in front of us: if the number we put there is **copied, not measured** — is that something we're willing to stand behind? That's the trade-off. That's the risk.

**The fix is small and already half-built:** Nova **already runs ffprobe on every transcode today** and throws the result away (verified in code — see Decision history). The complete fix is Nova-local plus one contract field: probe the *output* after transcoding, compare it to the input, fail the job on mismatch, and carry the measured duration in the completed event. This was proposed early, with the data ready, and deferred ("we don't need it unless they ask for it").

**Decision being requested — from someone with the authority to own it,** not defaulted by a developer or a product manager. If we ship a copied number, the people relying on it need to be made 100% aware of what it is — because if this goes wrong badly enough, it's a permanent mark on somebody's record. The options:

- **(a) Don't ship the duration display for transcoded files yet** — "unavailable" forces the old download-and-check workflow and creates no false reliance — until validation exists;
- **(b) Prioritize the validation / measured-value work** (the deferred fast-follow) before or alongside PRDV-16216; or
- **(c) Accept the risk explicitly, on record**, with operations made fully aware the displayed number is copied, not measured.

In every case: do not persist unmeasured copied durations into `files.length` in the interim.

---

## Concern 1 — Future combined-media feature needs *measured* values, and Nova is where measurement happens

There is future work already requested and parked as fast-follow items — work that will eventually be addressed for how the system is supposed to function. One of those items specifically: **a feature where we take the values of individual files and combine them into one media output** — so there's a full-file value representing what the combined output ultimately equals.

For that to be accurate, we will eventually need to **probe the values directly from FFMPEG inside Nova and write those measured values to the database**. Nova is the system with its hands on the actual media; it's probing the file right there.

If the plan of record becomes "the duration lives in Callisto's `files.length`, populated by copying," then when Nova needs durations to assemble a combined output, there's no measured value at the source — Nova would have to **reach out of Nova into Callisto** to get information about files it is itself processing. Are we really saying we're going to read Callisto every single time we have files that need to be put together? That's using a disparate system to go back and forth for data we could measure in place. It makes no sense.

**Assumption to verify (I may be wrong):** that the combine feature is implemented Nova-side and needs durations at combine time. If it turns out Callisto orchestrates the combine, the architectural picture changes — but the measured-vs-copied problem below still stands either way.

**Why the write-time copy makes this worse:** once copied values are persisted into `files.length`, the column holds a **mix of measured values (browser-probed at upload) and assumed copies (transcode-time)** with no way to tell them apart. When real FFMPEG-measured values start landing in the same column, we inherit a reconciliation problem we created ourselves. The read-time approach leaves `null = never measured`, so measured values can land later with zero cleanup and the display fallback naturally retires.

### The failure scenario copied values create (undiagnosable bad segment)

Say the combine feature produces an output file from files **1, 2, and 3**, and one of those files isn't actually the right length because **there was a problem with its transcode**. The combined output's real duration comes out **shorter than it should be**. Now try to diagnose it:

- Do the math against the recorded lengths and the total doesn't add up — but **every segment's recorded `length` says it's correct**, because under Larry's solution those values were *copied from the sources*, not measured from the transcoded outputs.
- **You won't know which file is actually the problem.** It will appear as if all three files were correct when one of them wasn't — the database is asserting lengths for outputs it never measured.

So the copied values don't just fail to help diagnose the bad segment — they **actively conceal it**. With honest data (`null` until measured, or FFMPEG-measured per segment), the discrepancy is attributable: compare each segment's measured output length against its source and the bad transcode identifies itself. With copied data, the per-segment comparison is meaningless by construction — both sides of the comparison are the same number.

---

## Concern 2 — Writing an assumed value with no validation is fudging it

At some point we are going to need to **log the actual value of what was transcoded** so it can be compared on the operations side — ops looks at it and says "yes, I can see the transcoded file's length is exactly the same as the original file's length," and *then* they confirm.

The write-time copy does the opposite: it **puts a value into the database asserting the durations are the same when we don't know they're the same**. There is no validation check anywhere in that flow. That's not recording a fact — it's recording an assumption dressed up as a fact.

- Read-time lookup makes the same assumption, but as **reversible presentation logic** — the DB stays honest (`length` null = never measured).
- Write-time copy **bakes the assumption into data permanently**. If a transcode ever does alter runtime (codec edge case, truncated output, Nova bug), the DB confidently reports a wrong duration and nothing can flag it, because the copied value is indistinguishable from a measured one.

Note: my original spec paired the display fallback with a **companion Nova duration-validation ticket** (fail any transcode whose output duration doesn't match its input). Larry's revision **removed the companion reference** while simultaneously making the assumption permanent — the guardrail got dropped at exactly the moment it became more necessary, not less.

---

## Concern 3 — No failure mechanism: a bad transcode ships silently, and the copied value certifies it (VERIFIED in code)

I asked whether this could actually happen — whether FFmpeg could output a shorter file because it had a problem mid-transcode, and whether our current system would flag it. **Checked against the Nova code on 2026-07-15: yes it can, and no we wouldn't.**

**Can FFmpeg produce a shorter output and still "succeed"?** Yes — this is standard FFmpeg behavior, not an edge case:

- A **truncated or partially corrupt input** (interrupted upload, damaged container index) is treated by the demuxer as early end-of-file. FFmpeg transcodes everything it could decode, writes a valid-but-shorter output, and **exits 0**.
- **Corrupt packets mid-file**: FFmpeg's default error detection is lenient — the decoder logs "corrupt frame" warnings to stderr, conceals or skips the damage, and keeps going. Exit code stays 0.
- Making FFmpeg fail hard on these requires explicit flags (`-xerror`, `-err_detect explode`) — and Nova's args template (`ffmpeg.template.ts`) has **neither**.

**Would Nova catch it?** No — verified in `nova-back-end`:

- `FfmpegAdapter.transcode()` ([ffmpeg.adapter.ts:58-73]) checks the **exit code only**. Stderr is logged as warnings and never inspected.
- The pipeline (`video-conversion.service.ts`) validates and probes the **input**, transcodes, gets the output's **file size** (for logging), uploads, and emits the completed event. **The output file is never probed.** No duration comparison exists anywhere.
- So the failure path is fully silent: short output → exit 0 → uploaded to S3 → `video-transcode-completed` event → Callisto creates the derived file row → it lands in front of operations as a normal deliverable.

**How Larry's approach compounds it:** at the exact moment Callisto receives that silently-bad file, it would write the **source's full duration** onto the derived row — the database now actively certifies the broken file as correct. Anyone who checks the length column sees the "right" number.

**The stakes:** this is legal videography. If QA doesn't catch that a two-hour deliverable is missing a minute, and that segment contained important testimony, and it shipped — that comes back to bite us big time. "The system said the length matched" is exactly the wrong defense when the system was designed so the lengths match by construction.

---

## Decision history — the pass-through was proposed early and rejected (and the data exists today)

Early on, I said it would have been so much better to **add the duration to the Nova payload and the contract so it could be passed through**. I had the data ready — it was literally ready. The answer, from at least three people including a product manager, was "we don't need it unless they ask for it" / "it doesn't matter right now." I said it was going to have an impact. This ticket is that impact arriving.

### The documented chronology (all artifacts in this folder, dated)

This is not reconstructed from memory — every step below is a dated document:

1. **2026-07-13 — original investigation** ([PRDV-16216-transcoded-media-duration.md](PRDV-16216-transcoded-media-duration.md)): my proposed solution was the full fix — **add an optional `duration` field to the `orbital-docking-protocol` completed event, have Nova probe the *transcoded output* and emit it, have Callisto persist the measured value**. The report records the integrity requirement (§10, line 180): *"Independent measurement is a legal-deliverable-integrity non-negotiable: the deliverable length must be verifiable against the source, **never copied/assumed**."* **That ruling was mine** — I set it as a non-negotiable because that is how a business handling legal deliverables should run. It was never a non-negotiable in the principal dev's view. *(The report originally mislabeled it "(principal-dev ruling)"; corrected 2026-07-15. All investigations in this folder were done by me; the 07-14 direction below is my same-day record of a verbal conversation with the principal dev, not his own writing.)*
2. **2026-07-14 — principal-dev review changed the direction** ([PRDV-16216-lookup-display-investigation.md](PRDV-16216-lookup-display-investigation.md)): Larry's ruling — keep 16216 minimal, no protocol change; 16216 becomes the Callisto **read-time lookup**, and the integrity check moves to a **separate Nova validation companion ticket** (probe output, compare, fail the job through the existing failure pipeline). I re-ran the investigation, documented the pivot, and complied. That report **explicitly evaluates the persist-time copy and rejects it** (§6 Alternatives): *"Writes an assumed value into the DB indistinguishable from a measured one (provenance); needs a separate backfill for historical rows; rows persisted before the companion ships would carry permanently unvalidated copies."* It also records, honestly, that until the companion ships the displayed value is an assumption, and that **product should explicitly accept that interim window** (§0, §10).
3. **2026-07-14/15 — I wrote the read-time spec per that direction** — against my own original recommendation, because the principal dev set the direction and I followed it, with the companion ticket drafted alongside as the integrity half.
4. **Now — [larry-adams PR #24](https://github.com/planetdepos/larry-adams/pull/24)** rewrites the spec to the **persist-time copy**: the exact alternative my 2026-07-14 investigation evaluated and rejected on provenance grounds, contrary to the never-copied integrity requirement I set on 2026-07-13, and a departure from the minimal/read-time direction the principal dev himself set on 2026-07-14 — while also **removing the companion validation ticket reference** from the spec.

So the current proposal is not a new idea being weighed for the first time. It is an alternative that was evaluated and rejected in the written investigation record, reinstated without addressing the reasons it was rejected there, with the compensating control (the validation companion) deleted in the same edit. The rejection was my analysis, not a team decree — but it is the only written analysis of this approach that exists, and PR #24 engages with none of it.

**To be clear about my own position in this:** the read-time spec is not what I wanted either. My recommendation was, and remains, the measured-value path (2026-07-13 report). I have been developing the lookup approach because the principal dev directed it — the documented package was *lookup + validation companion + explicit product acceptance of the interim window*. What PR #24 leaves is the copy alone, with none of those three safeguards.

**Verified in code (2026-07-15):** Nova **already probes the duration with ffprobe on every transcode** — `ProbeDurationStep` in `video-conversion.service.ts` returns `videoDurationSeconds`… which is then written to a success log line and discarded. It is not in the completed-event payload (`NovaProceedingFileVideoTranscodeCompletedV1Data` carries IDs and paths only) and is never compared to anything. The measured value this whole debate needs is being computed and thrown away in production right now.

The gap between "what we have" and "what we need" is small and Nova-local: probe the **output** after `TranscodeStep` (one more ffprobe call against a step that already exists), compare input vs output duration, fail the job on mismatch, and put the measured output duration in the completed event. That is the companion validation ticket, and it is also the write-time solution done honestly — persist a **measured** value, not a copied one.

---

## Why wasn't this considered previously? — the display request changed the risk model

They're going to ask this, so here is where it got tricky, in order:

1. **I developed the engine for the actual probe, and it works great.** The duration-capture mechanism (browser probe at upload → `files.length`, PRDV-9756 / PRDV-15875) does exactly what it was built to do. Everything on that side is working wonderfully. None of this concern is about that engine.
2. **Then, in the review meeting covering what Nova does and what would be visible in Atlas, Leah (video team manager) immediately requested a new feature: seeing the actual duration of a file inside Atlas.** That request is what created the complexity — not the engine, and not the original scope.
3. **Before that request**, the operational workflow was: **download the file and check it, every single time** — durations were manually validated outside this platform. The platform displayed nothing, so nobody could lean on it.
4. **After that request**, the displayed number offers a shortcut. Someone doing the validation can glance at the column, say "looks like it's the same," and just as easily **dismiss that glance as their check**. By adding the display, we effectively hand them a way to be lazy. That is the risk imparted by the request itself.

**The implication:** the moment duration became visible in Atlas, the Length column stopped being decorative metadata and became a **de facto verification surface** — whether or not we ever intended it as one. People will substitute the at-a-glance number for the download-and-check they used to do; that's not a hypothetical about lazy individuals, it's the predictable effect of putting a plausible number where a manual check used to be. Which means the accuracy bar for that number went **up** at the moment the feature was requested:

- A **null** ("unavailable") is safe — it forces the old workflow. You can't glance at "unavailable" and skip your check.
- A **measured** value earns the reliance it will get.
- A **copied** value is the worst of the three: it invites the reliance and cannot support it. Under Larry's approach, the column shows a full-length duration for a transcoded file that was never measured — displayed in the exact spot where the manual validation habit is being replaced.

So the answer to "why wasn't this considered previously" is: **previously there was nothing to consider.** The risk was born when the display feature was requested, because the display is what converts a wrong-but-invisible database value into a skipped human check on a legal deliverable. This document is the follow-through on that changed risk model.

---

## The historical artifact — delay accrues exactly the backfill problem we'd be avoiding

This is where the history angle actually does come into play, just not the way it first looked. There's no *existing* backlog (see below) — but **the clock starts at deploy**. Every transcode processed between now and whenever measured values start flowing becomes a row whose duration is either null (read-time approach) or an unverified copy (Larry's approach). If we don't start capturing the real values now — and Nova is already computing them — we are manufacturing the future backfill problem one file at a time, and with the copy approach we're doing it with values that *look* populated and therefore will never get revisited.

---

## Clarification — historical data (in the display sense) is NOT one of my concerns

We have not deployed to the entire company yet, so **there is no historical backlog of transcoded files to worry about**. The "fixes all historical rows on deploy" property of the read-time approach was never something I was going for — it just happens to work that way as a side effect.

I'm noting this so the comparison stays honest: the argument between the two approaches should **not** be weighed on backfill/history. The real differentiators are Concern 1 (measured-value future) and Concern 2 (unvalidated assumption persisted as data).

---

## Where this leaves the two approaches

| | Read-time lookup (mine) | Write-time copy (Larry's PR #24) |
|---|---|---|
| DB semantics | `length` null = never measured (honest) | `length` holds measured *or* copied values, indistinguishable |
| Future FFMPEG-measured values (Concern 1) | Land cleanly; fallback retires itself | Must overwrite/reconcile copied values already in place |
| Validation story (Concern 2) | Assumption is display-only, reversible | Assumption persisted with no validation; companion ticket also removed |
| Historical files | Covered incidentally (not a goal — see above) | Not covered (moot — nothing deployed company-wide) |
| Reach | Only paths through `FetchFilesByProceedingIdTS` | All consumers of `files.length` |

## Assessment — how the pieces fit together

*(Agent-assisted analysis, code-verified 2026-07-15; my conclusions.)*

**This stopped being an architectural preference the moment the Nova code was checked.** Before verification, read-time vs write-time was a defensible style debate — honest nulls vs. populated columns. After verification, it is a chain of three facts, each independently confirmed in code, that compose into one failure story:

1. **FFmpeg can silently truncate.** Corrupt/truncated input → early EOF → shorter output → exit 0. Making it fail hard requires flags (`-xerror`, `-err_detect explode`) that Nova's template does not pass.
2. **Nova cannot detect it.** Exit-code-only check ([ffmpeg.adapter.ts:58-73]); stderr logged but never inspected; output never probed; no duration comparison exists anywhere in the pipeline.
3. **The write-time copy certifies it.** At the exact moment Callisto receives a silently-short file, Larry's change stamps the source's full duration onto it. The database then asserts the one "fact" that would have exposed the failure.

Each step is unremarkable alone. Together they mean the proposed implementation doesn't just *tolerate* an undetectable failure mode — it **manufactures false evidence of success** for it.

**The strongest version of the combine-feature concern:** copying doesn't generalize; measuring does. A future combined-media output has *no single source to copy from* — its duration must be measured or summed from measured parts. So measurement is mandatory in the end-state regardless; the only question is whether the data accumulated between now and then is trustworthy (measured/null) or radioactive (copied, indistinguishable, never revisited because it looks populated).

**Honest cost accounting (so this survives pushback):** the probe Nova runs today measures the *input*, not the output. The complete fix is one additional ffprobe call against an adapter that already exists, a comparison, a job-failure path that already exists (`commitFailedOutboxAndInbox`), and **one field added to the `orbital-docking-protocol` contract**. The contract change is presumably why it was deferred — that is the real trade on the table: a one-field contract change now, versus unverifiable data plus an undiagnosable failure mode indefinitely. Anyone rejecting the fix should be rejecting it in those terms, on record.

**Anticipated counters, answered:**

- *"A bad transcode is rare."* — Rare failures you cannot localize are precisely the expensive ones. The scenario in Concern 1 shows the cost isn't the bad file — it's that nothing in the data can tell you **which** file is bad.
- *"The combine feature will re-probe everything anyway."* — That concedes the copied values can't be trusted, which is the argument against persisting them.
- *"We can add a provenance flag / overwrite with measured values later."* — Then the 1-point write-time ticket has grown a schema change and a reconciliation plan, and its simplicity argument — its main advantage — is gone.
- *"QA will catch a short file."* — QA's cheapest length check is comparing the displayed length to the source. The write-time copy makes that comparison pass by construction. The design removes QA's tool, then relies on QA. Worse: the display feature exists *because it was requested as a shortcut* to the old download-and-check workflow (see "Why wasn't this considered previously?") — so the check most likely to be skipped is the manual one, on the strength of a number we copied rather than measured.

**On the shared-reliance objection (pre-empting it honestly):** any display of an unmeasured number — read-time lookup included — creates the at-a-glance reliance risk. That is true and should be conceded up front. But the two proposals are not symmetric packages. The documented read-time plan (2026-07-14 investigation) was **lookup + Nova validation companion + explicit product acceptance of the interim window** — the reliance risk was named, bounded, and routed to product for sign-off, with reversible presentation logic underneath. PR #24 is **the copy alone**: the companion reference deleted, no interim acceptance, and the assumption written permanently into data. The difference isn't which code path is safer in the incident — it's that one package acknowledged and governed the risk and the other erases the record of it.

**Recommended order of argument when raising this:** lead with Concern 3 + Open Question 4 (silent failure + the fix Nova already half-computes); use Concerns 1–2 (provenance, combine feature) as supporting material, and the Decision history chronology when asked "why now?" or "wasn't this considered?" The headline is not "my approach is better than Larry's" — it's "both Callisto patches are interim details next to a validation gap in a legal-deliverable pipeline, one of the patches actively widens it, and the only written analysis of that patch rejected it."

---

## Open questions to settle with Larry / product

1. Is the combined-media fast-follow expected to be **Nova-side with FFMPEG-measured durations**? If yes, `files.length` for derived files should ultimately hold **measured** values — which argues against seeding it with copies now.
2. If we do persist at write time, are we committing to the **Nova validation companion** (or a `length` provenance marker) so copied values are either verified or distinguishable?
3. What does operations need to **confirm** a transcode preserved runtime — and does a copied value actively undermine that confirmation by making everything "match" by construction?
4. Given that Nova already probes duration on every transcode and discards it (verified — see Decision history), what actually blocks the small Nova-local change: probe the output, compare against the input, fail on mismatch, and carry the measured output duration in the completed-event contract? That one change resolves Concerns 1–3 at the root and makes both Callisto approaches interim details.
