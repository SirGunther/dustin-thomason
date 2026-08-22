# Cairn App — General Changelog

## Purpose

Running changelog for Cairn, a markdown-vault UI intended for integration into the WorkLists app (UI, UX, architecture decisions, and testing).

---

## Record integrity

- Every entry below was written in the session it describes; none is reconstructed after the fact.
- Verification claims name the command that produced them. Where a check could not be run, the
  entry says so and names the residual risk rather than recording `N/A`.
- Cairn now has a zero-dependency architecture harness. The POC's checkbox-splice and
  split-pane invariants remain outside it under `TST-001`.
- No Git history exists for `PDProjects` — `git status` reports it is not a repository — so this
  changelog and the capability catalog are the only durable record of what changed when.
- The 2026-08-20 entries all fall on the same day. Finer ordering is given by the sequence of
  headings, newest first, rather than by distinct timestamps.

---

## Scope

- **App:** `Cairn`
- **Primary workspace:** `C:\Users\dktho\OneDrive\PDProjects\Cairn`
- **Log location:** `C:\dustin-thomason\docs\cairn\cairn-app-changelog.md`
- **Integration target:** `WorkLists` (`C:\Users\dktho\OneDrive\SCRIPTS ALL SYSTEMS\To Do List\WorkLists`)

---

## Current state

**Phase:** **Phase 0 is closed.** The directory-handle transfer probe was run by hand in
Chromium on 2026-08-22 and passed — a transferred `FileSystemDirectoryHandle` still reads,
and the main thread retains its own access. That was the last load-bearing Phase 0 claim.
Architecture continues at Phase 1.

- A runnable zero-build prototype exists at `PDProjects/Cairn`. Open `index.html` for the UI;
  the Phase 0 graph and probes require a served origin because Workers cannot be constructed
  from `file://`.
- **Nothing writes to disk.** Sample-vault edits persist to `localStorage` (`cairn-poc-v1`); the real-folder path via the File System Access API is read-only.
- Markdown rendering is delegated to a **verbatim copy** of `WorkLists/public/markdownRenderer.js` at `vendor/markdown-renderer.js`, so render output and the task-checkbox round-trip are proven for the integration target, not just for the POC.
- Palette is lifted from `WorkLists/public/todoliststyles2.css` rather than newly chosen, per the WorkLists changelog constraint against introducing a second dominant palette.
- Four independently valuable DOM-free components are proven: `vault-source`,
  `markdown-renderer`, `document-projector`, and `vault-index`. Open decisions remain listed
  in `PDProjects/Cairn/DECISIONS-PENDING.md`; the Phase 0D evidence is in
  `Architecture/Phase0DEvidence.md`.

**Next:** Phase 1, contract governance, as a single batch for one agent: versioning and
compatibility policy, contract ownership, replay tests against older fixtures, generated
contract documentation with a drift gate, and `catalog_version` semantics.

---

## Plans

| Date       | Plan                                                              | Status        | Approach                                                                                                                                                                                                                                 |
| ---------- | ----------------------------------------------------------------- | ------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 2026-08-21 | Phase 0D — boundary proofs and granularity gate                   | `implemented` | Added `vault-index`, standalone port-driven proofs, the manual directory-handle transfer page, worker-count measurements, and the Phase 0 evidence record.                                                                               |
| 2026-08-20 | Feedback round 01 checklist — `PDProjects/Cairn/FEEDBACK-01.md`   | `superseded`  | 28 tracked items from the first review plus the SaySlate investigation. Split into `ROADMAP.md` (scope, status, Decisions resolved) and `DECISIONS-PENDING.md` (open choices with triggers); the file was then removed.                  |
| 2026-08-21 | Atomic architecture build order — `PDProjects/Cairn/TODO.md`      | `active`      | Ten phases, riskiest claims first. Isolation unit is a Web Worker; a wire is a transferred `MessagePort`. Feasibility verdict and evidence in `Architecture/FeasibilityReview.md`.                                                       |
| 2026-08-20 | Documentation spine + lightweight POC pass + reusable scaffolding | `implemented` | Adopt the SaySlate roadmap/changelog/decisions structure over the Argus canonical-record split; land the agreed design items in the POC; generalise the pattern into templates and two scripts; freeze the POC as an immutable baseline. |
| 2026-08-20 | V1 scope agreed in-session (chat)                                 | `active`      | Adapter seam + tree + preview/source toggle + save + checkbox write-back + favorites + quick open. Explicitly defers full-text search, live/hybrid preview, wikilinks, and graph view.                                                   |
| 2026-08-20 | POC 1 — look and feel (this session)                              | `implemented` | Zero-build HTML/CSS/JS prototype mirroring the shape of `Argus-POC-v1-2026-08-12`; embedded sample vault, no disk writes.                                                                                                                |

---

## Session log

_Newest first. Add one entry per working session or merge-worthy update._

### 2026-08-21T00:00:00Z — Prettier declared as a dependency; the formatting gate is real again

- **Summary:** Replaced the runtime formatter resolver with `prettier` as a declared devDependency. The formatting gate now runs on any machine instead of skipping when no formatter is found, and `npm audit` becomes applicable for the first time.
- **Problem:** The previous batch made the `verify` chain portable by resolving a formatter at run time and tolerating its absence. That was the instruction, and it worked as specified — but on this machine `prettier` lives in the WorkLists workspace, so the resolver found nothing, printed `prettier not found; skipping formatting check`, and exited 0. `npm run verify` therefore reported success while `tests/graph-prepare.test.mjs` was unformatted. A gate that passes because it did not run is worse than no gate.
- **Requirement:** The formatting gate must fail when the repository is unformatted, on any machine, without depending on a sibling project's `node_modules`.
- **Solution:** Added `prettier` `^3.8.3` — matching the WorkLists constraint so both projects format identically — as the single devDependency. `format:check` is now `prettier --check .` and `format` is `prettier --write .`. Deleted `tools/format-check.mjs`; the resolver existed only to work around the missing dependency.
- **Trade accepted:** the zero-dependency property is gone. It bought portability at the cost of a gate that silently did nothing, which was the wrong side of that trade. One dev-only, no-runtime-code dependency is the smaller cost.
- **Files/areas:** `package.json`, `package-lock.json` (new), `tools/format-check.mjs` (deleted), `tests/graph-prepare.test.mjs` (formatting only), and canonically `capabilities.md`.
- **User-visible impact:** None. `npm install` is now required before `format:check` or `verify`; every other gate still runs without it.
- **Tests run:** `npm.cmd test` — **24/24**. `npm.cmd run contracts:check` — 10 governed messages, ok. `npm.cmd run graph:check` — accepted, 5 components, 23 wires. `node tests/kernel-browser.mjs` — **18/18**. `node tests/component-standalone.mjs` — **12/12**. `npm.cmd run format:check` — clean. `npm.cmd run verify` — exit 0. `npm.cmd audit --audit-level=high` — **0 vulnerabilities**.
- **Negative tests, because a gate that cannot fail is not a gate:** injected a wrong-plane wire into `graphs/read-render.json` → `verify` exited **1** with three plane errors. Appended unformatted code to a test file → `verify` exited **1** on the formatting step. Both reverted; all gates re-run green afterwards.
- **Tests added/updated:** None — not relevant: this changed tooling, not behaviour. The 24 node checks include the registry-rejection assertions added in the previous batch and are unchanged here.
- **Regression impact:** `tests/graph-prepare.test.mjs` changed by whitespace only, confirmed by the suite still reporting 24/24. No contract, manifest, wire, or component was touched — the graph is still 5 components and 23 wires, and `vault.index-request` is still at `2.0.0`. The six protected POC files are byte-stable against the frozen snapshot and `vendor/markdown-renderer.js` is still byte-identical to `WorkLists/public/markdownRenderer.js`. `node_modules/` is already excluded by `new-poc-snapshot.ps1` and ignored by prettier, so the new dependency cannot leak into a future baseline.
- **API docs:** Not relevant — no HTTP surface in this project.
- **Tooling gates:** `audit` — now applicable and clean at 0 vulnerabilities. `lint` — no lint script; `format:check` is the gate and passes. Both rows in `capabilities.md` were `N/A`/skip-tolerant and are corrected.
- **Conflicts / exceptions:** The zero-dependency property recorded in earlier entries no longer holds; stated here rather than left for a reader to discover. The manual directory-handle probe remains the only Phase 0 closure item, unchanged by this batch. WorkLists board not updated this session — no status change to report beyond the card's existing Current Step.

