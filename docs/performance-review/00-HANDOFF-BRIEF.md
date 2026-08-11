# Handoff Brief — 2026 Annual Review Self-Input

**Purpose:** Everything a fresh agent needs to take over this task. Read this file first and in full.
**Created:** 2026-08-06
**Owner:** Dustin Thomason
**Status:** Deliverable NOT sent. Existing drafts contain known defects — see §5 before reusing any of them.

---

## 1. The original request (verbatim)

From Dustin's VP, **Jim**. This is the source of truth for scope. Do not expand past it.

> Thanks for this! To close the loop, could you please share some self-input on your performance for the year, the stakeholders you work with the most that should provide input, and some of your goals for next year? I'll do some legwork and put together an annual review that we can get some insights and specific plans from. Please send the self input by end of next week, and put the discussion on the calendar for the week after, to keep us moving forward on it so we can check it off.  Sound good?

### Deliverables

| # | Ask |
| --- | --- |
| 1 | Self-input on performance for the year |
| 2 | Stakeholders who work with him most and should provide input |
| 3 | Goals for next year |
| 4 | Send the self-input by end of next week |
| 5 | Dustin puts the discussion on the calendar for the week after |

### Timing — urgent

The request was received on/around **2026-07-31**. "End of next week" = **Friday, 2026-08-07**. Today is **2026-08-06**, so the send deadline is **tomorrow**. The discussion should be calendared for the week of **Aug 10–14, 2026**. Item 5 is Dustin's action and is easy to drop — confirm it isn't forgotten.

---

## 2. What Dustin actually wants out of this

Stated by him directly across the working sessions. This is intent, not decoration — it should drive the shape of the deliverable.

- **Acknowledgment of work that isn't visible.** Specifically: that he initiated Nova rather than being assigned it, and that mentorship and requirements work take real time and don't appear in commits.
- **Goals moving forward**, not a retrospective monument.
- **Growth and advancement.** He wants to keep learning systems and platforms, and he wants to move up. He is explicit that he wants to understand how to make a bigger jump, and notes there is a finite allocation pool. He believes this went unnoticed under his prior manager.
- **Scope discipline.** In his words, he does not want to "go off the rails in only one direction" or "impose any sort of data unnecessarily." Answer Jim's three questions. Volume is not the goal.
- **Tone.** He wants it known he cares about his job and enjoys the work.

### Hard constraints

- **Do not write in Dustin's first-person voice.** A ghostwritten letter was produced and rejected. He found the invented voice and self-characterization unusable. Produce material he writes from, or clean up his own dictation. Do not compose sentences he would have to own as his.
- **Do not claim an AWS → Power BI pipeline.** He stated it isn't fully done and said not to bring it up.
- **Do not include anything about his record-keeping habits.** He said in passing (to the agent, as context for why data was thin) that he only recently got better at capturing tickets. A prior draft turned this into a confession addressed to Jim. It is not part of the deliverable.
- **Delete nothing.** Standing instruction from Dustin, originally about WorkLists data. Applies to files here too.

---

## 3. Facts confirmed directly by Dustin

Highest-trust content. Sourced from his own dictation, not inferred from data.

### Nova (video transcoding)

- Originated in a conversation with **Nate Mollick** roughly five years ago; sat on the back burner since.
- **Shaye** and Dustin had been in prior meetings on it over the years.
- Implementing **FFmpeg** directly was considered unattainable — no software development team existed to build and maintain an input/output system around it. **HandBrake** became the practical path.
- Around last winter it was established this was buildable. Dustin reopened it and drove it forward.
- **First commit: December 2025.**
- He built the **initial prototype on his own time**. It was not asked of him. He judged it a potential win for the company.
- He took the initiative to do a **POC on his own** and investigated **cost** — how to do it inexpensively.
- Discussions afterward "dragged on for quite a while."
- Proving it out exposed missing infrastructure, notably messaging from **Atlas through Callisto**, which became the **orbital docking protocol**. He worked closely with **Xavier** on that.
- The investigations were not initiated by a product manager.
- He learned AWS through this: **Fargate tasks**, and the difference between Fargate and **EC2 instances**.
- **The Lambda-based schematic on the Nova board was the initial draw-up, produced before Fargate was known to them.** Cost and fit work moved it to **Fargate tasks**, which is the current and shipping solution. The Lambda design on the board is a learning artifact, not the plan.
- **Nova is in beta testing and about to launch for the first time** (as of 2026-07-31).
- He connects this to a company idea that pet projects are a way to learn and may deliver value, and to a point **Joe DiMonte** made about using an image as a mockup so someone can quickly understand a design and how it might integrate.

### Hubble (OCR)

- The OCR project **can be looked up under Hubble**, and Dustin said the project could be named that.
- His estimate of timing was "about a year prior… maybe not even… I don't know" — **he was uncertain**. Board data shows OCR work starting 2024-07, i.e. roughly two years. **This discrepancy is unresolved. Confirm with him before stating any duration.**
- It was his **first time learning Java**, and he was "dumped into the AWS world having no idea how any of that worked and having to learn everything."
- This was **before he used Cursor** and before the AI tooling he now works with.
- He wants it known that he is not only capable but **willing to learn**, with ambition to keep moving up.

