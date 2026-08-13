# Job stories — atlas/PRDV-16313

Source: [PRDV-16313-original-ticket.md](../PRDV-16313-original-ticket.md) (ClickUp capture, 2026-08-11 — **pointer only**, see below)

Authority on scope, **read at Phase 1**: `larry-adams/systems/neptune/callisto/granting-client-acess/epic-PRDV-15736-make-atlas-metadata-available-to-planet-portal/PRDV-16313-endpoint-file-renamed.md` and its design reference `dione-file-access-event-design.md`.

| # | Story | User type | Criteria | Open questions | Status | File |
| --- | --- | --- | --- | --- | --- | --- |
| 01 | The client sees the name the file actually has now | **Client (Planet Portal)** | 6 (all revised at Phase 3) | 1 carried (owner named) | **`accepted`** | [file](./PRDV-16313-job-story-01-client-sees-current-filename.md) |
| 02 | Names given to internal files stay internal | **Ops user working a proceeding** | 5 (unchanged) | 1 carried (owner named) | **`accepted`** | [file](./PRDV-16313-job-story-02-internal-renames-stay-internal.md) |

Status vocabulary: `draft` / `accepted` / `superseded (see dnu/)`.

Accepted at Phase 3 on 2026-08-11. Decisions: [PRDV-16313-locked-decisions.md](../specs/PRDV-16313-locked-decisions.md).

**Both user types confirmed as drafted** (LD-015) — story 01's is the client, story 02's the ops user. Neither story needed re-running from Motivation.