### 2026-08-21T17:44:28Z — Phase 0D follow-up review defects fixed as one cohesive batch

- **Summary:** Fixed the four Phase 0D follow-up review defects without beginning Phase 1:
  the verify script now resolves formatting at runtime, the canonical capability catalog is
  current, the registry's `vault.index-request` rejection cases are committed as node tests,
  and the preceding changelog entry uses the canonical shipping headings.
- **Problem:** The verify chain embedded a machine-specific formatter path and Windows-only
  `npm.cmd`; the capability catalog was stale about the node and kernel counts and the
  `npm test` versus `verify` distinction; the registry's path-only and version-rejection rules
  were not guarded; and the newest changelog entry omitted required canonical headings.
- **Solution:** Added a zero-dependency runtime formatter resolver that reports and tolerates a
  missing formatter while preserving real-gate failures; updated the capability prose; added
  one live-registry node test covering accepted paths-only, rejected `text`, and rejected 1.0.0
  envelopes; and restated the prior entry before adding this one with the canonical headings.
- **Files/areas:** `package.json`, `tools/format-check.mjs`,
  `tests/graph-prepare.test.mjs`, `README.md`, `Architecture/ComponentAuthoring.md`,
  canonical `capabilities.md`, and this changelog. No contract schema, graph, component, or
  protected POC file was edited.
- **Tests run:** Final commands passed: `npm.cmd test` 24/24; `npm.cmd run contracts:check`
  accepted 10 governed messages; `npm.cmd run graph:check` accepted 5 components and 23 wires
  with no unwired ports; `npm.cmd run test:kernel` passed 18/18; `npm.cmd run test:standalone`
  passed 12/12; and `npm.cmd run verify` passed all chained gates, including 3 worker-count
  measurements with no threshold applied. A focused registry run passed 1/1, and the failure
  propagation probe returned nonzero as required.
- **Tests added/updated:** Added the live-registry test while leaving the existing 23-test
  rejection matrix unchanged; the new test contains the three requested registry assertions.
- **Regression impact:** The change is isolated to verification tooling, committed tests, and
  documentation. `npm test` remains the fast node gate, `npm run verify` is the complete pass,
  `TST-001` remains open, and the seven named open decisions/issues remain unresolved.
- **API docs:** Not relevant — no HTTP surface, route, method, DTO, status, or auth metadata
  changed.
- **Tooling gates:** `npm.cmd run verify` completed with the runtime formatter result
  `prettier not found; skipping formatting check`; the missing formatter was explicitly
  tolerated, while all real gates passed. No npm dependency was added.
- **Conflicts / exceptions:** No new conflict was recorded. The manual directory-handle probe
  remains outstanding, and Phase 0 is not claimed closed.

### 2026-08-21T00:00:00Z — Phase 0D follow-ups implemented as one cohesive batch

- **Summary:** Completed all four Phase 0D review follow-ups without beginning Phase 1. The
  graph now carries `vault-index`'s ordinary rejection to `@supervisor`; `vault.index-request`
  is a path-only contract at schema version 2.0.0; the three browser harnesses are named npm
  scripts; and the standalone DOM-owner assertion now measures observed output.
- **Problem:** `graph:check` reported an unreachable `vault-index` rejection port, the index
  boundary carried up to 2,000,000 unused characters per document, browser suites were not
  represented by npm scripts, and the DOM-owner invalid-contract conjunct was a literal.
- **Solution:** Added the exact `vault-index -> @supervisor` `operation.rejected` wire and a
  graph-level malformed-path proof; removed `text` from the request schema and source/fixture
  payloads while applying the breaking version rule in `contracts/catalog.json`; added
  `test:kernel`, `test:standalone`, `measure:workers`, and `verify`; and removed the vacuous
  DOM-owner field because the invalid path emits nothing to validate.
- **Tests run:** `npm.cmd test` passed 23/23; `npm.cmd run contracts:check` accepted 10 governed
  messages; `npm.cmd run graph:check` accepted 5 components and 23 wires with no declared but
  unwired `vault-index` port; `npm.cmd run test:kernel` passed 18/18, including exactly one
  malformed-path rejection from `vault-index` and zero failures; `npm.cmd run test:standalone`
  passed 12/12, including registry rejection of a legacy payload carrying `text`.
- **Tests added/updated:** Added the graph-level malformed-path proof, named the three browser
  harnesses as npm scripts, and changed the standalone DOM-owner assertion to measure observed
  output; the invalid path emits nothing to validate, so the vacuous field was removed.
- **Regression impact:** The missing-document rejection remains one `operation.rejected` and zero
  failures; the valid tree projection is byte-identical; `npm test` remains only the fast node
  gate; the manual browser pages remain manual; `TST-001` stays open; and the seven named open
  decisions/issues remain unresolved.
- **Files/areas:** Phase 0 graph, contract catalog/schema, vault-source, standalone and kernel
  harnesses, package scripts, README, roadmap, architecture evidence, canonical changelog, and
  capabilities. The six protected POC files and the vendored renderer were not edited.
- **API docs:** Not relevant — this batch changed no HTTP surface, route, method, DTO, status, or
  auth metadata.
- **Tooling gates:** `npm.cmd run verify` chains the node, contract, graph, kernel, standalone,
  worker-cost, and `prettier --check .` gates. No npm dependency was added.
- **Conflicts / exceptions:** No new conflict was recorded. The manual directory-handle page
  remains a manual surface, the seven named open decisions/issues remain unresolved, and Phase 1
  did not begin.

### 2026-08-21T00:00:00Z — Phase 0D reviewed and accepted with three follow-ups

