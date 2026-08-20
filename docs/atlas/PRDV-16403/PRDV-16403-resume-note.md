# PRDV-16403 — resume note

Paused 2026-08-18.

## Objective

Fill the right-hand panel of the Access Manager with four read-only values from RB: case warning, contact warning, firm warning, case remarks. New Callisto read endpoint plus the Atlas panel.

## Current state

- Branch `PRDV-16403` in both `callisto-back-end` and `atlas-front-end`
- Nothing committed in either repo
- Callisto endpoint built: repository, transaction script, mapper, DTO, swagger, action, wiring
- Atlas built: types, request, URL builder, query key, composable, panel component, styling, i18n, overlay wiring
- Tests: 4 new suites in Atlas and Callisto, all passing; Atlas full suite 83 files / 767 tests green
- Integration spec written for the new repository, 9 cases — **untested**, no local Postgres, so the runner exits before any assertion
- Card `todo-1787076602882-c685cb38` updated: 10 rows marked, Current Step set to Development

## Key decisions

- **Derrick Dieso is the design authority.** His spec `5-story-PRDV-14828-view-warnings-in-access-manager.md` in `callisto-back-end/docs/specs/atlas-client-access/contacts/` governs. Nothing was specified by the agent.
- **Figma is the source of truth for wording.** Section headings are plural and sentence case; empty warnings read "None".
- **Shaye's ticket comments settled three things:** remarks are in scope as text with CSS styling, empty remarks read "No remarks info", failures read "Warnings/remarks failed to load".
- **Output is an addendum, not a new spec**, since duplicating a spec is forbidden.
- **Sanitiser is called bare**, per Derrick's spec. The allowlist in the ClickUp ticket is not his design and adds no safety.

## Three deviations from Derrick's spec, awaiting his response

- Returns 400, not the 404 his spec asks for, because the validator he names throws 400
- Added `ProceedingsReadAuthGuard`, which his spec does not mention
- Used `FetchClientAccessListAction` as the template, not the grants action he names, which has no mapper or guard

All three are written up in `specs/PRDV-16403-spec-addendum.md`.

## Open questions

- **Which permission the endpoint should check** — Derrick asked you to raise this with Shaye; it could be case, proceeding, or client deliverables
- **What the two case sections show before the replication ticket ships** — they will read "None" and "No remarks info" even when RB holds data, which is untrue

## Constraints worth remembering

- **PRDV-16391 already merged.** The three case columns exist. The ticket's sequencing note is void.
- **PRDV-16392 has not shipped and has no spec anywhere.** It is the reason case values arrive empty. Inject them by hand to test — the insert statement is in the test plan, manual step 8.
- **DOMPurify does not sanitise correctly under the test environment.** Probed directly: `<p>Safe</p><script>x=1</script>` returns `Safe<script>x=1</script>`. Sanitisation must be verified by hand in a browser; the specs only prove raw html is routed through the sanitiser.
- **`npx tsc --noEmit` does not pass on Callisto's main.** Eleven files fail on a stale package. None are files this ticket touches.
- **Manual verification is blocked** behind the `IS_GRANTING_CLIENT_ACCESS_ENABLED` Cognito flag. There is no override — the workaround recorded on PRDV-15776 does not exist in either repo.

## Resume point and next step

Resume at implementation. Two things unblock the rest:

1. Send the addendum to Derrick and get his answer on the three deviations
2. Ask Shaye which permission the endpoint should check

Then: run the integration spec against a local Postgres, and do the manual pass with case values injected by hand.

## Not started

- Local testing of any kind
- Testing-implementation artifact
- Commit, push, PR
