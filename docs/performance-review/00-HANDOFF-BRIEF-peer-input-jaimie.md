# Handoff Brief — 2026 Peer Input on Jaimie

**Purpose:** Everything a fresh agent needs to take over this task. Read this file first and in full.
**Created:** 2026-08-12
**Owner:** Dustin Thomason
**Status:** Draft written, **NOT sent**. See §7 — there is a standing constraint in the sibling brief that this draft is in tension with.
**Sibling task:** `00-HANDOFF-BRIEF.md` covers Dustin's own self-input. Different deliverable, same review cycle. Read it too — several of its facts and defects apply here.

---

## 1. The original request (verbatim)

From Dustin's VP, **Jim**. Source of truth for scope. Do not expand past it.

> Hey Dustin,
>
> I'm putting together annual reviews for the team and you've seen Jaimie's work up close. Three questions please:
>
> 1. What's something Jaimie did this year that helped you or made your work better? A specific example beats an adjective.
> 2. What's been hard, or what's one thing that would help you if they did it differently?
> 3. Where do you see Jaimie ready to grow or take on more?
>
> A few bullets is a complete answer.
>
> How I'll use it: I read the input and incorporate it into the review, writing it myself. Jaimie will hear themes, not who said what. Praise I'm glad to pass along with your name on it if you're ok with that. No need to re-create if you have something like this somewhere already.
>
> If talking beats writing, speech to text works fine, or you can grab some time on my calendar and just tell me. Anything by Friday the 14th helps.
>
> Thanks,
> Jim

### Mechanics that shape the deliverable

| Fact | Consequence |
| --- | --- |
| Jim writes the review himself | Input is raw material, not copy. Bullets can be blunt; Jim handles diplomacy. |
| **Jaimie hears themes, not attribution** | Any criticism must survive being stripped of context. Dustin will not be there to clarify it. This is the single most important constraint on §2's wording. |
| Praise can carry Dustin's name, with permission | Q1 attribution is an explicit decision, not a default. Dustin's leaning: yes. |
| "A few bullets is a complete answer" | Complete, not maximum. Concision is the target but not a hard cap. |
| Deadline **Friday, 2026-08-14** | Request received 2026-08-07. Roughly one week. |
| Speech-to-text explicitly welcomed | Dustin's native mode. See §2. |

---

## 2. Voice and communication philosophy — stated directly by Dustin

**This is the heart of the task.** He paused content work specifically to establish these. Treat them as binding.

### What he wants to come across as

- A **warm person with high competency** — both, simultaneously, not traded off.
- **Kindness and generosity.**
- Someone who **makes people feel safe.**

### Structural rules

- **Why → How → What.** Every point he communicates should run in that order so people understand it easily. Applied here as: *Why* (the stake), *How* (the mechanism), *What* (specific examples, as bullets).
- **One level deep.** In his words: "You do not ever really want to go further than one click because then you have to start remembering things." Nothing where the reader must hold two facts to understand a third.
  - **Origin:** accessibility work. His test is a reader "holding a kid in one hand" — preoccupied, one-handed, still able to grasp it. This is a design principle he carries across his work, not a preference about this document.
- **Bullets for the What.** He moved to bullets deliberately because Jim nudged that direction.
- **Simple, straightforward, surface-level.** His words.

### Two derived rules established in session

- **Write it as though Jaimie will read it.** Functionally she will — Jim passes themes. This constraint produces the correct tone automatically and is the practical guard against §6 wording defects.
- **Warmth comes from moves, not adjectives.** Three that are load-bearing in the current draft: naming her repeatedly, Dustin owning his share of the hard part, and contextualizing her weakness rather than letting it stand alone.

### Voice-to-text

Dustin dictates nearly everything, by preference: "we talk way faster than we type, and it is usually better to get thoughts out that way anyway. It feels more natural, and I try to handle things that way to keep my own voice in my work." He runs a grammar pass, **nothing otherwise altered.**

**Consequence for agents:** everything he says in a working session is already his voice. That is the raw material. An artifact of the grammar pass is that contractions come out expanded ("I do not" rather than "I don't") — this is transcription behavior, not a style preference. He leans toward loosening them for warmth.

### Pronouns

Dustin refers to Jaimie as **she/her** consistently. Jim's email used they/them, most likely because the request template is generic across reviewers. **Follow Dustin's usage — she/her — and stay consistent.**

---

## 3. Facts confirmed directly by Dustin

Highest-trust content. From his own dictation this session.

### Relationship — why his view carries weight

