# Investigation Report: Dependency-topology view on the Kanban board

> **What this is:** the delivered results of running the `investigate` method — findings and recommendation, plus the plan for what happens next. Use it as the shared reference for future discussions and decisions.
> **What this is not:** a plan *to* investigate. By the time this report exists, the investigating is done.

## Metadata
- **Status:** planned
- **Disposition:** proceed with conditions
- **Date:** 2026-07-08
- **Owner:** <you — set name>
- **Location:** `docs/investigations/001-dependency-topology-view.md`
- **Ticket:** <link on your Kanban board>
- **Domain:** software (feature on an existing custom Kanban board)
- **References / evidence:** existing custom Kanban board (system of record; multi-board / column / task / subnote; render/refresh function with queryable API); prior use of ClickUp dependency links (refuting evidence); this investigation transcript

---

## 0. Verdict (bottom line up front — written last, read first)
Proceed with conditions. This is **not a product and not a bend-vs-adopt decision** — it is a **new render mode (feature) on the Kanban board you already own.** The data, ticket identity, status, and refresh/API all already exist, which retires the single highest-risk assumption (freshness) before it can sink the effort. What is genuinely new is one thing: a **canvas where architecture elements are nodes and tickets are associated by pointing at them** — the pointing gesture *is* the dependency, the layout *is* the topology, and status is inherited from the board on render. Third-party canvases (Miro/Lucid/ClickUp map) are rejected not on features but on principle: routing your own data through a foreign tool to read it back re-introduces the two-sources-of-truth problem you already designed out.

- **Strongest path:** Build the topology layer as a render mode over the existing board. Architecture node placement + ticket-pointing is the authoring surface; the graph (count / fan-out / depth) is the read; status inherited by reference.
- **Not yet proven / not approved:** (1) That spatial node-placement upkeep stays cheaper than the payoff over time — the classic death of every dependency system. (2) That the tool changes *behavior* (acting on leverage), not just *diagnosis* (seeing it). (3) Stale-reference visible-fail behavior is specified but unbuilt. This is a validated direction, **not** a built or proven feature.

## 1. Problem class
- **Class the request assumed:** a **tooling gap** — "no product marries a kanban board with an architecture canvas."
- **Confirmed class:** **traceability** — specifically, *dependency-topology visualization derived from link data*, where both the *authoring* and the *reading* of that data must be spatial.
- **Reframed?** Yes, **twice**:
  - **Reframe 1 (Step 4, root cause):** assumed "ticket↔architecture tooling gap" → "durable link primitive." The convening instance (a day lost to a low-leverage task while a base skill silently gated others) evidenced *dependency/gating invisibility between work items*, not ticket-to-component invisibility.
  - **Reframe 2 (Step 5, refutation):** "link primitive" → "**spatial rendering of existing dependency data**." Refuted by direct evidence: the primitive already exists (ClickUp dependency links, in real use) and does **not** help. The gap is not missing data; it is data with no legible topology at the decision moment.
  - **Late unification (final turn):** the architecture view — earlier demoted to "a later lens" — returned as **load-bearing**, because spatial ticket→component pointing is the *authoring mechanism* that avoids blind ticket→ticket linking. Authoring and visualization collapse into one gesture.
- **What the confirmed class implies:** the deliverable is a *view/authoring surface over existing board data*, not a new store, not a new tracker, not a third-party integration.

## 2. Problem statement (the raw facts)
- **Named instances:**
  - **Convening instance (confirmed):** Yesterday, a full day spent compiling an organization/framework piece that gated nothing, while a basic skill was the actual unblocker for other projects — and nothing on the skill's surface (just an item in an epic) made its leverage visible. Bites immediately: a deliverable is due the next day.
  - **Recurring instance (confirmed):** This morning — sprint planning with the architecture-holder(s) potentially out; the team would be "shooting in the dark" on what to pull next without the PM/principal dev in the room.