- **Summary:** Reviewed the Phase 0D batch against its brief and the architecture's boundary rules. **Accepted.** Every boundary claim holds, the granularity gate was argued rather than asserted, and the two items that could have sunk the design were handled honestly. Three small follow-ups and one stale canonical claim were found and are recorded below; the formatting gate and two documentation gaps were fixed in this session.
- **Problem:** A batch that reports its own success is not reviewed. The specific risks worth checking were the ones the brief was written to prevent: a contrived fourth component to satisfy the granularity gate, a boundary quietly widened to make the work easier, an unusable measurement presented as evidence, and the protected POC files drifting.
- **Requirement:** Verify each Preserve claim independently rather than reading the report; confirm the held-open decisions are still open; and separate defects in the execution from defects in the brief, because those need different fixes.
- **What holds:**
  - **The granularity verdict is argued, not asserted.** `Architecture/Phase0DEvidence.md` justifies all four DOM-free components with what each does, why it is worth isolating, and what folding it would break. It correctly excludes `dom-owner` as privileged and `markdown-renderer-minimal` as a replacement rather than a fifth capability.
  - **The boundary held.** `vault-index` declares `state: none` and `side_effects: []`, so it gained no filesystem authority. `ui.tree-projection` carries only `name`, `path`, `parent_path`, and `type` — confirmed by walking the schema, no `text` field — so the second projection reaching the DOM owner cannot carry authoritative source either. Still exactly one privileged component; the kernel still reports zero document-wire ports with five components running.
  - **The protected files did not drift.** All six byte-stable against the frozen snapshot by SHA-256, and `vendor/markdown-renderer.js` still byte-identical to `WorkLists/public/markdownRenderer.js`.
  - **The standalone tests are not vacuous.** The valid and invalid checks assert genuinely different conjuncts of the same run, and the tree fixture returns real ordered paths. One weak spot: `dom-owner`'s `invalidContracts` is a hardcoded `true`, so that check reduces to two real conjuncts rather than three.
  - **Honest reporting under pressure to claim success.** The batch did **not** claim Phase 0 closed. The coarse `performance.memory` counter returned an identical 10,000,000 bytes before and after every run, and the evidence document says so plainly — "should not be interpreted as per-worker RSS" — rather than presenting a 0-byte delta as a finding. The directory-handle probe is recorded as `PENDING MANUAL RUN`, with the headless attempt logged as a limitation and not as a result. `ADP-001` and `ADP-002` remain unresolved, as do `EDT-001`, `EDN-001`, `BRK-001`, `SRC-001`, and `EMB-001`.
- **Follow-ups found, none blocking:**
  1. **`vault-index` declares `operation.rejected` with no wire**, so `graph:check` reports the port as declared and unreachable. Its rejection path works in the standalone harness, which wires the port itself, but in the graph an invalid path is dropped silently. `vault-source` has this wire; `vault-index` needs the same one.
  2. **`vault.index-request` requires a `text` field the component never reads.** `vault-index` builds a tree from paths; `text` appears only in a source comment. This forces up to 2MB per document across a boundary for nothing and contradicts the rule that a message carries only what its consumer needs. **This is a defect in the brief, not the execution** — the instruction said "accepts document paths and text," and the agent implemented what was specified.
  3. **The three browser harnesses are not npm scripts**, so `npm test` passing does not mean they ran. Recorded in the capability catalog rather than left implied.