- He **recommended Jaimie from among several candidates** because he believed she was the strongest fit. He is her sponsor, not a neutral peer.
- They formed **Team Tesseract** together.
- Reducing the ~4-year Power Platform knowledge concentration held in his head was **a deliberate goal of his year**, stated in his own self-input.
- His method: "I explain the architecture and the reasoning behind it, we discuss how something should change, and I give her a piece to own and review the result directly."
- **He listed Jaimie as a stakeholder on his own review** ("mentorship, technical context, and work review"). The feedback is bidirectional.
- **His goal #2 depends on her.** His self-input tells Jim that Team Tesseract enables him to shift toward AWS/Atlas. Any statement about her readiness is also a statement about whether he gets to move.

### What she did well

- **Whiteboard sessions.** She works logic out loud on a shared surface before either of them builds. Dustin's point about why this matters: in Power Platform there is no meaningful after-the-fact review surface, so talking it through first is the only one that exists. He notes it was **not necessarily her idea, but she adopted it immediately** — the adoption is the credit.
- It **changed how he works.** He used to hold all the architecture in his head; he no longer does.
- **JSON contract rework during the OMTI / RB9 / Power BI / Power Query incident.** She reconfigured how JSON carried data between systems, including coalesce statements and other JSON functions. Dustin: "That piece was hers and it was good."
- **She leverages AI tools competently.** Dustin flagged "it is not all her," then corrected himself unprompted: he uses AI too, "no harm, no foul," and she "knows well enough how to implement it and she understands those steps." **Do not reintroduce the hedge** — he retracted it deliberately.
- Named joint systems: **Operations Job Board** and **Automated Double Board**. See §8 — the exact attribution wording needs care.
- Joint live-incident work: RB9 connection going offline, OMTI 60-second query limit, SharePoint record detection changes, recurring sync failures. Per his self-input: "Jaimie and I have had to revisit query structures, reduce processing loads, and improve recovery behavior."

### What has been hard — two grounding incidents

Both given by Dustin unprompted, weeks apart. They share a symptom and that shared symptom is the actual finding.

| Incident | Time solo before he stepped in | Root cause | Was it catchable by her? |
| --- | --- | --- | --- |
| OMTI / RB9 / Power Query | **More than a week** on the ticket | Power Query **query folding** breaking on SQL pulldown — data buffers into Power Query/Power BI and is then manipulated locally | **No.** Dustin: "It comes with experience; it is something I knew about and recognized because I know the tools really well." |
| SharePoint list → archive (2026-08-11) | **Weeks**, saying she could not figure it out | **Data type mismatch** — a string sent to a number column. She wrote the query, he reviewed and traced it | **Yes.** Systematic verification, not tribal knowledge. Dustin: "I have drilled it into my brain to check data types and syntax." |

**The finding:** the shared symptom is **time-to-escalation**, not capability. The cost is that the time is already spent by the time it reaches him. The two root causes are different in kind and must stay separated — one is a knowledge gap that is nobody's fault, the other is a missing verification habit that is teachable.

### The Ops / scope-discipline situation

- She was taking on unscoped investigations pushed by **an Ops person functioning as an interim product manager.**
- **A real PM has since been brought in** and things now run closer to correctly.
- Dustin was absorbing the interim PM function himself and stepped in "a couple of times to try and almost protect her."
- His own read, verbatim: *"being able to recognize that sort of thing is maybe not in the role. I do not know."*
- **Corroborated in the sibling brief** (`00-HANDOFF-BRIEF.md` §3): he "pushed back when work was thrown at Jaimie without adequate context, to keep her from getting thrown into the fire without knowing how to handle the situation."

**Consequence:** the structural cause is largely resolved and was never hers. Reporting it as a standing weakness would attach a permanent note to a transient condition she did not create. Current draft handles it as protective context instead.

### Where she is ready to grow

Things Dustin states she has **not** done:

- Deployed into any dev / test / prod environment
- Worked much with permissions
- Set up or obtained credentials for these systems
- Set up environment variables (he is unsure she has done this at all)

Adjacent, and **deliberately excluded** — see §6: Azure Functions, Lambda, SQS, Fargate tasks, GitHub deploys, PRs.

- **She wants to move toward infrastructure as code.** Dustin thinks the instinct is right and the jump is bigger than it looks.
- His pipeline checklist has **"several dozen steps"** start to finish. She knows none of it. It took him **a couple of years.**
- **The skill is troubleshooting, not the happy path.** "Getting a system up and running is not easy. It is a task in and of itself. It is not a given that it just works."
- **The contractors matter.** Part of this knowledge lives with independent contractors rather than with Dustin. He reaches out to them constantly for clarification, and **"not every step is the same way every single time."** So she has to build those relationships herself.
- **His governing sentiment, verbatim — the warmest and most important line in the session:** *"I do not like seeing people fail. If they do fail, I want to see them fail safely because they are trying, rather than having it blow up in their face and become a stain."*

