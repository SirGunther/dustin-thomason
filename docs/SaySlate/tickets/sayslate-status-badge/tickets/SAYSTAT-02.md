# SAYSTAT-02 — Floating Slate badge says "Pass"

> **Withdrawn before dispatch, 2026-09-24 ([LD-004](../sayslate-status-badge-decisions.md)).** Floating Slate's wording stays as it is, and the full page matches it instead (SAYSTAT-01). This file is kept for traceability. It is not dispatched, and its checkboxes and objectives stay empty.

**Handoff:** [sayslate-status-badge-handoff.md](../sayslate-status-badge-handoff.md)
**Serves:** REQ-001, REQ-002
**Depends on:** SAYSTAT-01
**May run in parallel with:** Nothing
**Branch slug:** `saystat-02-floating-pass-labels`
**Exclusive production ownership:** `floating.js`, `tests/floating-dictation-integration.test.mjs`, `tests/verify.mjs` (the Floating Slate status-literal check at lines 286-288 only), `CHANGELOG.md` (`[Unreleased]` section only)
**Must not change:** `app.js`, `app.css`, `floating.css`, `floating.html`, `floatingHost.js`, `README.md`, the prompt text each pass sends (`floating.js:255,294`), and Floating Slate's other badge labels ("Starting", "Listening", "Resumed", "Retrying", "Needs attention", "Unavailable", "Ready", "Finishing", "Stopping", "Preparing send", "Inserting", "Submitted", "Inserted", "Copied instead", "Send stopped", "Insert failed", "Copied")

## Goal

Where Floating Slate's badge now says "Phase", it reads "Pass 1" / "Pass 2", including "Pass N ready" and "Pass N failed". It shows a pass label only while the provider request runs, so a pass that stops because no provider is chosen no longer leaves one showing (EV-011). This ticket exists only if open decision 1 resolves yes. It must not change Floating Slate's other labels, its styles, or how its passes run.

## Build checklist

- [ ] Replace "Phase" with "Pass" in the six labels at `floating.js:243,261,264,282,300,303` (REQ-002; open decision 1).
- [ ] Move the two `processing` label calls (`floating.js:243,282`) to after the active profile resolves and immediately before the provider request. The missing-profile returns at `floating.js:249-252,288-291` then leave the badge unchanged (REQ-001, EV-011; open decision 1).
- [ ] In `tests/verify.mjs:286`, change the required literals "Phase 1" and "Phase 2" to "Pass 1" and "Pass 2", keeping "Inserting" and "Retrying" (EV-014).
- [ ] Extend the fake adapter in `tests/floating-dictation-integration.test.mjs` (EV-019) so a scenario can hold a request in flight and can make it fail. Then add scenarios that drive the real pass buttons and assert `status.dataset.state` and `statusText.textContent`:
  - [ ] **First pass:** `processing` / "Pass 1" while in flight, then `complete` / "Pass 1 ready".
  - [ ] **Second pass:** `processing` / "Pass 2" while in flight, then `complete` / "Pass 2 ready".
  - [ ] **Failure:** a rejected pass ends at `error` / "Pass 1 failed".
  - [ ] **No active profile:** the badge still reads "Ready" and no provider request is sent.
- [ ] Add one line under `CHANGELOG.md` `[Unreleased]`, after SAYSTAT-01's line, stating that Floating Slate's badge says "Pass" instead of "Phase" (EV-023).

## Exit gate

- [ ] `node tests/verify.mjs` exits 0.
- [ ] `node --check floating.js` and `node --check tests/verify.mjs` exit 0.
- [ ] `git diff --check` reports nothing.
- [ ] `git grep -n "Phase" -- floating.js tests/verify.mjs` returns no matches.
- [ ] Every new badge assertion follows a real user action (a dispatched click). No test calls `setStatus` directly.
- [ ] The existing scenarios in `tests/floating-dictation-integration.test.mjs` pass unmodified.
- [ ] `git diff --stat <starting commit>..HEAD` lists only the owned files.

## Out of scope

- The full-page badge: SAYSTAT-01.
- Whisper model selection, a reasoning option, and a reconcile pass: excluded by the requirements' scope boundary.

## Objectives

Complete every objective below in place, using the handoff's Compact Audit Trail Output Rule. Resolved requires implemented code, direct evidence, and focused verification; intent or partial implementation is Unresolved.

### Pass wording on Floating Slate
**State:**
**Value:**
**Evidence:**
**Depends on:**

### No pass label without a running request
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Static check and tests follow the new wording
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Scope and architecture compliance
**State:**
**Value:**
**Evidence:**
**Depends on:**

### Implementation completeness
**State:**
**Value:**
**Evidence:**
**Depends on:**
