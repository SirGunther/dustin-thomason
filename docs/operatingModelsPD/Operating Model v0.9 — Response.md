# Technology Operating Model v0.9 — A Review

*My read on the v0.9 draft, offered as support for where it's headed. I tried to judge it on three questions rather than on whether it agrees with what I submitted earlier: does it solve the class of problem rather than the instance, are its claims written so they can be proven wrong, and where have efforts like this failed for other people before? The summary stands on its own; the sections below are the reasoning behind it.*

---

## 1. Executive summary

**The short version: this is the right direction, and I don't think we're setting ourselves up for failure.** It's a serious piece of work, and the thing I'd protect above everything else is that it's *falsifiable* — nearly every change carries a baseline number, so a year from now we can actually tell whether it worked. Most operating models can't be graded. This one can.

A few headlines:

- **Its standout strength is measurement.** 11.9% requirements churn, 93% of dated items finishing late, 25 of 237 features drifting — those numbers turn opinions into tests. That discipline is the real asset, and it's the first thing that quietly erodes when a plan gets simplified for rollout. We should guard it.
- **There's strong alignment with what several of us submitted** — reducing downstream uncertainty, clarifying intake before construction, treating missing foundations as explicit decisions, and making source-of-truth drift visible. It reads like the team's thinking, consolidated.
- **Two risks are worth naming out loud** so we see them coming: the *force that created the unowned seams in the first place* can quietly override the new controls, and our *metrics can become targets* the moment they're used to grade people instead of the system.
- **One thing I'd add:** a pivot tripwire for the model itself — a number we agree, in advance, would tell us to stop and rethink.
- **The one question I'd most want answered before we commit:** *what changes Monday morning?* If we can name the single behavior that changes for each role in week one, adoption mostly takes care of itself. If we can't, that's the risk — not the design.

None of this is a pivot. It's hardening a plan I think is fundamentally sound, built by a lot of people who clearly put real care into it.

---

## 2. How I read it

I want to be honest about the lens, because it shapes everything below.

It would have been easy to grade this draft by how much it echoes the input I sent in — and there's a fair amount of overlap. But *"does this agree with me?"* and *"is this a good plan?"* are two different questions, and only the second one helps us. So I set the first aside and read v0.9 the way I'd read any solution I care about: **Does it solve the class of problem, not just this instance? Are its claims written so they can be refuted? And — the one I think we under-ask — where have efforts like this failed for other people, and why?**

That last question is really just our own *see-around-corners* instinct pointed at the operating model instead of at a feature. Everything below comes out of those three tests.

---

## 3. The model, the way I hold it

The draft is dense, so here's the compression I use to keep it in my head — offered partly as a compliment, because *the fact that it compresses at all is a sign it's well-built:*

**Five seams, three engines, one contract each.**

The whole model says delivery breaks at *handoffs* — business to function, requirement to engineering, finished work back to the business, a running system to operations, a build to production — and the fix is the same every time: name an owner on each side, and agree what a clean handoff looks like. The three engines — the weekly review, the meeting norms, the single source of truth — are what keep those contracts honest over time.

A model you can hold in your head is one people can actually run. This one passes that test.

---

## 4. Where I see strong alignment

I was glad to see how much of the draft lines up with the direction several of us argued for. The intake-and-classification thinking — *get the first step right and the downstream falls into line* — is there in the prototype-to-clarify approach. The idea that a missing foundation should be an explicit *invest-now-or-keep-paying* decision rather than a silent workaround is there too, carrying the OMTI/LaGrange lesson we learned the hard way. And the source-of-truth drift that's been our most live pain — ClickUp, Figma, and GitHub quietly disagreeing — has become a real mechanism, a drift watcher running on our own data. That's genuinely further than I'd hoped.

If I can offer one framing that might be useful: the draft's principle of **clean seams** is the *where*, and there's a *why* underneath it worth keeping in view. **Uncertainty is expensive when it moves downstream** — and a seam is exactly the place where that uncertainty gets injected, because a handoff with no agreed contract is where context gets dropped. The five seams are, in effect, the five places we should expect cost to pile up. Naming the *why* alongside the *where* helps people understand not just what to do, but why the whole thing hangs together.

I'll also note the draft quietly answered a question I'd left open. I'd said keeping artifacts aligned wasn't something one person could own alone; naming a per-feature alignment owner is a cleaner answer than I had. Credit to whoever landed that — this reads like a lot of people's thinking, well consolidated.

---

## 5. What v0.9 gets right that's rare

