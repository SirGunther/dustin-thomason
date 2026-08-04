---
name: job-story
description: Turn a feature request or ticket into a job story — a structured user story plus acceptance criteria, built through a matrix sequence that strips solution-speak and unobservable outcomes before emitting. Produces a referenceable artifact the finished work gets held against. Use when the user says "job story", "write the story", "turn this into a story", "acceptance criteria for this ticket", or asks to define what done means for a request.
---

# Job story

Turn a request into the yardstick the finished work gets measured against: a **User Story** and **Acceptance Criteria**, arrived at through a fixed matrix sequence that catches solution-speak, emotional abstraction, and non-observable outcomes before anything is emitted.

The matrices are not scaffolding — they are the record showing what was caught and named. Keep them in the artifact.

## Boundary — what this owns

| This skill | `write-spec` |
| --- | --- |
| The yardstick — what the built thing gets held against | The blueprint — classes, entities, migrations, how it gets built |
| Written first, independently | Written after, informed by the story |
| Owns acceptance criteria | Cites the story's acceptance criteria; does not restate or amend them |

When a ticket arrives with its own acceptance criteria, those are **input**, not output — they get read, then rebuilt through the sequence below.

## Invocation and inputs

Resolve the target in this order:

1. **`PRDV-XXXXX` id** → `<Project>` is the system per the `ticket-changelog` rule.
2. **Project + slug** (e.g. "job story for WorkLists duplicate-card-option") → `docs/<Project>/tickets/<slug>/`.
3. **Free brief, no id** → derive `<slug>` from the brief (kebab-case, at most six words); ask once for `<Project>` if it is not inferable from the working directory or branch.
4. **Nothing** → ask exactly one question: "Paste the request text (or id) and name the project." Never synthesize a request into existence.

**The request text is required.** It is the source artifact; without it, stop and ask (per the `source-truth` rule).

## Artifact layout

Stories live in the canonical ticket folder, rooted at **`C:\dustin-thomason\docs\<Project>\tickets\<slug>\`** — the same folder `orchestrate` uses, so a story written standalone is already in place if the ticket is orchestrated later. Every artifact stays in `dustin-thomason` regardless of where the implementation code lives.

```text
docs/<Project>/tickets/<slug>/
  original-ticket.md                              the request verbatim — reuse if present, create if not
  stories/
    <slug>-job-stories-index.md                   the table of contents — every story, always current
    <slug>-job-story-01-<short>.md                one file per story
    <slug>-job-story-talking-points.md            optional, on request
  dnu/                                            superseded stories move here, names unchanged
```

- **`original-ticket.md`** — if it already exists, cite it and never rewrite its Original Request. If it does not, create it per `../../docs/original-ticket-artifact.md` before writing any story. There is exactly one verbatim capture per ticket.
- **One file per story**, numbered in creation order, `<short>` being two or three words naming the story's subject.
- **Superseded stories move to `dnu/`** — never deleted, never renamed, never edited in place after acceptance.

### The index

`<slug>-job-stories-index.md` is written or updated **every time a story file is created or its status changes** — the point of the artifact is that later work can reach it without opening each file.

```markdown
# Job stories — <Project>/<slug>

Source: [original-ticket.md](../original-ticket.md)

