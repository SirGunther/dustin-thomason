# Democratizing Data Access — Transcript Analysis & Recommended Approach

Status: Draft v0.2 — updated after the follow-up meeting (2026-07-06). The "Where this landed" section is new; the Problem Check and analysis below it cover the first (06/24) discussion and are retained as the record.
Prepared: 2026-07-06 (v0.1 pre-meeting, v0.2 post-meeting)
Scope: Analysis of the Jim discussions (06/24 and 07/06/2026) on data access — the landed wedge, trackable actions, and a recommended approach to reduce friction in data access while preserving security, governance, and architectural control.

Terminology note: the Otter transcript renders the phrase as "demonetizing access to data" throughout. Confirmed 2026-07-06 that the spoken word was **democratizing**. Evidence quotes below keep the verbatim transcript spelling; the analysis uses "democratize."

---

## In brief

Jim (new VP) and Dustin held an exploratory conversation about moving data access from a gatekeeper-heavy model to a self-service one. Most of the session walked through how access currently works — the PD Projects shared service account, SharePoint security groups and their visibility quirks, Carl's sandbox-admin tiering, and the undocumented reasoning behind existing tables. It ended with agreement that the topic matters, a 45-minute follow-up scheduled, and Dustin tasked to reflect and bring a proposal; no design was committed.

# Where this landed — follow-up meeting, 2026-07-06
---

## Landed (decided or confirmed in the room)

1. **Wedge locked, in Jim's words:** "new engineers and data folks... don't understand the systems and the data that they need to work with. It's not access." Sequencing sealed the same way: "before we can solve access, they need to know what they'd like access to." Data democratization stays the theme; **discovery is the wedge.**
2. **Problem reclassified:** "this is a knowledge management question" — AI/agent-aware knowledge management, not an access-provisioning project.
3. **Solution hypothesis endorsed in the room** ("Am I thinking about this right?" → "You are thinking about this right"): **progressive discovery** — a root agents file ("whatever we can fit in 200 lines"), organized repos each carrying their own agent instructions, routing to systems of record, vendor-neutral ("it's agents dot markdown, not cloud [Claude] dot markdown").
4. **Test case named and imminent:** Jamie's ADB/OJB → Lagrange rewire ("she's like, how, where do I start?").

## Trackable actions

Jim's closer: "if I can turn this into something I can track, I'm much more likely to do it." This table is that artifact. No dates were set in the meeting — owners to confirm dates async this week.

| # | Action | Owner | Done when (falsifiable) |
|---|---|---|---|
| 1 | Break up the larry-adams repo into purpose-scoped repos | Dustin + Larry (taxonomy) | An agent pointed at the root answers "where do I learn about RB9?" without loading everything |
| 2 | Draft the root agents.md — ≤200 lines, vendor-neutral, routing to wikis / flight manual / specs / Lucid ERDs | Larry + Dustin | A fresh agent traverses from it to the right repo on 3 test questions |
| 3 | Check in the LLM wiki ("mine isn't even checked in"); add the Lucid ERD reference | Larry | Everyone can pull it; it is citable from a harness |
| 4 | Write the source-of-record map: Lagrange-temporary / Callisto-forward / what lives where | Larry | Jamie can read, *before building*, which data her rewire can and cannot get from Lagrange |
| 5 | Onboarding doc v1 — cannibalize Carl's Eric doc; personal-repo pattern (the repo forces the GitHub seat) | Dustin + Carl | Exists in a new-hire repo template and links the wikis |
| 6 | Run the Jamie test | Dustin + Jamie | She goes from "where do I start" to path-known — who controls what, what access, which source — from the guide alone |

## Constraint record (highest-value knowledge capture of the meeting)

Stated by Larry, previously written down nowhere:

- "Hooking to Lagrange is sort of a dead end... a temporary solution." No proceedings, no new file data, no case-restriction metrics live in RB9/Lagrange — "all of that comes from Callisto going forward," while the old system is strangled.
- Golden path: **consumers own their data** — their own queues off the integration bus, stitching it their way — so Callisto's data model can change without ripple effects: "we're not supposed to change our contract without talking to the stakeholders down the line." Inbox/outbox patterns already provide the reliability layer.
- Rule to carry into every dataset doc: name **who is the source of record**.

This is trackable action #4. Had it been written down, Jamie's rewire could have aimed at a dead end; it surfaced only because Larry was in the room — the wedge problem demonstrating itself live.

## Container (proposed answer to "is this a project?")

