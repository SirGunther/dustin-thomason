# INT-140 — Test evidence (Playwright, local stack)

**Status: pass.** Every acceptance criterion is shown on the local stack. Run on 2026-10-07, 19:27–19:28 UTC.

The run was driven with Playwright over CDP in the signed-in Chrome (`--remote-debugging-port=9222`, profile `C:/temp/atlas-cdp`), in a new tab. The user's own tab was left untouched. Job 112233 (job date 05/01/2024).

## Stack under test

| Service | Checkout | Code | Running |
| --- | --- | --- | --- |
| callisto-back-end | main checkout, detached at `INT-140` | `55431e07` (on `origin/main` `8f31f933`) | :3004, started 15:25:18 local. Its `dist` contains `proceeding-creation-to-audit.converter.js` and `job-date-reader.port.js`. It started with the new `JOB_DATE_READER` binding, so the port resolves at boot |
| europa-back-end | main checkout, detached at `INT-140` | `9fbc0bb` (on `e5ff3be`) | :3006 (`nest start --watch`). Its `dist` contains the `Proceeding Name:` branch |
| atlas-front-end | main checkout, detached at `INT-140` | `cacfd124` (on `c15c22e3`) | :9000 (`quasar dev`) |

## Steps and results

| # | Step | Observed |
| --- | --- | --- |
| 1 | File Navigator, job 112233: New proceeding, then `INT140 Proceeding A`, Add another proceeding, `INT140 Proceeding B`, Save | One request: `POST /callisto/proceedings` `{"jobId":112233,"values":["INT140 Proceeding A","INT140 Proceeding B"]}` returned `201` `[{"id":2,"value":"INT140 Proceeding A"},{"id":3,"value":"INT140 Proceeding B"}]` at 19:27:18Z. The job shows 4 proceedings and the message "Successfully added 2 proceedings" |
| 2 | Europa audit page, Event Type `CREATED`, Resource Type `PROCEEDING` | Two rows, one per proceeding (LD-006). Each has User Email `dustin.thomason@planetdepos.com`, User Name `Dustin Thomason`, Resource set to the proceeding name, Resource Type `PROCEEDING`, Date `2026-10-07 15:27:18` (local), and a blank Bucket (LD-012). The Path has two bold-labelled lines: `Path: 052024/112233/2` / `Proceeding Name: INT140 Proceeding A`, and `Path: 052024/112233/3` / `Proceeding Name: INT140 Proceeding B` |
| 3 | Resource Type dropdown | Options: `FILE`, `FOLDER`, `PERMISSION`, `PROCEEDING`, `USER` |
| 4 | Regression: Event Type `CREATED`, Resource Type `FILE`, All time | File rows unchanged: the Path is the raw S3 key on one line with no bold label, and the Bucket is filled (e.g. `052024/112233/3002/5684fde2-…761d.pdf`, `s3-callisto-sb-ue1-jobs`) |

**The path's date segment (LD-005):** the job date 05/01/2024 gives `052024`. That is the same prefix as the S3 keys of files already uploaded under job 112233 (`052024/112233/3002/…`, step 4).

## Screenshots (`screenshots/`)

Narrowed on 2026-10-08 to the minimum that covers the original ticket's acceptance criteria. The other three are in `screenshots/dnu/`; see its README.

| Screenshot | Shows | Acceptance criteria |
| --- | --- | --- |
| `02-file-navigator-proceedings-created.png` | File Navigator, job 112233, listing both new proceedings, with "Successfully added 2 proceedings" | "File Navigator proceeding creation" action taken |
| `04-europa-resource-type-dropdown-lists-proceeding.png` | The Europa audit log with the Resource Type dropdown open and listing PROCEEDING. The same view shows both CREATED / PROCEEDING rows with User Email, User Name, Date, Resource Type PROCEEDING, and the two-line path `Path: 052024/112233/<id>` / `Proceeding Name: <name>` | Ops can view a log in Europa for proceeding creation; user info; date/time; Event Type Created; the Proceeding resource type added to the Resource Type drop down; path format (Path, Proceeding Name) |

**Not shown in a screenshot:** file CREATED rows staying unchanged (step 4). This is a regression check, not an acceptance criterion. It is covered by the atlas `SearchDataGrid.spec.ts` and the europa-back-end search spec.

## Not run

- **AJSF negative check** (spec §Manual step 5: an AJSF create produces no `CREATED` / `PROCEEDING` row). Not run, because it needs a pending job-submission form. The code-level evidence is that `JobSubmissionService`, `ProceedingAggregator.createProceedings` and `CreateProceedingsTS` are unchanged (F-02, LD-002), and the dispatch exists only in `ProceedingService.createProceedings`.
- **The stored Mongo record** (`oldState: null`, `newState: { path, value }`) was not inspected directly. The rows in step 2 can only be built from `newState.path` and `newState.value` (europa-back-end `CREATED` + `PROCEEDING` branch).

## State left behind

- The main checkouts of all three repos are detached at `INT-140`. Undo: `git switch INT-138` in callisto-back-end; `git switch --detach b03f5e6` in europa-back-end; `git switch --detach 2b7e1867` in atlas-front-end. Their earlier uncommitted files (callisto `.swcrc` and `notification-template-preview.html`; atlas `.claude/`) are untouched.
- Test data: proceedings 2 (`INT140 Proceeding A`) and 3 (`INT140 Proceeding B`) on job 112233.