**Both accepted with one open question each, deliberately.** `01.Q3` (does Dione re-read the name from any other source?) and `02.Q2` (what does the client's side do with an event for a file it has no record of?) are **both Dione's**, and both carry structural proof that Callisto cannot answer them: the consumer is not in this workspace, and the RabbitMQ descope removed the observation step. Holding either story in `draft` on another team's behalf would have blocked the spec on their epic.

**Six criteria changed in story 01; none in story 02.** That asymmetry is the most useful thing on this page. Story 02's criteria were written about **what Callisto does at its own boundary** — entirely inside this ticket's observable range. Story 01's were written about **what a client sees**, which nothing in this repo can witness. Same drafting discipline, and only one of the two survived contact with the scope.

**Story 01's rewrite was scope-following, not build-following — and the ordering is the whole defence.** Two decisions bounded the scope *before any code existed*: the epic owner's RabbitMQ descope (upstream `318bd0a`), which removed the only path to observing a client's view, and the user's ruling that the AJSF rename route is out of scope (LD-014). The criteria then followed a scope that had already moved. Nothing is implemented yet. Per-criterion reasoning is in story 01's Story log; the risk that this reads as reinterpretation is recorded as concern **C9**.

## What the accepted criteria knowingly do not claim

Recorded here rather than left for a reader to notice.

| Shortfall | Why | Where it lives |
| --- | --- | --- |
| **That the client sees anything.** This ticket proves the *producer* correct and asserts nothing about the client's view. | RabbitMQ descoped epic-wide; Dione's consumer is another team's. A payload that is correctly *shaped* but semantically wrong would pass every test here. | C9 — with a follow-up to walk story 01's original criteria 1–4 against real client behaviour once Dione consumes |
| **That every rename of a deliverable is covered.** The AJSF route renames deliverables with no user, no validator, no audit, and no event. | User ruling on workflow grounds: a submitted client deliverable has no legitimate reason to be renamed there. Named in criterion 1's scope rather than hidden by vagueness. | C1 · LD-014 |
| **Any latency bound.** No criterion states how fast the record must go out. | Design Q18 already accepts seconds-scale eventual consistency; a stated bound would create a target nobody measures. | C9 · LD-016 |

## Phase 1 reconcile — what closed

**Eight of the original fifteen closed, all against code or repo evidence, none by decision or inference.**

## Phase 1 reconcile — what closed

**Eight of the original fifteen closed, all against code or repo evidence, none by decision or inference.**

| Closed | How |
| --- | --- |
| `01.Q4` endpoint mutates only the name | `updateFileName:133-138` writes `file_name` + `updated_at`, nothing else |
| `01.Q5` payload sufficiency | Contract is five non-nullable fields; the new name is recoverable |
| `01.Q6` prerequisite merged | PRDV-16293 in PR #399 (`43ad3dea`), ancestor of the working branch |
| `01.Q8` no-op rename | The code already treats it as a non-event — early return, no `UPDATE` |
| `01.Q9` other rename surfaces | **Four surfaces, three sharing one transaction script.** Forced a finding, see below |
| `02.Q3` is the tag the sole condition | Yes, and already enforced by `ProceedingFileMustBeDeliverableValidator` since PRDV-15776 |
| `02.Q4` tag availability at the rename site | Not on the entity (no inverse relation), but already computed **twice** per request — no new read needed |
| `02.Q5` tag lifecycle | Mutable both ways, asymmetrically; status must be read at rename time, never cached |

**Sharpened rather than closed at Phase 1, then all closed at Phase 3:** `01.Q2` (→ LD-017), `01.Q3` (→ carried to Dione), `02.Q6` (→ LD-010, fail closed).

## Phase 3 reconcile — five more closed, three by evidence before any question reached the user

`P3.reconcile` re-ran the fact-vs-decision split before grilling. **Three candidate questions never reached the user** because the evidence answered them — the full gate table is in the [locked decisions](../specs/PRDV-16313-locked-decisions.md).

| Closed | How |
| --- | --- |
| `01.Q1` | **Client** — grilled (LD-015) |
| `02.Q1` | **Ops user** — grilled (LD-015) |
| `01.Q2` | Nowhere is observable here; criteria restated instead — LD-017 |
| `01.Q7` | Nothing states the latency — LD-016. The question was mis-framed as UX; it was really "does criterion 5 need a time bound?" |
| `02.Q6` | **Fail closed** — LD-010. Reduced to a narrower question first: evidence showed the house precedent is unambiguously fail-closed (no try/catch in the shipped producer, zero catch blocks in either outbox tree), so the user was asked "deviate or match?" rather than "what should happen?" |

## Story 02's premise was pointed at the wrong endpoint — and the worry was still real

Worth stating plainly since it would otherwise look like the story was drafted in error. The request justifies its tag guard with *"the rename endpoint may serve non-deliverable files as well."* It does not — that endpoint has 403'd non-deliverables since commit `4d284978`. So story 02 criterion 1 holds structurally at this endpoint before any code is written.

The story survives intact anyway: criterion 2 (the inverse — a deliverable rename still sends) is what catches the cheap wrong fix of suppressing everything, and `01.Q9` found the boundary genuinely *is* violable, just via the AJSF route the request never mentions. The underlying concern was correct; only its location was wrong.

## The ClickUp text is a pointer, not the spec — confirmed, and the wiki has its own defects

Verified at Phase 1: the wiki spec's acceptance criteria are **identical** to the ClickUp text, so unlike the sibling ticket there is no criteria-level conflict to resolve. But the wiki's **Technical Design** section is wrong on three counts — its named emit site does not exist, it is silent on atomicity, and it is silent on the deterministic event id whose collision is a silent overwrite. Details in [the investigation report](../investigations/PRDV-16313-investigation.md) §2 and the [why doc](../PRDV-16313-why-these-changes.md).

The `## Wiki` path printed in the ClickUp ticket is also dead — `emit-grant-events/` was renamed; the resolved path is at the top of this file.

A talking points list (UI/UX, Backend, Frontend) is available on request.

## Why two stories

The request states **one** motivation — *"Dione uses this to keep the displayed filename in sync with Callisto"* — so this split is a judgement rather than a compound motivation read off the page, and it is recorded as one.

It splits because the two outcomes **fail independently**:

| Failure | Story 01 | Story 02 |
| --- | --- | --- |
| The rename never reaches the client | ✗ violated | ✓ satisfied |
| An internal file's name reaches the client | ✓ satisfied | ✗ violated |
| Every rename is suppressed | ✓ vacuously | ✗ violated (criterion 2) |

A single story covering both could be reported complete while either half was broken. The third row is the one that matters most: the cheapest way to satisfy "don't leak internal names" is to emit nothing at all, and only a separate criterion catches that.

They also have **different user types** — the client reads a name (01); the ops user's own file names are what is at stake (02). Neither user type is stated in the request; both are carried as that story's first open question, and if either resolves the other way, that story is re-run from Motivation.

## The ticket's own acceptance criteria are input, not output

The request carries four criteria. All four describe **mechanism**:

| Request criterion | Why it is not carried across as a story criterion |
| --- | --- |
| An outbox row is written with routekey `callisto.client-access.file.renamed.v1` | Names the transport and the routekey. Says nothing about what anyone experiences. |
| Payload matches `CallistoClientAccessFileRenamedV1Data` | A type-conformance check, and the type's shape is not in the request. |
| Only emitted for files with the `CLIENT_DELIVERABLE` tag | The boundary condition — reframed as story 02, whose criterion 3 keeps the *outcome* and drops the tag name. |
| Unit tests prove outbox write occurs with correct payload | A test obligation, not a definition of done. Reframed as story 01 criterion 6 / story 02 criterion 5: after a real rename, can someone check what was sent. |

They are constraints the spec must satisfy. They are not the yardstick — the stories are.

## The ClickUp text is a pointer, not the spec

Established on the sibling ticket, carried here as a starting assumption to **verify at Phase 1, not to trust**: design doc Q25 records the convention *"ClickUp stays wiki-pointer."* PRDV-16312 took the ClickUp description as the specification and reached a wrong disposition on half that ticket before the wiki spec was read.

Two consequences for these stories:

1. **Every criterion above may move once the wiki spec is read.** In particular story 01's criteria 1–4 are written as client-observable, and the epic's RabbitMQ descope may mean the client-visible half is not provable within this ticket at all (`01.Q2`). PRDV-16312 had to reword a criterion in each of its two stories for exactly this reason.
2. **The `## Wiki` path printed in the ClickUp ticket is dead.** The `emit-grant-events/` folder was renamed to `epic-PRDV-15736-make-atlas-metadata-available-to-planet-portal/`; the resolved path is at the top of this file. The stale path is preserved verbatim in the original ticket and the changelog.

## Open questions at a glance

15 carried, none answered by inference. Their disposition is what Phases 1 and 3 are for:

| Resolvable how | Questions |
| --- | --- |
| **Code / repo evidence** (Phase 1 — the agent's job, not the user's) | `01.Q3` `01.Q4` `01.Q5` `01.Q6` `01.Q9` `02.Q3` `02.Q4` `02.Q5` |
| **Wiki spec / design doc** (Phase 1) | `01.Q2` `01.Q7` `02.Q2` (consumer-side; may not be answerable in Callisto at all) |
| **Genuine decision** (Phase 3 grill-me) | `01.Q1` `01.Q8` `02.Q1` `02.Q6` |

The two user-type questions — `01.Q1` and `02.Q1` — are the highest-consequence of the fifteen. Either one resolving the other way invalidates every row below Motivation in that story.

A talking points list (UI/UX, Backend, Frontend) is available on request.