Neither meeting established what kind of effort this is. Recommendation, phrased for a yes/no:

> Run the six actions as a **wedge-scoped effort inside normal work** — the fast lane — not a chartered initiative. **The Jamie test is the graduation gate:** if she gets her path from the guide alone, charter the broader knowledge-management effort into the foundation lane; if she can't, we've learned which gate actually blocks, cheaply, and re-aim.

## Proposed metric

- **Builder-interruptions during Jamie's path** — how many times she still has to ask Larry/Dustin/Carl. Target for the second reader (Chris): ~0.
- **Time from "where do I start" to path-known.** Baseline is the current state: indefinite without a builder in the room.

Both countable this month; neither rewards producing artifacts (anti process-as-purpose).

## Deferred register

The four-way split named in the meeting is the risk list:

| Sub-problem | Status |
|---|---|
| Taxonomy / discoverability | Addressed by the wedge (actions 1–5) |
| Freshness — "keeping it up to date, so it doesn't sprawl and get wrong and horrible" | **Deferred — the known wiki-killer.** Revisit at the graduation gate |
| Cost / efficiency (token spend, model choice) | Deferred; optimize only after the wedge proves value |
| Accessibility for non-tech users | Deferred; parked with the Open WebUI / voice-prototype ideas |

Park list held from the meeting: company-wide agent for Joe, voice/paralegal prototype, token min-maxing, other departments' onboarding. All named, none committed.

## v0.1 open questions — reconciled

| v0.1 question | Status after the meeting |
|---|---|
| Scope of "self-service" v1 | **Answered by the wedge:** discovery first — "before we can solve access, they need to know what they'd like access to" |
| Gateway PoC ownership, joint with Lagrange track | Open — Carl implied ("hey Carl, you're gonna have to build some kind of gateway"), not decided |
| PII stance (v1 vs production-only) | Open — untouched in the follow-up |
| PD Projects account: retire or formalize | Open — untouched |
| First KPIs to baseline | Partially — metric proposed above, not yet agreed with Jim |
| Lead-architect gate criteria/SLA | Open — untouched |

**One watch-out carried forward:** the wedge shifted from "access" to "knowledge management" deliberately — but Jamie's rewire still needs actual gateway/access build regardless of how good the guide is. The guide tells her the path; someone still has to pave it. Two tracks.

---

*The sections below are the v0.1 pre-meeting analysis of the first (06/24) discussion, retained as the record.*

# The question
---

### Asked
|  |  |
|---|---|
| **finding** | Jim frames the problem as democratizing data access: self-service for authorized people, with no per-request setup |
| **evidence** | "strategically critical to our philosophy is demonetizing access to data" |
| **finding** | The stated success condition is that setup ceases to be a step at all |
| **evidence** | "there's no setup required to do it" |

### Answered
|  |  |
|---|---|
| **finding** | The discussion mostly inventories how the current gatekept model works and why its knowledge is tacit, rather than designing the open model |
| **drift** | "how do we democratize access" → "how access currently works, and why it's locked to specific people" |
| **evidence** | "as our lock and key to get in and out" |

### Should-ask
|  |  |
|---|---|
| **finding** | Which gate actually blocks self-service — credentials, knowledge of the data, trust in the person, or the missing AWS→Microsoft path — and in what order do we remove them? |
| **why** | It decides where the proposal aims. The transcript itself establishes that granting credentials alone fails ("even if you gave people that" access, undocumented tables stay unusable), so a proposal that only provisions access is refuted before it starts |

# Flags
---

### Conflation
|  |  |
|---|---|
| **finding** | Four distinct problems are treated as one "access" problem: (1) credential/permission plumbing, (2) undocumented institutional knowledge, (3) trust/vetting of the person, (4) the missing data path from AWS into SharePoint/Power BI |
| **consequence** | Solving plumbing does not touch knowledge — a fully-credentialed user still cannot use a table nobody documented. Each gate needs its own fix, owner, and test; a single "access project" will report done while three gates stay closed |
| **evidence** | "the access to it is is hidden in weird ways" / "there's not easily clear, even if you gave people that" |

