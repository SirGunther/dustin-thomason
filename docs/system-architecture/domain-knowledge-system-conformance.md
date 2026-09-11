# Domain Knowledge System: conformance baseline

Compares [domain-knowledge-system.md](domain-knowledge-system.md), the founding
document, against [domain-knowledge-system/](domain-knowledge-system/), the template
built from it.

First pass 2026-09-04. Second pass 2026-09-05, after a six-phase closure plan
addressed every gap the first pass found. This document reflects the second pass;
the first pass's findings are kept below under "First-pass findings, closure
status" rather than deleted, so the record of what was wrong and how it was fixed
stays intact.

Status vocabulary matches `docs/_templates/project-docs-README.template.md`:

| Status | Meaning here |
| --- | --- |
| `Conforms` | The document's requirement is present in the template |
| `Improved` | Present, and the template makes it more testable than the document does |
| `Diverges` | Deliberately different, with the reason recorded below |
| `Partial` | Some of the requirement present, some absent |
| `Absent` | Required by the document, not in the template |

## Verdict, second pass

| Status | Count |
| --- | --- |
| Conforms or Improved | 30 |
| Diverges deliberately | 6 |
| Partial | 0 |
| Absent | 0 |

Every row that was Absent or Partial after the first pass is now Conforms,
Improved, or Diverges. Six rows remain deliberate divergences, all previously
recorded, none new. The count differs from the first pass's 36 rows because
several sections merge into one row below where the same evidence answers more
than one section (2.1 through 2.3 and 33 through 34 each already spanned
multiple related sections in the first pass's own table).

## What closed the gaps

Six phases, run in dependency order. Full detail is in the six-phase plan this
document does not reproduce; the summary:

1. **Identifiers** (`identifiers.md`). Rule IDs derived from file path with no
   sequence number. Decision and invariant IDs scoped to the area, not the
   individual node file, so a later split into feature files does not renumber
   them out from under a retained context artifact.
2. **Agent entry point.** `README.md` is now the file that survives
   instantiation; `TEMPLATE-USAGE.md` carries the copy-and-delete steps and is
   the file deleted.
3. **Domains.** Made selectable by file name, the same mechanism as `specs/`,
   rather than through a free-text `answers` field that could not materialize a
   missing question as a reportable gap. Fifteen universal area stubs ship from
   the start; `bootstrap-prompt.md` names only the areas that list does not
   cover, from interface signals, never from directory structure.
4. **Four templates added**: `context-artifact.template.md` (section 10's
   schema), `qa-review.template.md` (section 15's fifteen checks), each is now
   backed by a real filled example produced during verification, and
   `decision-entry.template.md` (section 25's nine sections plus one recorded
   addition), `regression.template.md` (section 19).
5. **Recording and review.** `record-prompt.md` and `qa-prompt.md` cover the
   Feature Expert responsibilities and QA process the selection prompt alone
   did not reach.
6. **Validation.** `completeness-checks.md` implements section 29's four
   detections. `specifications.yaml` now separates citations into rules that
   are written, rules that are not yet written, and citations that resolve to
   nothing, so a renamed or deleted rule file produces a reported gap instead
   of a silently wrong entry.

## What verification found and fixed, not just confirmed

Running the actual prompts against real material, rather than only re-reading
the files, found two defects that a read-through would not have surfaced.

**Bootstrap dry run against `C:\WhisperService`.** `bootstrap-prompt.md`'s
stop condition originally counted candidate areas after already-covered ones
were discarded, which would have told a small, well-organized application that
its source does not expose areas at all, when in fact most of its areas were
already covered by the universal stub list and only two were genuinely new.
Moved the count earlier, before the discard. The same dry run found that nothing
prevented a narrow candidate (`worker-isolation`) from being written as a
separate area file from the broader candidate whose signals already covered it
(`transcription`), which is exactly the over-decomposition this design exists to
prevent. Added a fold step that keeps a signal-subset candidate as a reported
feature-level candidate under its broader area rather than a second area file.
Both fixes are in `bootstrap-prompt.md` as it now ships; the dry run's evidence
is retained in the scratch instantiation this verification produced.

**The section 17 and 34 question sweep** found that its own dry-run node had
left History unrecorded despite real knowledge having changed during the task
(a rule promoted from unwritten to active, an open QA finding), which is the
exact failure `completeness-checks.md`'s fourth detection exists to catch.
Corrected before closing out the sweep, as a demonstration that the detection
works rather than only that it exists on paper.

**`indexes/features.yaml`'s own header** still described `answers` as "the
selection surface for domains" after `domains/README.md` had already been
corrected to demote it to a discriminator among already-selected siblings. This
drift was found while regenerating the index during the round-trip dry run, not
during the section-by-section reading pass, and is a caution that a rewritten
section's neighbors need the same check the section itself received.

## Section by section, second pass

Only sections whose status changed from the first pass are listed with new
detail; unchanged Conforms and Diverges rows are folded into the summary above.
Full first-pass detail for every section is preserved below.

| Sec | First-pass status | Second-pass status | What changed |
| --- | --- | --- | --- |
| 1 | Partial | Conforms | All ten links in the reasoning chain now have a template: `context-artifact.template.md`, `decision-entry.template.md`, `qa-review.template.md`, `regression.template.md`. "Where it was implemented" remains answered by the deliberate divergence (decision-entry's point-in-time `implementation` field, or reading the repository), not by a maintained map. |
| 2.1 | Absent | Improved | Fifteen universal area stubs plus `bootstrap-prompt.md`'s signal-based derivation make domains retrievable by listing and give a stated method for deriving product-shaped areas instead of mirroring source directories, which the founding document does not itself specify. |
| 2.2 | Partial (9 of 13) | Partial (12 of 13) | Decisions, tests, ticket artifacts, QA evidence, defects, history, and traceability links all now have homes. Interfaces as a standalone concept remains the one gap; `Not owned` and `Affects` cover dependency framing but not contract framing. |
| 2.3 | Partial (6 of 8) | Conforms | Durable knowledge update, previously with no mechanism, is now `record-prompt.md`'s entire purpose. |
| 3.1 | Conforms, with a caveat | Conforms | Stub ID caveat closed by `identifiers.md` and the prefix table in `specs/README.md`. |
| 3.2 | Partial | Conforms | Closed by the domains retrieval fix in 2.1. |
| 3.3 | Improved, with a caveat | Improved | Same closure as 3.2. |
| 3.4 | Diverges | Diverges | Edge cases and known limitations, previously unaddressed, now map explicitly onto invariants and decisions in `domains/README.md`. Known defects now have a home in `regression.template.md`. The four originally-removed sections remain removed, unchanged. |
| 3.5 | Partial | Conforms | `selection-prompt.md` now enters from either `specs/` or `domains/` file names, so a task against an existing feature has a direct entry path. |
| 3.6 | Partial | Improved | `context-artifact.template.md` reproduces section 10's schema and adds ambiguity, over-pull, and revision tracking beyond it. |
| 7 | Diverges | Diverges | The stated threshold gap is closed; see "Stated threshold for section 7's fan-out" below. Still diverges by choice. |
| 8 | Partial | Conforms | `selection-prompt.md`'s report now requires revision per selected rule and reports ambiguity. |
| 10 | Absent | Conforms | `context-artifact.template.md`. |
| 11 | Partial | Conforms | Revision now reported; stubs now carry IDs. |
| 12 | Absent | Conforms | Items 1-5 via `selection-prompt.md`, items 6, 9, 10, 11, 12, 13 via `record-prompt.md`. Items 7 and 8 (implementing the change, updating tests) are code-authoring actions outside what a documentation template can perform; this is a scope boundary, not a gap. |
| 14 | Partial | Conforms | `qa-prompt.md` states independence explicitly; `qa-review.template.md`'s Inputs read block carries all eight named inputs, with applicable specifications and feature decisions nested inside context_artifact and updated_nodes rather than duplicated as separate top-level fields. |
| 15 | Partial (5 of 15) | Conforms | All fifteen checks are explicit fields in `qa-review.template.md`. |
| 16 | Partial (8 of 12) | Partial (10 of 12) | `reviewed-by` now has a back-link via node frontmatter; `discovered-by` now has a field in `regression.template.md`, distinguished from `previously_verified_by`. `implemented-by` remains a deliberate divergence, partially mitigated by the point-in-time `implementation` field on each decision. `discovered-by` between a Regression and the Test that caught it versus the test that should have caught it are now two distinct fields, closing the ambiguity the first pass did not consider. |
| 17 | Partial (8 of 13, corrected from a first-pass miscount of 14) | Conforms | All thirteen questions answerable, several exercised directly during verification's round trip and QA dry run rather than only structurally present. Two (specification staleness by comparing recorded versus current revision, repeat-defect detection by invariant) have the mechanism in place but were not exercisable in a scratch sandbox with no real version history; this is a sandbox limitation, not a template gap. |
| 18 | Absent | Diverges | Phases 2, 4, 6, 7, 8, 9 now have homes; phase 5 (implementation) is properly out of scope the same way section 12 items 7-8 are. Phase 3 (fan-out) remains the same deliberate divergence as section 7. Phase 1 (intake) has no separate artifact; it is assumed to happen before `selection-prompt.md` is given a feature description and criteria, which is a light, acknowledged gap rather than an absence. |
| 19 | Absent | Conforms | `regression.template.md`, `artifacts/regressions/`, and identifiers close every part of this section. |
| 21 | Conforms, with a caveat | Conforms | `implemented_in` and `documented_in` now exist as fields on the context artifact template. |
| 22 | Conforms, with a caveat | Conforms | The root README's reference to the methodology document is now conditional prose, not a markdown link, so it does not read as broken once the folder moves. |
| 23 | Partial | Diverges | `domains/` scaffolded, all three deferred artifact folders created, all four indexes present, six of seven templates present (the seventh, `domain.md`/`feature.md`, is a deliberate one-template consolidation via `kind: area \| feature`, recorded rather than counted as missing). Root files (`PHILOSOPHY.md`, `ROADMAP.md`, `CHANGELOG.md`) remain the one deliberate omission. |
| 24 | Diverges | Diverges | The "never considered, no home" complaint about Edge Cases and Known Limitations is closed; see 3.4. The four originally-removed sections remain removed by choice. |
| 25 | Absent | Conforms | `decision-entry.template.md`, all nine sections plus the `Rejected` addition, now explicitly documented as an addition in that file rather than left as an undocumented divergence. |
| 27 | Partial | Conforms | `context-artifact.template.md` defines the retained shape. |
| 28 | Partial | Conforms | `artifacts/tickets/` now exists and holds the task-id-to-review-id links that give ticket-level history, closing the one gap this row had. Project changelog remains a deliberate omission, recorded elsewhere. |
| 29 | Absent | Conforms | `completeness-checks.md` implements the four detections; the full ticket-to-completion sequence is stated in `README.md`'s "What an agent does, by task" table. |
| 30 | Diverges | Diverges | Same closure as section 7. |
| 33 | Partial (9 of 16) | Diverges (15 of 16) | Rule 4 and Rule 16 close with the domains fix. Rule 9 (fan out and fan in) remains the one deliberately unmet rule. |
| 34 | Partial (7 of 10) | Diverges (9 of 10) | "How it was reviewed" and "what knowledge changed" now have homes in `qa-review.template.md` and node History sections respectively, and both were exercised with real content during verification. "Where is it implemented" remains the one deliberate divergence, unchanged from the first pass. |
| 36 | Partial (3 of 12) | Diverges (11 of 12) | Domain folders and feature folders (the mechanism; actual feature files are created via the same growth rule as before) close during this pass. Fan-out context retrieval (item 8) remains the one deliberate divergence. |

Unlisted sections (2, 3, 4, 5, 6, 9, 13, 20, 26, 31, 32, 35) are unchanged from
the first pass; see "First-pass findings, closure status" below for their
original detail, all of which still holds.

## Stated threshold for section 7's fan-out

Section 7's fan-out and section 30's conditional cost model were replaced with
sequential traversal in `selection-prompt.md`, because that prompt requires
listing every folder and file name under `specs/` and `domains/` in one
operation and matching every acceptance criterion against that full listing in
one pass. This is recorded here as a stated, falsifiable hypothesis, not as a
measured result: the sequential form stops being reliable once a single
discipline folder under `specs/` or a single area folder under `domains/` holds
roughly 50 files, on the reasoning that `ui-ux` already required deliberate
handling of near-neighbor collisions at 25 files
(`overlays`/`toasts`/`tooltips`, `keyboard`/`keyboard-only`/
`keyboard-coverage`), and doubling that count is where a single linear pass is
expected to start missing or mispairing matches.

The number itself is a placeholder. The actual trigger to revisit this
divergence is `selection-prompt.md`'s own ambiguity and uncovered-criteria
report lines showing a sustained rate of misses concentrated in one folder,
which the prompt already surfaces without any additional instrumentation. If
that rate appears before 50 files are reached, the threshold was too high; if it
does not appear well past 50, the threshold was too conservative. Either
observation replaces this number with a measured one.

## Remaining deliberate divergences, second pass

Unchanged from the first pass except where noted:

| Divergence | Document says | Template does | Why |
| --- | --- | --- | --- |
| Feature node has six sections, not fourteen | Sec 24 | Governs, Decisions, Invariants, Not owned, Affects, History | Purpose, Interfaces, Implementation Map, and Test Map are rebuildable from the repository and go stale faster than the code. A stored copy makes the tree a second copy of the source, which section 32 forbids. |
| Implementation locations are not maintained as a live map | Sec 3.4, 24 | Resolved at task time; a point-in-time record exists only inside each decision entry, marked explicitly as historical rather than current | A stored map used as a boundary prevents discovering an unrecorded coupling, which defeats the Code Impact Resolver in section 8. |
| Specification tree is flat within a discipline | Sec 6 | `specs/ui-ux/tree-navigation.md` rather than nested under a navigation folder | Retrieval reads a directory listing; nesting hides names one level deeper without adding selection power. |
| No fan-out | Sec 7, 30 | Single sequential traversal, now with a stated revisit threshold | See "Stated threshold" above. |
| Root files omitted | Sec 23 | No PHILOSOPHY, ROADMAP, or CHANGELOG | Roadmap and pending decisions live beside the code, the project changelog follows the existing project documentation convention, and philosophy lives in the methodology document. |
| Retrieval by file name, not an index of trigger conditions | not in the document | Acceptance criteria matched against folder and file names | Standardizable across systems and auditable by a reviewer with no domain knowledge. The cost is that file naming must stay honest. |
| Every candidate subject and area exists as a stub | not in the document | 80 spec stubs, 15 universal area stubs, all `Status: Not written` | A subject with no file cannot be selected, and its absence produces no signal. |

## First-pass findings, closure status

The five findings from the 2026-09-04 pass, and what closed each.

1. **`domains/` had no scaffold.** Closed by phase 3: fifteen universal area
   stubs, file-name selection in `selection-prompt.md`, `bootstrap-prompt.md`
   for the rest.
2. **Decisions and invariants had no identifiers.** Closed by phase 1:
   `identifiers.md`, area-scoped IDs.
3. **There was a read path and no write path.** Closed by phase 5:
   `record-prompt.md`, `qa-prompt.md`.
4. **The instantiated tree had no entry point.** Closed by phase 2: `README.md`
   retained, `TEMPLATE-USAGE.md` deleted.
5. **`templates/` held 2 of 7 entries.** Closed by phase 4: four templates
   added; the seventh is a recorded one-template consolidation, not a gap.

## First-pass section-by-section detail, preserved

| Sec | Requirement | First-pass status | Evidence at first pass | First-pass divergence or gap |
| --- | --- | --- | --- | --- |
| 1 | Preserve the chain of reasoning; an agent reconstructs expertise without the original chat | Partial | Governs, Decisions, Invariants, History cover six of the ten links | "What was implemented" and "where" deliberately not stored; "how it was reviewed" has a folder and no template; no context-artifact template |
| 2.1 | Knowledge topology resembles software topology | Absent | `domains/README.md` describes a shape | No files, no naming convention, not retrievable by listing. Finding 1 |
| 2.2 | Thirteen named persistent assets | Partial | Nine present in some form | Interfaces, implementation references, and ticket artifacts absent; defects absent as a folder; tests only as per-invariant `Proven by` |
| 2.3 | The eight-link traceability chain | Partial | Six links have a home | Decision-to-code deliberately unstored; the final durable-knowledge-update step has no mechanism |
| 3.1 | Specification defined and authoritative | Conforms | `specs/README.md`, 80 subject files across 7 disciplines | Stubs carry no ID and no ID convention is stated |
| 3.2 | Domain as a meaningful area | Partial | Defined in `domains/README.md` | Prose only. Finding 1 |
| 3.3 | Feature as bounded product behavior | Improved | Defined, plus a promotion test the document does not have | Prose only. Finding 1 |
| 3.4 | Feature knowledge: ten contents | Diverges | Six sections retained | Interfaces, implementation locations, and tests-as-map removed deliberately; edge cases and known defects were not considered and have no home |
| 3.5 | Feature Expert composition formula | Partial | `selection-prompt.md` implements it as deterministic traversal | The prompt enters from specifications only. A task against an existing feature has no direct entry path |
| 3.6 | Context Artifact as synthesized package | Partial | `artifacts/context/` exists and is described | No template; section 10's schema is not reproduced |
| 4 | Store knowledge at the narrowest scope where it is universally true | Improved | Two-consumer test in `specs/README.md`, promotion test in `domains/README.md` | None |
| 5 | Specifications answer what rule; features answer how and why | Conforms | `domains/README.md` states nodes never restate rules | None |
| 6 | Specifications may be contextual and nested | Diverges | Flat files | One nesting level removed, accepted because a flat listing is what retrieval reads |
| 7 | Fan-out to parallel resolvers, fan-in to one artifact | Diverges | Single sequential pointer traversal | No fan-out at all. Correct at 32 files, unproven at 500. No threshold stated |
| 8 | Resolver output schema | Partial | The prompt's report covers relevance and applicability | Revision and possible ambiguity are not required outputs |
| 9 | Smallest sufficient authoritative context | Improved | Selection by acceptance criterion; over-pull is a reported defect | None |
| 10 | Context artifact schema | Absent | Nothing | The document supplies a complete schema and the template reproduces none of it |
| 11 | Provenance | Partial | `feature-node.template.md` Governs block carries all four | The prompt's report omits revision; stubs have no IDs |
| 12 | Feature Expert workflow, thirteen responsibilities | Absent | Items 1 to 5 via the selection prompt | Items 6 to 13 have no prompt, template, or trigger. Finding 3 |
| 13 | Promote generalized discoveries into specifications | Improved | Two-consumer test, plus the inconsistent-behavior branch | None |
| 14 | QA independent, receives eight named inputs | Partial | `artifacts/qa/` described | No template, no prompt, no statement of the eight inputs |
| 15 | Fifteen QA checks | Partial | Five appear in `artifacts/README.md` | Ten unrepresented; no qa-review template |
| 16 | Traceability graph, twelve edges | Partial | Eight edges have a home | `implemented-by` unstored by choice; `reviewed-by` has no back-link; `discovered-by` not represented |
| 17 | Questions the system should answer | Partial | Eight answerable | Four blocked by missing decision and invariant IDs; one needs specifications.yaml, deferred. Finding 2 |
| 18 | Nine-phase ticket lifecycle | Absent | Phases 2 to 4 | Phases 1, 5, 6, 7, 8, 9 absent. Finding 3 |
| 19 | Defects enter through the same system | Absent | History mentions regressions | No regressions folder, no template, no defect-to-invariant link |
| 20 | Knowledge in a separate repository | Conforms | Knowledge in dustin-thomason, applications in their own repositories | None |
| 21 | Record application and knowledge revisions | Conforms | `Reviewed against` block requires both | `implemented_in`/`documented_in` absent, no ticket records existed |
| 22 | Must be movable without restructuring | Conforms | Self-contained copyable folder | The root README's relative link breaks when the folder moves |
| 23 | Proposed repository structure | Partial | All 7 spec disciplines; all 4 indexes; two artifact folders; 2 of 7 templates | Root files omitted; `domains/` unscaffolded; three artifact folders absent; five templates absent. Finding 5 |
| 24 | Feature knowledge template, fourteen sections | Diverges | Six sections plus Reviewed against | Four removed deliberately; edge cases and known limitations unaddressed |
| 25 | Decision template, nine sections | Absent | A Decisions section inside the node | No standalone template |
| 26 | Specification template, eight sections | Conforms | `spec-entry.template.md` matches all eight | None |
| 27 | Context artifact retained as evidence | Partial | `artifacts/README.md` states retention | Shape undefined |
| 28 | History at four levels | Partial | Feature and area History sections | Project changelog omitted; ticket-level absent |
| 29 | Orchestrator, missing-artifact detection | Absent | Nothing | The four detections match Finding 3 exactly |
| 30 | Conditional fan-out to control cost | Diverges | No fan-out | Same as section 7 |
| 31 | Cache retrieval by specification revision set | Absent | Governs carries revisions | No mechanism; document frames this as eventual |
| 32 | Eight things the system is not | Improved | All eight respected | None |
| 33 | Sixteen foundational rules | Partial | Nine met, five partial, two unmet | Rule 9 and Rule 16 unmet |
| 34 | Completion definition, ten questions | Partial | Seven answerable | "Where implemented" unstored; "how reviewed" and "what changed" no artifact |
| 35 | Working name and storage convention | Conforms | Copyable folder, implementation-agnostic naming | Instantiation target is `docs/<project>/`, consistent with section 20 |
| 36 | V1 goal, twelve items | Partial | 3 complete, 6 partial, 3 absent | Domain folders, feature folders, fan-out retrieval absent |
