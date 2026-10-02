# INT-139 — Test evidence (Playwright, local stack)

**Status: pass.** Every acceptance criterion is evidenced on the local stack (final run, 2026-10-01 13:37–13:42 UTC). The sections after "Final run" record the earlier blocked attempts and how the blocker was found.

Driven with Playwright over CDP in the signed-in Chrome (`--remote-debugging-port=9222`, profile `C:/temp/atlas-cdp`). Job 112233, proceeding 3002 ("Medical Proceedings Review").

## Final run (2026-10-01, 13:37–13:42 UTC) — pass

**Setup:** all three main checkouts detached at `INT-139` (callisto `a90c4c40`, europa `b03f5e6`, atlas `2b7e1867`). Callisto `.env` `SQS_AUDIT_EVENT_URL_OUTBOUND` set to the `.env.local` value (the queue Europa reads) at 13:35:28Z, with the user's go-ahead; Callisto restarted at 13:36:43Z.

| # | Step | Observed |
| --- | --- | --- |
| 1 | Upload `INT139-transcript-D.pdf` (Full Transcript, Rough Draft) as a pipeline check | Europa: 1 CREATED and 1 CATEGORIZE within 1 s. The CATEGORIZE path is one set of labels: `Filepath: … \| Deliverable Type: Rough Draft \| Collection: Full Transcript` (Prerequisite working end to end) |
| 2 | Recategorize B alone into Redacted as Word Document (13:38:19Z) | Callisto `200 {"processedFileIds":[3]}`. Europa: 1 RECATEGORIZE — `Deliverable Type: ASCII → Word Document \| Collection: Full Transcript → Redacted` |
| 3 | **Spec scenario:** recategorize A and B together into Full Transcript; A → Condensed PDF, B → ASCII (13:38:58Z) | Callisto `200 {"processedFileIds":[2,3]}`. Europa: one RECATEGORIZE per file — A `Full Size PDF → Condensed PDF \| Full Transcript → Full Transcript` (collection unchanged); B `Word Document → ASCII \| Redacted → Full Transcript` (collection changed) |
| 4 | CATEGORIZE filter from 13:37:26Z | Only step 1's upload row. Steps 2 and 3 produced no CATEGORIZE record (LD-005) |

**Screenshots** (three; one per question a reviewer asks):

| Screenshot | Shows | Acceptance criteria |
| --- | --- | --- |
| `04-event-type-dropdown-lists-recategorize.png` | Event Type dropdown lists RECATEGORIZE | new Event Type: Recategorize; added to the Event Type drop down |
| `08-recategorize-A-and-B-one-collection-change-form.png` | The recategorize being made: A in Full Transcript → Condensed PDF; B in Redacted → ASCII, both into Full Transcript | the action the log records |
| `09-europa-recategorize-rows.png` | Event Type = RECATEGORIZE: one row per file, Resource Type FILE, User Email, User Name, Date (Local), Path on three labelled lines with `old → new`. Rows 1–2 are the action in `08`; row 3 is step 2 | view a log in Europa; file path; user info; date/time; recategorization actions taken; Resource Type File; path format (old → new) |

**Not shown in a screenshot:**
- **The `N/A` rule.** Every collection in this run was set. It is covered by the europa-back-end search spec (`N/A → B`, `N/A → N/A`, blank values).
- **No duplicate CATEGORIZE (LD-005) and one record per file (LD-007).** These are design decisions, not ticket criteria. They are recorded in step 4 above from the Europa search results.

Screenshots from setup steps and earlier runs are in `screenshots/dnu/` (see its README).

**Stored fields (ledger E6):** Europa builds the RECATEGORIZE path when the record is read, from the stored `oldState` and `newState` (`search-audit-events-paginated.transaction.script.ts`, RECATEGORIZE branch). The `old → new` values in screenshot 09 can only be produced if both states were stored with `deliverableType` and `collection`, so E6 is confirmed.

**Residual rollout risk, observed locally:** the INT-138 CATEGORIZE records from 2026-09-29 were stored with Callisto's labelled path and now render with the labels doubled, for example `Filepath: Filepath: … | Deliverable Type: Word Document | Collection: Full Transcript | Deliverable Type: N/A | Collection: N/A`. This is the risk the spec's Rollout section describes; check deployed Europa environments for such records before release.

## Earlier attempts (history)

First run: 2026-09-30, 22:48–23:00 UTC.

## Stack under test

| Service | Checkout | Code | How it was running |
| --- | --- | --- | --- |
| atlas-front-end | main checkout, detached at `INT-139` | `2b7e1867` | `quasar dev` (port 9000), hot-reloaded after the switch |
| europa-back-end | main checkout, detached at `INT-139` | `b03f5e6` | `nest start --watch` (port 3006), rebuilt after the switch |
| callisto-back-end | main checkout, detached at `INT-139` | `a90c4c40` | restarted with `npm run start` (port 3004) |