- **Fixed in this session:** `prettier --check` was failing on 11 files, while `capabilities.md` claimed the formatting gate was `Working` — a canonical document asserting a gate result that was not true. Formatting restored and all gates re-run afterwards. `README.md` had no runnable command at all for any gate or harness; a **Verify** section now lists all six plus the two gesture-driven pages. The `Run it` block in `Architecture/ComponentAuthoring.md` was stale, omitting the three new harnesses.
- **Files/areas:** reviewed all of `contracts/`, `runtime/`, `components/`, `graphs/`, `tests/`, and `Architecture/`. Changed: `README.md`, `Architecture/ComponentAuthoring.md`, formatting across 11 files, and canonically `capabilities.md` and this changelog.
- **User-visible impact:** None. The POC entry points are untouched.
- **Tests run:** `npm.cmd run contracts:check` — 10 governed messages, catalog 1.0.0, ok. `npm.cmd run graph:check` — accepted, 5 components, 22 wires. `npm.cmd test` — **23/23**. `node tests/kernel-browser.mjs` — **17/17**, zero page or console errors. `node tests/component-standalone.mjs` — **12/12**. `node tests/worker-cost.mjs` — 3 measurements, no threshold applied. `prettier --check .` — clean. All re-run after the formatting change, so these are the final-state results.
- **Tests added/updated:** None — not relevant: this session reviewed and corrected documentation. The three follow-ups above will need tests when they land; the `vault-index` rejection wire in particular should get a graph-level assertion, since the gap was invisible to the existing suites precisely because the standalone harness wires the port itself.
- **Regression impact:** The only code-adjacent change was whitespace from `prettier --write` across 11 files. Verified by re-running all four automated gates afterwards and re-confirming the six protected files by hash. No contract, manifest, wire, or component logic was altered.
- **API docs:** Not relevant — no HTTP surface in this project. The WorkLists API was read only to update the board card.
- **Tooling gates:** `audit` — not applicable: `package.json` declares no dependencies. `lint` — no lint script; `prettier --check .` now clean, having been failing at the start of this session.
- **Conflicts / exceptions:** The Phase 0D entry below does not use the canonical shipping-checklist headings and omits the failing formatting gate. Left as written rather than rewritten, since amending another session's record is worse than annotating it — this entry supplies the missing gate result. Board card `todo-1787318488373` updated: workflow sections added from the designated template and Current Step / Waiting On / Next Up filled, each write carrying a `lastModified` precondition. The status label could **not** be moved from `Unrefined` to `In Progress`: the API returned `400 Task status is not available for this card's color tags`, and the card carries no tag. Adding a tag is not a permitted agent write under `worklists-card-sync`, so the label is unchanged and this is reported rather than worked around.

### 2026-08-21T00:00:00Z — Phase 0D implemented; boundary proofs and granularity gate

- **Summary:** Completed Phase 0D as one batch. `vault-index` is the fourth independently
  valuable DOM-free component: it receives path/text records and emits a sorted tree
  projection without filesystem authority or state ownership. The original four-component
  chain and its 17 wires remain unchanged; the accepted graph is 5 components and 22 wires.
- **Proofs:** `node tests/component-standalone.mjs` passed 12/12 focused checks across all
  five components with valid and invalid fixtures. `node tests/kernel-browser.mjs` passed
  17/17 checks, including the tree projection, zero kernel document-wire ports, projection
  text exclusion, the missing-document rejection, renderer replacement, and removed-wire
  negative test. `node runtime/contract-registry.mjs --check` accepted 10 governed messages.
- **Measurement:** `node tests/worker-cost.mjs` measured 4, 6, and 8 workers. On Chromium
  `HeadlessChrome/148.0.7778.96` with Node `v24.11.1`, startup was 11.400/11.600/12.900ms,
  median routing was 0.000ms, and the coarse browser heap counter reported a 0-byte delta
  at all three counts. These are machine-specific observations, not thresholds.
- **Directory probe:** `Architecture/probes/directory-handle-transfer.html` now takes the
  required user gesture, posts a real directory handle to a worker, reads `probe.txt`, and
  reads it again on the main thread. Its manual result is pending until the page is run in
  Chromium or Edge; this evidence does not resolve `ADP-001` or `ADP-002`.
- **Residual:** `TST-001` remains open because the POC's single-line checkbox splice and
  split-pane geometry are not yet permanent committed assertions. `EDT-001`, `EDN-001`,
  `BRK-001`, `SRC-001`, and `EMB-001` remain unresolved, as do the adapter and persistence
  choices.

### 2026-08-21T00:00:00Z — Phase 0B and 0C implemented; contracts, graph preparation, and the kernel

- **Summary:** Built the architecture groundwork: a contract catalog, a component manifest, a wiring graph, graph preparation carrying the whole rejection matrix, and a kernel that constructs Web Workers and wires them with transferred `MessagePort`s. The first vertical slice runs end to end. 40 checks pass. The existing POC is byte-unchanged.
- **Problem:** The feasibility session established that the Argus model transfers to a browser and wrote the build order, but nothing existed to build on. Another agent continuing the work would have had to invent the envelope, the manifest shape, and the kernel's authority boundary from prose — which is exactly how a default-deny architecture drifts into a conventional one.
- **Requirement:** Every boundary the architecture promises must be enforced by something executable, and enforced _before_ a component starts. A component must be replaceable by behaviour rather than by assertion. The kernel's authority must be finite and written down in both directions. And the whole thing must be runnable and extendable by someone who was not here.
- **Solution:** `contracts/` (8 governed messages across two planes, one schema each), `runtime/` (validator, registry, graph preparation, kernel, component host), `components/` (four components plus a replacement), `graphs/read-render.json`, and two test suites. Plus `Architecture/KernelAuthority.md` and `Architecture/ComponentAuthoring.md` as the handoff.

### What the design decides

- **A wire is one `MessageChannel`.** The kernel creates it, transfers both ends, and drops its references — verified: it holds zero document-wire ports after bootstrap, so it cannot read a document body. This is the substantive difference from Argus, where default-deny means a router declines to deliver; here there is no channel to decline over.
- **The DOM is granted to exactly one component, by declaration.** A `runtime.kind` of `main-thread` requires `privileged: true`, and preparation rejects a second one, a worker claiming the `dom` effect, and a privileged worker. The kernel will not construct a privileged component from a URL — the host passes a factory, so privilege is always an explicit application choice. This is the enforcement behind the largest risk in `FeasibilityReview.md`.
- **The DOM owner never receives authoritative text.** `ui.document-projection` has no `text` field, so the boundary rests on the contract rather than on the privileged component behaving well. `document-projector` exists purely to hold that line; collapsing it into the renderer would work today and would quietly remove the guarantee.
- **Graph preparation is pure** — no Worker, no DOM, no filesystem — so the entire rejection matrix runs under `node --test` in ~120ms, and a malformed graph is rejected before anything has been started.
- **The validator refuses a schema keyword it cannot enforce.** Argus recorded its subset validator as a snapshot weakness; the weakness is not the small subset but that an unknown keyword is silently ignored, so a field looks checked and is not. This one throws at load time.
- **Validation happens twice**, at the kernel boundary and again at the component's own — the second is what protects a component from a kernel bug.
- **One deliberate divergence from Argus:** `component-host.mjs` is shared protocol rather than boilerplate duplicated per component. Argus duplicates it and lists the duplication as a weakness. The rule being honoured is "a component imports no implementation from a sibling", and the runtime is not a sibling. Recorded with the caveat that if that file ever starts knowing what a document is, the judgement was wrong.
- **Files/areas:** `contracts/` (14 files), `runtime/` (5 modules), `components/` (5 components), `graphs/read-render.json`, `tests/` (3 files), `Architecture/{KernelAuthority,ComponentAuthoring}.md`, `package.json` (new, zero dependencies), `TODO.md`, `ROADMAP.md`, `DOCS.md`.
- **User-visible impact:** None. `index.html`, `app.js`, `styles.css`, and `theme.js` are byte-identical to the frozen snapshot, verified by hash. The graph runs only from its own harness.
- **Tests run:** `node runtime/contract-registry.mjs --check` — 8 governed messages, catalog and schemas agree. `node runtime/graph-prepare.mjs graphs/read-render.json` — 4 components, 17 wires accepted, topology printed. `node --test tests/*.test.mjs` — **23/23**, the rejection matrix. `node tests/kernel-browser.mjs` — **17/17** in real Chromium, zero page or console errors. All four re-run against the final formatted tree.
- **What the browser checks actually prove:** the slice runs end to end and the vendored renderer produces real markup (`markdown-task-checkbox`, `data-markdown-line-index`) inside a worker; the outline and task counts survive three hops; no projection the DOM owner received carries `text`; the kernel holds zero document-wire ports; the DOM owner cannot emit an undeclared contract; a missing document yields `operation.rejected` and **not** `component.failure`; the replacement starts with a byte-identical wire list and is genuinely different (baseline renders a `<table>`, replacement does not, so the test cannot pass vacuously); and removing the projection wire removes the capability with the drop visible in the trace rather than silent.
- **Two real bugs found by the browser that Node could not have caught:** `process?.argv` throws a `ReferenceError` in a page — optional chaining guards a null value, not an undeclared identifier — so the CLI guards in two shared modules took the whole graph load down; replaced with an `import.meta.filename` comparison, which is Node-only and needs no path-separator literal. And `loadGraph` resolved manifests before applying a caller's mutation, so swapping a component failed with a confusing "manifest was not loaded"; the mutation hook now runs before manifests are fetched.
- **Record-integrity defect found and fixed:** the `ROADMAP.md` **Decisions resolved** rows from the two previous sessions were never actually written. Both sessions used an unguarded `str.replace` against a table anchor written from memory, and prettier had padded the table cells for alignment, so the replace silently matched nothing while the script reported success. Ten rows were missing. Re-applied by line position rather than cell text, verified present, and re-verified **after** prettier — that last step is the one that was missing. Worth stating plainly: a decision register that reports a write it did not perform is the precise failure these documents exist to prevent.
- **Tests added/updated:** `tests/graph-prepare.test.mjs` (23 checks) and `tests/kernel-browser.mjs` (17 checks) are new and are the first real regression guards this project has had. `TST-001` is **not** closed — there is still no harness for the POC's own invariants (the checkbox splice, split-pane geometry), which remain guarded only by a scratch script outside the repo. A `package.json` with `node --test` now exists and carries zero dependencies, so closing `TST-001` is a smaller step than it was.
- **Regression impact:** Additive. Every new path lives under `contracts/`, `runtime/`, `components/`, `graphs/`, or `tests/`; the four POC entry points are byte-identical to the snapshot and `vendor/markdown-renderer.js` is still byte-identical to the WorkLists original, both verified by hash. The one shared-file edit was the CLI guard in two runtime modules, whose Node behaviour is covered by the two CLIs still running correctly.
- **API docs:** Not relevant — no HTTP surface. The browser test starts a throwaway loopback server for one run and serves only files inside the repository, with an explicit containment check.
- **Tooling gates:** `audit` — not applicable: `package.json` declares no dependencies, so there is nothing to audit. `lint` — no lint script; `prettier --check .` clean, with `contracts/` newly ignored because those files are script-generated and validated by `contracts:check` instead.
- **Conflicts / exceptions:** Phase 0D is **not** complete — no granularity gate, no worker-count measurement, no per-component standalone harnesses, and `vault-source` reads an embedded fixture rather than a folder. Stated in `KernelAuthority.md` and `ComponentAuthoring.md` rather than implied by the passing tests. WorkLists board still not updated — no card id supplied, and `worklists-card-sync` forbids searching for the card; sixth session carrying this exception.

### 2026-08-21T00:00:00Z — Architecture feasibility determined and build order written

- **Summary:** Read the Argus architecture record, probed whether its model survives being moved into a browser, and wrote the Cairn build order. Verdict: feasible, and in one respect stronger than Argus. No application code changed.
- **Problem:** Argus's architecture rests on OS process isolation, NDJSON over stdio, and an orchestrator that refuses to route an undeclared message. Cairn is a browser page with a single JS realm and no processes, so whether the model transfers at all was an open question — and answering it by writing the architecture first and discovering the answer later would have been expensive.
- **Requirement:** Establish, from executable evidence rather than reasoning, what plays the part of a process, what plays the part of a wire, which of Argus's invariants survive, and what the substitution costs. Then order the work so the claims that would sink the design fail first and cheaply.
- **Solution:** `Architecture/probes/` — six probes driven through Chromium, cited by `Architecture/FeasibilityReview.md` and reproducible with `node Architecture/probes/probe.mjs`. `TODO.md` carries ten phases in the spirit of Argus's, adapted rather than copied.
- **The substitution:** the isolation unit is a **Web Worker**; a wire is a transferred **`MessagePort`**; the diagnostics stream is a second port rather than stderr; process exit becomes `onerror`/`terminate()`; and `ARGUS_SESSION_ROOT` becomes a `FileSystemDirectoryHandle` transferred to exactly one component. The `@` pseudo-component namespace, both planes, no-transitive-authority, one-owner-per-state, and the replacement test all carry over unchanged.
- **The finding that matters most:** Argus enforces "nothing crosses unless a wire exists" through a router that declines to deliver. In a browser, if no `MessageChannel` was created and no port transferred, **there is no channel to route over at all.** Measured both directions: an unwired worker reports no `document`, no `window`, no host globals (`CAIRN_SAMPLE_VAULT` is simply absent), no `localStorage`, no sibling enumeration, and zero channels; with exactly one channel created, the message arrives. Default-deny stops being a policy and becomes a property of the platform.
- **Second finding — the core capability is already isolable.** `vendor/markdown-renderer.js` loads into a worker with **zero modifications** and produces correct tables, checkboxes, `data-markdown-line-index`, and a working single-line splice, with `touchedDom: false`. The thing the whole project is built around did not need restructuring to cross the boundary.
- **Confirmed costs, stated rather than buried:**
  1. **`file://` stops working.** A `file://` page cannot construct a worker at all — `SecurityError`, opaque origin, for both classic and module workers. `npx serve .` becomes mandatory from Phase 0 onward, which costs the double-click-to-run property that made the POC actually get used. This is the single biggest thing being traded away.
  2. **The DOM is one privileged component that cannot be decomposed.** This is Argus Phase 7 promoted to a day-one constraint. It means the honest component count is lower than Argus's, and it is why `TODO.md` Phase 0D carries a granularity gate: if fewer than four genuinely DOM-free components exist, the correct outcome is to say so and keep Cairn a single-realm app.
  3. **No polyglot story.** Argus's native/container replacement test has no cheap browser equivalent; WebAssembly is a different experiment.
- **Also measured:** `localStorage` does not exist in a worker (so component-owned persistence must be IndexedDB, which `ADP-002` already wanted); `showDirectoryPicker` and `navigator.clipboard` are main-thread-only, so both become capability adapters exactly as in Argus Phase 7; structured-clone costs 0.06ms for a 35KB document, so boundaries are not the bottleneck at document granularity.
- **Sequencing difference from Argus, recorded because it is the main risk:** Argus built services first and bridged a UI in at Phase 7. Cairn already has a complete working UI that must be _pulled apart_ behind a boundary it currently ignores. The shortcut already works and removing it will look like a regression, which is why Phase 7 carries the explicit test "prove the DOM owner cannot read a file's text without a wire."
- **Files/areas:** `PDProjects/Cairn/TODO.md` (new), `Architecture/FeasibilityReview.md` (new), `Architecture/probes/` (new — 6 worker probes, harness, README), `DOCS.md`, `ROADMAP.md`, `DECISIONS-PENDING.md`.
- **User-visible impact:** None. No application code was touched; `index.html`, `app.js`, `styles.css`, and `theme.js` are unchanged.
- **Tests run:** `node Architecture/probes/probe.mjs` from the repo, after formatting, against Chromium — all six probes returned, zero page and console errors. Results are quoted verbatim in `FeasibilityReview.md`, so every "measured" claim there can be re-derived by re-running that one command. `prettier --check .` clean across the repo including the new probe sources.
- **Tests added/updated:** The probe harness is new and is committed as evidence rather than as a suite — it answers feasibility questions, it does not guard behavior. It is not a substitute for `TST-001`, which remains open; the invariants that need permanent guarding are still unguarded.
- **Regression impact:** Isolated — documentation and a self-contained probe directory. No file under `PDProjects/Cairn` outside `Architecture/`, `TODO.md`, and the three doc files was modified; the app entry points are byte-unchanged, and `vendor/markdown-renderer.js` is still byte-identical to the WorkLists original.
- **API docs:** Not relevant — no HTTP surface exists in this project. The probe harness starts a throwaway loopback server on 127.0.0.1:8791 for the duration of one run and exposes no application route.
- **Tooling gates:** `audit` — not applicable: no `package.json` in `Cairn` or at the `PDProjects` root; the probes resolve Playwright from the WorkLists workspace. `lint` — no lint script; `prettier --check .` clean.
- **Conflicts / exceptions:** `ADP-003` resolved and recorded as moot — a served origin is required regardless of the picker's `file://` behavior. The POC v1 snapshot deliberately **not** re-cut: it is the frozen baseline for the pre-architecture state, and this session's artifacts belong to what comes after it. WorkLists board still not updated — no card id supplied, and `worklists-card-sync` forbids searching for the card; fifth session carrying this exception.

### 2026-08-20T00:00:00Z — Documentation spine, POC design pass, reusable scaffolding, POC v1 frozen

- **Summary:** Adopted a real documentation structure for Cairn, landed the agreed design work in the POC, generalised the whole pattern into reusable templates and scripts, and froze the POC as an immutable comparison baseline. POC 1 is closed; architecture is next.
- **Problem:** Cairn had a changelog and an ad-hoc feedback checklist, which meant scope, settled decisions, and open questions were all mixed into one file with no rule about where anything belonged. Decisions were getting re-litigated because nothing recorded that they were settled. Separately, this was the third project to need this structure and the pattern had been re-derived by hand each time — including the Argus POC snapshot, whose creation sequence existed only as its own output and could not be repeated.
- **Requirement:** One authoritative location per kind of record. A settled decision must be findable as settled. A deferred choice must carry a safe default and a concrete trigger so implementation cannot bypass it silently. The structure must be reproducible for the next project without re-deriving it. And the POC's agreed design items must be judgeable before the baseline is frozen.
- **Solution:** SaySlate's roadmap/changelog/_Decisions resolved_ shape, laid over the Argus split between canonical record and code-adjacent documents.

### Part A — documentation spine

- Repo (`PDProjects/Cairn`): `ROADMAP.md` (scope, status, **Decisions resolved** — 12 rows), `DECISIONS-PENDING.md` (14 open choices, each with a safe default and a trigger), `DOCS.md` (pointer forbidding a second changelog), trimmed `README.md`. `INVESTIGATION-SAYSLATE.md` moved to `docs/investigations/sayslate-design-baseline.md`; screenshots to `docs/screenshots/`.
- Canonical (`dustin-thomason/docs/cairn`): `README.md` (index, artifact ownership, 8 maintenance rules, shared status vocabulary), new `capabilities.md` separating `Working` / `UI POC` / `Specified` / `Deferred`, and a `Record integrity` section on this changelog.
- `FEEDBACK-01.md` deleted after its content was split. Verified no dangling references remain.

### Part B — POC design pass

- **Three complete palettes as token blocks** — Argus dark (default, from `PDProjects/Argus/styles.css`), light (from SaySlate's light block), WorkLists dark. No component rule names a color; verified by scanning `styles.css` for literal colors outside the token blocks. Body links use a separate `--link` token set to Argus's own `--blue`, because the lime accent is a chrome color there and is harsh at paragraph density. A `--code-bg` token was added after light mode revealed the inline-code chip disappearing against the page.
- **Theme stamped before first paint** by a separate `theme.js` in `<head>`. Verified by reading `data-theme` at the first `readystatechange`: it is already correct, so there is no flash.
- **Two-line viewport-safe tooltips** ported from SaySlate, replacing the inline `<kbd>` and every `title=` in the shell. Readable on disabled controls, which is why they replaced `title=`.
- **Laptop-height adaptation** at 820px and 680px via `--topbar-h`/`--doc-pad-y`, with `100dvh` so browser chrome cannot hide the status bar, and wrapping action groups.
- **Icon-only topbar** at subdued idle weight. Preview/Split/Source deliberately kept as text — three icons meaning "view mode" are not distinguishable, so the SaySlate pattern was not copied wholesale there.
- **Lightweight multi-root workspace.** `addRoot()` appends rather than replaces, prefixing each path with its root name — which means `buildTree()` yields roots as top-level nodes and `sectionOf()` turns them into section tabs with no change to either function. Roots render collapsed on purpose, so what you see is folder names rather than loose files. Per-root remove. In-memory only; no persistence.
- **One deviation from the plan, recorded:** roots were to be disambiguated by parent path. `showDirectoryPicker()` exposes only `handle.name` and never the parent, so a counted suffix (`Work (2)`) is what the API actually permits. `ROADMAP.md` states this rather than implying the original approach shipped.

### Part C — reusable scaffolding

- Six templates in `docs/_templates/`: roadmap, changelog, decisions-pending, capabilities, POC snapshot, project-docs README.
- `scripts/new-project-docs.ps1` — scaffolds the canonical trio and the code-adjacent pair, with a collision check that prevents a partial scaffold and a `-WhatIfSummary` dry run.
- `scripts/new-poc-snapshot.ps1` — the sequence that produced the Argus snapshot, now repeatable: filtered copy, rendered `SNAPSHOT.md`, `SHA256SUMS.txt`, ZIP, and a checksum sidecar beside the ZIP, then read-only. Two deliberate corrections to the Argus original: checksum files are written **UTF-8 without BOM** (the existing `Argus-POC-v1-2026-08-12.zip.sha256` has a BOM, which makes `sha256sum -c` reject its only line), and the narrative arrives via `-NarrativeFile` **before** hashing, because `SNAPSHOT.md` is itself covered by the manifest and the ZIP.
- **Fixed a pre-existing bug in `new-ticket-changelog.ps1`.** Its line-76 `-replace` pattern contains em dashes, and Windows PowerShell 5.1 reads a BOM-less `.ps1` as CP1252, so the pattern decoded to `### YYYY-MM-DD a€" repo-name` and never matched the template. Every ticket changelog scaffolded on 5.1 kept the literal `YYYY-MM-DD` placeholder instead of the date and repo. Reproduced, fixed by adding a UTF-8 BOM (the pattern must contain a real em dash to match), and proven by scaffolding a throwaway ticket and reading back `### 2026-08-20 — encoding-probe`. Probe removed.
- My own scripts took the other route — pure ASCII — since their em dashes were only prose. This cost real diagnosis time: the mis-decoded em dash produces a `"` that terminates the enclosing string, so the parse error surfaced 50 lines later as `Unexpected token 'entries'`. Recorded in `ROADMAP.md` → Decisions resolved.

### POC v1 frozen

- `PDProjects/Cairn-POC-v1-2026-08-20` plus its ZIP and sidecar. 26 source files, 425,085 bytes. Narrative authored first at `Cairn/docs/poc-v1-snapshot-notes.md` and rendered in.
- **Files/areas:** repo — `ROADMAP.md`, `DECISIONS-PENDING.md`, `DOCS.md`, `README.md`, `theme.js` (new), `styles.css`, `index.html`, `app.js`, `docs/**`. Canonical — `docs/cairn/{README,capabilities,cairn-app-changelog}.md`. Tooling — `docs/_templates/*` (6 new), `scripts/new-project-docs.ps1`, `scripts/new-poc-snapshot.ps1`, `scripts/new-ticket-changelog.ps1` (encoding fix).
- **User-visible impact:** Argus dark by default with a working light/WorkLists toggle; icon-only topbar with two-line tooltips; usable at laptop heights; multiple real folders aggregated as named roots.
- **Tests run:** Playwright from the WorkLists workspace's `node_modules`, against the final tree. Carried invariants both hold — a checkbox click changes exactly one source line with the line count unchanged, and split panes share a row and span the full container width. New: theme cycles argus→light→worklists and survives reload with `data-theme` already set at the first `readystatechange`; tooltip is `pre-line` and capped at 280px and survives `disabled`; zero horizontal overflow at 1280×768, 680, and 620 with the status bar visible at each; three roots added in sequence render as three collapsed root rows with **zero** file rows and three section tabs, a duplicate name becomes `Work (2)`, and removing a root prunes its files, tabs, favorites and section tab. Zero page and console errors throughout. PowerShell: both new scripts parse clean under 5.1; `new-project-docs.ps1` dry-run verified; `new-poc-snapshot.ps1` run for real and `sha256sum -c` accepts all 28 manifest entries and the ZIP sidecar.
- **Defect found and fixed during verification:** 22px of horizontal overflow at 1280px wide. Cause was the new tooltips — a centered `::after` on a control near the right edge lays out from the control's midpoint to midpoint + up to 280px, pushing `scrollWidth` past the viewport even though the transform visually pulls it back. The edge-aware override only covered `:last-child`; both action groups are `justify-content: flex-end`, so every control in them is against the edge, not just the last. Fixed by anchoring the whole group inward. Worth noting for later: a `getBoundingClientRect()` sweep found nothing, because pseudo-elements have no client rect — `scrollWidth` was the only signal.
- **Tests added/updated:** None — blocked, unchanged and now formally tracked as `TST-001`. This project still has no `package.json` or harness. Residual risk: every invariant above is guarded only by a scratch script outside the repo. Smallest follow-up: a `package.json` with Playwright plus the assertions already written across these four sessions.
- **Regression impact:** The palette change touched every color in the app, so it was verified by re-running the full render and geometry checks rather than by inspection; the WorkLists token block reproduces the previous values exactly, so embedding is unaffected. `walkDirectory()` gained an optional `budget` parameter defaulting to `MAX_FILES`, so its existing behavior is unchanged when the argument is omitted. WorkLists itself was read only — `vendor/markdown-renderer.js` remains byte-identical to `WorkLists/public/markdownRenderer.js`, re-verified by `diff`.
- **API docs:** Not relevant — no HTTP surface in this project; no route, DTO, status, or auth decorator exists to change. The prototype makes no network calls.
- **Tooling gates:** `audit` — not applicable: no `package.json` in `Cairn` or at the `PDProjects` root. `lint` — no lint script; `prettier --check .` clean across the repo, with `vendor/` and the generated `sample-vault.js` ignored so parity diffs stay readable.
- **Conflicts / exceptions:** WorkLists board still not updated — no card id supplied, and `worklists-card-sync` forbids searching for the card. Fourth session carrying this exception. One plan deviation (root disambiguation) recorded above and in `ROADMAP.md`.

### 2026-08-20T00:00:00Z — SaySlate design investigation; two corrections applied

- **Summary:** Mined `Browser Extensions/SaySlate` for the design direction Cairn should be working toward, and fixed two places where Cairn was doing something SaySlate had already tried and explicitly reversed.
- **Problem:** The target look was described as "more like Argus, and I like SaySlate because it is closer to Cursor," but the reasoning behind those preferences lived in a changelog nobody had read into this project. Without it, Cairn would keep re-deriving decisions that were already settled next door — and in two cases had already re-derived them wrongly.
- **Requirement:** The design direction must come from the artifacts rather than from inference, with each recommendation traceable to the release that established it. Anything Cairn is already doing against a settled decision must be corrected, not just noted.
- **Solution:** Read `CHANGELOG.md` (377 lines, 1.0.0 → 1.11.5), `ROADMAP.md`, `README.md`, `app.css`, `animations.css`, and `theme.js`. Three release arcs are pure design work and carry the signal: 1.8.1–1.8.2 controls and tooltips, 1.9.1–1.9.4 surface palette, 1.10.0–1.10.2 motion and viewport fit. Findings recorded in `PDProjects/Cairn/INVESTIGATION-SAYSLATE.md`; 13 new tracked items appended to `FEEDBACK-01.md` (now 28 total).
- **Confirmed from the source:** the dark-theme target is Cursor, stated outright in the intermediate-development section — "Added persistent light and Cursor-inspired dark themes."
- **Corrections applied to `styles.css`:**
  1. **Reduced motion was near-zero.** Cairn had the boilerplate `transition-duration: 0.01ms !important` on `*`. SaySlate 1.10.1 exists specifically to undo that pattern — "Prevented reduced-motion detection from making theme, panel, and toast transitions completely instant… while preserving visible feedback." Now matches SaySlate's tested landing point of `80ms` plus `scroll-behavior: auto`. The retained `!important` carries a comment naming what it beats and why removal was not possible, per the browser-loop guardrail on overrides.
  2. **Two hardcoded `#1a1a1a` surfaces** (source pane, fenced code blocks) replaced with a `--text-surface` token. This is the same defect SaySlate 1.9.3–1.9.4 fixed by making one shared class "the single background source for editable text fields," after removing higher-specificity per-component backgrounds that kept overriding it. Token named after his class deliberately, so both projects use the same word for the same idea.
- **Top recommendations recorded** (detail and citations in the investigation doc): two-line viewport-safe `[data-tooltip]::after` tooltips replacing inline `<kbd>` clutter and bare `title=` — pure CSS, `white-space: pre-line`, edge-aware by scoped override, and still readable on disabled controls; laptop-height adaptation at his tested 820/680 breakpoints using `dvh` rather than `vh` (Cairn currently burns 168px of chrome with no height adaptation at all); light+dark with the theme stamped before first paint by a separate tiny early script; icon-only action bar with subdued idle controls.
- **Behavioral principle flagged as a constraint rather than a task:** failure-gate every stage and never destroy user content after a failure. It recurs throughout the SaySlate changelog and governs Cairn's future disk-write path — if a write fails, keep the buffer dirty, keep the tab open, and never mark saved.
- **Files/areas:** `PDProjects/Cairn/INVESTIGATION-SAYSLATE.md` (new), `FEEDBACK-01.md` (extended to 28 items), `styles.css` (two corrections).
- **User-visible impact:** Reduced-motion users now get shortened rather than eliminated transitions. No other visible change; the token swap is value-identical.
- **Tests run:** Re-ran the Playwright smoke and geometry checks against the post-edit tree. Checkbox splice still changes exactly one source line with the line count unchanged; split panes still share a row and span the full width; tables and checkboxes still render; zero horizontal overflow; no page or console errors.
- **Tests added/updated:** None — blocked, unchanged from the previous session: this project still has no test harness or `package.json`. Residual risk: the reduced-motion and token changes are CSS-only and unguarded by any assertion. Smallest follow-up remains a `package.json` with Playwright plus the already-written assertions.
- **Regression impact:** The `--text-surface` swap is value-identical (`#1a1a1a` before and after) and was verified by re-running the render checks. The reduced-motion change is scoped inside `@media (prefers-reduced-motion: reduce)`, so no default-motion behavior is reachable from it. No file outside `PDProjects/Cairn` was modified; SaySlate and WorkLists were read only.
- **API docs:** Not relevant — no HTTP surface in this project; no route, DTO, status, or auth decorator exists to change.
- **Tooling gates:** `audit` — not applicable: no `package.json` in `Cairn` or at `PDProjects` root. `lint` — no lint script; `prettier --check .` clean. Note: Prettier reflowed one paragraph into a spurious list item (a line wrapping onto a leading `+`); caught on review and reworded.
- **Conflicts / exceptions:** WorkLists board still not updated — no card id supplied, and `worklists-card-sync` forbids searching for the card. Third session carrying this exception.

### 2026-08-20T00:00:00Z — Feedback round 01 captured; two blocking findings

- **Summary:** Captured the first hands-on review of POC 1 as a tracked 15-item checklist, and ran two investigations that change how the top two asks should be built.
- **Problem:** The review mixed praise, agreed changes, deferred wants, and an unresolved decision in one pass. Without capture, the deferred items and the reasoning behind them are the ones that get lost between sessions.
- **Requirement:** Every item raised must be recorded with its status and, where it is a change, enough detail to act on later without re-deriving it. Anything that would be built the wrong way must be flagged before the work starts, not after.
- **Solution:** `PDProjects/Cairn/FEEDBACK-01.md` — 7 confirmed-working items, 4 agreed changes, 4 deferred, 1 open decision, plus a recommended order.
- **Files/areas:** `PDProjects/Cairn/FEEDBACK-01.md` (new). No application code changed this session.
- **Finding 1 — visual-mode round trip is lossy and unsafe for full documents.** Dustin's top wish is WorkFlowy-style editing inside the rendered view. `WorkLists/public/markdownEditor.js` already supplies the toolbar and a three-mode controller including a contenteditable visual mode, so the chrome exists. But driving `markdown-kitchen-sink.md` through `renderMarkdownForVisual()` → `htmlToMarkdown()` loses **12 of 41 content lines**: every task checkbox state is destroyed (`- [x] Done` → `- Done`), nested list items merge onto one line, the code fence is corrupted by the copy button's label leaking into content, table alignment is flattened, and `---` rules vanish. Acceptable for a short card note; it would eat the feature this project exists for. Conclusion recorded: build inline editing **per block** with a splice commit — the mechanism that already makes the checkbox safe — never whole-document HTML round-tripping.
- **Finding 2 — the Argus palette conflicts with the WorkLists integration constraint.** Dustin asked to move the colors toward Argus and pointed at the SaySlate extension as a Cursor-like reference. Read both: Argus is `#0b0f0e` with a `#d9ff70` lime accent; SaySlate dark is `#181818` with `#88c0d0` and **translucent** line colors. Cairn currently matches WorkLists (`#1f1f1f` / `#5b9bd5`) precisely because the WorkLists changelog forbids a second dominant palette. Recommendation recorded: two `:root` token blocks — Argus-dark standalone, WorkLists-dark when embedded — which unblocks the palette work without waiting on the standalone-vs-embedded decision.
- **Multi-root feasibility answered:** yes. `showDirectoryPicker()` is callable repeatedly for N roots; handles persist in IndexedDB (not `localStorage`); reopening needs a user-gesture permission re-grant, which is unavoidable in Chromium and surfaces as a _Reconnect workspace_ click.
- **User-visible impact:** None — capture and investigation only.
- **Tests run:** No gates apply to a docs-only session. The two findings were produced by executing real code, not by inspection: the round-trip loss was measured by loading the actual WorkLists renderer and editor into headless Chromium and diffing input against output.
- **Tests added/updated:** None — not relevant: no behavior changed. The round-trip harness is scratch, not committed; it should become a real spec when item 12 is built, since it is the regression guard that would catch checkbox destruction.
- **Regression impact:** Isolated — one new markdown file in `PDProjects/Cairn`. No application code, in Cairn or WorkLists, was read-modified this session.
- **API docs:** Not relevant — no HTTP surface exists in this project; no route, DTO, or auth decorator to check.
- **Tooling gates:** `audit` — not applicable: no `package.json` in `Cairn` or at `PDProjects` root. `lint` — no lint script; formatted with the WorkLists Prettier binary, `prettier --check .` clean.
- **Conflicts / exceptions:** WorkLists board still not updated — no card id supplied, and `worklists-card-sync` forbids searching for the card. Unchanged from the previous session; still waiting on the id or on approval plus a template pointer.

### 2026-08-20T00:00:00Z — POC 1: markdown vault shell

- **Summary:** Created the Cairn project and a runnable look-and-feel POC for a markdown vault that reads like OneNote and behaves like VS Code.
- **Problem:** Reading and ticking off markdown notes currently means opening Cursor. There was no evidence about whether a browser-hosted vault UI could feel good enough to live inside WorkLists, and no basis for deciding the harder questions (file access, editor choice, write-back) without that evidence.
- **Requirement:** A vault must be browsable as a tree, readable in preview by default with source one keystroke away, and a checkbox ticked in the preview must rewrite exactly one line of markdown source. It must be judgeable without installing anything, and it must not be able to damage real notes.
- **Solution:** A zero-build prototype at `PDProjects/Cairn` following the shape of the Argus POC (`index.html` + `styles.css` + `app.js`, seeded content, open the file to run). Markdown rendering is a verbatim vendored copy of the WorkLists renderer, so `updateTaskCheckboxMarkdown()` supplies the single-line splice rather than a new implementation. The real-folder path is read-only by design; every save target is browser storage.
- **Code name:** Cairn — a stacked trail marker left for whoever comes next. Same mineral family as Obsidian without imitating it; no collision with an existing PDProjects folder or a known markdown tool (unlike Slate → Slate.js, Quartz → Obsidian Quartz).
- **Files/areas:**
  - `PDProjects/Cairn/index.html`, `styles.css`, `app.js` — shell, visual language, behavior
  - `PDProjects/Cairn/vendor/markdown-renderer.js` — verbatim copy of `WorkLists/public/markdownRenderer.js`
  - `PDProjects/Cairn/sample-vault/**/*.md` + `sample-vault.js` + `tools/build-sample-vault.mjs` — sample content on disk plus its generated embedded copy (`fetch()` is blocked on `file://`)
  - `PDProjects/Cairn/README.md` — run instructions, what it proves, intentionally unresolved