### Dustin's boundaries — stated firmly

- He is there for **mentorship** — showing someone what to watch out for. He is **not** there to "manage somebody else's career or how well they perform."
- **He cannot do the work for her**, especially specifying exactly what she must do.
- **He cannot train while delivering.** "I cannot train somebody while I am doing my own job in this context. It is way too intense." He is one developer among a handful.
- Nobody at the company showed him this; he learned it on his own. ⚠️ See §8 — true as history, contested as a standard.

---

## 4. The one-axis structure — do not break this accidentally

Sections 2 and 3 of the draft are deliberately **the same axis**: reaching outward early instead of grinding alone.

- §2 is the cost being absorbed now (late escalation).
- §3 is the version that scales (building contractor relationships, asking early).

This is what lets three short answers carry weight instead of reading as three unrelated observations. **If a future pass rewrites one section, verify the other still lines up.**

---

## 5. Existing files — trust levels

| File | Trust | Notes |
| --- | --- | --- |
| `00-HANDOFF-BRIEF-peer-input-jaimie.md` | — | This file. |
| `2026-peer-input-jaimie-draft.md` | ⚠️ **Draft — needs ratification** | Current working draft, Why/How/What structure, bullets as the What. Content is sourced from Dustin's dictation, but see §7 before treating it as sendable. Carries its own open-decisions table and exclusion rationale. |
| `00-HANDOFF-BRIEF.md` | ✅ **Read in full** | Sibling task (self-input). Its §3 Jaimie/mentorship material, §6 attribution defects, and §7 verified numbers all bear on this task. |
| `Dustin-Thomason-2026-Annual-Review-Self-Input.md` | ✅ Reference | The self-input he actually sent, 2026-08-07. Source for the Team Tesseract framing, his goals, and the incident list. Note it is written in first person and he did send it. |
| Other `2026-*` files | See sibling brief §5 | Trust levels already documented there. `2026-self-input-to-send.md` is marked **DO NOT USE.** |

---

## 6. Dead ends — do not re-propose these

Each was raised and closed this session. A fresh agent will regenerate them without this list.

**a) "Hand her the checklist."** Closed twice over.
1. **The Power Platform environment checklist does not exist.** Dustin: "I do not have a checklist for a Power Automate or Power Platform environment. How to set that all up is something I learned on the fly by knowing what to look for." The several-dozen-step checklist he mentioned is for pipeline work, and even that is a **review instrument** — "just to see if she addressed the general idea" — not a procedure.
2. **A step-by-step guide would teach the wrong thing.** The steps are not the same twice, so a procedure implies determinism the work does not have. Dustin's word for the result: a **crutch.**

**b) "Attention to detail" as a phrase.** Dustin used it ("that sort of attention to detail that gets her into trouble a lot of the time") and it is **excluded on purpose.** It generalizes from two instances, and since Jim strips attribution it would become a theme that follows her across review cycles — every future mistake confirms it. The specific version (no type-and-contract check at the boundary before hunting the logic) is both fairer and more useful.

**c) Query folding as a criticism.** It was the real root cause of the OMTI problem and she could not have caught it. Dustin confirmed it takes years with the tool. It is **§3 context about the remaining knowledge delta, not a failure.** Jim does not need the internals.

**d) The AWS / traditional-code list.** Lambda, SQS, Fargate, PRs, GitHub deploys. Most is not Power Platform, and some of it is **Dustin's own trajectory rather than hers.** Listing it would read as "she is not a real developer," which is not what he means, and he would not be present to clarify. Azure Functions and source control may be mentioned as *opportunity* only — never as a gap.

**e) Side-quests / scope discipline as the primary Q2.** Superseded. It was the first framing, then the structural cause turned out to be a missing PM role that has since been filled. Demoted to protective context. **The late-escalation finding replaced it** and is better grounded.

**f) The AI hedge.** "It is not all her" was raised and retracted by Dustin in the same breath. Do not reintroduce it.

---

## 7. ⚠️ Standing constraint this draft is in tension with

The sibling brief (`00-HANDOFF-BRIEF.md` §2, **Hard constraints**) records:

> **Do not write in Dustin's first-person voice.** A ghostwritten letter was produced and rejected. He found the invented voice and self-characterization unusable. Produce material he writes from, or clean up his own dictation. Do not compose sentences he would have to own as his.

**The current draft is written in his first-person voice.** That is a real tension and it must not be discovered later. Recorded honestly:

**Why this case is arguably different:**
- He **explicitly asked for the draft** after seeing the approach, and asked for it to be structured Why/How/What with bullets.
- Nearly every substantive sentence is **assembled from his own dictation this session**, several verbatim — "stain," "fail safely," "it was good," "the general idea," "not every step is the same way every single time."
- He reviewed the prose version in-session and accepted its substance, correcting specifics as he went.
- The prior rejection was of **invented** voice and **invented self-characterization** — fabricated content he had never said. That is a different failure than assembling his own words.

**Why the risk is still live:**
- The constraint is stated absolutely and was recorded after a rejection, which means it was expensive to learn.
- The distinction above is a judgment call, and it is **Dustin's to make, not an agent's.**

**Required action before sending:** Dustin ratifies the draft **line by line**, or rewrites it from the bullets. Do not treat agent-assembled first-person prose as sendable on the strength of the reasoning above. If he cools on the draft, **this is the reason** — do not re-litigate it, revert to neutral bullets he writes from.

---

## 8. Claims needing verification before send

**a) "The Operations Job Board and the Automated Double Board are both genuinely hers now."**

The sibling brief §6a documents a **known over-attribution defect on these exact two systems** — source notes were objectives in future tense and got rendered as completed work. Its §8 open question #5 is still unresolved: what Dustin personally did on ADB/OJB versus planned or participated in.

Dustin's self-input says "**our joint work** on the Operations Job Board and Automated Double Board." "Genuinely hers now" is stronger than that. Also note the sibling brief records **Caitlin** as partly responsible for delivery on both boards. **Confirm the ownership wording with Dustin before sending.**

**b) "Nobody at this company showed me how to do it."**

True as history. Shaky as a standard, and flagged to him as the one soft spot in his reasoning:
- He learned it over ~2 years with nobody waiting on him. Her curve sits on the critical path for a transition he has already committed to in writing. Different conditions, different clock.
- Stripped of attribution in a review, that reasoning reads as gatekeeping — which contradicts his own "fail safely rather than blow up" position.

The observation stands; the **inference** from it is what to be careful with. It is not in the current draft. Keep it out unless he wants it.

**c) The bandwidth admission.**

The draft includes "I will own part of that… my delivery schedule has not left much room for it." It is the only paragraph about Dustin rather than Jaimie. It is also his **strongest ask** — his own self-input tells Jim that Team Tesseract enables his move to AWS/Atlas, while the transfer needs mentorship time he does not have. Only Jim can resolve that.

**Framing is decisive:** "training her is too intense" reads as *she is high-maintenance*. "The transfer needs mentorship time the delivery schedule does not leave room for" is a **resourcing ask.** Same fact. Keep the second form.

---

## 9. Open questions for Dustin

1. **Is environment access actually available to grant?** If the environments do not exist or she cannot be granted access, §3 of the draft becomes a request to Jim rather than a growth observation about her, and should be worded as one. **Unresolved.**
2. **Does the bandwidth paragraph stay in?** He was leaning yes. Not formally confirmed.
3. **Name on the praise?** Jim offered. Leaning yes. Not formally confirmed.
4. **"Stain" — keep it?** It is his own word in the closing line, and the most human sentence in the letter. Possibly too raw for a review file. His call.
5. **Ownership wording on OJB/ADB** — see §8a.
6. **Is the AI-assisted-but-unverified hypothesis correct?** Raised in session, unconfirmed: the good OMTI JSON work and the string-to-number miss may be the same phenomenon — output that is structurally sound and unverified at the boundary. If true it sharpens §2 considerably. **Only Dustin can confirm.** It is a "verify the output" note, never a note about using AI.

---

## 10. Recommended next step

1. **Resolve §9 #1 first** — it determines whether draft §3 is an observation or a request.
2. **Get §8a confirmed** — it is the one factual attribution claim in the draft, and it sits on systems with a documented over-attribution history.
3. **Have Dustin ratify or rewrite the draft per §7.** If he rewrites, feed him the bullets, not prose.
4. **Trim §2 first if length needs cutting.** It carries the most risk and the most value, so it is also the section most likely to need softening.
5. **Preserve the one-axis link (§4)** through any rewrite.
6. Deadline **Friday 2026-08-14**. Speech-to-text and a calendar slot are both acceptable delivery modes — he does not have to write it.