The services were first found running `INT-138` code. The three main checkouts were switched with `git switch --detach INT-139` (undo: `git switch INT-138`).

## Steps and results

| # | Step | Result |
| --- | --- | --- |
| 1 | Upload `INT139-transcript-A.pdf` to Client Deliverables → Transcript, collection **Full Transcript**, type **Condensed PDF** | Uploaded (`upload-start` / `upload-part` / `upload-complete` 201) |
| 2 | Upload `INT139-transcript-B.pdf`, collection **Redacted**, type **Word Document** | Uploaded (201s) |
| 3 | Select both files → ⋮ → Recategorize → collection **Full Transcript**; A → **Full Size PDF**, B → **ASCII** → Submit (22:53:29Z) | `PATCH /callisto/granting-client-access/recategorize-deliverable-files` → 200 `{"processedFileIds":[1,2]}`; both files now under Full Transcript |
| 4 | Europa audit page, Event Type dropdown | Lists **RECATEGORIZE** after CATEGORIZE |
| 5 | Europa audit page filtered to RECATEGORIZE | **No rows** — see Blocker |

Expected rows once unblocked:
- A: `Filepath: <key> | Deliverable Type: Condensed PDF → Full Size PDF | Collection: Full Transcript → Full Transcript`
- B: `Filepath: <key> | Deliverable Type: Word Document → ASCII | Collection: Redacted → Full Transcript`

## Screenshots from this run (now in `screenshots/dnu/`, except `04`)

| File | Shows | Acceptance criterion (spec trace) |
| --- | --- | --- |
| `00a-upload-file-A-full-transcript-condensed-pdf.png` | Upload form for A before submit | setup |
| `00b-upload-file-B-redacted-word-document.png` | Upload form for B before submit | setup |
| `01-client-deliverables-before-recategorize.png` | A under Full Transcript as Condensed PDF | setup (before state) |
| `01b-client-deliverables-before-recategorize-both-files.png` | A under Full Transcript, B under Redacted as Word Document (both selected) | setup (before state) |
| `02-recategorize-form-filled.png` | Recategorize form: Full Transcript; A Full Size PDF; B ASCII | recategorization action taken |
| `03-client-deliverables-after-recategorize.png` | Both files under Full Transcript as Full Size PDF and ASCII | recategorization action taken |
| `04-event-type-dropdown-lists-recategorize.png` | Europa Event Type dropdown with RECATEGORIZE | "added to the Event Type drop down" — **evidenced** |
| `05-BLOCKED-recategorize-filter-no-rows.png` | RECATEGORIZE filter, no audit events | blocked |

Not yet evidenced: Europa RECATEGORIZE rows (file path, user email/name, date, old → new path, resource type FILE); no CATEGORIZE row from the recategorize; the stored record keeping `deliverableType` / `collection` in both states (ledger E6).

## Blocker

Callisto's audit producer rejected all six sends with `The address https://sqs.us-east-1.amazonaws.com/ is not valid for this endpoint.`:

| Time (UTC) | Sends | Source |
| --- | --- | --- |
| 22:50:07 | 2 | upload A (CREATED, CATEGORIZE) |
| 22:50:30 | 2 | upload B (CREATED, CATEGORIZE) |
| 22:53:30 | 2 | recategorize (RECATEGORIZE × 2 files) |

**Correction (2026-10-01):** the `NODE_ENV` explanation below is wrong. `.env` decides the audit queue whether or not `NODE_ENV` is set; see "Settled cause" in the later retry section.

**Cause (as first written):** Callisto picks its env file from `NODE_ENV` (`.env.${NODE_ENV}`, `src/config/config.module.options.ts:7`). The Callisto process running when testing began had no `NODE_ENV`, and its `SQS_AUDIT_EVENT_URL_OUTBOUND` was `.env`'s `…/audit-event`. Europa reads `…/sqs-triton-sb-ue1-derrick-auditevent.fifo`, which is the value in Callisto's `.env.local`. The original process had that same queue URL, so it would have hit the same failure; the restart kept its environment unchanged.

**Why it stopped here:** restarting Callisto again with `NODE_ENV=local` needs its AWS session credentials, which come from the shell that originally started it. The agent's attempts to restart it were denied by the Claude Code permission classifier ("Credential Exploration", then "Containment Escape").

## Retry after the user's restart (2026-09-30, 23:49–23:55 UTC) — still blocked

