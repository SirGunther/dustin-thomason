# Demo runbook — PRDV-15619 "Refresh proceedings" button (AJSF step 5)

How to stand up and **demo the manual refresh-proceedings button live, solo** — every prerequisite, command, terminal type, env value, and DB edit used during validation. Follow top to bottom on a clean machine and you'll reproduce the exact demo (1 new / 3 new / error / up-to-date) with no agent help.

- **Feature branch (Atlas):** `PRDV-15619`
- **Surface:** AJSF (Pending Job Submission Form) → step 5 **"File upload"**, for a job assigned to your resource.
- **Backend touched:** none — frontend-only; reuses `GET /callisto/proceeding-job-submission/job-detail/{jobId}/proceedings`.
- **Base setup reference:** [`full-stack-local-setup.md`](./full-stack-local-setup.md) and [`dev-testing-prerequisites.md`](./dev-testing-prerequisites.md). This doc only needs **Callisto + Atlas** (Triton/Europa not required).

---

## 0. Prerequisites (one-time + per-session)

| Need | How | Per-session? |
|------|-----|--------------|
| **Docker Desktop** running | launch the app | yes |
| **Postgres + RabbitMQ containers** exist | `full-stack-local-setup.md` Step 0 (one-time) | start each session |
| **Node.js** 22+ (24 used) | installed | — |
| **GitHub PAT** (`read:packages`, SSO-authorized for PlanetDepos) | `$env:GITHUB_TOKEN="<pat>"` in the shell you run `npm ci` from | yes (per shell) |
| **AWS credentials** (Neptune **DEV**) | [Planet Portal](https://planetportal.awsapps.com/start/#/?tab=accounts) → export or env file | yes (expire 1–4h) |
| **DEV Cognito pool** wired in env files | see [§2 Env files](#2-env-files-critical-for-login) | one-time |
| **SB/DEV login account** with Neptune access | your `@planetdepos.com` SSO account | — |
| **DBeaver** (or `docker exec ... psql`) | this doc shows both | yes |
| Branch `PRDV-15619` checked out in `atlas-front-end` | `git checkout PRDV-15619` | — |

> **Terminal types (Windows):** start commands are **PowerShell**. AWS-cred exports for backends are easiest in **Git Bash** (the portal hands you a ready-to-paste `export ...` block). DB commands below use `docker exec ... psql` from **PowerShell**, or paste the SQL into **DBeaver** (Callisto connection).

---

## 1. Start the stack (2 terminals)

```powershell
# Terminal 1 (PowerShell) — Docker + Callisto
docker start callisto-postgres
docker start callisto-rabbitmq
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"   # both Up

cd C:\Users\dustin.thomason\callisto-back-end
$env:NODE_ENV = "local"
# Windows note: `npm run dev:watch` uses `rm -rf dist` (Unix) and fails on Windows.
# Clear dist with PowerShell, then run nest directly:
Remove-Item -Recurse -Force dist -ErrorAction SilentlyContinue
npx nest start --watch
# verify (new shell): curl.exe http://localhost:3004/callisto/health  → {"status":"ok",...}
```

```powershell
# Terminal 2 (PowerShell) — Atlas front-end
cd C:\Users\dustin.thomason\atlas-front-end
git branch --show-current        # expect: PRDV-15619
npm run dev:local                # opens http://localhost:9000
```

Triton/Europa are **not** needed. You'll see harmless `http proxy error: /triton/...` / `/europa/... ECONNREFUSED` noise in the Atlas console — ignore it.

---

## 2. Env files (critical for login)

The login failure ("An error was encountered with the requested page") happens when the Cognito pool in the env files doesn't match the account you sign in with. This demo used the **Neptune DEV** pool. Pool/client IDs are non-secret config (also visible in the repo's GitHub Actions variables).

**`atlas-front-end/.env.local`**

```
ENV_NAME=local
CALLISTO_API_URL=http://localhost:3004
AWS_USER_POOL_ID=us-east-1_otBuqDnBc
AWS_USER_POOL_WEB_CLIENT=4fv54dc49gaorvr0tk6sm1fn7q
AWS_AUTH_DOMAIN=neptune-dev-ue1.auth.us-east-1.amazoncognito.com
AWS_REDIRECT_SIGN_IN=http://localhost:9000,https://atlas-dev.planetdepos.com
AWS_REDIRECT_SIGN_OUT=http://localhost:9000,https://atlas-dev.planetdepos.com
```

**`callisto-back-end/.env`** (the values that matter for this demo)

```
APP_PORT=3004
OUTBOX_ENABLED=false
INBOX_ENABLED=false
AWS_COGNITO_CLIENT_ID=4fv54dc49gaorvr0tk6sm1fn7q
AWS_COGNITO_USER_POOL_ID=us-east-1_otBuqDnBc
# placeholder SQS values must be valid URIs (config validation rejects "sqs-url"):
SQS_PROCEEDING_FILE_UPLOAD_URL_OUTBOUND=https://sqs.us-east-1.amazonaws.com/000000000000/local-dummy
# ...repeat a valid dummy URI for any other required SQS_* vars
```

> **Port note:** this demo ran Callisto on **3004**, so `CALLISTO_API_URL=http://localhost:3004` is set in Atlas. If you instead leave `APP_PORT` unset, Callisto defaults to **3003** and you should omit `CALLISTO_API_URL` (quasar proxies to 3003). Pick one and keep both files consistent, or the Atlas proxy throws ECONNREFUSED.

After editing either env file, **restart that service**.

---

## 3. One-time DB seed (closes the local-environment gaps)

A fresh local Callisto DB is missing three things the AJSF needs. Run these once (PowerShell `docker exec`, or paste the SQL bodies into a **DBeaver** SQL editor on the **Callisto** connection with `SET search_path TO callisto, public;` at the top).

**3a. Test job + your resource** — run the existing test-data script: insert your resource (`full-stack-local-setup.md` → "Insert yourself into the resources table", id `999999997`) then execute [`SQLScript.mdc`](./SQLScript.mdc). This creates **job `899999996`** with tasks `899999966–899999969` assigned to resource `999999997`.

**3b. Seed `video_transcodes`** — empty table blocks AJSF form creation with `VideoTranscode "" reference value not found` (500 → null `jobId` → `/job-detail/NaN/proceedings`). The `NONE` value is an **empty string**:

```powershell
docker exec callisto-postgres psql -U postgres -d callisto -c "INSERT INTO callisto.video_transcodes (value) VALUES (''), ('Standard'), ('Video Mix'), ('Site Survey'), ('Day in the Life'), ('Other') ON CONFLICT (value) DO NOTHING;"
```

**3c. Grant `AJSF_PROCEEDINGS` read** — the resource key exists but ships with **zero ALLOW** grants, so every proceedings read 403s regardless of role. Flip all rows to ALLOW:

```powershell
docker exec callisto-postgres psql -U postgres -d callisto -c "UPDATE callisto.permissions p SET effect = 'ALLOW' FROM callisto.resource_keys rk WHERE rk.id = p.resource_keys_id AND rk.key = 'AJSF_PROCEEDINGS';"
```

Verify the seeds:

```powershell
docker exec callisto-postgres psql -U postgres -d callisto -c "SELECT count(*) FROM callisto.video_transcodes;"   # 6
docker exec callisto-postgres psql -U postgres -d callisto -c "SELECT effect, count(*) FROM callisto.permissions p JOIN callisto.resource_keys rk ON rk.id=p.resource_keys_id WHERE rk.key='AJSF_PROCEEDINGS' GROUP BY effect;"  # ALLOW | 96
```

---

## 4. Log in and open the AJSF

1. Browse to `http://localhost:9000`.
2. Sign in via Cognito Hosted UI with your **SB/DEV** `@planetdepos.com` account (the one with Neptune access).
3. Navigate to the **Pending Job Submission Form** for job **`899999996`** and go to **step 5 "File upload"**.
   - Opening the form auto-creates the `job_submission_forms` row (needs §3b done).
4. You should see the **existing proceedings** list with a **Refresh proceedings** icon button in the section header.

---

## 5. Reset to a clean baseline (before each demo run)

Leave **one** proceeding so the list isn't empty, then **full-reload** the browser so the UI matches the DB.

```powershell
# remove any leftover demo rows, keep a single baseline
docker exec callisto-postgres psql -U postgres -d callisto -c "DELETE FROM callisto.proceedings WHERE job_id = 899999996 AND value <> 'Deposition - Refresh Test Witness';"
# ensure the baseline row exists
docker exec callisto-postgres psql -U postgres -d callisto -c "INSERT INTO callisto.proceedings (value, job_id) VALUES ('Deposition - Refresh Test Witness', 899999996) ON CONFLICT (value, job_id) DO NOTHING;"
docker exec callisto-postgres psql -U postgres -d callisto -c "SELECT id, value FROM callisto.proceedings WHERE job_id = 899999996 ORDER BY id;"
```

Then **hard-reload** the AJSF page → the panel shows **1 proceeding**.

---

## 6. The demo (4 scenarios)

For each: run the DB step, then in the browser click **Refresh proceedings** and watch the toast. The button does a one-shot fetch (fail-fast — no 2-minute retry hang) and writes the cache directly, so the form's unsaved data is never touched.

### Scenario 1 — "1 new proceeding(s) found"

```powershell
docker exec callisto-postgres psql -U postgres -d callisto -c "INSERT INTO callisto.proceedings (value, job_id) VALUES ('Deposition - Jane Smith Witness', 899999996);"
```
Click Refresh → toast **"1 new proceeding(s) found"**, new row appears (2 total).

### Scenario 2 — "3 new proceeding(s) found"

```powershell
docker exec callisto-postgres psql -U postgres -d callisto -c "INSERT INTO callisto.proceedings (value, job_id) VALUES ('Deposition - Robert Brown Witness', 899999996), ('Hearing - Acme Contract Dispute', 899999996), ('Deposition - Maria Garcia Witness', 899999996);"
```
Click Refresh → toast **"3 new proceeding(s) found"** (counts only the 3 new ones via ID-diff, not the 2 already shown), 3 rows appear (5 total).

### Scenario 3 — error path: "Couldn't refresh, try again"

Revoke read so the fetch 403s:

```powershell
docker exec callisto-postgres psql -U postgres -d callisto -c "UPDATE callisto.permissions p SET effect = 'DENY' FROM callisto.resource_keys rk WHERE rk.id = p.resource_keys_id AND rk.key = 'AJSF_PROCEEDINGS';"
```
Click Refresh → toast **"Couldn't refresh, try again"**, and the existing list **stays intact** (the error-swallow fix — no blanking). This is the key behavior to show.

### Scenario 4 — recovery: "Proceedings up to date"

Restore read:

```powershell
docker exec callisto-postgres psql -U postgres -d callisto -c "UPDATE callisto.permissions p SET effect = 'ALLOW' FROM callisto.resource_keys rk WHERE rk.id = p.resource_keys_id AND rk.key = 'AJSF_PROCEEDINGS';"
```
Click Refresh → toast **"Proceedings up to date"** (no new rows since last sync).

---

## 7. Cleanup (leave the env demo-ready)

```powershell
# reset proceedings back to the single baseline
docker exec callisto-postgres psql -U postgres -d callisto -c "DELETE FROM callisto.proceedings WHERE job_id = 899999996 AND value <> 'Deposition - Refresh Test Witness';"
# ensure AJSF_PROCEEDINGS is ALLOW (must NOT be left DENY)
docker exec callisto-postgres psql -U postgres -d callisto -c "UPDATE callisto.permissions p SET effect = 'ALLOW' FROM callisto.resource_keys rk WHERE rk.id = p.resource_keys_id AND rk.key = 'AJSF_PROCEEDINGS';"
```

---

## 8. Tables touched (DBeaver / psql — Callisto schema)

| Table | Operation | Why |
|-------|-----------|-----|
| `callisto.resources` | INSERT (one-time, id `999999997`) | your user must exist for job assignment |
| `callisto.jobs` / `callisto.jobs_tasks` (+ via `SQLScript.mdc`) | INSERT (one-time) | creates test job `899999996` assigned to your resource |
| `callisto.video_transcodes` | INSERT (one-time, 6 rows incl. empty `NONE`) | unblocks AJSF form creation |
| `callisto.permissions` (key `AJSF_PROCEEDINGS`) | UPDATE `effect` ALLOW↔DENY | grant read (setup) / simulate the 403 error path (Scenario 3) |
| `callisto.proceedings` | INSERT / DELETE | drive each "N new" scenario and reset the baseline |
| `callisto.job_submission_forms` | auto-created by backend on form open | references `video_transcodes` (id 1 = empty `NONE`) |

---

## 9. Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Login: "An error was encountered with the requested page" | Cognito pool mismatch | set the **DEV** pool values in both env files (§2), restart services |
| Opening AJSF → 500 `VideoTranscode "" reference value not found` | empty `video_transcodes` | run §3b |
| `/job-detail/NaN/proceedings` calls / `jobId` null | form creation failed (above) | fix §3b, reopen form |
| Refresh → 403 / always "Couldn't refresh" | `AJSF_PROCEEDINGS` all DENY | run §3c (ALLOW) |
| `npm run dev:watch` fails: `rm` not recognized | Unix `rm -rf dist` on Windows | `Remove-Item -Recurse -Force dist` then `npx nest start --watch` (§1) |
| Atlas console floods with `/triton` `/europa` ECONNREFUSED | those backends aren't running | harmless — not needed for this demo |
| Callisto boot: `"SQS_..._URL" must be a valid uri` | placeholder `"sqs-url"` in `.env` | use valid dummy URIs (§2) |

---

See also: [`full-stack-local-setup.md`](./full-stack-local-setup.md) (full stack), [`dev-testing-prerequisites.md`](./dev-testing-prerequisites.md) (pre-flight), [`SQLScript.mdc`](./SQLScript.mdc) (test job data), and `docs/atlas/PRDV-15619-changelog.md` (validation history).
