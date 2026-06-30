# Dustin's Operating Model & Approach

Per your request, my personal thoughts and approach. I've organized it around your three questions, but it all comes back to one idea, so I'll lead with that.

## The thread that ties it together

The priority I'd lead with is **productivity multipliers**: the foundational process and technical work that removes repeated friction across many future efforts.

The reason this matters is that **uncertainty is expensive when it moves downstream.** When a ticket enters refinement without enough context, when a business decision comes forward without a recommended direction, or when a feature depends on backend foundations that don't exist yet, the team can still move forward, but the cost shows up later as rework, workarounds, blocked time, repeated discussion, and slower delivery. In other words, **missing foundations create repeated downstream cost.**

That's why some work is worth prioritizing even when it isn't the easiest immediate feature or fix. A foundational improvement takes more focused effort up front, but if it removes friction from many future requests, it pays for itself many times over. This maps directly onto your two-speed model: the fast lane is where we *find* the real requirement cheaply; the foundation lane is where we make sure the thing we build doesn't generate downstream cost. Slow is smooth, smooth is fast.

One concrete proof point from my own work: I built an AI workflow for a Kanban-style system *(I use this to manage most of my work and would be glad to show you if interested)* where the **first step is classification**: the AI decides what kind of input it's looking at, and that decision dictates which prompt and which downstream steps run next. Once I standardized *what comes first*, the later steps fell into place almost on their own: it could spin up multiple cards, attach the right notes, and route work without me hand-sorting any of it. The output became multiplicative, not additive, because the structure was decided early instead of patched together later. That's the same principle at the team level: **get the first step (intake, classification, decision) right, and everything downstream gets easier.** It's also a direct example of the fast lane in action: I prototyped it, saw the value, and now it's worth building properly.

---

## 1. What we'd need to get there

We need clearer standards at the points where **work changes hands or moves forward**, because that's where uncertainty leaks in. Three specifically:

- **Standardize intake before refinement.** Before a ticket hits refinement, Product, Engineering, and the business should share a clear view of the problem, impact, constraints, risks, dependencies, open questions, and a recommended direction. This is the "classification step" for the team: decide what kind of work this is, up front, so the downstream steps are obvious.
- **Make missing technical foundations visible earlier.** We need a way to distinguish a one-off feature request from a backend/platform gap that will keep slowing future work if left unaddressed. Right now those gaps surface late, as workarounds, instead of early, as a decision.
- **Consolidate sources of truth.** We work across ClickUp, Figma, GitHub, and our specs, and when an AC, spec, or design changes in one place, it's on the developer to notice and chase down whether they're still building against the current understanding. This is our most live pain point right now with spec-driven design. Even when every artifact is individually valid, the team loses confidence when they can drift apart. We should be intentional about *where the current truth lives, how changes propagate, and who owns keeping related artifacts aligned.* Scattered truth is just downstream uncertainty wearing a different hat.

**Where AI fits:** it supports human judgment, it doesn't replace it. We can use it to structure incomplete information, surface missing context, pressure-test assumptions, and pre-draft tickets or decision notes before refinement, the same classification-then-route pattern that made my own workflow multiplicative.

## 2. KPIs to baseline and measure

The goal of metrics here is to **prove what we believe is happening** instead of relying on memory or opinion. Three categories, all baseline-able today:

- **Workflow friction:** time from request to ready-for-refinement; number of clarification cycles per ticket; blocked time; rework caused by unclear requirements; how often a decision carries across multiple meetings without resolution.
- **System health:** uptime/downtime, failure frequency and failure types, users impacted, manual interventions required, cost to run, support volume, and time spent maintaining or working around a system. (This is also where our over-dependence on third-party software shows up, since we can measure what we don't control.)
- **Source-of-truth drift:** number of times an AC/spec/design changed after refinement; defects or rework traced to outdated specs; number of places a developer must check before implementing; time spent reconciling ClickUp/Figma/GitHub differences.

**A real example of why system health matters: OMTI and LaGrange.** We lean on systems like OMTI, and we didn't treat their failures as a priority until a catastrophic failure forced the issue and we had to halt work to make a decision to stand up LaGrange. Prioritizing those failures as they crept in, LaGrange could have started sooner and on our own terms instead of as an emergency. We got behind the curve because we prioritized building new where there were no bugs actively harming the company, and let proven, creeping failures slide because they weren't staring us in the face every day. We shouldn't ignore what we can already prove. Tracking system health is how a slow-moving risk stays visible before it becomes the kind of crisis that craters our cadence.

**On the workflow friction metrics specifically:** we used to track this more intentionally Kat had integrated it, and it helped. That discipline has largely faded in the forefront, whether because we genuinely got better as a team or simply stopped watching. Either way, it's cheap to baseline again and a good test of whether decisions are actually landing instead of recirculating. But if memory serves, much of this was also more in our face when we had retrospectives after every sprint, which I personally find useful, if for no other reason than it gives people a chance to speak a bit more candidly on the process.

**Time itself is a signal.** If something takes longer than expected, or the same kind of request keeps needing extra clarification or workaround effort, that's evidence we're missing a process or technical foundation, and a clue about *where* to invest next.

## 3. Suggested sub-goals / OKRs (with owners)

- **Reduce downstream uncertainty before execution.** Pilot a refinement-readiness standard on upcoming work; measure whether it cuts clarification cycles, blocked time, and rework. *Owner: Product + Eng leads jointly (intake is the handoff between them).*
- **Reduce workaround-driven development.** Identify the backend/platform gaps that repeatedly slow delivery, then prioritize the foundations that make future work faster and more predictable. *Owner: Engineering, surfaced during refinement.*
- **Establish a single source of truth for active work.** Define where current truth lives and who keeps artifacts aligned as ACs/specs/designs change. *Owner: this is team-dependent. It isn't something one person can solve independently; we all need to agree on the standard and own our part of keeping it true, so this needs to be worked out together as a team.*

---

## The larger principle

We should design the operating model around **connectedness and change.** A local gap rarely stays local; it ripples into handoffs, timelines, architecture, customer experience, and team communication. If we identify uncertainty earlier and invest in the right foundations, we build a system that moves faster *and* pivots more gracefully. That's the whole game: decide the first step well, and let the downstream fall into line.