### Thin
|  |  |
|---|---|
| **finding** | "Self-service" is undefined — read vs. write, which environments, which datasets, which user tiers |
| **evidence** | "people can self-service data access" (no scope stated anywhere) |
| **finding** | The "trusted gateway" is named as the wish but unspecified — no authentication model, no statement of how PII stays filtered on the way through |
| **evidence** | "I would love there to be a trusted gateway and path" |
| **finding** | KPIs are raised as needing rationalization, but none is defined, and the same conversation warns that metrics work drifts into process-as-purpose |
| **evidence** | "What are actual real measurable KPIs" / "the process becomes the purpose" |
| **finding** | The lead-architect review is asserted as necessary with no criteria — nothing states how it avoids becoming the new single hole |
| **evidence** | "a lead architect needs to review" |

### Off
|  |  |
|---|---|
| **finding** | The proven pattern offered in the room is the pattern the goal rejects: the PD Projects account is a shared admin identity behind one static, unrotated password — a single hole |
| **consequence** | If the best current answer to friction is a shared secret between two people, the proposal must explicitly retire or formalize it; carrying it forward silently rebuilds the gatekeeper one layer down, minus the audit trail |
| **evidence** | "won't work for us... through those tiny little holes" → "doesn't change... it's just kept between the couple of us" |
| **finding** | Vet-before-grant contradicts no-setup-required, within the same conversation |
| **consequence** | Both instincts are legitimate (speed vs. integrity) but they cannot both govern the same tier — which is the strongest argument in the transcript for tiered environments rather than one access policy |
| **evidence** | "no setup required to do it" → "you almost have to vet somebody... before you even give it to them" |

---

## Investigate our assumptions

**Does the solution solve the class of problem, not just this instance?**
The instances in the room are Jamie's Power Apps access, the Claude subscription, and per-request grants routed through whoever holds the key. The class is: *any authorized person reaching any governed dataset without a human in the loop, and being able to use it without its builder present.* A proposal that onboards Jamie or provisions one tool solves an instance. The class solution is a repeatable pattern — identity → role/group → entitlement — plus a documentation standard, plus one governed data path. Notably, the class-level pattern already exists in this org in three separate places (Carl's sandbox tiering, the Cognito role groups such as `NEPTUNE_LITTECH_MEMBERS` gating Atlas features, and the `-SG` SharePoint security groups); it has just never been named and generalized.

**Will the solution scale?**
The shared-service-account pattern scales by sharing a secret: no per-person revocation, no attribution of actions, and every new user increases exposure without increasing capability. It fails the audit question ("who did this?") by design. The scalable substitutes are already in local use: per-user identity plus security groups at the edges, and least-privilege service principals for machine access (the Atlas sync function's Entra app registration; the OJB lookup function's read-only `Sites.Read.All` scope with its explicit "No PII beyond JobNo" logging rule). Scale here means adding a person is a group membership change, not a credential-sharing event.

**Can you abstract the solution? Should it?**
Yes, and cheaply — the abstraction is codification, not invention. Three access tiers, generalized from what Carl already runs:

| Tier | Access posture | Who/how |
|---|---|---|
| Sandbox / Dev | Admin by default, granted at onboarding | "admin is right there, it's ready to go" — trust extended up front, blast radius contained |
| Curated / Shared | Per-user identity, security-group entitlements, read via governed connections; **documented datasets only** | The self-service tier — where democratization actually happens |
| Production | Service principals only; no interactive shared credentials; PII/row-level controls; architect gate | "less and less ability to make a mistake" as you go up |

**Will the implementation follow best practices and integrate cleanly?**
Only if it generalizes what exists instead of inventing parallel machinery. The constraints are already established in the Power Platform → AWS decision memo (`WorkLists/docs/power-platform-aws-investigation/decision-memo.md`) and must be preserved, not contradicted: no direct public database exposure; TLS/DNS certificate identity as a first-class constraint; least-privilege read-only DB roles; connection sharing restricted to named technical owners. This proposal extends that recovery-scoped work into the access-model space it deliberately left open.

**Leaks found — resolve now or ticket?**
Two leaks surfaced:
1. *The trusted gateway is a shared dependency.* The recovery track's Lagrange Plan B needs the same secure AWS→Power Platform path this initiative needs. Designing it twice doubles the LOE and risks two half-gateways. **Resolve now, once, jointly** — the gateway PoC should serve both efforts and reuse the decision memo's existing PoC gates.
2. *The knowledge/documentation gap.* Real, named repeatedly in the transcript, but a different discipline (curation, not infrastructure). **Ticket it as its own workstream** with its own owner and definition of done — folding it into the gateway work is how it gets dropped.

