# PRDV-16216 — Local Validation Plan (persist-time copy)

> Status: active · Created 2026-07-16 · Owner: Dustin Thomason
> Feature under test: PR #24 persist-time copy of media duration onto Nova-transcoded file rows.
> Companion artifacts: `PRDV-16216-future-development-concerns.md` (risk record), `PRDV-16216-changelog.md` (decision log), `artifacts/PRDV-16216-update-length-endpoint.patch` (superseded browser-probe endpoint).

## Context

Shipped implementation (user decision 2026-07-16): when Nova's `video-transcode-completed` event reaches Callisto, the derived file row is created with `length = originalFile.length` (copied, not measured — accepted trade-off; risk record above). Unit level proven (25 tests green). This plan validates the feature **end-to-end locally**: event in → inbox → handler → S3 copy → DB row born with length → Atlas UI displays it.

**Sanity check — branch isolation: CONFIRMED.** `callisto-back-end` on branch `PRDV-16216`; working diff is exactly the 5 feature files (param, service, mapper + 2 specs). Atlas requires no changes (display path already ships).

## How the feature fires locally (traced in code)

```
publish event → vhost: nova, exchange: nova.events (topic),
  routing key: callisto.proceeding.file.video-transcode-completed.v1
       ↓ queue → NovaProceedingFileVideoTranscodeCompletedListener
       ↓ row into callisto.proceeding_inbox_events
ProceedingInboxPoller → ProceedingVideoTranscodeCompletedInboxHandler
       ↓ ProcessProceedingVideoTranscodeCompletedService
  1. context assembler: original file must exist (fileId+proceedingId+trackTypeId);
     S3_JOBS config present; destination key must NOT already exist
  2. S3 copy transcodedbucket/key → jobs bucket  (REAL AWS call)
  3. persistDerivativeTS → mapper → file.length = sourceLength   ← THE FEATURE
       ↓ Atlas proceeding page → Length column shows duration on converted row
```

Payload shape: `callisto-back-end/docs/runbooks/video-transcode-events.md` (verbatim example).

## Required setup

| Item | State | Action |
| ---- | ----- | ------ |
| Stack (postgres, rabbitmq, Callisto :3004, Atlas :9000) | UP, verified | none |
| `INBOX_ENABLED` | `false` in `.env` — **blocker #1** | set `true` in `.env` (+ `.env.local`), restart API |
| RabbitMQ `nova` vhost + `nova.events` exchange | vhost exists; exchange auto-declared on boot | verify after restart |
| AWS credentials | **absent — blocker #2**; S3 copy is a real call against `S3_JOBS=s3-callisto-sb-ue1-jobs` (sandbox) | Dustin: fresh keys from Planet Portal; `export AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY/AWS_SESSION_TOKEN` in the Git Bash shell that starts the API |
| Test data (fresh local DB) | **empty — blocker #3**: need job + proceeding + Video-track original file **with non-null length**, and a matching S3 object | create by uploading a small real `.mp4` through local Atlas (browser probe fills `length`; upload puts a real object in the SB jobs bucket) |
| `video_transcodes` seed | seeded by migrations on fresh DB | verify with SQL |
| Chrome + CDP for UI validation | agreed | `start chrome.exe --remote-debugging-port=9222 --user-data-dir=C:/temp/atlas-cdp http://localhost:9000` (Git Bash); Playwright 1.61.1 global attaches via `connectOverCDP` |

## Exact commands

```bash
# restart Callisto after env edits (same pattern as quickstart Part 2):
cd /c/Users/dustin.thomason/callisto-back-end
netstat -ano | grep -E ":3004 .*LISTENING" | awk '{print $5}' | sort -u | while read pid; do taskkill //PID $pid //F 2>/dev/null; done
export AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=... AWS_SESSION_TOKEN=...   # Dustin
NODE_ENV=local nohup npm run start:dev > /tmp/callisto.log 2>&1 &
sleep 50 && curl.exe http://localhost:3004/callisto/health

# publish the crafted event (RabbitMQ HTTP API, guest/guest):
curl.exe -s -u guest:guest -H "content-type:application/json" \
  -X POST http://localhost:15672/api/exchanges/nova/nova.events/publish \
  -d '{"routing_key":"callisto.proceeding.file.video-transcode-completed.v1","payload":"<runbook-shaped JSON with real ids>","payload_encoding":"string","properties":{}}'

# scoped automated tests (already green; rerun as final gate):
npm test -- --runInBand src/proceedings/domain/transaction-scripts/persist-proceeding-video-transcode-derivative-ts src/proceedings/domain/services/process-proceeding-video-transcode-completed-service
```

## Manual validation steps

1. **Inbox processed:** `SELECT type, processed_at FROM callisto.proceeding_inbox_events ORDER BY received_at DESC LIMIT 5;` → our event, non-null `processed_at`.
2. **The feature:** new derived `files` row exists; **`length` equals the original row's `length`** (not null); `file_derivations` links source→derived (`producer_system='NOVA'`, COMPLETED).
3. **S3 (implicit):** persistence only happens after a successful copy, so a persisted row proves the copy ran.
4. **UI (Playwright/CDP):** open proceeding page → converted row shows formatted duration in **Length** (not "unavailable"); screenshot as evidence.
5. **Negative (design-accepted):** rows transcoded *before* this change stay "unavailable" (no backfill).

## Automated tests

- **Run:** scoped suites (25 tests, incl. copied-length + null-source→null) + full gates before commit (`npm audit --audit-level=high` → `npm run lint` → full `npm test -- --runInBand`).
- **Add:** none required — copy semantics covered; E2E is the manual/Playwright pass.

## Known gaps / assumptions / blockers

- **Gap:** local E2E still touches **sandbox S3** (`s3-callisto-sb-ue1-jobs`); expired session tokens are the likeliest mid-test failure (re-export + restart API).
- **Assumption:** crafted-event payload passes the parser (runbook example is the source shape; ids swapped for real rows).
- **Assumption:** local Atlas upload lands the object in the same jobs bucket the handler uses (`S3_JOBS`) — verified in config, not yet exercised.
- **Blocker if declined:** no AWS creds → no local E2E; fallback is sandbox-deploy testing (normal route for this event flow).
- **Docs gap:** transcode-event *injection* isn't documented — add to the runbook once this works.

## Ownership

**Dustin (local-only):** AWS keys + export in shell · Azure login in CDP Chrome · upload a small `.mp4` via UI · confirm SQL + UI results.
**Agent (codebase/automation):** flip `INBOX_ENABLED`; restart + verify boot; craft event JSON from real ids; publish via RabbitMQ HTTP API; run SQL checks; drive Playwright UI verification; rerun gates; changelog entry before commit.

## Turn-based execution

| # | Who | Step | Done-when |
|---|-----|------|-----------|
| 1 | Agent | `INBOX_ENABLED=true`, restart, verify boot | health OK + nova listener queue bound |
| 2 | Dustin | Export AWS creds in Git Bash; agent restarts API in that shell | health OK with creds present |
| 3 | Dustin | Launch CDP Chrome, log in, open a real local job/proceeding (create if empty) | proceeding detail renders |
| 4 | Dustin | Upload small `.mp4` (Video track) | row shows a Length (browser-measured original) |
| 5 | Agent | Read real ids from DB, craft + publish completed event | publish returns `{"routed":true}` |
| 6 | Agent | SQL: inbox processed; derived row `length` = original's; derivation row present | all three true |
| 7 | Agent | Playwright: reload page, assert converted row Length, screenshot | duration visible, not "unavailable" |
| 8 | Both | Ship: full gates + changelog session log; commit/push on Dustin's word | gates table green |