- **One sentence:** *Dependency data exists on the board but has no legible topology at the moment of decision, so priority collapses to whoever holds the architecture in their head — and when that person is absent, the team reconstructs it by hand in a meeting.*
- **Distinct problems (kept separate):**
  1. Prioritization / attention (rabbit-hole; buried blocker) — **confirmed, convening.**
  2. Ticket↔architecture spatial traceability — **now the authoring surface** for #1.
  3. Progress / resumption context (where we left off; body of work an epic has chewed through) — real (meeting churn), in scope as a later lens of the same graph.
  4. Knowledge management / discoverability (wiki agent, RTFM) — **separate class, NON-GOAL.**
- **Urgency:** Bites on the next occasion the architecture-holder is absent during planning or mid-sprint re-planning — i.e. now, recurring per sprint.
- **Wedge (final form):** a canvas where architecture elements are nodes and tickets are associated by pointing at them — association *is* the dependency, layout *is* the topology, status inherited on render. Reusable because the same graph serves three lenses (dependency now / architecture / progress-over-time) with different node types and time filters.

## 3. The contract (locked before solutioning)
### Acceptance criteria
| Criterion | Status | What's needed to close it |
|-----------|--------|---------------------------|
| **Bus test:** with the architecture-holder absent, a dev sees unaided what to pull next and what it unblocks — without a reconstruction meeting | needs-proof | Stage the absence; observe whether the meeting is avoided |
| **Freshness:** inherited status is current on render | covered (directionally) | Already handled by existing render/refresh + API; confirm parity in graph mode |
| **Visible-fail:** a node whose source ticket no longer resolves fails visibly, never shows stale-but-plausible status | gap | Specify + build broken-reference detection and display |
| **Topology legibility:** count (fan-in), fan-out, and path depth readable at a glance | needs-proof | Build render; test the three reads against a real board |
| **Authoring cost:** creating links via pointing stays folded into thinking already being done, not a separate chore | needs-proof | Measure upkeep drift over several sprints |

### Non-goals / out of scope
- **Knowledge management** (wiki-reading AI agent) — separate class, separate solution already in flight.
- **Gantt / temporal axis** — re-merges the temporal/spatial split this whole investigation separated; later follow-up.
- **Sprint-planning replacement** — this is the *fallback when the plan and its authors diverge*, not the happy path. A well-run sprint board already covers the happy path.
- **Decorative architecture modeling** (pretty C4 for its own sake) — only the *minimum* architecture representation needed as pointing targets is in scope.

## 4. What changed since the request was created
- **Shifted from:** "find/build a tool that marries a Kanban board with a Lucid-style architecture diagram" → **to:** "add a render mode to the board I own, where spatial ticket→component pointing authors dependencies and the graph makes topology legible when the plan's authors aren't in the room." *(Class changed — see Section 1, two reframes.)*
- **What that buys us:** collapses product→feature; dissolves bend-vs-build; retires freshness via existing infra; makes authoring a byproduct of positioning rather than a blind linking tax.
- **What it still needs to prove:** node-placement upkeep economics; behavior change vs. mere diagnosis; visible-fail correctness.

## 5. Why it exists
- **Origin traced to:** dependency data represented as tags/lists forces the reader to reconstruct the graph mentally at every decision — *and* forces the author to declare links blind. Same root cause on both ends: no spatial representation at either authoring or reading time.
- **Evidence:** ClickUp dependency links exist and are used, yet do not help — a falsifiable claim that met its refutation. The convening instance shows the reconstruction cost concretely.
- **Class re-check:** flipped twice (Section 1), then unified. Wedge and acceptance criteria were redone after each flip, as the method requires.

## 6. Alternatives considered
| Alternative | Rejected because |
|-------------|------------------|
| Miro + live Jira/board cards | Exports your own data to a foreign tool to read it back; re-introduces two sources of truth you already designed out |
| Lucid data-overlay / pointers | Same two-sources problem; authoring still lives away from the board of record |
| ClickUp native dependency links + its map view | The refuting evidence itself — links exist, don't help; list/tag authoring is blind |
| Build the link primitive first (earlier wedge) | Refuted — primitive already exists and is insufficient |
| Ticket→ticket "blocks/unblocked" API in the board | Authoring blind; process-as-purpose; hasn't proven its worth — the exact reason it was never built |
| Full architecture modeler (C4 etc.) | Overreach; only minimum pointing-target representation is needed |