**Front-end: adjust behavior, look, or both?**
Both, in a specific sense: self-service is a front-end claim. If a user cannot *discover* what data exists, why a table was built, and who owns it, access is theoretical — the transcript says exactly this ("if you're not talking to me about it, you might not know"). The democratized model therefore needs a discovery surface — a data catalog, however lightweight — where "documented" means: what it is, why it was built, who owns it, how fresh it is. Undocumented = not democratized in practice, whatever the permission bits say.

---

## Transcript analysis tasks

### Uncertainties

| # | Uncertainty | Why it matters |
|---|---|---|
| 1 | Trusted gateway authentication model (service principal vs. gateway host vs. PrivateLink path) | Blocks all AWS→Power BI/SharePoint flow; shared dependency with Lagrange Plan B |
| 2 | How PII is filtered in transit and at rest in the open model (row-level security is never mentioned in any existing doc) | "hold on, this is the most sensitive PI" — the one hard stop Jim named |
| 3 | What "self-service" covers: read/write, environments, user tiers | Undefined scope means undefined done |
| 4 | Lead-architect review criteria and SLA | Without written criteria it becomes the new bottleneck it was meant to prevent |
| 5 | Fate of the PD Projects shared account: retired, or formalized with rotation and scoping | The Off flag above; also matches risk R11 in the recovery risk register |
| 6 | How institutional knowledge gets captured — standard, owner, cadence | The transcript's own evidence says access without knowledge fails |
| 7 | Which KPIs prove the model works without becoming process-as-purpose | Jim's explicit ask; Robin-era Friday-update culture is the named failure mode |

### Decisions (explicit, extracted)

The transcript is exploratory, not decision-dense — worth stating plainly. Only three explicit commitments were made:

1. CC Jacob on the Claude subscription discussion ("okay, I'll cc that").
2. Schedule a 45-minute follow-up, targeted next week, on "demonetizing [democratizing] data access in a secure way."
3. Dustin to reflect and bring an approach ("if you want to reflect on that... share what, how we can").

Everything else — tiering, gateway, service accounts — was described or endorsed in passing (e.g., "I really like Carl's approach") but not decided.

### Testing strategies

Each written so it can fail:

1. **Gateway PoC** — one service principal, read-only, one real dataset, through the intended network path, PII columns filtered. Reuse the decision memo's PoC gates verbatim (encryption on, certificate identity validated, no public DB exposure, least-privilege read role, throttle behavior observed). *Fails if* any gate can't be met on the chosen path.
2. **Time-to-first-authorized-query** — a new (or newly-authorized) team member goes from zero to a successful query against a curated dataset with no human intervention beyond group membership. Baseline it now with the current process; the model works if the number drops and stays down. *Fails if* a gatekeeper touch is still required.
3. **Interact-but-can't-see test** — an authorized user can submit/interact with a list yet cannot read rows they aren't entitled to (the SharePoint paradox the team already solved once on the HR portal; verify the pattern holds on new portals). *Fails if* entitlement and visibility can't be separated.
4. **Documentation test** — a second person, using only the written catalog entry, correctly uses a table without contacting its builder. *Fails if* they have to ask why the table exists or which variant to use.
5. **Attribution test** — every data action in the curated tier maps to an individual identity. The PD Projects account fails this today by design; the new model must pass it.

### Recommendations (summary)

1. Name the conflation and split into four workstreams: plumbing, knowledge, trust/vetting, gateway.
2. Adopt the three-tier access model, codified from Carl's existing practice.
3. Make documentation/catalog a first-class deliverable with a definition of "documented."
4. Retire shared static service accounts in curated/production tiers; per-user identity + security groups for people, service principals for machines.
5. Design the trusted gateway once, jointly with the Lagrange Plan B track.
6. Define a small KPI set that measures outcomes (time-to-first-query, gatekeeper touches per request, catalog coverage, audit attribution coverage) — each with a number obtainable today.
7. Make lead-architect review an async gate with published criteria and an SLA, not a synchronous person.

---

## Recommended approach

**Problem.** Data access runs through individual gatekeepers and shared credentials; the reasoning behind existing data structures lives in specific people's heads; there is no governed path from AWS into the Microsoft/Power BI world. Together these throttle delivery speed and make "special projects" non-repeatable.

**Requirement.** Any authorized person can discover and use governed data without per-request human setup — while PII stays filtered, every action stays attributable to an individual, production stays behind hard controls, and none of the recovery track's locked constraints (no public DB exposure, TLS/DNS identity, OJB timeout gates) are violated.