| # | Story | User type | Criteria | Open questions | Status | File |
| --- | --- | --- | --- | --- | --- | --- |
| 01 | <short title> | <user type> | <count> | <count> | draft | [file](./<slug>-job-story-01-<short>.md) |
```

Status vocabulary: `draft` / `accepted` / `superseded (see dnu/)`.

## Synthesize the request into evidence

This step is the skill's own work, not a read of someone else's findings. Work the request text directly, and for each thing the story will claim, hold two pieces together: **the question it answers**, and **the reason for believing it**. That pairing is the story's evidence — it is what makes a criterion defensible when the finished work is held against it months later.

Where the request leaves something undecided, it becomes an **Open Question** on the story. Carry it; do not decide it by inference. If the answer is discoverable in the code, trace it and resolve it from evidence.

When the request bundles two or more distinct problems, write **a story for each**. A compound motivation is the signal to split.

### Relationship to Problem Check

`../../docs/problem-check.md` audits a request's framing and surfaces *questions that might get asked*. This skill **synthesizes** — it commits to what the story is and why it is believed. They are peers, not stages:

- **Neither is a prerequisite.** A story can be written before any investigation exists; Problem Check can run on a request that has no story.
- **When both exist, each must be updated when the other moves.** A Problem Check flag landing after a story is written is a revisit trigger; a story that splits or changes user type means the framing read is stale.
- **On acceptance criteria, this skill is authoritative.** Problem Check informs the story; it does not define what done means.

Under orchestration, the phases that revisit each artifact — and the gate at each one — are wired into `../orchestrate/SKILL.md`.

## The sequence

Work these in order; each consumes the prior output. One concise sentence per row and per bullet throughout.

### 1. Story Matrix

Columns: **Component** | **Framework Language** | **Story Sentence**. Fill in this order, using these templates exactly:

| Component | Framework Language |
| --- | --- |
| Motivation | *A [user type] doesn't want [undesired outcome].* |
| Context + Intent | *While [context], they want to [action].* |
| Obstacle + Desired Action | *Except that [obstacle], so they want to [action to rectify].* |
| Resolution | *Now they'll be able to [positive outcome].* |

### 2. Revision Matrix

The story must be **agnostic to system design**. No design words — filter, button, view, dropdown, grid, column, screen, page, modal, endpoint, field. Sentences carry only user motivation, context, and desired outcome.

Always revise the **Obstacle + Desired Action** row; add a row for any other component that carried design words. Show before, the named issue, and after.

### 3. Delivery Acceptance Statement (DAS)

A checklist, as many deliverables as the story needs, beginning with this line verbatim:

> *We know this story is considered complete when:*
> - [Deliverable]
> - [Deliverable]

### 4. Concatenated Story

The sentences from the **final (revised)** matrix, run together as a natural paragraph.

### 5. Final Review Matrix

Columns: **Original Sentence** | **Issue/Observation** | **Refined Sentence**. One row for **every** story sentence and **every** DAS line.

Name the issue explicitly, from these:

| Issue | Fix |
| --- | --- |
| Vague phrasing | Replace with specific language. |
| Emotional abstraction ("feel confident") | Replace with an observable outcome. |
| Solution-speak (buttons, filters, screens) | Replace with user-outcome wording. |
| Non-observable outcome | Replace with a measurable or clearly knowable result. |
| Wordiness | Replace with a concise sentence. |

Use **everyday experiential phrasing** — check, grab, look, scroll, tap, spot, pull up — over abstract or formal register (monitor, utilize, engage in, interact with).

Each refined sentence must be one thought, expressed as motivation, context, or outcome, and verifiable — someone could confirm it happened.

### 6. User Story

The refinements applied, in the same four-component sequence, written as a **natural story paragraph**. Heading is exactly **User Story** — no qualifier, no subheading.

### 7. Acceptance Criteria

The refined DAS lines, **omitting** the phrase "We know this story is considered complete when:". Heading is exactly **Acceptance Criteria** — no qualifier, no subheading.

## Output

Emit all seven in order, in chat and in the story file:

**Matrix** → **Revision Matrix** → **Delivery Acceptance Statement (DAS)** → **Concatenated Story** → **Final Review Matrix** → **User Story** → **Acceptance Criteria**

The story file adds a header (ticket, project, date, link to `original-ticket.md`), then after the criteria: an **Open Questions** section, and a **Story log** — newest first, one entry per phase or session in which the story moved, each labeled with what changed. Then update the index.

Close by telling the user a **talking points list** is available on request.

## Talking points (on request)

Draw only on what the story and its matrices already established — grouped for **UI/UX**, **Backend**, and **Frontend**, one concise line per point, naming what each discipline has to decide or account for. Write to `stories/<slug>-job-story-talking-points.md`. Never introduce a requirement here that is not traceable to a criterion or an open question.

## Revisit

A story is a living artifact: `draft` while anything can still move it, `accepted` once its open questions close. Any of these re-opens it, and the trigger names itself in the Story log.

| Trigger | Action |
| --- | --- |
| An open question gets answered | Fold the answer into the affected criterion; close the question. |
| A decision contradicts a criterion | The decision wins on *how*; the criterion still owns *what done means* — rewrite it to stay observable. |
| A plan step traces to no criterion | Either a criterion is missing or the step is out of scope; record which. |
| A criterion proves unobservable in practice | It failed its own Final Review Matrix row — rewrite it, and never reinterpret it to match what was built. |
| A second distinct problem surfaces late | Split it into a new story; the original keeps its number. |
| The user type turns out wrong | Re-run the sequence from Motivation — every row below it is invalid. |

**While `draft`:** revise in place and log it. **Once `accepted`:** move the file to `dnu/` unchanged, write the next version, and point the index row at it with the supersession noted.

## Inside orchestration

`orchestrate` owns the enforcement — the phase that drafts the stories, the phases that revisit them, and the gate evidence at each one are all defined in `../orchestrate/SKILL.md`. In outline: drafted at **Phase 0** from the verbatim request, revised through **Phases 1–2** as the investigation surfaces answers, **accepted at Phase 3**, then used as the yardstick by the spec, the test plan, and the Phase 6 review.

## Do not

- Do not write a story without the request text in hand.
- Do not treat Problem Check (or any investigation artifact) as a prerequisite for a story, or as the authority on its acceptance criteria.
- Do not let a story change without a **Story log** entry naming what moved.
- Do not answer an open question by inference — carry it, or resolve it from code evidence.
- Do not let design words survive into the final story.
- Do not fold two conflated problems into one story.
- Do not edit an accepted story in place — move it to `dnu/` and write a new one.
- Do not rewrite `original-ticket.md`'s Original Request, ever.
- Do not create a story file without updating the index in the same pass.
- Do not put a story anywhere except `docs/<Project>/tickets/<slug>/stories/`, even when the code lives in another repo.
- Do not deviate from the **User Story** and **Acceptance Criteria** headings, or from the four-component sequence inside the story paragraph.
