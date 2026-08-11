# 2026 Peer Input — Jaimie (DRAFT)

**For:** Jim
**Requested:** August 7, 2026
**Due:** Friday, August 14, 2026
**Status:** working draft — not sent

---

## How this is structured

Each of Jim's three questions gets the same shape: **Why** (the stake — why I have a view worth reading), **How** (the mechanism), **What** (the specific examples, as bullets).

Two rules the writing has to obey:

- **One level deep.** Jim is writing reviews for the whole team and will read this distracted. Nothing where he has to hold two facts to understand a third.
- **Write it as though Jaimie will read it.** Functionally she will — Jim passes themes, not attribution. That constraint produces the right tone on its own.

The **Why / How / What** labels are scaffolding. Delete them in the send version, same as the draft-to-send split on my own self-input.

---

## Draft

Jim,

Happy to. Quick context on why I have a view here: reducing the Power Platform knowledge concentration was one of my goals this year, and Jaimie is how it is actually happening. So I see most of this up close.

### 1. What Jaimie did that helped me

**Why it matters:** Four years of Power Platform work had piled up in my head. That was a real risk to the company, and getting it out of there was the point of Team Tesseract.

**How she did it:** She is willing to whiteboard logic out loud before either of us builds anything. In Power Platform there is no real way to review someone's work after the fact, so talking it through first is the only review surface that exists. She took to that immediately.

**What that has looked like:**

- The Operations Job Board and the Automated Double Board are both genuinely hers now.
- During the OMTI and RB9 mess, she rebuilt how the JSON contracts carried data between systems, including the coalesce handling. That piece was hers and it was good.
- She made my own work better, which I did not expect. I used to keep all of that architecture in my head. I do not anymore, and I am more deliberate for it.

### 2. What has been hard

**Why it matters:** A handoff this size only works if problems surface fast. The cost is not the bug — it is the time spent stuck before anyone else knows.

**How it shows up:** Jaimie will stay on a hard problem by herself longer than she should, so it reaches me after the time is already gone.

**What that has looked like:**

- On a couple of tickets, a week or more went by before it got to me, and the answer turned out to be something small in the data contract.
- This is not about her judgment. She has not learned yet that surfacing something early is the strong move, not the weak one.
- I will own part of it. Handing off systems this size takes real mentoring time, and my delivery schedule has not left much room for it. Worth knowing when you look at how fast the transfer is going.
- Before the new PM came in, she was getting pulled into unscoped Ops investigations with no clear way to route them. She said yes to all of it. That is a generous instinct with no cover behind it, and it has already improved.

### 3. Where she is ready to grow

**Why it matters:** I cannot step back from these systems until someone else can stand one up and deploy it. That is the whole gap between where we are and where Team Tesseract was supposed to get us.

**How she gets there:** Not by being handed a procedure. There is no guide for this. I learned it by knowing what to look for, a good part of it lives with our contractors rather than with me, and the steps are not the same twice. So it has to be her doing the discovery, with me reviewing whether she addressed the general idea.

**What I would point her at:**

- Power Platform environments — setting them up, moving work from dev to test to prod, credentials, environment variables. She has not done any of it yet.
- She wants to move toward infrastructure as code. That instinct is right, and it is a bigger jump than it looks from the outside.
- Building the working relationships with our contractors herself, rather than through me. Same muscle as surfacing problems early.
- What I would ask for her: a real environment build to own, with real stakes and a small blast radius. I would rather watch her fail safely while she is trying than have something blow up and become a stain on her.

Happy to talk through any of it.

Dustin

---

## Open decisions

| Item | Question | Leaning |
| --- | --- | --- |
| Name on praise | Jim offered to attribute praise. Take it? | Yes — the whiteboard credit is more credible from the person whose work improved because of it |
| "Stain" | Kept my own word in the closing line. Powerful, or too raw for a review file? | Keep — it is the most human sentence in the letter |
| Bandwidth admission | The "I will own part of it" paragraph is the only one about me. Leave it in? | Leave in — it is the strongest ask I have, and it is the source of the warmth |
| Contractions | Mostly expanded, matching how my dictated text lands. Loosen them? | Loosen slightly for warmth |
| Length | Roughly 450 words against "a few bullets is a complete answer" | Fine — Jim said complete, not maximum. Trim §2 first if needed |

## Deliberately left out

- **"Attention to detail."** What I actually mean is narrower and fixable — she does not yet run a type-and-contract check at the boundary before hunting through the logic. As a phrase, "attention to detail" would follow her across review cycles and every future mistake would confirm it. Not worth the damage when the specific version is more useful anyway.
- **Query folding.** The real root cause of the OMTI problem was Power Query folding breaking on the SQL pulldown, which she could not have caught. That is years with the tool, not a failure. It is context for §3, not a criticism, and Jim does not need the internals.
- **Azure Functions, Lambda, SQS, Fargate, PRs.** She has not done these, but most of it is not Power Platform and some of it is my trajectory rather than hers. Listing it would read as "she is not a real developer," which is not what I mean and I would not be there to clarify.

## Notes for the next pass

- §2 is the section most likely to need softening or tightening. It carries the most risk and the most value.
- The two open items I have not resolved: whether the environment access is actually available to grant, and whether Jim reads the bandwidth line as a resourcing ask or as a complaint.
- Q2 and Q3 are deliberately the same axis — reaching outward early instead of grinding alone. That is what lets three short answers carry weight instead of reading as three unrelated observations.
