# PR review patterns — recurring requested changes across reviewers

> **Purpose:** track the fixes reviewers consistently ask for across PR reviews — any reviewer, not just one person — so they can be caught in self-review **before** a PR goes up, not just fixed reactively after. Two lenses are kept side by side: **patterns** (the concrete, greppable instance) and **classes of changes** (the higher-level category a pattern belongs to, useful as evidence of "the proper way to build" when writing specs or onboarding). Append a new dated entry each time a fresh instance appears — don't rewrite history — and promote a pattern to the "Self-review checklist" once it's recurred (2+ PRs).
>
> Originally scoped to p-lana's review comments (see git history); broadened 2026-07-24 to cover any reviewer's requested changes, sourced from actual GitHub PR review comments (inline + review-summary + issue-level), not from memory or paraphrase.

## Self-review checklist (run before requesting review)

- [ ] **No hardcoded user-facing strings.** Any string shown to a user (toast/notify message, error message, label) is pulled from the i18n JSON locale files, not written inline in a `.ts`/`.vue` file. *(Class A)*
- [ ] **No magic string literals for status/state comparisons.** Values compared or switched on (e.g. `Promise.allSettled` statuses, API status codes, enum-like strings) are named constants, not bare string literals repeated at each comparison site. *(Class B)*
- [ ] **No hand-rolled type casts in test mocks.** Use the repo's typed mock-factory helpers (`createApplyMock<T>()`, `createComposableMock`, or add a sibling `createMockXProjection()`) instead of `as jest.Mocked<...>` or `as never` — those silently stop protecting you when the underlying type changes shape. *(Class C)*
- [ ] **Mirror/parallel implementations have symmetric test coverage.** If two validators, guards, or adapters mirror each other (same shape, different lane), and one has a 3-case spec (not-found / wrong-lane / right-lane), its sibling gets the same shape — not "we'll get to it." *(Class D)*
- [ ] **Dense inline handler logic is extracted into named helpers.** If a handler mixes 3+ concerns (capture state → await → compute a message → notify), pull the compute steps into small named functions so the handler reads as the orchestration. *(Class E)*
- [ ] **Intentional removal of a safety net (try/catch, a guard branch) carries a one-line comment explaining why.** Otherwise a reviewer has to stop and ask whether it was a mistake. *(Class F)*
- [ ] **No stray/unnecessary comments left in before requesting review.** Grep your own diff for debug comments, TODOs you already resolved, or commented-out code before opening the PR. *(Class G)*
- [ ] **Ad hoc mechanisms are not shipped as a stand-in for a shared architectural capability without flagging it first.** (e.g., polling as a stand-in for push/websockets) — if the "fast" path bypasses an architecture decision that affects more than this one feature, say so explicitly and let someone with that scope weigh in before it ships. *(Class H)*

---

## Classes of changes (index)

| Class | What it's really about | Patterns | Instances | Reviewers seen |
| --- | --- | --- | --- | --- |
| **A — i18n externalization** | User-facing strings must live in locale JSON, not inline | Pattern 1 | 4 | p-lana |
| **B — Named constants over magic literals** | String/status literals used in comparisons need a name | Pattern 2 | 1 | p-lana |
| **C — Typed test-mock helpers over hand-rolled casts** | `as X`/`as never` in specs mask real type drift | Pattern 3 | 2 | midnjerry |
| **D — Mirror-implementation coverage symmetry** | Parallel implementations need parallel test coverage | Pattern 4 | 1 | midnjerry |
| **E — Extract-for-readability** | Dense inline logic → named pure helpers | Pattern 5 | 1 | p-lana |
| **F — Justify intentional removal of defensive code** | Removing a try/catch reads as a bug unless explained | Pattern 6 | 1 | dthomason-pd (self, prompted by reviewer question) |
| **G — Editorial cleanup before review** | Leftover unnecessary comments | Pattern 7 | 1 | derrickdso |
| **H — Escalate cross-cutting architecture decisions** | Don't let a feature branch quietly decide an org-wide mechanism | Pattern 8 | 1 | daedalus1215 |