## 7. Solution & stress-test
- **Proposed solution:** A graph render mode on the existing board. Architecture elements are placed as nodes; tickets are associated by pointing at them (Lucid-style). Association creates the dependency; layout is the topology; status/history/epic-membership are **inherited by reference** from the board on render (never edited in the view). Toggle active / completed. One board → many views.
- **Solves the confirmed class?** Yes — it makes both authoring and reading of dependency topology spatial, which is the confirmed class, not just the convening occurrence.
- **Scale:** Discoverability is the driver; scale is the amplifier. The reconstruction cost bites at ~20 tickets, not only at 2000. Render must stay legible as node/edge count grows (clustering / filtering will matter).
- **Generalization:** Right-sized. One graph, three lenses (dependency / architecture / progress). Not abstracted beyond that; decorative modeling explicitly excluded.
- **Fit:** Strong — it is a feature of the board you own, reusing its data model, identity, and refresh. No foreign conventions imported.
- **Adjacent issues:** Knowledge-management and Gantt surfaced and were spun off as non-goals rather than absorbed.
- **Sufficiency:** Partial *by design and honestly stated* — it makes the leverage move **visible** (fixes diagnosis); it does **not enforce** acting on it (does not fix discipline). Over-claiming here is the easy mistake.
- **Feedback speed:** Fast — the very next planning session with the architecture-holder absent tells you whether the reconstruction meeting was avoided.
- **Happy-path story (30s):** Tomorrow, principal dev is out. Three devs switch the board to graph view. They see one node — the base skill — with four arrows fanning out to blocked work, and yesterday's org-compile sitting off to the side gating nothing. No reconstruction meeting. One dev pulls the skill; the others queue behind what it unblocks. **The person absent from the story is the principal dev — that absence is the point.**

## 8. Assumptions ledger
- **Claim:** The freshness problem is real and unsolved. — **Status:** revised → largely retired. **Confirm/revise by:** existing render/refresh + queryable API already keep multi-board/column/task/subnote current; confirm parity holds in graph mode.
- **Claim:** The missing primitive is the dependency *link*. — **Status:** refuted. **Confirm/revise by:** ClickUp links exist and don't help.
- **Claim:** The architecture view is a *later* lens, not core. — **Status:** refuted. **Confirm/revise by:** it is the authoring surface that avoids blind linking.
- **Claim:** Spatial node placement stays cheaper than its payoff over time. — **Status:** open (highest risk). **Confirm/revise by:** measure upkeep drift across several sprints; watch for the point placement lags reality.
- **Claim:** Making leverage visible changes behavior. — **Status:** open. **Confirm/revise by:** does the rabbit-hole rate actually drop, or is it seen-and-ignored?
- **Claim:** A confidently-wrong graph is worse than none. — **Status:** confirmed (principle). **Confirm/revise by:** enforced via visible-fail negative path.