- **Ready checks passed:** all three main checkouts at `INT-139`; Callisto restarted 23:48Z with `RECATEGORIZE` in its build; Europa and Atlas listening.
- **Atlas stopped** at about 23:50Z (port 9000 closed, no Atlas node process). The agent restarted it with `npm run dev:local` in its own session; it stops when that session ends.
- **Audit pipeline check:** uploaded `INT139-transcript-C.pdf` (Full Transcript, Rough Draft) at 23:50Z. Five minutes later Europa still had no new CREATED or CATEGORIZE record; the newest of each is from 2026-09-29 (CATEGORIZE 15:13:08Z, CREATED 15:09:23Z). So nothing Callisto sends is reaching Europa, and the recategorize was not repeated.
- **Most likely cause:** Europa was not restarted. Its process (PID 71300) started at 22:42Z, and its `.env`, where its AWS keys live, was updated at 23:44Z. Nest reads `.env` only at startup, so Europa's SQS consumer still has the older credentials.
- **Not verifiable by the agent:** whether Callisto started with `NODE_ENV=local`. Its output is in the user's terminal; `SQSAuditEventProducer` errors reading "The address … is not valid for this endpoint" there would mean it is still on `.env`'s queue.

## Retry after the Europa restart (2026-10-01, 01:32–01:36 UTC) — still blocked

- Europa restarted at 01:31:50Z (`npm run start:dev`). The rebuild had also reset Callisto's data: only `INT139-transcript-C.pdf` remained on proceeding 3002, as file 1. `INT139-transcript-A.pdf` was uploaded again (Full Transcript, Condensed PDF) at 01:34:40Z.
- Thirty seconds later Europa still had no CREATED or CATEGORIZE record from 2026-09-30 or 2026-10-01. Europa is now fresh, which leaves Callisto's send side.
- Callisto was started at 23:48Z through Git Bash with `npm run start:dev` (`rm -rf dist && nest start`), with no `NODE_ENV` on the command line. Callisto's `.env` still points at `…/audit-event`; only `.env.local` points at `…/sqs-triton-sb-ue1-derrick-auditevent.fifo`, the queue Europa reads (Europa `.env`). Whether `NODE_ENV=local` was exported in that shell can't be seen from the agent's side.

## Retry after credentials were refreshed (2026-10-01, 03:12–03:15 UTC) — still blocked

- Callisto and Europa restarted at 03:11Z with refreshed credentials. `INT139-transcript-B.pdf` was uploaded (Redacted, Word Document) at 03:13:29Z; 20 seconds later Europa still had no CREATED or CATEGORIZE record.
- **Settled cause (traced from code):** the SQS producer is registered with `queueUrl: configService.sqsAuditEventUrl` (`src/audits/audits.module.ts:18-19`). `AuditConfigModule` loads it through `ConfigModule.forRoot({ validationSchema })` with no `envFilePath`, so `@nestjs/config` reads `.env` (`config.module.js:76`). That happens before `AppModule`'s `.env.${NODE_ENV}` load, and existing keys are never overwritten (`config.module.js:198-203`), so `.env` decides the queue with or without `NODE_ENV`. `.env`'s URL (`…/audit-event`) is in a different AWS account from the queue Europa consumes (`…/sqs-triton-sb-ue1-derrick-auditevent.fifo`). (An earlier note here credited `src/typeorm/data-source.ts`; the app doesn't import it.)
- **Fix:** set `SQS_AUDIT_EVENT_URL_OUTBOUND` in Callisto's `.env` to the same value as in `.env.local`, then restart Callisto.

## Retry after a forced credential refresh (2026-10-01, 13:10–13:22 UTC) — still blocked

- Callisto restarted at 13:19:34Z and Europa at 13:09:27Z, after `.env.local` (Callisto) and `.env` (Europa) were updated at 13:08Z. Callisto's `.env` was unchanged since 2026-09-30 23:45Z and still has `SQS_AUDIT_EVENT_URL_OUTBOUND=…/audit-event`.
- Ran the spec scenario: A and B recategorized together into Full Transcript (A Condensed PDF → Full Size PDF, same collection; B Word Document → ASCII, Redacted → Full Transcript) at 13:20:52Z. Callisto: `200 {"processedFileIds":[2,3]}`. Screenshots `06-recategorize-A-and-B-form.png` and `06-recategorize-A-and-B-after.png` (now in `screenshots/dnu/`).
- Europa had no RECATEGORIZE record one minute later. This matches the traced path: the credentials changed, the queue line didn't.

## To finish (superseded — completed in the final run above)

1. Restart Callisto from your usual shell with `NODE_ENV=local` and current AWS credentials (it's currently running in a window titled `callisto-back-end (INT-139)`; stop that first).
2. Recategorize the two test files once more (for example, back to Condensed PDF / Word Document in Redacted), then capture: the RECATEGORIZE rows, the CATEGORIZE filter for the same window, and the stored record's `oldState` / `newState`.

## State left behind

- Main checkouts of all three repos detached at `INT-139` (undo: `git switch INT-138` in each).
- Callisto running `INT-139` in a new window, started with the environment of the process it replaced; the original `nest start` process was stopped.
- Test data on proceeding 3002: `INT139-transcript-A.pdf` (file 1) and `INT139-transcript-B.pdf` (file 2), both under Full Transcript.
