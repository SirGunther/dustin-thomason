# Investigation Report: Upload Manager count up instead of down

> Delivered results of running the `investigate` method on PRDV-14055. Companion artifacts:
> [coverage ledger](./PRDV-14055-coverage-ledger.md) · [diagrams](./PRDV-14055-diagrams.md) · [test plan](../testing/PRDV-14055-test-plan.md).

## Metadata
- **Status:** done
- **Disposition:** proceed with conditions
- **Date:** 2026-07-21
- **Owner:** Dustin Thomason
- **Location:** `docs/atlas/PRDV-14055/investigations/PRDV-14055-investigation.md`
- **Ticket:** [PRDV-14055](https://app.clickup.com/t/43227262/PRDV-14055)
- **Domain:** software (frontend, Vue/Quasar)
- **References / evidence:** `atlas-front-end` @ `ef217844` — `src/callisto/stores/uploadManagerStore.ts:43-48`, `src/callisto/components/FileUploadWrapper/UploadManager/UploadManagerTitle.vue:48-53`, `src/triton/layouts/MainLayout/FileUploadWrapper/shared/UploadManager/UploadManager.vue:244-248` + `UploadManagerTitle.vue:27-29`, `src/i18n/en-US/common.json:134`, `useUploadItem.ts:103-104,159-160`

---

## 0. Verdict (bottom line up front)

The defect is fully understood and small: the Upload Manager's first number is computed as the count of **remaining (non-terminal)** files, so it counts **down** as uploads finish. The fix is to feed the title a **count of files that have started or completed**, which rises to the total. Root cause was determined entirely from source — it is a pure frontend presentation computed with no backend authority — so the investigation is confident. It is **proceed with conditions**, not an unconditional go, because two decisions remain: (a) the exact count semantics (how in-progress and mid-flight failures are counted) and (b) whether scope is Callisto-only or Callisto **and** the duplicate Triton implementation. Both are locked in Phase 3.

- **Strongest path:** add a dedicated display computed (`isComplete || percentCompleted > 0`) on each affected side, wire it to the title's `active` slot, leave `activeUploadsCount`/`hasActiveUploads` and all other computeds untouched, and add red→green tests.
- **Not yet proven / not approved:** exact inclusion rules for in-progress/error/cancel (open var #1); Callisto-only vs Callisto+Triton scope (open var #2); runtime confirmation that the number visibly rises (deferred to Phase 5).

## 1. Problem class

- **Class the request assumed:** a display/count bug in the Upload Manager progress message.
- **Confirmed class:** same — a **frontend presentation bug**: the displayed quantity is defined as "remaining" when the requirement wants "progressed". No data, contract, or upload-logic defect.
- **Reframed?** no — the assumed class held. Root-cause evidence (a single `.filter(...).length` computed driving the label, with the actual upload pipeline correct) confirms it is purely what the label counts, not how uploads behave.
- **What the confirmed class implies:** the solution space is a small, localized display change (one computed per affected surface + its render). No store-action, API, or lifecycle change. The real risk is **sideways** (a duplicate copy in Triton) and **regression** (shared neighbors on the same store), not depth.

## 2. Problem statement

- **Named instances:** Ops Atlas users uploading a batch (e.g. "Uploading 3 of 6") see the first number **decrease** toward 1 as files succeed; it reads as files being *removed from the queue / failing* rather than completing. Reported via the ticket (Ops primary stakeholder, stakeholder impact 3); reproducible on any multi-file upload in the current build.
- **One sentence:** the Upload Manager's "Uploading N of M files" shows N as the number of *remaining* uploads, so N counts down instead of up.
- **Distinct problems:** (1) the count direction/definition (the ticket); (2) *latent* — the same logic is duplicated in Triton, and (3) *latent* — Triton's label is hardcoded, not i18n. (2) and (3) are surfaced here, not necessarily in scope.
- **Urgency:** no hard date; it is a perception/UX defect degrading confidence during every batch upload. Ticket is READY FOR WORK, 2 points, QA-approved.
- **Wedge:** the single displayed count expression. Redefining that one value fixes the whole class of "the number goes the wrong way" — reusable across both Callisto and Triton because both share the identical expression.

## 3. The contract

### Acceptance criteria
| Criterion | Status | What's needed to close it |
|-----------|--------|---------------------------|
| First number = completed + in-progress (not remaining) | needs-proof | New display computed; unit test asserting it counts progressed files |
| First number **counts up** to total as each begins/completes | needs-proof | Monotonic formula (`isComplete \|\| percentCompleted > 0`); test over a staged queue |
| Happy-path end state: first == second == total | needs-proof | Test: all `isComplete` → count === queue length |
| Second number stays = total in current batch | covered | Already `uploadQueue.length`; unchanged (assert unchanged in test) |

### Non-goals / out of scope
- Changing upload behavior, concurrency (`MAX_CONCURRENT_FILES=2`), progress-bar math (`totalProgress`), or the success/error/failed title branches.
- Changing the close-confirmation dialog / beforeunload guard (`hasActiveUploads`).
- Converting Triton's hardcoded label to i18n (recorded as a future-development concern unless the user pulls it in).

## 4. What changed since the request was created

- **Shifted from:** an API-first framing (per changelog Attempt history) → **to:** a frontend display investigation. Further, the changelog Context recorded a **Playwright/browser-loop** investigation direction; this investigation determined root cause from **source** instead, because the defect is a deterministic pure computed with no runtime unknown.
- **What that buys us:** faster, exact root cause and a precise surface enumeration without needing an authenticated live session.
- **What it still needs to prove:** the *visible* behavior (number rising) — captured as a Phase 5 browser/runtime validation step, and flagged as open variable #4 for the user to confirm the medium change is acceptable.

## 5. Why it exists

- **Origin traced to:** `activeUploadsCount = uploadQueue.filter(f => !f.isComplete && !f.isCancelled && !f.error).length` — an intentionally "in-flight" count that was reused as the user-facing first number. As files reach terminal state they leave the set, so the number falls.
- **Evidence:** `uploadManagerStore.ts:43-48` (Callisto); `UploadManager.vue:244-248` (Triton, identical formula). Rendered at `UploadManagerTitle.vue:48-53` (Callisto i18n) and `:27-29` (Triton hardcoded). Lifecycle that the fix keys off: `useUploadItem.ts:103-104` (`percentCompleted`), `:159-160` (`isComplete`).
- **Contract alignment (software-lens C1):** there is **no backend/authoritative source** for this count — it is pure FE presentation. The only "authority" is each side's own computed. The durable risk is **re-drift between the two copies**: fixing Callisto alone leaves Triton counting down. Diagrams file shows both chains.
- **Detection gap (software-lens C4):** the Callisto specs actively *assert* the down-semantics (`uploadManagerStore.spec.ts:75-94`, `UploadManagerTitle.spec.ts:57-65`), and Triton's manager/title have **no spec at all** — so nothing could have flagged that the display count contradicts the requirement. The red→green tests added in Phase 5 close this.
- **Class re-check:** held — the root-cause evidence is a display computed, confirming the frontend-presentation class.

## 6. Alternatives considered

| Alternative | Rejected because |
|-------------|------------------|
| Repurpose `activeUploadsCount` to mean "progressed" | Its name means in-flight; misleads future readers, and it shares a name-concept with `hasActiveUploads`. Cleaner to add a new, honestly-named computed. |
| Compute the up-count inline in the title template | Duplicates logic into the view, untestable at the store level, and would need repeating in both titles. A named computed is testable and single-sourced per side. |
| `firstNumber = completedCount` (isComplete only) | Shows "0 of 6" while the first files are actively uploading — looks stalled; violates AC "completed **and in progress**". |
| Count all non-terminal as "in progress" (include queued-at-0%) | That is the current down-counting set (starts at total, falls). Fails the count-up requirement. |
| Extract one shared upload-manager module for both Callisto and Triton | Correct long-term, but a refactor far beyond a 2-point display fix; overreach. Recorded as a future-development concern. |

## 7. Solution & stress-test

- **Proposed solution:** Add a dedicated display computed per affected surface — Callisto store (`uploadManagerStore.ts`) and, if in scope, Triton local (`UploadManager.vue`) — e.g. `completedAndInProgressCount = uploadQueue.filter(f => f.isComplete || (f.percentCompleted ?? 0) > 0).length`. Pass it into the title's existing `active` slot. Leave `activeUploadsCount`, `hasActiveUploads`, `totalProgress`, `allUploadsComplete` untouched.
- **Solves the confirmed class:** yes — it redefines the one displayed quantity for the whole "wrong direction" class, not just the "3 of 6" example.
- **Scale:** count is over the current batch queue (bounded, concurrency 2); trivial. Monotonic because `isComplete` and `percentCompleted` only move forward and terminal flags never revert.
- **Generalization:** one computed per side is the right size. A shared cross-module abstraction is overreach for this ticket (future concern).
- **Fit:** matches the existing store-computed + prop-driven-title pattern; the Callisto i18n key already accepts `{active}` so no i18n change needed there.
- **Adjacent issues:** Triton duplication and Triton hardcoded-string — lower effort to note as follow-ups than to fold a refactor into a 2-point ticket; fixing Triton's *count* is cheap if scope includes it.
- **Sufficiency:** covers the full pain (perception that uploads are being removed) on the happy path; error handling keeps its own title.
- **Feedback speed:** immediate — unit tests prove direction at build; a single batch upload confirms visually in seconds.
- **Happy-path story:** Ops drops 6 files; the manager reads "Uploading 2 of 6", then 3, 4, 5, 6 as files transfer and complete; at the end it switches to "All files uploaded successfully" — never counting backward.

## 8. Assumptions ledger

- **Claim:** The displayed first number is `activeUploadsCount` and nothing else feeds it.
  - **Status:** confirmed
  - **Confirm/revise by:** grep `activeUploadsCount|active-uploads-count` across `src` — only store→UploadManager→title path (Callisto) and the Triton local copy.
- **Claim:** `activeUploadsCount` counts remaining and therefore decreases as uploads complete.
  - **Status:** confirmed
  - **Confirm/revise by:** read `uploadManagerStore.ts:43-48`; filter excludes `isComplete/isCancelled/error`.
- **Claim:** Changing the display count does not affect the close-confirmation dialog, beforeunload guard, or progress bar.
  - **Status:** confirmed directionally
  - **Confirm/revise by:** those use `hasActiveUploads`/`totalProgress` (independent computeds); prove with a regression test asserting they are unchanged.
- **Claim:** `percentCompleted > 0` reliably distinguishes actively-transferring files from queued-at-0% files.
  - **Status:** confirmed directionally
  - **Confirm/revise by:** `useUploadItem.ts:103-104` sets it per completed chunk; a just-started file may briefly show 0%. Acceptable; confirm framing in Phase 3.
- **Claim:** The Triton implementation is a genuine second user-facing instance (not dead code).
  - **Status:** open
  - **Confirm/revise by:** confirm which manager the Ops user reaches (open variable #2).

## 9. Validation plan

**Happy path**
1. Queue a batch larger than the concurrency limit (e.g. 6 files, `MAX_CONCURRENT_FILES=2`).
2. As files transfer and complete, the first number **rises** (never falls): observed sequence increases toward 6.
3. When all complete, title switches to "All files uploaded successfully"; just before switch the first number equals total.
4. Unit: store computed returns rising counts for staged queue states; ends at `queue.length` when all `isComplete`.

**Negative paths**
- **All errored:** title shows "Upload failed" (unchanged branch); the count never goes negative or above total.
- **Mixed success/error:** title shows "completed with errors" (unchanged); verify the first number's treatment of failed files matches the locked decision (open var #1) and never decrements below a previously shown value on the happy path.
- **Empty queue:** no progress message rendered (existing test preserved).
- **Neighbors unchanged (regression):** `hasActiveUploads` still gates the close-confirmation dialog; `totalProgress` bar math unchanged — asserted by test.
- **Second number:** remains `uploadQueue.length` in every state.

## 10. Decisions, recommendation & open variables

- **Decisions (settled):** frontend-presentation class confirmed; root cause is the `activeUploadsCount` display computed; add a new computed rather than mutate the existing one; leave neighbors untouched; Triton i18n conversion is out of scope.
- **Recommendation (in order):** (1) Phase 3 grill-me to lock open var #1 (exact semantics) and #2 (scope); (2) refine the test plan into concrete assertions; (3) write the spec; (4) Phase 4 implementation plan; (5) implement with red→green tests + neighbor regression; (6) validate the count rising in a real batch upload.
- **Sequencing & gates:** do not implement until open var #1 (formula) and #2 (scope) are locked — they change how many files and which surfaces are touched. Runtime/visual confirmation gates Phase 6 sign-off.

### Open variables to collect
- [ ] **#1 Exact count semantics** — include only `percentCompleted > 0` as in-progress, or also prep/queued? How to count mid-flight error/cancel (stay counted vs drop, to preserve monotonic-up)? — owner: user (Phase 3 grill-me); recommended: `isComplete || percentCompleted > 0`, terminal states stay counted.
- [ ] **#2 Scope** — Callisto only, or Callisto + Triton? Which manager does the Ops user see? — owner: user / PM.
- [ ] **#3 Triton i18n** — convert hardcoded label to i18n now, or defer? — owner: user; recommended: defer (future concern).
- [ ] **#4 Investigation medium** — accept source-first root cause with browser-loop moved to Phase 5 validation? — owner: user.

---

## 11. Plan — Next steps

### Handoff table
| Action | Owner | Done-when (falsifiable) |
|--------|-------|-------------------------|
| Lock count semantics + scope (Phase 3 grill-me) | user + agent | `PRDV-14055-locked-decisions.md` has LD rows resolving open vars #1–#4 |
| Refine test plan into concrete assertions | agent | test plan status `refined`; each AC maps to a named assertion |
| Write spec (P→R→S) | agent | `specs/PRDV-14055-spec.md` with locked-decisions summary linking the ledger |
| Implementation plan (Phase 4) | agent | every step traces to spec/report/test-plan; branch step named |
| Implement + tests | agent | red→green store/title tests pass; neighbor regression asserted; count rises in a batch upload |

### Checklist
#### Investigation
- [x] This report (Sections 0–10)
- [x] Coverage ledger
- [x] Diagrams
- [x] Test-plan seed

#### Project Spec
- [ ] Resolve open variables (Phase 3 grill-me)
- [ ] Create spec

#### Development
- [ ] Create branch `PRDV-14055`
- [ ] Implement (Callisto store + title; Triton per scope)

#### Testing & Validation
- [ ] Execute test plan (serial); validate count rises in a real batch upload

#### Deploy & PR
- [ ] Push; open PR

#### Ticket Closeout
- [ ] Document root cause / detection gap (this report §5)

---

## 12. Definition of done (investigation gate)
- [x] Class derived from instances, re-confirmed against root cause; "reframed? no" justified (§1)
- [x] Problem in one plain sentence (§2)
- [x] Named blocked instance (Ops batch upload) (§2)
- [x] Date it bites next (every batch upload; no hard deadline) (§2)
- [x] Wedge + why reusable (the single displayed count expression) (§2)
- [x] Acceptance criteria + non-goals locked before solution (§3)
- [x] Alternatives recorded with rejection reasons (§6)
- [x] 30-second happy-path story (§7)
- [x] Metric that proves it works + speed (count rises; unit tests at build, visual in seconds) (§9)
- [x] Verdict + disposition stated (§0 — proceed with conditions)
- [x] Open variables each have an owner (§10)
- [x] Tracked action with falsifiable done-when (§11 handoff table)
- [x] Problem Check lens run and reflected (§13 addendum — added 2026-07-21)

---

## 13. Problem Check (Step-1 lens — dated addendum, 2026-07-21)

> Added after the report was marked `done`: the mandated Step-1 Problem Check lens (`problem-check.md`) was
> not produced explicitly in the first pass; appended here rather than rewriting §1–§2. Findings that sharpen
> earlier sections are cross-referenced, not silently edited. Source = the ticket Original Request + Acceptance
> Criteria (`PRDV-14055-original-ticket.md`). Rule followed: every finding cites the words that justify it; a
> finding with nothing behind it is recorded as "nothing here" rather than manufactured.

### In brief

The ticket asks to flip the Upload Manager progress message so the first number counts *up* (completed + in-progress)
instead of *down* (remaining). It is a single, well-scoped frontend display change, given as an as-a-user story plus
four acceptance bullets. The only genuinely underspecified point is what "in progress" means and how non-happy-path
files count.

### The question

**Asked** — a display-direction change.
- finding: change the first number to count up instead of down.
- evidence: "count up instead of down".

**Answered** — the AC refines the ask into a *composition* rule (minor drift, not divergence).
- finding: the AC actually specifies what the first number *is* (completed + in-progress), which is stronger than "count up".
- drift: "count up" (direction) → "first number = completed + in-progress" (definition).
- evidence: "number of completed and in progress uploads as the first number".

**Should-ask** — the sharper, more upstream question.
- finding: what exactly counts as "in progress" (queued-at-0% vs actively transferring), and how is a file that fails or is cancelled mid-batch counted?
- why: it is the only thing the AC leaves undefined, and it fully determines the count formula → **this is open variable #1 / grill-me Q1**.

### Flags

**Conflation** — nothing here at the request level.
- finding: the request is one behavior (the displayed count). It is *not* bundling two distinct problems.
- consequence: the multiplicity that matters (two implementations — Callisto store + Triton local) is a **code-surface** fact, captured under software-lens C2 / §2 "distinct problems" and open variable #2 — not a conflation inside the ask. Recording honestly rather than inflating it into a request-level conflation.
- evidence: "the upload manager" (singular) — the second implementation is invisible in the request.

**Thin** — one real gap (the load-bearing finding of this lens for this ticket).
- finding: "in progress" is undefined, and while the happy-path end state is specified, the non-happy-path count (errors / cancellations mid-batch) is unstated.
- evidence: "completed and in progress uploads" (no definition of *in progress*); "The happy-path end state should have all files uploaded" (only the happy path is pinned).
- feeds: §8 assumptions (percentCompleted-as-in-progress claim) and §10 open variable #1.

**Off** — nothing here.
- finding: the four acceptance bullets are internally consistent (first = completed+in-progress; counts up; ends equal to second; second = total). No claim contradicts another.

### How this threads into the report

- **Thin → Should-ask** is the origin of **open variable #1** (§10) and grill-me **Q1** — the count-semantics decision. The lens confirms this is the single genuinely-open point in the ask.
- **Conflation = nothing here** confirms **§1's "reframed? no"**: there is no hidden second problem in the request; the class stays "frontend presentation bug". The Callisto/Triton multiplicity is a surface finding (§2, C2, open var #2), not a reframing.
- No change to the **verdict (§0)** or **class (§1)**: the Problem Check reinforces them rather than altering them.

---

## 14. Uncertainty reclassification — workflow vs code (dated addendum, 2026-07-21)

> Added after a user distinction: an **open variable** is resolved by a **decision** (a choice someone with authority
> makes — "workflow"); an **uncertainty** is resolved by **discovery** (a fact of the matter we go and find — on a
> software ticket, "code"). The two must not be conflated, because they route to different actors and actions:
> a **code uncertainty must be resolved evidence-first, now** — parking it as "open for discussion" is a category
> error — while a **workflow decision** legitimately waits for the owner. §10's flat open-variables list blurred
> this. This pass splits each item, resolves the code half from source, and leaves only the genuine decisions for
> Phase 3 grill-me. Appended (not rewritten into §10) per the done-report rule; §10's items are superseded by the
> reclassification below.

### Reclassification and code-half resolution

| # | Item | Code half (fact — resolved here, evidence-first) | Workflow half (decision — stays for grill-me) |
| --- | --- | --- | --- |
| 1 | Count semantics | **Resolved.** Concurrency gating is wired ([UploadItem.vue:60-66](src/callisto/components/FileUploadWrapper/UploadManager/UploadItem/UploadItem.vue#L60-L66): `waitForUploadSlot → registerFileUpload → uploadFile → unregisterFileUpload`), so with `MAX_CONCURRENT_FILES=2` several files genuinely sit **queued at `percentCompleted=0`**. **No per-item flag distinguishes "waiting for a slot" from "just started at 0%"** — the waiting state lives only in the component's `onMounted`, not on the `TUploadFile`. Therefore `percentCompleted > 0` is the **only** clean "actively transferring" signal; the sole alternative ("count all non-terminal") is exactly today's down-count. Terminal flags and `percentCompleted` only move forward ([useUploadItem.ts:103-104,159-160](src/callisto/components/FileUploadWrapper/UploadManager/UploadItem/composables/useUploadItem.ts#L103-L104)), so any formula built on them is monotonic. | Only: **how to count a file that fails/cancels mid-batch** — stay counted (monotonic up) or drop (re-introduces a decrement). Pure UX choice, code-unconstrained. (The "in progress = `percentCompleted > 0`" part is now effectively forced by the code, not a free choice.) |
| 2 | Scope | **Resolved.** Callisto `UploadManager` is mounted app-wide, gated `isCallistoRoute` ([App.vue:34](src/App.vue#L34)) → Callisto route-space. Triton `UploadManager` is mounted in [TritonAppContainer.vue](src/triton/layouts/MainLayout/TritonAppContainer.vue) → the Triton app. **Both are live in separate apps; both exhibit the identical defect; neither is dead code.** | Only: **which app(s) the ticket intends** — does the "Ops Atlas user" work in the Callisto app, the Triton app, or both? Not derivable from code (ticket names neither; metadata: "Atlas Maintenance", team NASA, stakeholder Ops). |
| 3 | Triton i18n | **Resolved.** Triton components already consume the shared `common.*` i18n namespace (e.g. Triton `FileUploadWrapper.vue` → `t('common.invalidFileName')`), and `common.uploadingProgressTxt`/`uploadAllSuccessTxt` already exist. A Triton conversion **reuses existing keys — no new keys required** — so it is low-effort, not the broader change first assumed. | Only (and contingent on #2 including Triton): **convert now or defer.** A cost input to the decision, now known to be small. |
| 4 | Investigation medium | n/a — not an uncertainty. | **Already resolved** by Phase 1 plan approval (source-first root cause; browser-loop → Phase 5 validation). |

### Consequence for Phase 3

After evidence-first resolution, the genuine **workflow decisions** left for grill-me are narrower:

- **Q1 (narrowed):** for the first number, how are mid-batch **errors/cancellations** counted — stay counted (never decrement) or drop out? (The completed-plus-actively-transferring core is fixed by code as `isComplete || percentCompleted > 0`.)
- **Q2:** which app(s) are in ticket scope — Callisto, Triton, or both? (Both are live and identically broken; "both" remains the safe default.)
- **Q3 (contingent on Q2⊇Triton):** convert Triton's label to i18n now (cheap — reuses existing keys) or defer?

This does not change the **verdict (§0)**, **class (§1)**, or the recommended formula's core (§7); it resolves the discoverable facts that §10 had left open and tightens what actually needs a human decision. §8 assumptions "percentCompleted-as-in-progress" and "Triton is a genuine second instance" both move to **confirmed** on this evidence.

---

## 15. Open-variable justification — proof each is a decision, not dodged code work (dated addendum, 2026-07-21)

> Discipline step (per user direction): an item may **remain** an open variable only after evidence shows code
> investigation **cannot** resolve it. For each, record two things — **(a) why it was flagged open at review**, and
> **(b) the evidence that it cannot be rectified by reading the code**. An item that fails (b) is not open; it is
> unresolved code work and must be investigated before it is allowed to reach a human. This is the gate that keeps
> §14's "workflow" bucket honest. What code characteristically *cannot* supply: **authorial intent**, **product/persona
> knowledge**, and **scope/prioritization boundaries** — none are encoded in the source.

### OV-1 — How the first number treats a file that errors/cancels after starting

- **(a) Why flagged open at review:** the AC pins the happy path ("completed and in progress"; "both numbers equal") but is silent on a file that fails or is cancelled mid-batch — the count could stay (monotonic) or drop (decrement).
- **Code investigated:** `activeUploadsCount` ([:43-48](src/callisto/stores/uploadManagerStore.ts#L43-L48)), `totalProgress` ([:62-65](src/callisto/stores/uploadManagerStore.ts#L62-L65), error/cancel → +100), `allUploadsComplete` ([:50-57](src/callisto/stores/uploadManagerStore.ts#L50-L57)), per-item failure rendering ([UploadItem.vue:106-116](src/callisto/components/FileUploadWrapper/UploadManager/UploadItem/UploadItem.vue#L106-L116)).
- **(b) Why code can't fully rectify it:** code resolves the *behavioral* half unambiguously — every existing signal treats a failed/cancelled file as **progressed/terminal** (bar counts it 100%; remaining-count drops it exactly like a completion; all-complete includes it), which favors **stay counted**. What code **cannot** establish is whether the AC author *intended* the new count to mirror that or to diverge (a literal reading of "completed and in progress" excludes failures). **Authorial intent is not in the source.** So the residual open portion is a one-line intent confirmation, not a code fact — the narrowest of the three.
- **Residual decision · owner:** mirror existing behavior (stay counted) vs literal-AC divergence (exclude failures). Owner: user/PM. **Code-backed default: stay counted.**

### OV-2 — Which app(s) are in the ticket's scope

- **(a) Why flagged open at review:** the ticket says "the upload manager" (singular), but two live managers exist.
- **Code investigated:** Callisto mount + `isCallistoRoute` gate ([App.vue:34](src/App.vue#L34)); Triton mount ([TritonAppContainer.vue](src/triton/layouts/MainLayout/TritonAppContainer.vue)); both formulas.
- **(b) Why code can't rectify it:** code proves both managers are live, in separate apps, identically defective — but **no source artifact maps the ticket's "Ops Atlas user" to an app or route-space.** "Ops", "Atlas Maintenance", and owning-team "NASA" are ClickUp org/process labels, not code identifiers; there is no route, guard, or config that binds a persona to an upload surface. Which app Ops actually uses, and whether the author means one or both, is **product/domain knowledge external to the repo.**
- **Residual decision · owner:** Callisto / Triton / both. Owner: user/PM. **Code-backed note: both are broken; "both" is the safe default.**

### OV-3 — Convert Triton's label to i18n now, or defer

- **(a) Why flagged open at review:** Triton's label is a hardcoded English string; unclear whether this ticket should also fix it.
- **Code investigated:** Triton title (hardcoded [:27-29](src/triton/layouts/MainLayout/FileUploadWrapper/shared/UploadManager/UploadManagerTitle.vue#L27-L29)); Triton `FileUploadWrapper.vue` i18n usage; `common.json` keys.
- **(b) Why code can't rectify it:** code resolves the fact (hardcoded) and the **cost** (cheap — reuses existing `common.*` keys, no new keys). But whether to include it in **this** ticket is a **scope/prioritization boundary** — code can measure cost, it cannot decide a ticket's boundary. Contingent on OV-2 including Triton.
- **Residual decision · owner:** convert now / defer. Owner: user/PM. **Code-backed note: cost is small.**

### OV-4 — Investigation medium (closed)

- Not a code question and not open: a **process decision** already settled by Phase 1 plan approval (source-first root cause; browser-loop → Phase 5 validation). Listed for completeness.

### What this step caught

Running the gate shrank the decision set: **OV-1 nearly closed itself** (code determines the behavior; only intent remains), and OV-2/OV-3 are confirmed as genuine decisions because the thing they turn on — persona-to-app mapping and ticket-scope boundary — is provably absent from the code. No item failed the gate (i.e., none was a code question hiding as a decision) *after* the §14 pass; before §14, OV-1's formula and OV-2's app-mapping both would have.