## 9. Validation plan
**Happy path**
1. Place architecture nodes for a real epic.
2. Point its tickets at the nodes (association = dependency).
3. Open graph view; confirm status inherited correctly from the board on render.
4. Read fan-in (what's most gated), fan-out (what unblocks most), depth (buried blockers) at a glance.
5. Toggle completed on/off; confirm the "body of work chewed through" is visible.
6. Stage the bus test: architecture-holder absent, team pulls next work unaided, no reconstruction meeting.

**Negative paths**
- Source ticket deleted/reparented → its node **fails visibly** (flagged), never shows stale-but-plausible status.
- Node/edge volume grows → render stays legible (degrades gracefully, not into hairball).
- Refresh latency bound holds so "current on render" is true in practice, not just in theory.
- Placement upkeep lagging reality must be **detectable** (e.g. tickets with no node), not silently rot.

## 10. Decisions, recommendation & open variables
- **Decisions:** Board = system of record. View = derived, read-only for status. Nodes carry intrinsic topology (links + layout); inherit status by reference. Architecture node + ticket-pointing = the authoring gesture. No ticket→ticket "blocks" API. Non-goals: KM, Gantt, sprint replacement, decorative modeling.
- **Recommendation (in order):** (1) Spec the node/edge data model + visible-fail behavior. (2) Build minimal graph render reading board status via existing API. (3) Build spatial pointing authoring. (4) Add count/fan-out/depth reads. (5) Add active/completed toggle. (6) Stage the bus test.
- **Sequencing & gates:** Do not expand to the architecture lens or progress-over-time lens until the dependency lens passes the bus test once. Do not add any temporal/Gantt work until the spatial view has proven upkeep economics over ≥2 sprints.

### Open variables to collect
- [ ] Node-placement upkeep economics (highest-risk) — owner: <you>
- [x] Stale/broken-reference visible-fail spec — closed 2026-07-08: epic [002](./002-topology-view-epic.md) decision 13 + story [007](./007-story-5-reads-filters-visible-fail.md)
- [ ] Behavior-change measure (does rabbit-hole rate drop?) — owner: <you>
- [ ] Legibility strategy at scale (clustering/filtering thresholds) — owner: <you>
- [x] Minimum viable architecture-node representation — closed 2026-07-08: title + color + groups + position/size, notes via event-notes; no C4/types/descriptions (epic [002](./002-topology-view-epic.md) decisions 9–10)

---

## 11. Plan — Next steps
### Handoff table
| Action | Owner | Done-when (falsifiable) |
|--------|-------|-------------------------|
| Spec data model + visible-fail | <you> | ✅ Done 2026-07-08 — [002-topology-view-epic.md](./002-topology-view-epic.md) + stories [003](./003-story-1-data-model-and-api.md)–[008](./008-story-6-node-notes.md); broken-reference rendering defined in [007](./007-story-5-reads-filters-visible-fail.md) |
| Minimal graph render over board API | <you> | Opening graph view shows real tickets with status matching the board within one refresh |
| Spatial pointing authoring | <you> | A ticket dragged to an architecture node creates a persisted dependency with no separate "blocks" click |
| Topology reads (count/fan-out/depth) | <you> | Given a real epic, the most-gated and most-unblocking nodes are identifiable in <5s by someone without the mental model |
| Stage the bus test | <you> | One planning session runs with the architecture-holder absent and no reconstruction meeting occurs |

### Checklist
#### Investigation
- [x] This report (Sections 0–10)

#### Project Spec
- [x] Draft open questions / unknowns (grill-me session 2026-07-08 — all design branches resolved; decisions recorded in [002-topology-view-epic.md](./002-topology-view-epic.md) §3)
- [x] Create project spec (epic [002](./002-topology-view-epic.md) + stories [003](./003-story-1-data-model-and-api.md), [004](./004-story-2-canvas-shell.md), [005](./005-story-3-nodes-and-wires.md), [006](./006-story-4-card-placement-and-parity.md), [007](./007-story-5-reads-filters-visible-fail.md), [008](./008-story-6-node-notes.md))

#### Development
- [ ] Create new branch
- [ ] Begin implementation

#### Testing & Validation
- [ ] Test and validate implementation locally

#### Deploy & PR
- [ ] Push to GitHub
- [ ] Deploy to sandbox + verify there
- [ ] Open PR
- [ ] Address feedback / wait for approval
- [ ] Merge to main
- [ ] Deploy to test

#### Ticket Closeout
- [ ] Update board: merged to test
- [ ] Set ticket to Ready for QA
- [ ] (If bug) Document root cause / why it slipped through

---

## 12. Definition of done (investigation gate)
- [x] Class derived from instances, re-confirmed against root cause; "reframed?" answered (yes, twice — Section 1)
- [x] Problem in one plain sentence
- [x] Named blocked instance (yesterday's lost day; this morning's shooting-in-the-dark)
- [x] Date it bites next (next architecture-holder absence; recurring per sprint)
- [x] Wedge + why it's reusable within the confirmed class
- [x] Acceptance criteria + non-goals locked before the solution
- [x] Alternatives recorded with rejection reasons
- [x] 30-second happy-path story
- [x] Metric that proves it works + how fast it arrives (bus test; next planning session)
- [x] Verdict + disposition stated (proceed with conditions)
- [x] Open variables each have an owner
- [x] Tracked action with a falsifiable done-when