- **User-visible impact:** OneNote-style section tabs from top-level folders; keyboard-navigable explorer tree; tab strip with dirty markers; Preview / Split / Source modes; checkbox-to-source rewrite; favorites; `Ctrl+P` fuzzy quick open; outline rail with an `Alt+↑/↓` heading pointer; resizable sidebar; session restore.
- **Defects found and fixed during runtime verification** (all root-cause fixes, no overrides or tuned constants):
  1. Split mode stacked the panes vertically. The `::before` divider is the first grid item in box order, so leaving the preview pane to auto-place pushed it onto a second grid row. Fixed by placing all three split children explicitly.
  2. Vertical rhythm was counted twice — the renderer emits a `markdown-blank-line` spacer per source blank line, and CSS block margins were also firing. Collapsed the spacer to zero so block margins are the single owner of rhythm in a full document.
  3. The empty Favorites group stayed visible: `.sidebar-group { display: flex }` outranks the `[hidden]` attribute's default `display: none`. Added `.sidebar-group[hidden] { display: none }`.
  4. Nested lists carried the top-level list's block margins, adding a paragraph gap per indent level. Scoped `li > ul, li > ol` to the list-item margin; item pitch is now uniform at 26–27px across depths.
- **Finding recorded, not fixed:** the vendored renderer joins paragraph lines with `<br>`, so soft-wrapped prose renders with hard breaks where standard markdown would join them. Left verbatim to preserve parity with WorkLists and documented as an open decision; `sample-vault/Notes/markdown-kitchen-sink.md` demonstrates it.
- **Tests run:** No unit harness exists in this repo (see **Tooling gates**). Verified by driving the real page in headless Chromium via Playwright resolved from the WorkLists workspace. Confirmed: exactly one source line changes when a checkbox is ticked (`- [ ]` → `- [x]` at line 9, total line count unchanged); split panes share a row and span the full width; favorites, edited text, view mode, and active tab all survive reload; all 7 sample files render; no page or console errors; zero horizontal overflow at 1520px and 960px.
- **Tests added/updated:** None — blocked. This POC has no test harness and no `package.json`; adding the first one would mean scaffolding a runner unrelated to the look-and-feel question this POC exists to answer. Residual risk: no regression guard on the checkbox round-trip or the tree/keyboard behavior. Smallest follow-up that unlocks coverage: a `package.json` with Playwright plus the assertions already written for this session's verification.
- **Regression impact:** Isolated — new top-level project folder. No file in `WorkLists` or any other repo was modified; the WorkLists renderer was read and copied, never edited (`WorkLists/public/markdownRenderer.js` is byte-identical to `Cairn/vendor/markdown-renderer.js`).
- **API docs:** Not relevant — no HTTP surface in this POC. No route, method, DTO, status, or auth decorator exists to change; the prototype makes no network calls.
- **Tooling gates:** `audit` — not applicable: no `package.json` at `PDProjects` root or in `Cairn`. `lint` — no lint script in this project; formatted with the WorkLists Prettier binary and config against `index.html`, `styles.css`, `app.js`, `README.md`, `tools/`, and `sample-vault/**/*.md`; `prettier --check .` reports clean. `vendor/` and the generated `sample-vault.js` are `.prettierignore`d so parity diffs against WorkLists stay readable.
- **Conflicts / exceptions:** WorkLists board not updated — no card id was supplied and `worklists-card-sync` forbids searching for a card by title or ticket id. The WorkLists server was reachable (`GET localhost:3010/openapi.json` → 200), so this is a missing-input stop, not the server-down skip. Waiting on the card id, or on approval plus a template pointer to create one.
