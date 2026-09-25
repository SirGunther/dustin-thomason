# Orchestration — atlas/INT-138

**Location note:** the artifacts for this ticket live at `docs/atlas/INT-138/`, not at the skill's default `docs/atlas/tickets/<slug>/`. That follows the atlas per-ticket convention (PRDV-16312, PRDV-16313 and PRDV-16461 do the same), and the user put the original ticket here at kickoff. Artifact filenames carry the `INT-138-` prefix, the same way PRDV tickets carry theirs. Later phases use the standard subfolders (`stories/`, `investigations/`, `specs/`, `testing/`, `dnu/`) under this root.

| WorkLists card | todo-1790172671871-1461f0f9 |

| Phase | Status | Artifacts | Date | Notes |
| --- | --- | --- | --- | --- |
| 0 Capture | done | `INT-138-original-ticket.md` (refreshed in place), `stories/INT-138-job-stories-index.md`, `stories/INT-138-job-story-01-categorization-audit.md`, this ledger; changelog `docs/atlas/INT-138-changelog.md` | 2026-09-23 | **Original ticket:** the user supplied the file containing only the raw ticket body. I rewrote it into the artifact shape (metadata, constraints, context paths). The Original Request is the user's text **byte-for-byte**, checked with `cmp` against a copy taken before the edit. **Story 01** was drafted: 6 criteria and 9 open questions (5 fact for Phase 1 to trace, 4 decision). It is one story because there is one motivation over one action. **Changelog** was copied from the template by hand, because `new-ticket-changelog.ps1` accepts only `PRDV-\d+`. It was new, so there were no Current state, Plans or Attempt history entries to align with. **Card id:** path A, supplied by the user. **Board: guard stop.** See the WorkLists board table. **Kickoff override:** the user said to put all three repos on `main` and stash any work. That touched implementation repos (git only, no file edits) before Phase 1, and the user explicitly authorised it. See the Kickoff record. The context path `C:\dustin-thomason\.agents` does not exist on disk |
| 1 Recon and plan | done | plan staged; saved verbatim to `investigations/INT-138-recon-and-plan.md` at Phase 2's first action (`cmp` identical to the approved plan file) | 2026-09-23 | The recon ran three read-only Explore agents (Callisto, Europa, Atlas), and I checked the load-bearing claims myself. **Reframed:** this is not a new log. It is a gap in what Callisto sends to the audit pipeline. **Recategorize sends nothing to the audit log.** Approve and upload send `APPROVED`/`CREATED` but without type or collection. **Europa needs no code change**, because it stores and filters any type string, and its filter is exact and case-sensitive. The dropdown lives in `atlas-front-end` `src/europa/utils/constants.ts`. **One event per file is required**, because Europa shows only resource `[0]`. **Consulted:** PRDV-16192 was reused for Europa ingest and storage, and its projection and grid areas were reopened because the code changed (`d71f2bd`, `c2814144`). PRDV-16312/16313 were used as pointers only. `larry-adams` has no INT-138 spec. **Story:** OQ-04, OQ-06 and OQ-08 were answered by evidence. OQ-02, 05 and 07 were split into fact and decision. 8 decisions (D1–D8) are carried with owners, and D1 and D2 gate the spec. The plan was approved by the user without edits |
| 2 Report | done | `investigations/` — `INT-138-recon-and-plan.md` (frozen), `-investigation.md`, `-coverage-ledger.md`, `-diagrams.md`; `testing/INT-138-test-plan.md` (seeded); `INT-138-why-these-changes.md`; `INT-138-future-development-concerns.md` (C1–C6); `INT-138-pr-draft.md` (shell); `stories/` reconciled (7 criteria, 7 open decisions); changelog session log `2026-09-23T18:55:00Z` | 2026-09-23 | **Verdict: proceed with conditions.** D1 and D2 gate the spec. `check-steps.ps1 -ThroughPhase 2`: 10 VERIFIED, 7 REVIEW (Phase 0/1 judgement items, satisfied in the artifacts named), 8 n/a, 0 MISSING. The report has no fenced blocks and §5 links the diagrams. The Mermaid diagrams are hand-checked, not machine-rendered (no renderer installed). Board is blocked by the guard at phase start and completion; the rows I would have marked are named in the board table. All three app repos are clean on `main` at their baselines |
| 3 Probe & spec | in-progress | | 2026-09-23 | Auto-advanced from Phase 2 (same mode) |
| 4 Prep | pending | | | |
| 5 Implement | pending | | | |
| 6 Manual review | pending | | | |

