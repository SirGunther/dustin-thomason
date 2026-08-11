# ⛔ REJECTED DRAFT — DO NOT USE, DO NOT SEND

> **Rejected by Dustin on 2026-08-06.** Retained only as a record of what failed. Read [00-HANDOFF-BRIEF.md](./00-HANDOFF-BRIEF.md) before touching anything in this directory.
>
> **Why it failed:**
>
> 1. **Ghostwritten in Dustin's first-person voice.** He did not write it and would not say it this way. Composing sentences he has to own as his own is out of bounds.
> 2. **Fabricated admission.** The "one honest note" line about record-keeping came from an aside Dustin made to the agent explaining why the data was thin. It was turned into a confession addressed to his VP. He never said it and it does not belong in the deliverable.
> 3. **Plans presented as completed work.** The ADB/OJB claims ("I designed…", "On ADB I replaced…", "I ran…") derive from notes written as *objectives in future tense* describing *team* strategy. See handoff brief §6a.
> 4. **Invented self-characterization** — lines such as "it's the most reliable thing about me" and "Thanks for asking for this" are the agent's words, not his.
>
> Content below is unverified. Do not copy from it.

---

## Original draft content (rejected)

*This is the short version: Jim's three questions, answered, and nothing else. Detail lives in [2026-accomplishments.md](./2026-accomplishments.md), which is what you bring to the discussion — not what you send.*

**Target send date:** Friday, August 7, 2026 · **Discussion:** week of August 10–14

---

Jim,

Here's my self-input. I've kept it to your three questions and I'm happy to go deeper on any of it in the discussion.

## Performance this year

**Nova.** The video transcoding project is entering beta and about to launch for the first time. The part I'd want you to know is where it came from: it started as a conversation with Nate Mollick about five years ago and sat dormant because we had no development team to own an FFmpeg-based system. When that constraint changed last winter, I reopened it, and I built the initial proof of concept on my own time before it was assigned or funded. The investigation that made the case was mine too — benchmarking AWS Elemental MediaConvert at roughly 4× the cost of orchestrating it ourselves, sizing real demand with the video team, and designing the staged pipeline we're now shipping on Fargate. First commit was December 2025. Proving it out also surfaced a platform gap we didn't know we had, which became the Atlas-to-Callisto messaging work I did with Xavier.

**Restoring ADB and OJB.** When the RB9 connection went down on May 21, both boards were unusable and operations fell back to manual reconciliation. The hard part was that OMTI enforces a non-negotiable 60-second query timeout, so reconnecting would have meant instantly timing out on a month of backlog, permanently. I designed a throttled incremental reconnection that advances a high-water mark past the backlog, with failed queries folded into the next pass, validated in a cloned pre-production environment first. On ADB I replaced a legacy pattern that triggered a full database refresh on every user login with a decoupled semantic model refresh. I ran a near-term repair track and a long-term Lagrange migration track in parallel so the patch wouldn't quietly become the architecture.

**Two years of learning this stack from zero.** This is the part that predates you, and it's the throughline. In July 2024 I started on Hubble, our OCR automation, having never written Java and with no working knowledge of AWS. I learned both on that project — containers, Fargate, SQS, dead-letter queues, Aurora, trace IDs, CloudWatch — took it through pilot to production, and I still own it today; two of my current tickets are Hubble spikes. The Fargate design Nova is launching on first appears in my Hubble notes in August 2024. I mention it because it's the most reliable thing about me: when something is unfamiliar, I learn it and then build with it.

**The work that doesn't show up in commits.** Training Jaimie is a real and recurring part of my week — walking through systems I built, then reviewing her work directly, not handing off tasks. I review the team's pull requests and wrote down the review patterns so expectations are explicit. I helped define the two-tier spec-driven development framework we're adopting ahead of team growth. And I've been in effectively every ADB and OJB requirements meeting making sure what's asked is achievable before we commit — including pushing back when work was headed to Jaimie without enough context to succeed with it.

One honest note: I only got disciplined about capturing my work partway through this year, so my own records are thinner for January through May than what actually happened. That habit is fixed now.

## Stakeholders who should provide input

- **Nate Mollick** — the original transcoding conversation and the arc from idea to launch
- **Xavier** — orbital docking protocol and the Callisto authorization work
- **Karl** — Nova architecture, environments, and Hubble production deployment
- **Caitlin** — requirements realism and the ADB/OJB recovery from the operations side
- **Jaimie** — training and mentorship, as the direct beneficiary
- **Larry Adams** — Nova ticket definition and team engineering standards

Also useful if you want breadth: **Kat** (Nova test coverage), **Erik Johnson** (Hubble and notifications), **Julia White** (investigation rigor), **Leah** (video team requirements).

## Goals for next year

**Get definition upstream of the work.** Requirement checkpoints at intake and the spec-approval gate made real rather than nominal. Most of what went wrong this year went wrong before the code — incomplete requirements, undefined success criteria — and that's the highest-leverage thing I can fix.

**Turn what I've built into team capability.** Move my development harness, investigation process, and troubleshooting documentation from personal practice into shared onboardable assets, which matters more as the team grows.

**Take Nova and platform reliability to production maturity.** Nova through beta into real use, the Lagrange migration completed so ADB and OJB stop depending on a fragile legacy source, and OJB throughput tuned up without giving back reliability.

**Keep widening the stack I can build in.** More architecture, more platforms, more depth — and I'd benefit from being pointed at bigger problems rather than only finding them myself.

**One thing I want to raise directly.** I'm looking to move up, and I'd rather say that plainly than leave it under the surface. Two things would help: knowing what the next level actually requires here — scope, ownership, architectural or people responsibility — so I can aim at it deliberately, and a candid read on what a meaningful step looks like and what timeline it lives on. You mentioned wanting specific plans out of this, and that's where I'd value one most.

I've got a longer write-up with the detail and numbers behind all of this if it's useful for the review. I'll get the discussion on the calendar for the week of the 10th.

Thanks for asking for this — it was genuinely useful to put together.

Dustin
