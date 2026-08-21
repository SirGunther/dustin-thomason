# Implement Phase {{PHASE}} — {{PHASE_NAME}} as one cohesive batch

Project: `{{REPO_PATH}}`
Canonical documentation: `{{DOCS_PATH}}`
Immutable baseline — never modify: `{{BASELINE_PATH}}`

Do not split Phase {{PHASE}} into subphases.

---

## CHECKLIST

Post this checklist in the chat before editing and update it as work progresses.

_One line per requirement section below, plus the four fixed closers. If a section cannot be
stated as a checkable item, it is a topic rather than a requirement — cut it or sharpen it._

- [ ] Establish a focused baseline
- [ ] _One line per requirement in **IMPLEMENTATION REQUIREMENTS**_
- [ ] Add focused tests for each new seam
- [ ] Update architecture and canonical documentation
- [ ] Run complete verification gates once
- [ ] Send completion notification containing "{{AGENT_MARKER}}"

Do not report completion until every item is implemented and validated.

---

## FOCUSED READING

Read only:

- `TODO.md` — Phase {{PHASE}}
- _the two or three architecture documents that govern this phase's boundary_
- _the files being changed, named individually_
- relevant contracts, manifests, and wiring files found with `rg`

Do not reread unrelated phase history or redesign the architecture.

---

## IMPLEMENTATION REQUIREMENTS

_Numbered, one per boundary or capability. Each carries three kinds of statement, and the
second is the one that gets dropped when this template is reused carelessly:_

### {{N}}. _Requirement name_

_What must exist._

Preserve:

- _existing behavior that must not regress — name it explicitly, because "don't break
  anything" is not checkable and this list is what makes a regression a test failure rather
  than a discovery_

Must not:

- _the specific bypass this boundary exists to prevent_

---

## DOCUMENTATION

Update:

- `TODO.md`
- `DECISIONS-PENDING.md` where applicable
- `Architecture/DesignDecisions.md` **only for actual new decisions**
- generated contract documentation and history
- a focused `Architecture/{{PHASE_EVIDENCE_DOC}}`
- `README.md` with the exact start instructions
- canonical changelog and capability documentation under `{{DOCS_PATH}}`

Keep `{{DEFERRED_ID}}` unresolved: Phase {{PHASE}} does not decide _the thing it would be
convenient to decide here_.

Keep `{{EVIDENCE_ID}}` unresolved unless this implementation produces sufficient evidence to
make it an explicit decision.

---

## OUT OF SCOPE

Do not add:

- _every adjacent thing that would make this phase easier and the next one harder_
- _the frameworks, hosts, packaging, and storage systems this phase must not reach for_
- additional Phase {{PHASE}} substeps

Do not reimplement Phase {{PRIOR_PHASE}}. Exercise it only through regression tests.

---

## VERIFICATION

During development, run focused Phase {{PHASE}} tests.

Prove:

- _one line per claim, stated as an outcome rather than a task_
- _include at least one invalid case per seam, and one negative test per boundary_

After implementation and documentation are complete, run **once**:

```text
{{GATE_COMMANDS}}
```

Run the deterministic demo/smoke command once.

Report the exact test count, contract catalog result, start command, supported controls, and
intentionally unavailable behavior.

Do not run redundant staged matrices, full-tree hash comparisons, or unrelated benchmarks.

---

## COMPLETION

Review the full checklist in the chat before declaring completion.

Only after all required work passes, run:

```text
{{NOTIFY_SCRIPT}}
```

Include "{{AGENT_MARKER}}" in the notification body.

---

## Notes on using this framework

Five things carry the weight. Everything else is scaffolding.

**The scope fence, stated twice.** "One cohesive batch" at the top and "no additional
substeps" in out-of-scope. Without both, a large phase gets delivered as a first slice with
the hard half deferred, and the deferral looks like progress.

**The read fence.** Naming the files to read, and saying not to reread phase history, is what
stops the work becoming a redesign. It is also the instruction most often omitted, because it
feels like withholding context.

**The Preserve lists.** These convert "don't regress" into specific claims that a test can
fail. A requirement section without one produces work that satisfies the new requirement and
quietly drops something that was already working.

**The Prove list.** Outcomes, not tasks — "accepted, stale, and rejected edits" rather than
"test the edit path." Tasks get ticked; outcomes get demonstrated. Require an invalid case per
seam and a negative test per boundary, or only the happy path gets covered.

**Deferred decisions held open by name.** `{{DEFERRED_ID}}` and `{{EVIDENCE_ID}}` exist so a
phase cannot quietly resolve a choice it merely touched. A phase that needs to decide one
says so and stops; it does not decide it in passing.

Two smaller ones worth keeping: the immutable baseline named at the top as never-modify, and
the gates run **once** at the end rather than repeatedly during development — which is what
keeps the reported result the final state rather than an earlier green run.