Resume: Phase 3 — Working mode

## Kickoff record (user instruction: repos on `main`, stash any work)

Done 2026-09-23T18:01Z. For each repo: `git stash push -u` (only if dirty), `git checkout main`, `git pull --ff-only`.

| Repo | Branch before | Working tree before | Stash created | `main` now at |
| --- | --- | --- | --- | --- |
| atlas-front-end | `PRDV-14184-spec` | clean | none | `26eaa0bbe1b6f5f4a7a1bbdb8587ccab8e432584` |
| europa-back-end | `PRDV-16597` | `.prettierrc`, `.swcrc` modified. The diff was empty apart from line endings (CRLF warnings only) | `stash@{0}`: "WIP on PRDV-16597 before INT-138 main sync 2026-09-23T18:01:11Z". `git stash show --stat` is empty, which confirms the change was line endings only | `1082fdad063c034e97b4fcd7b4d9f9c5cf766bdf` |
| callisto-back-end | `main` | clean | none | `59b1abd39d50139df0287f44f726ad1b49626b2e` |

All three trees were clean after the sync.

## WorkLists board

| Phase | Write | Result |
| --- | --- | --- |
| 0 start (`currentStep`) | **not written: guard stop, ticket-id mismatch** | `GET /todos/todo-1790172671871-1461f0f9` resolved, but the card's title line is `# Ticket Template` and the expected ticket id is `INT-138`. Per `worklists-card-sync`, nothing was written. The checklist note `9903b1bf-44a7-4e0a-8ed4-318cb5eeac6d` exists and has the standard sections (Preliminary through Ticket Closeout). Card status is `Unrefined`. The card was created 2026-09-23T14:11:11Z and looks like it came from the template but was never renamed |
| 0 completion (rows, `nextUp`) | **not written: same guard** | Rows I would have had evidence for: none in Phase 0. "Generated ticket for the work to be done" refers to the card itself, which is outside what Phase 0 produced, so it would have stayed unmarked anyway. Board writes resume once the card title carries `INT-138` or the user confirms this card is correct |
| 1 (Plan phase: nothing to write; its phase-start write moves to Phase 2) | n/a | — |
| 2 start (`currentStep`) | **not written: guard stop, ticket-id mismatch** | I re-read the card on 2026-09-23 at Phase 2's first action. The title is still `# Ticket Template` and `lastModified` is still `2026-09-23T14:11:25.179Z`, so the card has not been edited since Phase 0. The expected id is `INT-138`. Nothing was written. I sent a notification |
| 2 completion (rows, `nextUp`) | **not written: same guard** | These **Investigation** rows have evidence and would be marked once the guard clears: "Generate Artifacts", with both of its children ("Investigation Report to validate the Spec to be written" = `investigations/INT-138-investigation.md`; "LucidChart - Mermaid diagrams of current vs target summary" = `investigations/INT-138-diagrams.md`, which is Mermaid, not LucidChart). **Left unmarked:** "Contact relevant parties for clarification (if needed)" and "Loop in Pair Programmer + set up discussion session (if needed)". Neither happened; the facts were resolved from code, and the decisions go to Phase 3. Would-be `nextUp`: "Phase 3: resolve D1/D2 with Product, write the spec" |