Before I push on anything, I want to be clear about how much this draft gets right, because these are the things similar efforts usually miss:

- **It's falsifiable.** Every change carries a metric and a baseline. That's rare, and it's the property I'd defend hardest, because it's the first thing to go when a plan gets trimmed for adoption. Keep the numbers.
- **It solves the class, not the instance.** *Seam → contract → two owners* is an abstraction that works for any handoff we invent later, not a one-off fix for today's five. That's the right altitude.
- **It designs out the usual killers.** Efforts like this normally die in predictable ways, and the draft has an answer for each: it's built on *mechanisms, not willpower*; it sequences in *waves* rather than all at once; it's *co-authored*, not imposed, with norms that bind leadership too; it treats its own changes as *hypotheses, kept-or-killed*; and it changes *contracts, not the org chart*, so it sidesteps reorg theater. That's a strong immune system.

---

## 6. Where I'd pressure-test it

Everything here is meant as hardening, not objection. I've written each as a claim we could prove wrong, with a *tripwire* — an early signal to watch for — so these stay honest and we can see the corner before we hit it.

**1. The force that created the seams can quietly override the fix.** *(The one I'd watch most.)* The draft's own diagnosis of demand is that prioritization has run on the founder and the business deciding, without a formal ranking. A published, ranked backlog is a good control — but a control sits *on top of* that force, and urgency can still route around it. If it does, the backlog slowly becomes decoration.
- *Tripwire:* in the first ~6 weeks, count the priority changes that bypassed the ranked backlog and arrived with no one-line reason. If that number isn't near zero, the seam is already reverting — and we address it early instead of assuming the backlog holds.

**2. Our metrics can become targets.** This is the flip side of the draft's greatest strength. The moment these numbers grade *people* rather than diagnose the *system*, behavior bends to feed them: clarification comments migrate to DMs where they aren't counted, reviews get rubber-stamped to move the concentration number, estimates drift to the safe end so nothing reads late. The draft already protects the headline number well — *measure surprise, not slippage* rewards honest re-forecasting — and I'd just want that same protection stated for the rest.
- *Tripwire:* the day a v0.9 metric shows up in a one-on-one as a personal scorecard, or the day clarification churn drops while rework doesn't. Either one means we're gaming the measure, not fixing the problem.

**3. Some owners don't exist yet, or can't enforce.** A contract is only as real as the person who can accept or reject against it. A few of the acceptance roles are still open questions — the incident manager, the demand-side owner, ops' capacity to actually run UAT. A gate whose owner has no budgeted time doesn't add safety; it becomes the new bottleneck, and people route around it.
- *Tripwire:* before wave 1 ships, every named owner in the run-time and production seams has a real name and real hours. Any "TBD" is a seam that will quietly stay unowned.

**Two more, briefly:**

- **The adoption question.** Can we name the *single* behavior that changes for each role in week one? The wave sequencing is the right instinct; I'd just want wave 1 small enough that everyone knows their one new habit on the first Monday.
- **Coverage — the seam we haven't named.** The five seams model the internal handoffs well. I'd want us to confirm requirement risk isn't leaking in through one we haven't drawn: engineer-to-engineer knowledge silos (the review-concentration numbers hint at this), and the *end client* sitting behind "the business owner." If the paying customer's need enters through an unnamed seam, we'd want to know before it costs us.

---

## 7. The one thing I'd add

The draft is good about keeping or killing individual *mechanisms* — but it doesn't yet say how we'd know the *model itself* is failing. I'd add two small things at the planning day:

- **A pre-mortem.** Assume it's twelve months out and this didn't work — name the top three reasons now, while we can still design around them.
- **A pivot tripwire.** Pick one or two headline numbers — the share of slips flagged before the date, and requirements churn are the natural ones — and agree *in advance* what movement in the wrong direction tells us to stop and rethink.

Seeing around the corner isn't a feeling; it's a number we agreed to ahead of time. *Owner: this belongs with whoever runs the weekly operational review, since that's already the room where the contracts get inspected.*

---

## 8. Where this leaves me

Right direction, real rigor, and a genuinely strong foundation. My push is narrow: name the two risks out loud — the force behind the seams, and metrics becoming targets — make sure every owner is real before wave 1, and give the model its own tripwire. That's hardening, not a pivot.

Thank you to everyone who put work into this; it shows. If it's useful, I'm glad to help pilot any of it or stand up the measurement side — some of this is close to the friction tracking we used to run with Kat, and I'd enjoy helping bring that discipline back.