### People and roles

| Person | Role / status — as stated by Dustin |
| --- | --- |
| **Jim** | His VP. Board data indicates Jim is new in the role. |
| **Joe DiMonte** | Cofounder / managing partner; handles the technology department. |
| **Joey Velazquez** | Litigation Technology Director ("I think that's what his title is now"). |
| **Gregg** | **No longer with the company** — let go the week of ~2026-07-27. Performed Dustin's previous review; Dustin considered it poor. **Exclude from stakeholder asks.** Do not editorialize about him in any deliverable. |

### Mentorship — Jaimie

Not task handoff. He sits down and meets with her, explains how the systems he built work, discusses how they might change or fix them, and sometimes leaves a piece to her and then reviews the work directly.

### Requirements and team protection

- He has had a large part in making sure a particular group's work is going to plan. **The group's name was unclear in the audio and remains unconfirmed — ask him.**
- Delivery there is partly **Caitlin's** responsibility, covering the **Operations Job Boards** and the **Automated Double Board**.
- He has been part of all of those meetings, making sure the team is capable of what's being asked, acting as "a voice of reason."
- He has pushed back when work was thrown at Jaimie without adequate context, to keep her from "getting thrown into the fire without knowing how to handle the situation."

### Cross-functional reach

Sometimes it is more useful to talk directly to the person who had the problem, or to interact with **IT** to find the real issue. He believes a large part of his value is that he can approach many stakeholders directly and it is generally well received. He thinks Jim knows "to a degree" that his capabilities extend beyond engineering.

### Architecture

- Architecture learned on **Atlas** has changed how he solves problems in the **Power Platform** — aiming for designs that are more scalable, robust, expected and predictable.
- Example he gave: there was little additional security around **HTTP calls from the Power Platform out into AWS**. He had a large hand in building those bridges. This is done with some regularity now.
- He has also done work with **Azure** and **Power BI**.
- **Excluded per his instruction:** AWS → Power BI.

---

## 4. Data sources

Local WorkLists app. Dustin runs it at `http://localhost:3010/`.

| Source | Detail |
| --- | --- |
| Full board JSON | `GET http://localhost:3010/data` — returns `boards`, `columns`, `todos`, `event-notes`, etc. |
| Live note lookup | `GET http://localhost:3010/api/notes?eventId=<todo-id>` |
| Card → note join | `event-notes[].eventId` matches `todos[].id`. Cards carry only a title; **all content lives in notes.** There is no parent/child field, so "nested" means this join only. |
| **Weekly Accomplishments** | board `board-10` (*Personal Life*) → `column-1782147601915`. 6 date-range cards, 15 notes, covers **2026-06-22 → 07-31**. Two cards empty. 3 of the 15 notes are personal (car, wedding, family) — exclude. |
| **Sprints 2026** | `board-22`. 17 columns, 142 cards, 135 notes, covers **2026-01-07 → 07-31**. Sprints 01–10 have **0 notes**; notes begin at Sprint 11. Inventory already extracted — see `2026-sprint-harvest.md`. |
| **Nova** | `board-20`. Architecture, research, cost findings, requirements sizing. |
| **Hubble** | `board-19`, spans **2024-07-24 → 2026-01-14**, includes a 30-card `OCR` column. |
| Considered, not done | Dustin raised connecting the **ClickUp API** to mine tickets he's tagged in, then questioned whether more data was needed. Not pursued. Treat as optional and low priority; ClickUp holds assigned work, which is the already-visible portion of his record. |

Note: a card note dated 2026-06-16 under *Power Platform to AWS* contains a plaintext credential. **Dustin has confirmed it is old and already rotated. No action needed. Do not reproduce it.**

---

## 5. Existing files — trust levels

All in `docs/performance-review/`. **Read this table before reusing any content.**

| File | Trust | Notes |
| --- | --- | --- |
| `00-HANDOFF-BRIEF.md` | — | This file. |
| `2026-self-input-to-send.md` | ❌ **DO NOT USE** | Ghostwritten letter in Dustin's first-person voice. **Rejected by him.** Contains invented voice, invented self-characterization, and a fabricated admission about his record-keeping. Also contains the over-attribution defects below. Retained only as a record of what was rejected. |
| `2026-accomplishments.md` | ⚠️ **Audit before reuse** | Structure and factual inventory are useful. **§1, §2 and §8 contain first-person over-attribution** — see §6. Written in first person throughout, which Dustin rejected. |
| `2026-sprint-harvest.md` | ✅ Reference | Sprint inventory, PRDV ticket list, people list, hard numbers, Hubble timeline. Cites sources. Most reliable of the derived files. |
| `2026-annual-self-input.md` | ✅ Reference | Compilation of the 15 Weekly Accomplishments notes with provenance. Personal items quarantined in its Appendix B. Its coverage caveats are now superseded by the sprint harvest. |

