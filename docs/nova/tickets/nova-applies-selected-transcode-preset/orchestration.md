# Orchestration — nova/nova-applies-selected-transcode-preset

**Ticket:** PRDV-16398 — Nova applies selected video transcode preset (Video Mix)
**Implementation repo:** `C:\Users\dustin.thomason\nova-back-end` (git)
**Changelog:** `docs/nova/PRDV-16398-changelog.md`
**Rigor:** full — all seven phases (user-confirmed 2026-07-28)

| Phase | Status | Artifacts | Date | Notes |
| --- | --- | --- | --- | --- |
| 0 Capture | done | `PRDV-16398-original-ticket.md`, `orchestration.md`, `docs/nova/PRDV-16398-changelog.md` | 2026-07-28 | Capture pre-existed at `docs/atlas/PRDV-16398-original-ticket.md`; moved to canonical `docs/nova/tickets/<slug>/` per user decision. Original Request unchanged. `<Project>` = `nova` chosen over `nebula`/`atlas`. |
| 1 Investigate | done | approved investigation plan (`~/.claude/plans/go-twinkly-popcorn.md`); `PRDV-16398-why-these-changes.md` | 2026-07-28 | Ledger row + Why doc were `deferred (plan mode)`, materialized as Phase 2's first action. **Class reframed** from "consumer half never built" to "contract vocabulary mismatch" — see Why doc. A1–A10 all resolved by evidence; D1–D6 are genuine decisions staged for Phase 3. Phase 0's docking-protocol skew flag closed (stale local install). |
| 2 Report | done | `investigations/PRDV-16398-investigation.md`, `-coverage-ledger.md`, `-diagrams.md`, `testing/PRDV-16398-test-plan.md`, `PRDV-16398-future-development-concerns.md`, `PRDV-16398-pr-draft.md` (shell) | 2026-07-28 | Disposition **proceed with conditions**. Software lens reconciled per point. 7 alternatives recorded, incl. the shape Larry's spec implies. Two AC added (7: vocabulary convergence; 8: red→green) as consequences of the reframing. AC 2 vs the drift note is a live contradiction → D4. |
| 3 Probe & spec | done (partial) | `specs/PRDV-16398-locked-decisions.md` | 2026-07-28 | **No separate spec written** — Dustin ruled Larry's spec is the implementation shape unless the investigation found genuine drift (LD-000); it didn't, so a second spec would have been duplication. Locked-decision ledger stands as the Phase 3 record. **Correction logged in that file:** an earlier version recorded six decisions as "agent default" that were Dustin's to make; he pulled it back and set a standing no-unapproved-changes rule. |
| 4 Prep | skipped (Dustin directed straight to implementation) | — | 2026-07-28 | Missing downstream input: no separately approved implementation plan. Mitigated by LD-000 — Larry's spec supplied the ordered shape, and the report's §10 recommendation supplied the sequence. |
| 5 Implement | in-progress | 17 files on branch `PRDV-16398`; `testing/PRDV-16398-testing-implementation.md` | 2026-07-28 | Code complete except `vid-mix.preset.ts` arg values. AC 2, 3, 4 **verified live** in Docker E2E; AC 1 blocked on the HandBrake preset. **Not committed** — `npm audit` exits 1 (8 high, all pre-existing) which blocks commit per `git-commit-workflow`. |
| 6 Manual review | pending | | | |

Resume: Phase 3 — Working mode

---

## Ledger notes

### Phase 0 (2026-07-28)

- **Docs root decision.** `<Project>` = `nova`. Considered `nebula` (matches larry-adams' `systems/nebula/video-transcode` grouping) and `atlas` (where the capture had landed). Chose the implementation-repo name for consistency with the `ticket-changelog` system→repo table pattern.
- **Changelog scaffolded manually, not by script.** `scripts/new-ticket-changelog.ps1` has `-System` as `ValidateSet('atlas','callisto','europa','triton','other')` — it cannot emit `docs/nova/`, and `-System other` writes to `docs/other/`. Copied `docs/_templates/TICKET-changelog.template.md` by hand instead. **Cruft candidate for Phase 6** — the ValidateSet and the rule's system→repo table both lack `nova`.
- **Named blocker carried into Phase 5.** Video Mix FFmpeg args do not exist in any repo in the workspace. Per `source-truth`, they will not be inferred. User is retrieving the HandBrake Video Mix preset; Phases 1–4 proceed, and `vid-mix.preset.ts`'s arg values remain blocked until that source artifact is in hand.
- **Coworker spec is an input, not a substitute.** Larry Adams' spec exists at `larry-adams/systems/nebula/video-transcode/PRDV-16398-nova-applies-selected-transcode-preset.md` (read-only). It is compared against in Phase 3, not adopted in place of this ticket's own investigation.
- **No implementation-repo file touched during Phase 0.** Reads only across `nova-back-end`, `nova-orbital-back-end`, `callisto-back-end`, `atlas-front-end`.