**Solution.** Three moves, mapped to Jim's two-speed model — this is the frame to put in front of him:

1. **Tiered access = the two lanes made concrete.** Sandbox is the fast lane: admin by default at onboarding, trust extended up front, blast radius contained. Curated and Production are the foundation lane: per-user identity, security-group entitlements, service principals, PII/row-level controls. A prototype **graduates** from sandbox to curated exactly when it is documented, identity-attributable, and gateway-connected — the graduation rule makes "slow is smooth, smooth is fast" testable instead of aspirational.

2. **One trusted gateway, built once.** A governed AWS→Power BI/SharePoint path using the service-principal pattern already proven by the Atlas sync function, constrained by the rules already locked in the decision memo. Shared deliverable with the Lagrange Plan B PoC — one design review, one security review, two consumers.

3. **A documentation standard that gates entry to the curated tier.** Lightweight catalog entry per dataset: what, why, owner, freshness. This is the workstream that converts institutional knowledge from single points of failure into shared capability — and it is the workstream most likely to be dropped if it isn't separately owned.

This is a productivity-multiplier investment in the operating-model sense already on record with Jim: uncertainty moving downstream is the cost, missing foundations are the cause, and one governed access pattern removes friction from every future data effort rather than one.

**Tripwires** (signals the model is failing, agreed in advance):
- Lead-architect review queue exceeds its SLA twice in a month → the gate has become the bottleneck; criteria or capacity change.
- Time-to-first-authorized-query doesn't drop below baseline within one quarter of the curated tier existing → the friction wasn't where we thought; re-run the gate analysis.
- Any PII reaches a workspace without passing the filter design → stop-ship on tier expansion until root cause is closed.

### Open questions for the 45-minute follow-up

1. Scope of "self-service" v1: read-only curated datasets, or does it include write paths?
2. Who owns the trusted-gateway PoC, and is it formally joint with the Lagrange track (Eric/Carl/Larry)?
3. PII stance: is row/column-level filtering a v1 requirement or a production-tier-only requirement?
4. PD Projects account: retire or formalize? On what timeline?
5. Which two or three KPIs does Jim want baselined first?
6. Lead-architect gate: who is it, what are the written criteria, what is the SLA?

---

## Sources

| Source | Used for |
|---|---|
| Otter transcript, Jim discussion 06/24/2026 | v0.1 evidence quotes (verbatim, including the "demonetizing" transcription) |
| Follow-up meeting transcript, 2026-07-06 (Jim, Dustin, Larry) | "Where this landed": wedge statement, KM reclassification, progressive-discovery hypothesis, Lagrange/Callisto constraint, trackable actions |
| `c:\dustin-thomason\docs\operatingModelsPD\discussion.md` | Jim's mandate, two-speed model, productivity-multiplier framing |
| `WorkLists\docs\power-platform-aws-investigation\decision-memo.md` + `risk-register.md` | Locked constraints (no public DB exposure, TLS/DNS identity, PoC gates), risk R11 |
| `PDProjects\Atlas\Readme.md` | Working service-principal gateway pattern (Entra app, Graph scopes) |
| `c:\dustin-thomason\docs\atlas\accessing-atlas-features-by-environment.md` | Cognito role-group entitlement model |
| `PDProjects\OJB\ojb-lookup-node-func\Requirements.md` | Least-privilege read-only pattern, "No PII beyond JobNo" |
| `PDProjects\Power Automate\API\*.JSON` | `-SG` security-group / break-inheritance provisioning (the SharePoint visibility paradox) |

---

## Post-meeting fill-ins

v0.2 completed:

- [x] Record meeting outcomes → "Where this landed" section.
- [x] Capture new constraints → Constraint record (Lagrange-temporary / Callisto-forward / source-of-record rule).
- [x] Update Decisions from exploratory → committed where applicable → wedge, hypothesis, test case landed; v0.1 open questions reconciled.

Remaining (v0.3):

- [ ] Confirm dates + owners for the six trackable actions.
- [ ] Get Jim's yes/no on the container proposal (wedge inside normal work; Jamie test as graduation gate).
- [ ] Agree the metric with Jim (builder-interruptions + time-to-path-known); confirm or revise the v0.1 tripwire thresholds.
- [ ] Resolve rolled-forward opens: gateway ownership, PII stance, PD Projects account, lead-architect gate.
- [ ] Run the Jamie test; record results; decide charter / no-charter.
- [ ] Fold agreed KPIs + baselines into the operating-model response doc.