---

## Pattern 1 — Hardcoded strings should move to i18n JSON

**Class:** A — i18n externalization.

**Reviewer comment (verbatim, p-lana):** *"Can we move this to JSON?"* / *"move to common.json, please"*

**What it means:** any string a user sees — error messages, toast text, fallback labels — belongs in the i18n locale JSON files (the codebase already has an i18n system; see `common.uploadingProgressTxt` etc.), not written literally in the component/composable.

**Instances:**

| Date | PR | Reviewer | File:line | The literal | Fix direction |
| --- | --- | --- | --- | --- | --- |
| 2026-07-23 | [atlas-front-end #548](https://github.com/planetdepos/atlas-front-end/pull/548) | p-lana | `useUploadItem.ts:54` | `'Upload request timed out'` | Add an i18n key (e.g. `common.uploadTimedOutTxt`) and reference it instead of the inline `Error` message string. |
| 2026-07-23 | [atlas-front-end #548](https://github.com/planetdepos/atlas-front-end/pull/548) | p-lana | `useUploadItem.ts:77` | `'Upload failed'` (fallback error message) | Add an i18n key (e.g. `common.uploadFailedTxt`) for the fallback used when the caught error has no message. |
| 2026-07-23 | [atlas-front-end #548](https://github.com/planetdepos/atlas-front-end/pull/548) | p-lana | `useUploadItem.ts:81` | `` `${fileToUpload.fileAndPath.file.name} failed to upload` `` (toast message template) | Add an i18n key with an interpolation slot for the filename (e.g. `common.fileFailedToUploadTxt` = `"{file} failed to upload"`), pass the filename as the param — same pattern already used for `uploadingProgressTxt`. |
| 2026-06-29 | [atlas-front-end #524](https://github.com/planetdepos/atlas-front-end/pull/524) (PRDV-15619) | p-lana | `FileUploadSectionCore.vue`, `console.error('Failed to refresh proceedings', err)` | hardcoded `console.error` string | Added `common.callisto.proceedings.refreshProceedingsFailed` to `common.json` and switched the `console.error` call to `t(...)` — matches the sibling `addProceedingsFailed` key convention already in `common.json`. |

**Recurrence note:** this is now confirmed across **two independent tickets** (PRDV-14055 and PRDV-15619), which is what promoted it to the checklist.

---

## Pattern 2 — Magic string literals for status checks should become named constants

**Class:** B — Named constants over magic literals.

**Reviewer comment (verbatim, p-lana):** *"I think it would be better to move 'rejected' and other statuses into constants."*

**What it means:** when code branches on a string value (a `Promise.allSettled` result's `status`, an API status, any enum-like string), the literal should be a named constant so the comparison is self-documenting and typo-proof, not a bare string repeated at each call site.

**Instances:**

| Date | PR | Reviewer | File:line | The literal | Fix direction |
| --- | --- | --- | --- | --- | --- |
| 2026-07-23 | [atlas-front-end #548](https://github.com/planetdepos/atlas-front-end/pull/548) | p-lana | `useUploadItem.ts:192` | `result.status === 'rejected'` | Introduce a constant (e.g. `PROMISE_STATUS_REJECTED = 'rejected'`, or use `PromiseSettledResult`'s own discriminant more directly) and compare against that instead of the bare literal. If `'fulfilled'` appears anywhere nearby, name that too for symmetry. |

---

## Pattern 3 — Hand-rolled test-mock casts should use the repo's typed factory helpers

**Class:** C — Typed test-mock helpers over hand-rolled casts.

**Reviewer comment (verbatim, midnjerry):** *"nit: would you mind swapping this for `createApplyMock<DeliverableFileAuthorizeRole>()`? Hand-rolled `as jest.Mocked<...>` has bitten us before when the type shifts under us — the helper keeps us honest."* / *"`as never` will mask a real type error if `ProceedingFileRenameProjection` grows a required field... Could we cast as `Partial<ProceedingFileRenameProjection>` or pop a `createMockProceedingFileRenameProjection()` helper into test-utils so the projection stays the source of truth?"*

**What it means:** a test double built with `as jest.Mocked<T>` or `as never` compiles today but silently stops protecting you the moment `T` gains a new required field — the cast just swallows the type error instead of surfacing it. The repo already carries typed factory helpers (`createApplyMock<T>()`, or a sibling `createMockXProjection()`) whose whole job is to keep the mock's shape pinned to the real type.

**Instances:**

| Date | PR | Reviewer | File:line | The literal | Fix direction |
| --- | --- | --- | --- | --- | --- |
| 2026-07-02 | [callisto-back-end #340](https://github.com/planetdepos/callisto-back-end/pull/340) (PRDV-15776) | midnjerry | `update-deliverable-file-auth.guard.spec.ts:21` | `as jest.Mocked<DeliverableFileAuthorizeRole>` | Swapped for `createApplyMock<DeliverableFileAuthorizeRole>()` (commit `22933b0d`). |
| 2026-07-02 | [callisto-back-end #340](https://github.com/planetdepos/callisto-back-end/pull/340) (PRDV-15776) | midnjerry | `proceeding-file-must-be-submission.validator.spec.ts:36,66` | `as never` casts on `ProceedingFileRenameProjection` | Exported `ProceedingFileRenameProjection`, added `createMockProceedingFileRenameProjection()`, replaced both `as never` casts with the typed helper (commit `22933b0d`). |

---

## Pattern 4 — Mirror implementations need mirror test coverage

**Class:** D — Mirror-implementation coverage symmetry.

**Reviewer comment (verbatim, midnjerry):** *"Would you mind throwing a spec on `ProceedingFileMustBeDeliverableValidator`? I sus we just missed it — its mirror `ProceedingFileMustBeSubmissionValidator` got three tests over in `proceeding-file-must-be-submission.validator.spec.ts` and that file should drop right in as a template (file-not-found, wrong-lane, right-lane). Want to keep them in lockstep so the next person doesn't have to wonder which side is the source of truth ❤️"*

**What it means:** when a change introduces two parallel implementations of the same concept (two validators for two lanes, two guards for two resource types), reviewers expect **both** to carry the same shape of test coverage, not just the one the PR happened to touch first. An asymmetric pair reads as "which one is actually trustworthy?" to the next person who touches either side.

**Instances:**

| Date | PR | Reviewer | File:line | The gap | Fix direction |
| --- | --- | --- | --- | --- | --- |
| 2026-07-02 | [callisto-back-end #340](https://github.com/planetdepos/callisto-back-end/pull/340) (PRDV-15776) | midnjerry | `proceeding-file-must-be-deliverable.validator.ts` (no spec) | Missing spec on the mirror validator while its sibling had 3 tests | Added `proceeding-file-must-be-deliverable.validator.spec.ts` covering file-not-found, wrong-lane, right-lane — same shape as the sibling (commit `22933b0d`). |

---

## Pattern 5 — Extract dense inline handler logic into named helpers

**Class:** E — Extract-for-readability.

**Reviewer comment (verbatim, p-lana):** *"Maybe we could try to make the code a little more readable? You could try it this way, if that works for you."* (followed by a concrete suggested extraction into `getProceedingIds()` / `getRefreshMessage()`)

**What it means:** when a single async handler mixes several concerns inline (capture prior state → await a call → compute a derived message → notify), pull the computation steps into small named functions so the handler itself reads as the orchestration (capture → refresh → notify), not a wall of inline logic.

**Instances:**

| Date | PR | Reviewer | File:line | Before | Fix direction |
| --- | --- | --- | --- | --- | --- |
| 2026-06-29 | [atlas-front-end #524](https://github.com/planetdepos/atlas-front-end/pull/524) (PRDV-15619) | p-lana | `FileUploadSectionCore.vue`, `handleRefresh` | Inline id-capture + count computation inside `handleRefresh` | Extracted `getProceedingIds()` and `getRefreshMessage(refreshed, priorIds)`; kept `Set<number>` rather than the reviewer's suggested `Set<string>` because `Proceeding.id` is a `number` — flagged and justified the one deviation from the suggestion rather than applying it blindly. |

**Note:** this instance is a good model for **how to respond** to a review suggestion that's *mostly* right — apply the shape, but call out and justify the one place the literal suggestion would have broken type-correctness.

---

## Pattern 6 — Justify intentional removal of a safety net in the code itself

**Class:** F — Justify intentional removal of defensive code.

**Reviewer comment (verbatim, dthomason-pd, as the reviewer on someone else's/own removal):** *"Why did we remove the try catch block?"*

**What it means:** removing error handling that looks load-bearing (a `try/catch` that silently returned `[]` on failure) reads as an accidental regression unless the removal explains itself. In this instance the removal was correct — the old catch was masking `queryFn` failures as a successful empty result, which blanked the cached list on any transient refetch error — but that reasoning lived only in the PR comment thread, not in the code, until asked.

**Instances:**

| Date | PR | Reviewer | File:line | What was removed | Fix direction |
| --- | --- | --- | --- | --- | --- |
| 2026-06-29 | [atlas-front-end #524](https://github.com/planetdepos/atlas-front-end/pull/524) (PRDV-15619) | dthomason-pd | `useJobSubmissionJobProceedings.ts`, `fetchJobProceedings` | `try/catch` returning `[]` on failure | No revert — the removal was correct (letting the error propagate lets Vue Query keep last-good `query.data` and surface `proceedingsError`, and the manual refresh path shows an error toast instead). Added a comment above the function documenting *why* the try/catch is gone, so the next reader — reviewer or not — doesn't have to ask. |

---

## Pattern 7 — Clean up unnecessary comments before requesting review

**Class:** G — Editorial cleanup before review.

**Reviewer comment (verbatim, derrickdso):** *"lets clear out these unnecessary comments and likely good to go!"*

**What it means:** self-review pass should catch and remove comments that were useful while drafting (explaining a decision to yourself, a scratch note) but add no value to the reviewer or the next reader — before the PR goes up, not after a reviewer flags it.

**Instances:**

| Date | PR | Reviewer | File:line | What was flagged | Fix direction |
| --- | --- | --- | --- | --- | --- |
| 2026-07-02 | [atlas-front-end #530](https://github.com/planetdepos/atlas-front-end/pull/530) (PRDV-16047) | derrickdso | `useProceedingFilePermission.ts:59` | Draft-stage explanatory comments left in past their usefulness | Removed before merge; PR approved immediately after. |

---

## Pattern 8 — Escalate cross-cutting architecture decisions instead of shipping an ad hoc workaround

**Class:** H — Escalate cross-cutting architecture decisions.

**Reviewer comment (verbatim, daedalus1215, on the PRDV-15619 spec):** *"I'd remove this spec. The proper way of solving this is web sockets, not periodically polling... We need to architect a solution that can be used for all of our web socket needs. This requires some research... TLDR: If we are going with polling, we might as well go with websocket. Since polling is a cludgey solution that is discouraged. If the desire is to get this asap, then the button should work. If we have more time, and a senior developer's time, then they can take a stab at the design and I would need to review it. Or I need to prioritize it and architect."*

**What it means:** a feature-level spec that proposes a mechanism with org-wide implications (polling vs. a shared websocket capability) got explicitly rejected at the spec-review stage, before implementation — the reviewer drew a line between "ship the narrow, immediately-correct fix" (a manual refresh button — which is what actually shipped as PRDV-15619 / atlas-front-end #524) and "silently establish a pattern (polling) that should really be an architecture decision with broader research behind it." This is spec-level feedback (from a `larry-adams` companion PR, not a code PR), but it's exactly the kind of "proper way to build" evidence worth keeping alongside the code-level patterns: **don't let a single feature branch quietly decide a cross-cutting mechanism.**

**Instances:**

| Date | PR | Reviewer | Artifact | What was rejected | Resolution |
| --- | --- | --- | --- | --- | --- |
| 2026-06-27 (approx.) | [larry-adams #8](https://github.com/planetdepos/larry-adams/pull/8) (PRDV-15619 spec) | daedalus1215 | `PRDV-15619-polling-refresh.md` | A periodic-polling spec for AJSF proceedings refresh | Polling spec dropped; the companion `PRDV-15619-refresh-proceedings-overview.md` (button-based manual refresh) was approved instead ("This spec makes sense to me ✅") and is what shipped in atlas-front-end #524. Websocket architecture work was explicitly deferred, not silently skipped. |

---

## Coverage — tickets/PRs surveyed for this pass (2026-07-24)

Every open item plus the five `docs/atlas/PRDV-*` ticket folders were checked against **actual GitHub PR review data** (`gh api .../pulls/{n}/comments`, `/reviews`, `/issues/{n}/comments`) — not reconstructed from memory. Folders/PRs with **no** requested changes are recorded here so the absence is verified, not assumed:

| Ticket | Repo / PR | Result |
| --- | --- | --- |
| PRDV-14055 | [atlas-front-end #548](https://github.com/planetdepos/atlas-front-end/pull/548) | Already captured — Patterns 1 & 2 (this was the original doc's source). |
| PRDV-15619 | [atlas-front-end #524](https://github.com/planetdepos/atlas-front-end/pull/524) | 3 review comments (p-lana) — Patterns 1, 5, 6. |
| PRDV-15619 (spec) | [larry-adams #8](https://github.com/planetdepos/larry-adams/pull/8) | 1 substantive rejection (daedalus1215) — Pattern 8. |
| PRDV-15776 | [callisto-back-end #340](https://github.com/planetdepos/callisto-back-end/pull/340) | 4 review comments + 1 issue comment (midnjerry) — Patterns 3 & 4. |
| PRDV-15776 | [atlas-front-end #511](https://github.com/planetdepos/atlas-front-end/pull/511) | Clean — approved with praise only, no requested changes. |
| PRDV-16047 | [atlas-front-end #530](https://github.com/planetdepos/atlas-front-end/pull/530) | 1 review comment (derrickdso) — Pattern 7. |
| PRDV-16047 (spec) | [larry-adams #13](https://github.com/planetdepos/larry-adams/pull/13) | Clean — "lgtm", no requested changes. |
| PRDV-16216 | [callisto-back-end #383](https://github.com/planetdepos/callisto-back-end/pull/383) | Clean — approved (midnjerry, daedalus1215), no requested changes. |
| PRDV-16216 (spec) | [larry-adams #23](https://github.com/planetdepos/larry-adams/pull/23), [#24](https://github.com/planetdepos/larry-adams/pull/24) | No review activity recorded via API. |

**Note on "5 folders, one already addressed":** the folder-level scan of `docs/atlas/` found 5 PRDV folders (14055, 15619, 15776, 16047, 16216) — 14055 was the one already addressed (source of Patterns 1–2). The other four each mapped to one or more real merged PRs via `gh search prs`, which is how Patterns 3–8 above were sourced.

## Notes for next time

- All patterns are **cheap to self-check before opening a PR** — that's the point of the checklist above. Grep for quoted strings passed to `notify(`/`Error(`/thrown messages, for bare string literals in `===`/`switch` comparisons, for `as never`/`as jest.Mocked<` in spec files, and diff the two sides of any mirrored implementation, before requesting review.
- If a new distinct pattern shows up in a future PR, add a new `## Pattern N` section (and a matching row in the **Classes of changes** index — reuse an existing class if it fits, or add a new one) rather than folding it into an existing pattern that doesn't quite match.
- When pulling new instances from GitHub, use `gh api repos/{owner}/{repo}/pulls/{n}/comments`, `/reviews`, and `/issues/{n}/comments` directly — don't reconstruct comment wording from the changelog or from memory; the changelog records the *response*, not always the reviewer's literal words.