---

## 6. Known defects — do not inherit these

The rejected draft failed for reasons a new agent will repeat unless warned.

**a) Plans were converted into completed accomplishments.** The 2026-06-15 notes on the *Power Platform to AWS* card are **objectives written in future tense**. They were rendered as finished personal work:

| Source note says | Draft claimed |
| --- | --- |
| "The **objective is** to restore the OJB by establishing a throttled, incremental reconnection…" | "**I designed** a throttled incremental reconnection…" |
| "The ADB **will be** restored to production by transitioning from a direct database-refresh pattern…" | "**On ADB I replaced** a legacy pattern…" |
| "**The team is** balancing a near-term 'repair' strategy (Plan A) with a long-term 'modernization' strategy (Plan B)" | "**I ran** a near-term repair track and a long-term Lagrange migration track in parallel" |

Verify tense and subject before attributing any ADB/OJB work to Dustin.

**b) Team and third-party work was attributed to Dustin.** Two specifics:
- The shift in success criteria from "is it working?" to specific testable measures is credited in **Dustin's own note** to *"Greg's Product Management pivot."* Not Dustin's.
- The OJB/ADB Business Operations Alignment meeting notes were **authored by Kat**, which does not establish that Dustin led the session.

**c) A causal lineage was inferred that may contradict him.** Fargate appears in the Hubble notes in **August 2024**, and a draft used this to argue Nova's Fargate design descended from Hubble. **Dustin said Fargate came from later learning, after the Lambda schematic.** Do not assert the lineage without asking.

**d) Context given to the agent was promoted into the deliverable.** The record-keeping remark is the clearest case. Things Dustin says to explain *why data looks a certain way* are not statements he wants sent to his VP.

**General rule:** the notes in this system are frequently AI-generated analyses of meeting transcripts. They describe problems, objectives and team discussions. They are **not** records of what Dustin personally completed. Attribution requires evidence, not proximity.

---

## 7. Verified numbers available

Safe to cite. Each is traceable to a board card or a note.

| Figure | Source |
| --- | --- |
| AWS Elemental MediaConvert ≈ **4× the cost** of self-orchestrating the pipeline | Nova research card |
| Typical video **3–4 hours**; ~**9 parallel jobs** per file at 30-minute segments | Nova — Leah requirements |
| **~900 jobs/month** over 23 working days ≈ **40 users/day**; hypothetical cap 110 simultaneous | Nova — Leah requirements |
| OMTI **60-second hard query timeout**, non-negotiable, source-side | OJB/ADB notes |
| RB9 connection **offline since May 21** | OJB reconnection strategy note |
| OJB sync batch **10 → 3 items**, then **3 consecutive days zero failures** | Weekly Accomplishments, 2026-06-27 |
| AAE query executes in **3–12 seconds** | DirectQuery evaluation note |
| ADB legacy pattern: full DB refresh **on every user login** | ADB decoupling note |
| PRDV-15776 shipped — Atlas PR **#511**, Callisto PR **#340** | Sprint 11 note |
| Nova first commit **December 2025**; now in **beta** | Dustin |
| 14 named PRDV tickets in 2026 | `2026-sprint-harvest.md` §2 |

Caution on the zero-failures figure: a separate note states that guaranteed zero failures is **not achievable** under the current Power Apps/SharePoint architecture. Both statements are in the data. Present carefully or omit.

---

## 8. Open questions for Dustin

Unresolved. Several block accurate claims.

1. **Hubble/OCR duration** — he estimated "about a year prior" but was unsure; board data suggests ~2 years (from 2024-07). Which is right?
2. **The group name in the requirements work** (§3) — unclear in audio, never confirmed.
3. **Nova vs. Rhea** — the Nova board carries both names. Which does Jim recognize?
4. **Hubble vs. "the OCR project"** — which name will Jim recognize on first mention?
5. **His actual role in the ADB/OJB recovery** — needs his own account, given §6a and §6b. What did he personally do versus plan or participate in?
6. **Xavier and Karl** — both appear throughout the boards, neither is on his People board. Distinct people? Correctly credited?
7. **Derrick vs. Derek** — sprint cards say Derrick; his People board says Derek.
8. **Christina** — appears in an escalation path. Include as a stakeholder?
9. **Advancement ask** — how directly does he want the promotion/compensation ambition stated to Jim? He wants it raised; the framing is his call.

---

## 9. Recommended next step

1. Confirm the §8 questions with Dustin — particularly #5, since the ADB/OJB material is the largest block of unverified attribution.
2. Produce a **claim sheet**, not prose: each candidate accomplishment, the source text, who else was involved, and whether it is confirmed / plan-only / team work. Let Dustin select.
3. Only then draft the message — **from his dictation**, or as neutral bullet points he can rewrite. Do not compose in his voice.
4. Keep it to Jim's three questions.
5. Remind him to calendar the discussion for the week of Aug 10–14.
