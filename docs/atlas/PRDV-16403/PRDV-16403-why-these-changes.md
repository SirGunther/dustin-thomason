# Why these changes — atlas/PRDV-16403

> The living "Why" of this ticket. Created Phase 1 (materialized at Phase 2's first action — Plan mode cannot write), updated every phase, finalized at close. High-level: scenarios live in the testing-implementation doc; the point-in-time classification lives in [the investigation report](./investigations/PRDV-16403-investigation.md).

## Problem class (the core — what are we actually solving?)

**Completion of a deliberately deferred read path.** Not a new capability, though the ticket is framed as one.

Every constituent part of this feature already exists and ships today. The Access Manager overlay renders a right-hand panel whose entire content is a placeholder reading *"Warnings and notes will appear here in a future release."* The overlay already receives every input the work needs. The data columns all exist in Callisto, CDC-replicated from RB9. A four-layer read stack to copy sits in the same backend module. What is missing is the wire between them — an IOU written by PRDV-14820, which built the shell and named this story as the thing that would fill it.

**Why the reclassification is load-bearing rather than pedantic:** it relocates the risk. The ticket spends its detail on the plumbing — endpoint path, file list, DTO shape, registry entries — and that is precisely the part with a known-good template and machine-enforced fitness functions to keep it honest. Mirror the sibling and the plumbing is close to mechanical. The risk lives in four places the ticket barely touches: a state ambiguity it cannot see, a freshness requirement its own options over-specify, a render path with no precedent in the repo, and a scroll requirement its target element structurally cannot satisfy. See report §1.

## The code at the root (what/where is the problem)

Not a defect, so there is no faulty line. The **absence** has a precise location:

- `atlas-front-end/src/callisto/pages/JobProceedingPages/ProceedingDetailPage/components/AccessManagerOverlay/AccessManagerOverlay.vue` **L333-335** — the placeholder `<p>` bound to `common.callisto.accessManager.warningsPlaceholder`, inside `section.rightColumn` (L318). That paragraph *is* the gap.
- `callisto-back-end/src/granting-client-access/contacts/` — no read path exists from `contacts.warning` / `firms.warning` / `cases.warning` / `cases.remarks_html` to any HTTP surface.

Full trace in report §5.

## The problems we're solving

Three distinct problems, which is why the single ClickUp story became three job stories. Each has a different undesired outcome, and criteria for the first could pass while both others fail:

1. **Reach** — an Ops user must break off and open RB9 to learn what cautions exist against the case, the contact, and the firm ([story 01](./stories/PRDV-16403-job-story-01-reference-rb-notes.md)).
2. **False negative** — an Ops user cannot tell *"no caution recorded"* from *"the cautions did not load"*, and acts on the wrong one. The only one of the three where the failure is silent ([story 02](./stories/PRDV-16403-job-story-02-absent-vs-unavailable.md)).
3. **Fidelity, safely** — the case remarks arrive as formatted content that can either lose the emphasis carrying its meaning, or carry something that acts rather than reads ([story 03](./stories/PRDV-16403-job-story-03-remarks-read-as-written.md)).

## Why-log (append per phase; label each entry)

### Phase 1 — 2026-08-18 — [COURSE CHANGE]

**Obvious from the start:**

- The panel shell, the overlay context props, and the sibling read stack all exist. This was always going to be substantially a copy exercise on the backend.
- Contact and firm warnings are live RB9-replicated data. Nothing had to be built to make them available.

**Not obvious — and this is where the phase earned its keep:**

- **The blocker named in the ticket is not a blocker.** PRDV-16391 has already merged to `origin/main` (`53d961ed`; migration `1786036989067`). The ticket's entire *Sequencing note* — land contact+firm first, add the case join when 16391 merges — is moot. All four fields build in one pass.
- **The ticket names the wrong sibling to mirror.** `fetch-contact-deliverable-type-grants` has no mapper, no guard, and the loose `ParseIntPipe`. This endpoint needs all three. `FetchClientAccessListAction` has them.
- **The ticket's 404 is unreachable by the means it prescribes.** It says reuse `ValidateContactExists` for 404 — that validator throws `BadRequestException`. The clause contradicts itself.
- **The panel cannot scroll where the criterion assumes it can.** `.rightColumn` is `overflow: hidden`. Without a new inner scroll element, long content clips silently rather than scrolling.
- **Manual verification is blocked, and someone already hit this wall.** PRDV-16312 recorded an acceptance criterion as *"not demonstrated — blocked on the GCA feature flag."* The workaround PRDV-15776 documents does not exist: `IsFeatureAllowedTS` states in its own JSDoc that access follows Cognito claims only with no server-side override, and no override exists anywhere in Atlas either.

**[COURSE CHANGE] — the wedge was revised mid-phase, on the record.** The first draft of the recon proposed *ship Contact + Firm warnings end-to-end first* as the wedge, reasoning that they had real data while the case fields were blocked. Once the blocker proved false, that reasoning collapsed and the wedge was **withdrawn**. The wedge is now **the sanitised-render plus empty/error-state panel** — the only part of the work with no in-repo precedent (exactly one `v-html` and one `DOMPurify.sanitize` exist, passing no config) *and* no prior investigation by any ticket. It is also the part any future RB-sourced rich text in Atlas will inherit.

**Assumptions logged and resolved by evidence this phase**, rather than carried as questions: reopening for the same contact refetches (the overlay unmounts on close, so `refetchOnMount: 'always'` fires every open); a partial failure is not representable (one endpoint, one query, one response); a permission gate already exists at two levels; `forFeature` widening is genuinely required because neither `JobModule` nor `ProceedingsModule` re-exports `TypeOrmModule`.

**What was noise / discarded:**

- **The survives/stripped sanitization lists.** Read as an apparent contradiction on first pass — `<img>` and `<table>` listed as surviving, then *"no images or tables expected… text with CSS styling only."* Closer reading shows the request resolves its own tension: *"renders as-is with no dedicated styling support"* is a scope statement. Raised with the user, who ruled it **out of scope** — formatting the spec does not name is not to be reopened. Discarded, not carried.
- **Two prior-ledger claims that turned out stale**, both corrected rather than reused: 16313's *"no feature flags in `granting-client-access`"* (superseded by `IS_CLIENT_ACCESS_OUTBOX_ENABLED` via PRDV-16310), and 16312's dependency-state note (already corrected by 16313 itself).

**What got us here:** the consult protocol paid for itself twice — once by surfacing the F9 manual-test blocker from a prior ticket's test plan rather than discovering it in Phase 5, and once by turning up `docs/atlas/reviews/`, which the ledger glob misses because it is not ledger-formatted and which is the only prior coverage of the `contacts/` submodule anywhere. Beyond that, the corrections came from checking `origin/main` rather than the local branch: the local checkout sits on `PRDV-16313`, and every wrong claim in the Phase 0 record traces to reading it as though it were current.

## Changes made — categorized (filled as implementation locks; subject to update)

> Not yet started. No code has been written; Phase 2 emits documents only. This section fills at Phase 5.

Count: _(pending implementation)_

## Why it shipped together

_(pending — fills once the change set is known.)_ The candidate argument: all three job stories describe one act — reading the recorded cautions while granting access — and the panel cannot satisfy story 01 without also answering story 02's absent-vs-unavailable question, because an empty panel is the default state for two of four fields until PRDV-16392 ships.

## Scope

Confined to one new read endpoint in `callisto-back-end/src/granting-client-access/contacts/` and one panel plus composable in the existing `AccessManagerOverlay` tree in `atlas-front-end`. No migrations (PRDV-16391 already shipped them), no writes, no permission-model change, no change to the DMS mapping (PRDV-16392).

**Already narrowed:** formatting not named in the spec is out of scope by user ruling, 2026-08-18.

**Follow-ups likely to spin off:** the firm-identity mismatch (F3) is recorded as a concern rather than fixed here.

## Net

_(one line, at close.)_ Provisionally: paying a deliberate IOU, where the plumbing was the easy half and the state modelling was the real work.
