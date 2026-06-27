# Atlas Full-Stack Local Setup

Full runbook for running Atlas front-end + Callisto + Triton locally on Windows. First time? Start at **Step 0**. Returning session? Start at **Start here**.

---

## Start here (returning session)

Pre-flight: run through [`dev-testing-prerequisites.md`](./dev-testing-prerequisites.md) first (Docker, DBeaver, AWS creds, GitHub PAT).

```powershell
# Terminal 1 — Callisto
docker start callisto-postgres
docker start callisto-rabbitmq
cd C:\Users\dustin.thomason\callisto-back-end
$env:NODE_ENV = "local"
npm run dev:watch:pretty
# verify: curl http://localhost:3003/callisto/health

# Terminal 2 — Triton
cd C:\Users\dustin.thomason\triton-back-end
$env:NODE_ENV = "local"
npx nest start --watch
# verify: curl http://localhost:3001/triton/health

# Terminal 3 — Atlas
cd C:\Users\dustin.thomason\atlas-front-end
npm run dev:local
# opens http://localhost:9000
```

Start backends before the front-end or the Vite console will flood with ECONNREFUSED noise.

---

## For AI agents: pre-flight questions

Before spinning up services, confirm:

1. What needs to run? (All three — Atlas + Callisto + Triton? Just one backend?)
2. First-time setup or returning session?
3. For each repo, run `git branch --show-current`. Stay on the feature branch for active UI work; use `main` for backends.
4. After any pull or branch switch, run `npm ci` before starting.

---

## Architecture overview

```
Browser (:9000)
    │
    ▼
Atlas front-end (Quasar/Vite dev server)
    │ proxy /callisto/*  →  Callisto API (:3003)
    │ proxy /triton/*    →  Triton API   (:3001)
    │ proxy /europa/*    →  Europa API   (remote sb)
    │
    ▼
callisto-postgres Docker container (:5432)
    ├─ database: callisto  (schema: callisto)
    └─ database: triton    (no custom schema)

callisto-rabbitmq Docker container (:5672, mgmt :15672)
    ├─ vhost: nova      (exchanges: nova.events, nova.events.dlx)
    └─ vhost: callisto  (exchanges: callisto.events, callisto.events.dlx)
```

## Prerequisites

- **Node.js** 22+ (24 recommended)
- **Docker Desktop** running
- **GitHub PAT** with `read:packages`, SSO-authorized for PlanetDepos org
- **AWS credentials** from [Planet Portal](https://planetportal.awsapps.com/start/#/?tab=accounts) (session tokens expire — refresh often)
- **DBeaver** (or any Postgres client) for browsing the local databases
- **Git Bash** or PowerShell — commands below are PowerShell unless noted

## Port map (critical — must align)

| Service | Port | Source of truth |
|---|---|---|
| Atlas front-end (Quasar dev) | `9000` | Quasar default |
| Callisto back-end | `3003` | `quasar.config.ts` default fallback |
| Triton back-end | `3001` | `quasar.config.ts` default fallback |
| Europa back-end | remote | `.env.local` → `https://atlas-sb.planetdepos.com` |
| PostgreSQL | `5432` | Docker `callisto-postgres` |
| RabbitMQ AMQP | `5672` | Docker `callisto-rabbitmq` |
| RabbitMQ Management UI | `15672` | Docker `callisto-rabbitmq` |

**The quasar.config.ts proxy defaults are `3003` (Callisto), `3001` (Triton), `3000` (Europa).** If your backend `.env.local` has a different `APP_PORT`, either change the env to match or override in `atlas-front-end/.env.local` with `CALLISTO_API_URL=http://localhost:<port>`. The early ECONNREFUSED errors were caused by this mismatch.

### Port alignment checklist (do this before first run)

This bit us hard — one of the backend env files had `APP_PORT=3005` while `quasar.config.ts` was sending proxy traffic to `3003`. The front-end showed a wall of ECONNREFUSED errors and nothing worked until the ports matched. **Every time you set up or copy env files, verify these three values agree:**

1. Open `atlas-front-end/quasar.config.ts` — note the fallback ports on lines 11-13:

```
CALLISTO_API_URL → 'http://localhost:3003'
TRITON_API_URL   → 'http://localhost:3001'
EUROPA_API_URL   → 'http://localhost:3000'
```

2. Open `atlas-front-end/.env.local` — if `CALLISTO_API_URL` or `TRITON_API_URL` are **commented out**, the quasar defaults above apply. If they're set, whatever port is in the URL wins.

3. Open each backend's `.env.local` (or `.env`) — check `APP_PORT`:
   - **Callisto**: `APP_PORT` must match what quasar expects. Safest: **don't set `APP_PORT` at all** — Callisto defaults to `3003`.
   - **Triton**: `APP_PORT` must be `3001`. Safest: copy from `.env.sample` which already has `APP_PORT=3001`.

If any of these disagree, pick one source of truth and update the others. The easiest fix is to leave the backend `APP_PORT` values unset or matching the quasar defaults, and leave the front-end URL overrides commented out.

## Step 0: Docker containers (one-time)

Both backends share one Postgres container. RabbitMQ is needed when `OUTBOX_ENABLED=true` in Callisto.

```powershell
# PostgreSQL
docker run -d --name callisto-postgres `
  -e POSTGRES_USER=postgres `
  -e POSTGRES_PASSWORD=postgres `
  -e POSTGRES_DB=callisto `
  -p 5432:5432 postgres:16

# Create schemas and databases
docker exec callisto-postgres psql -U postgres -d callisto -c "CREATE SCHEMA IF NOT EXISTS callisto;"
docker exec callisto-postgres psql -U postgres -c "CREATE DATABASE triton;"
docker exec callisto-postgres psql -U postgres -d triton -c "CREATE SCHEMA IF NOT EXISTS triton;"

# Required Postgres extensions for the callisto DB (notifications migrations call uuid_generate_v4()).
# Install into the public schema so the default search_path ("$user", public) resolves the unqualified call.
docker exec callisto-postgres psql -U postgres -d callisto -c "CREATE SCHEMA IF NOT EXISTS public;"
docker exec callisto-postgres psql -U postgres -d callisto -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\" WITH SCHEMA public;"
docker exec callisto-postgres psql -U postgres -d callisto -c "CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;"

# RabbitMQ
docker run -d --name callisto-rabbitmq `
  -p 5672:5672 -p 15672:15672 rabbitmq:3-management
```

After creating the RabbitMQ container, bootstrap the vhosts and exchanges Callisto expects:

```powershell
cd C:\Users\dustin.thomason\callisto-back-end
npm run setup:local-rabbitmq
```

Or manually:

```powershell
docker exec callisto-rabbitmq rabbitmqctl add_vhost nova
docker exec callisto-rabbitmq rabbitmqctl add_vhost callisto
docker exec callisto-rabbitmq rabbitmqctl set_permissions -p nova guest ".*" ".*" ".*"
docker exec callisto-rabbitmq rabbitmqctl set_permissions -p callisto guest ".*" ".*" ".*"
```

Plus declare topic exchanges via the management API (port 15672) for `nova.events`, `nova.events.dlx`, `callisto.events`, `callisto.events.dlx`.

## Step 1: Pull code and install dependencies

The backends (Callisto, Triton) should generally run on **`main`** — you're consuming their APIs, not developing on them. The front-end (Atlas) may be on a **feature branch** if you're actively developing UI work.

**Rule of thumb:** only pull `main` for repos where you're not doing active feature work. If you're on a feature branch, stay on it.

```powershell
# Callisto — pull main (unless you're actively developing here)
cd C:\Users\dustin.thomason\callisto-back-end
git checkout main
git pull origin main
npm ci

# Triton — pull main (unless you're actively developing here)
cd C:\Users\dustin.thomason\triton-back-end
git checkout main
git pull origin main
npm ci

# Atlas front-end — stay on your current branch if doing feature work
cd C:\Users\dustin.thomason\atlas-front-end
# git checkout main          # only if you want latest main
# git pull origin main       # only if you want latest main
npm ci                        # always run after any pull or branch switch
```

**Important:** Run `npm ci` after every `git pull` or branch switch. Skipping it can cause phantom module-not-found errors when `package-lock.json` has changed.

**For AI agents:** Before checking out `main`, verify the user isn't on a feature branch they intend to keep. Run `git branch --show-current` first and confirm with the user before switching.

## Step 2: Start Docker each session

```powershell
docker start callisto-postgres
docker start callisto-rabbitmq
```

Verify:

```powershell
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

Expected: both containers **Up**, Postgres on `:5432`, RabbitMQ on `:5672` + `:15672`.

## Step 2: AWS credentials (required before starting backends)

Both Callisto and Triton need AWS credentials to interact with S3, SQS, and Cognito. These are **temporary session tokens** that expire every 1-4 hours — you'll need to refresh them at the start of every session and again if they expire mid-work.

### How to get credentials

1. Open the **AWS Start Portal** for PlanetDepos: [https://planetportal.awsapps.com/start/#/?tab=accounts](https://planetportal.awsapps.com/start/#/?tab=accounts)
2. Find the **Neptune SB** environment (sandbox).
3. Click on **Administrator** (or whichever role you have access to).
4. Click **Access keys**.
5. You'll see three values: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_SESSION_TOKEN`.

### Set credentials in Git Bash (before starting services)

Open a **Git Bash** terminal and paste the credentials. This must be done **before** you start Callisto or Triton in that terminal session:

```bash
export AWS_ACCESS_KEY_ID="ASIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."
```

The portal gives you a ready-to-paste block in this exact format — just copy and paste the whole thing.

### Alternative: set credentials in env files

Instead of exporting in the shell, you can add the credentials directly to each backend's env file:

- **Callisto**: add to `callisto-back-end/.env.local`
- **Triton**: add to `triton-back-end/.env`

```
aws_access_key_id=ASIA...
aws_secret_access_key=...
aws_session_token=...
```

**Downside:** you have to update the env files every time the tokens expire. The Git Bash export approach is faster for short sessions.

### If credentials expire mid-session

You'll see errors like `Token expired at ...` in Triton logs, or S3/SQS operation failures in Callisto. Refresh from the portal, re-export or update env files, and restart the affected backend.

## Step 3: Callisto back-end

### Env files

Callisto loads `.env` for CLI tools (TypeORM migrations) and `.env.local` for the running app (when `NODE_ENV=local`). Both need aligned DB values.

Key values in `.env.local`:

| Variable | Value |
|---|---|
| `APP_PORT` | **Not set** (defaults to `3003` — matches quasar proxy) |
| `DB_NAME` | `callisto` |
| `DB_PORT` | `5432` |
| `DB_USERNAME` / `DB_PASSWORD` | `postgres` / `postgres` |
| `READ_DB_HOST` / `WRITE_DB_HOST` | `localhost` |
| `MQ_BROKER_URL` | `amqp://localhost:5672` |
| `MQ_USERNAME` / `MQ_PASSWORD` | `guest` / `guest` |
| `OUTBOX_ENABLED` | `true` (requires RabbitMQ vhosts set up above) |

If you set `APP_PORT=3005` (or any non-3003 value), you **must** also add `CALLISTO_API_URL=http://localhost:3005` to `atlas-front-end/.env.local`, or the Quasar proxy will send traffic to `:3003` and you'll get ECONNREFUSED.

### Start

```powershell
cd C:\Users\dustin.thomason\callisto-back-end
$env:NODE_ENV = "local"
npm run dev:watch:pretty
```

Verify:

```powershell
curl.exe http://localhost:3003/callisto/health
# Expected: {"status":"ok",...}
```

### Migrations (Windows-safe)

The `npm run migration:run` script can fail on Windows because TypeORM doesn't resolve `src/*` path aliases. Use:

```powershell
npx ts-node -r dotenv/config -r tsconfig-paths/register ./node_modules/typeorm/cli.js migration:run -d ./src/typeorm/data-source.ts
```

Migrations also run automatically on API startup.

### Seed test data (optional)

```powershell
npm run migration:seed
```

Seeds assume a **fresh** database. On an already-seeded DB, duplicate key errors are expected.

## Step 4: Triton back-end

### Env files

Triton shares the same Postgres container. Key values in `.env`:

| Variable | Value |
|---|---|
| `APP_PORT` | `3001` (matches quasar proxy default) |
| `DB_NAME` | `triton` |
| `DB_PORT` | `5432` |
| `DB_USERNAME` / `DB_PASSWORD` | `postgres` / `postgres` |
| `READ_DB_HOST` / `WRITE_DB_HOST` | `localhost` |
| `AWS_REGION` | `us-east-1` |

Triton **requires AWS credentials** for S3/SQS. Make sure you've completed **Step 2** (AWS credentials) before starting Triton — either export them in your Git Bash session or add them to the `.env` file.

### Start

```powershell
cd C:\Users\dustin.thomason\triton-back-end
$env:NODE_ENV = "local"
npx nest start --watch
```

Or in Git Bash:

```bash
cd ~/triton-back-end
npm run dev
```

Verify:

```powershell
curl.exe http://localhost:3001/triton/health
```

## Step 5: Atlas front-end

### Env files

The front-end uses `.env` (base) and `.env.local` (overrides, loaded when `ENV_NAME=local`).

Key values in `.env.local`:

| Variable | Value | Notes |
|---|---|---|
| `ENV_NAME` | `local` | Required |
| `CALLISTO_API_URL` | omit (defaults to `http://localhost:3003`) | Only set if Callisto runs on a non-default port |
| `TRITON_API_URL` | omit (defaults to `http://localhost:3001`) | Only set if Triton runs on a non-default port |
| `EUROPA_API_URL` | `https://atlas-sb.planetdepos.com` | Points to remote sandbox (not run locally) |
| AWS Cognito vars | sandbox values | See `.env.sample` |

### Start

```powershell
cd C:\Users\dustin.thomason\atlas-front-end
npm run dev:local
```

Opens browser at `http://localhost:9000/`.

## Startup order

1. Docker containers (`callisto-postgres`, `callisto-rabbitmq`)
2. AWS credentials (export in Git Bash or update env files)
3. Callisto back-end (port 3003)
4. Triton back-end (port 3001)
5. Atlas front-end (port 9000)

Starting the front-end before backends is harmless — you'll see ECONNREFUSED proxy errors in the Vite console that resolve once the backends come up. But it's noisy and can be confusing.

## Common issues and fixes

### ECONNREFUSED on `/callisto/*` or `/triton/*` proxy

**Cause:** Backend isn't running, or port mismatch between `quasar.config.ts` defaults and actual `APP_PORT`.

**Fix:** Either don't set `APP_PORT` in backend `.env.local` (use defaults: Callisto=3003, Triton=3001), or add `CALLISTO_API_URL` / `TRITON_API_URL` to `atlas-front-end/.env.local`.

### RabbitMQ "Connection Failed: broker (nova/callisto)"

**Cause:** The `callisto-rabbitmq` Docker container only has the default `/` vhost. Callisto needs `nova` and `callisto` vhosts with exchanges.

**Fix:**

```powershell
cd C:\Users\dustin.thomason\callisto-back-end
npm run setup:local-rabbitmq
```

Then restart the Callisto API. Alternatively, set `OUTBOX_ENABLED=false` in `.env.local` to skip RabbitMQ entirely (fine for UI-only work).

### `Cannot find module 'src/shared/...'` when running seeds or migrations

**Cause:** The npm scripts didn't include `-r tsconfig-paths/register`, so `src/*` path aliases don't resolve on Windows.

**Fix:** The `migration:seed` script was updated to include `tsconfig-paths/register`. For migrations, use the Windows-safe command in the Migrations section above.

### Seed files fail with FK constraint violations

**Cause:** Seed data drift — SQL column names or FK references don't match current schema.

**Fix:** Fixed in this session (May 2026):
- `3_seed`: Added missing jobs `112233`-`112236` that proceedings reference
- `9_seed`: Renamed `accounts_id`→`account_id`, `persons_id`→`person_id`, `contact_types_id`→`contact_type_id`, `sales_rep_resources_id`→`sales_rep_resource_id`

### Callisto crashes on startup: `function uuid_generate_v4() does not exist`

**Cause:** The `notifications` table migrations (which run automatically on API startup) call `uuid_generate_v4()`, provided by the `uuid-ossp` extension. A fresh local Postgres doesn't have it.

**Fix:** Install the extension into the `public` schema (so the default `search_path` `"$user", public` resolves the unqualified call):

```powershell
docker exec callisto-postgres psql -U postgres -d callisto -c "CREATE SCHEMA IF NOT EXISTS public;"
docker exec callisto-postgres psql -U postgres -d callisto -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\" WITH SCHEMA public;"
docker exec callisto-postgres psql -U postgres -d callisto -c "CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;"
```

If you hit `ERROR: no schema has been selected to create in`, it's because the `postgres` role's `search_path` had no valid schema — creating `public` first (as above) resolves it.

### `npm ci` in callisto-back-end fails with `401 Unauthorized` from `npm.pkg.github.com`

**Cause:** `.npmrc` resolves the registry auth token from `_authToken=${GITHUB_TOKEN}`. If `GITHUB_TOKEN` is unset in the shell, npm sends an empty token and GitHub Packages rejects `@planetdepos/*` installs with `401`. A token that is **expired** or **not SSO-authorized for the PlanetDepos org** fails the same way.

**Fix:** Export a valid, non-expired, SSO-authorized PAT (`read:packages`) in the **same shell** before installing:

```powershell
$env:GITHUB_TOKEN = "<your-pat>"   # PowerShell
npm ci
```

```bash
export GITHUB_TOKEN=<your-pat>      # Git Bash
npm ci
```

Note: `.env.local` may hold only a placeholder (`GITHUB_TOKEN=X`) — that does not populate the shell env that `npm`/`.npmrc` reads.

### Token expired errors in Triton logs

**Cause:** AWS session tokens from Planet Portal expire (typically 1-4 hours).

**Fix:** Refresh credentials from [Planet Portal](https://planetportal.awsapps.com/start/#/?tab=accounts), update `.env` / `.env.local`, and restart the backend.

## DBeaver setup

DBeaver connects to the same `callisto-postgres` Docker container for both databases. The setup is not intuitive — pay attention to the manual database name entry and the schema visibility steps.

### Create a Callisto connection

1. **Add Connection** → select **PostgreSQL** from the driver list.
2. Fill in the connection fields. The **Database** field defaults to `postgres` — you must **manually type** `callisto`:

| Field | Value | Notes |
|---|---|---|
| Host | `localhost` | |
| Port | `5432` | |
| Database | `callisto` | Manually type this — not in the dropdown |
| Username | `postgres` | |
| Password | `postgres` | All lowercase, no spaces |

3. **Configure schema visibility** — this is the weird part. After connecting, go to the **Database Navigator**, expand the connection, right-click **Schemas** and open schema settings. You'll see both `callisto` and `public` schemas. **Delete `public`** and keep only `callisto`. Callisto stores all its tables under the `callisto` schema, not `public`. If you leave `public` visible, it'll look empty and confuse you.

4. **Set search_path** in SQL Editor sessions. When you open **SQL Editor → New SQL Script**, run this at the top so unqualified table names resolve:

```sql
SET search_path TO callisto, public;
```

Without this, queries like `SELECT * FROM cases` fail with "relation does not exist."

**Tip:** In connection settings → **PostgreSQL** tab, set **Default schema** to `callisto` to avoid running `SET search_path` every session.

### Create a Triton connection

1. **Add Connection** → select **PostgreSQL**.
2. Fill in the connection fields. Again, **manually type** `triton` in the Database field:

| Field | Value | Notes |
|---|---|---|
| Host | `localhost` | |
| Port | `5432` | |
| Database | `triton` | Manually type this — not in the dropdown |
| Username | `postgres` | |
| Password | `postgres` | All lowercase, no spaces |

3. **Configure schema visibility** — opposite of Callisto. Triton uses the `public` schema. If you see a `triton` schema listed, **delete it** and keep only `public`.

### Insert yourself into the resources table

Callisto's `resources` table (under `callisto` schema) must contain a row for your user before job tasks and assignments work. The script that creates test jobs (`SQLScript.mdc` — see below) references a `resource_id`, and your resource row must exist with that ID.

Open a SQL Editor on the **Callisto** connection and insert your resource:

```sql
SET search_path TO callisto, public;

INSERT INTO resources (id, email, person_id, full_name, first_name, middle_name, last_name, resource_type_id)
VALUES (
  999999997,                              -- match the ID used in test job scripts
  'your.name@planetdepos.com',            -- your actual email
  999999997,                              -- can match the resource ID
  'Your Full Name',
  'YourFirst',
  '',                                     -- middle name (can be empty string)
  'YourLast',
  1                                       -- resource type ID (check resource_types table if unsure)
)
ON CONFLICT (id) DO NOTHING;
```

### Run the test data script

After inserting your resource, run the test job/task script to create sample data that references your user:

1. In DBeaver, open a **New SQL Script** on the Callisto connection.
2. Paste the contents of [`SQLScript.mdc`](./SQLScript.mdc) (located in `dustin-thomason/docs/atlas/local/`).
3. Execute. This creates a test job with four job tasks assigned to the resource ID `999999997`.

### Useful Callisto queries

```sql
SET search_path TO callisto, public;

-- Confirm migration state
SELECT * FROM migrations ORDER BY id DESC LIMIT 5;

-- Row counts after seeding
SELECT
  (SELECT COUNT(*) FROM cases) AS cases,
  (SELECT COUNT(*) FROM jobs) AS jobs,
  (SELECT COUNT(*) FROM files) AS files;

-- Verify your resource exists
SELECT * FROM resources WHERE id = 999999997;
```

## Verifying your data in the browser

### My Jobs (Callisto)

After inserting your resource and running the test job script, view your jobs in the browser at:

```
http://localhost:9000/callisto-stuff/my-jobs
```

Note the path is `/callisto-stuff/my-jobs`, **not** `/callisto/my-jobs`. The "My Jobs" feature may not be fully wired up yet — this URL is the current way to see jobs assigned to your resource.

### Drive folders (Triton)

Folders you create through the Atlas UI (file uploads, drag-and-drop) show up in the Triton database under the `public.folders` table. To verify in DBeaver, use the **Triton** connection:

```sql
SELECT * FROM public.folders ORDER BY created_at DESC;
```

## Triton drive permissions (H drive access)

The Atlas UI shows five legacy drives: **R** (Audio), **V** (Video), **T** (Transcript), **K** (Case), and **H** (Highly Confidential). Access to each drive is controlled by the Triton `permissions` table. By default, most roles have the H drive set to DENY.

### How it works

Three tables in the Triton database control drive access:

| Table | What it holds |
|---|---|
| `roles` | Role names (e.g. `Neptune_IT`) — each has a numeric `id` |
| `resource_keys` | Drive identifiers — `H_DRIVE` is id `5` |
| `permissions` | Links a `roles_id` + `resource_keys_id` + `action` → `ALLOW` or `DENY` |

Your Cognito user has one or more role names in its `custom:roles` claim. When you log in, Triton reads those role names, looks them up in the `roles` table, then checks the `permissions` table to determine what you can do on each drive.

### Find your role

Open a SQL Editor on the **Triton** connection in DBeaver and run:

```sql
SELECT id, type FROM roles ORDER BY id;
```

This shows all roles and their IDs. Find the role that matches what's in your Cognito token (check with your team or look at the Triton server logs on login — it prints `authorized roles:`).

### Grant H drive access for a specific role

Once you know your role's `id`, run this to grant full H drive access for that role:

```sql
UPDATE permissions
SET effect = 'ALLOW'
WHERE roles_id = <your role id>
AND resource_keys_id = 5;
```

Replace `<your role id>` with the number from the first query. For example, if your role is `Neptune_IT` (id 19):

```sql
UPDATE permissions
SET effect = 'ALLOW'
WHERE roles_id = 19
AND resource_keys_id = 5;
```

### Grant H drive access for ALL roles (blanket permission)

If you don't know or care which role you have and just want H drive to work for everyone locally:

```sql
UPDATE permissions
SET effect = 'ALLOW'
WHERE resource_keys_id = 5;
```

This flips every role's H drive permission from DENY to ALLOW. Fine for local dev — doesn't affect anything outside your machine.

### Verify the change

After running either UPDATE, confirm it worked:

```sql
SELECT r.type, p.action, p.effect
FROM permissions p
JOIN roles r ON r.id = p.roles_id
WHERE p.resource_keys_id = 5
AND p.effect = 'ALLOW';
```

Then refresh Atlas in your browser. The "Highly Confidential (H)" drive should now appear and be accessible in the Legacy Drives section.

### Reference: resource_keys IDs

| id | key | Drive letter |
|---|---|---|
| 1 | K_DRIVE | K (Case) |
| 2 | V_DRIVE | V (Video) |
| 3 | R_DRIVE | R (Audio) |
| 4 | T_DRIVE | T (Transcript) |
| 5 | H_DRIVE | H (Highly Confidential) |

You can use this same pattern to grant or revoke access to any drive by changing `resource_keys_id` in the queries above.

## Callisto resource-key permissions (spoofing roles for auth testing)

Callisto authorizes API actions the same data-driven way Triton does, but against the **`callisto`** schema's `permissions`/`roles`/`resource_keys` tables. This is how you reproduce role-specific scenarios locally (e.g. "Facilities can rename client deliverables but not submission files") without a real Cognito account for that role.

### How it resolves

On **every request**, Callisto reads the role names from the id-token `custom:roles` claim, looks them up in `roles`, and selects the `permissions` rows with `effect='ALLOW'` joined to `resource_keys`. Two consequences:

- Your **role** is fixed by the token (can't change without a different login), but the **permissions a role maps to are DB-editable** and re-read each request — edit the table and the next request picks it up, no re-login.
- Actions are stored lowercase (`update`, `create`, `read`, `delete`); effects uppercase (`ALLOW`/`DENY`). Token verification uses Cognito public keys, not AWS creds.

### Find your role and the relevant resource keys

```sql
SET search_path TO callisto, public;

-- your logged-in role appears in the Callisto server log on login (`authorized roles:`)
SELECT id, type FROM roles ORDER BY id;

-- resource keys for the client-deliverable vs submission file lanes
SELECT id, key FROM resource_keys
WHERE key LIKE '%PROCEEDING_FILES_TRANSCRIPT' ORDER BY key;
```

### Spoof a specific role's permission

```sql
-- grant: deliverable transcript update
UPDATE permissions SET effect = 'ALLOW'
WHERE roles_id = <your role id>
  AND resource_keys_id = (SELECT id FROM resource_keys WHERE key = 'CLIENT_DELIVERABLE_PROCEEDING_FILES_TRANSCRIPT')
  AND action = 'update';

-- deny: submission transcript update
UPDATE permissions SET effect = 'DENY'
WHERE roles_id = <your role id>
  AND resource_keys_id = (SELECT id FROM resource_keys WHERE key = 'SUBMISSION_PROCEEDING_FILES_TRANSCRIPT')
  AND action = 'update';
```

### Blanket spoof (copy a known role's full profile onto everyone)

When you don't want to track which role your Cognito user maps to, copy a reference role's entire permission set onto all roles. Example: reproduce the `Neptune_Facilities` (role id 14) profile so any login behaves like Facilities. **Always back up first** — this is reversible:

```sql
-- backup
DROP TABLE IF EXISTS callisto.permissions_backup;
CREATE TABLE callisto.permissions_backup AS SELECT * FROM callisto.permissions;

-- copy role 14's permissions onto every other role
DELETE FROM callisto.permissions WHERE roles_id <> 14;
INSERT INTO callisto.permissions (roles_id, resource_keys_id, action, effect, created_at, updated_at)
SELECT r.id, p.resource_keys_id, p.action, p.effect, now(), now()
FROM callisto.roles r
CROSS JOIN callisto.permissions p
WHERE p.roles_id = 14 AND r.id <> 14;

-- restore when finished
TRUNCATE callisto.permissions;
INSERT INTO callisto.permissions SELECT * FROM callisto.permissions_backup;
DROP TABLE callisto.permissions_backup;
```

### Verify the spoof

```sql
SELECT r.type AS role, rk.key AS resource_key, p.action, p.effect
FROM callisto.permissions p
JOIN callisto.roles r          ON r.id  = p.roles_id
JOIN callisto.resource_keys rk ON rk.id = p.resource_keys_id
WHERE r.type = '<your role>'
  AND rk.key IN ('CLIENT_DELIVERABLE_PROCEEDING_FILES_TRANSCRIPT', 'SUBMISSION_PROCEEDING_FILES_TRANSCRIPT')
  AND p.action = 'update'
ORDER BY rk.key;
```

> A fuller worked example (with browser-console evidence capture and the matching success/403 calls) lives in the PRDV-15776 changelog's **Manual Reproduction Steps** (`docs/atlas/PRDV-15776-changelog.md`).

## Quick-reference: the working commands

```powershell
# ── 0. Pull latest (backends on main, front-end on your branch) ──
cd C:\Users\dustin.thomason\callisto-back-end
git checkout main && git pull origin main && npm ci

cd C:\Users\dustin.thomason\triton-back-end
git checkout main && git pull origin main && npm ci

cd C:\Users\dustin.thomason\atlas-front-end
# Only pull if you want latest main — skip if on a feature branch
npm ci

# ── 1. Docker ──
docker start callisto-postgres
docker start callisto-rabbitmq

# ── 2. Callisto (Terminal 1) ──
cd C:\Users\dustin.thomason\callisto-back-end
$env:NODE_ENV = "local"
npm run dev:watch:pretty

# ── 3. Triton (Terminal 2 — PowerShell) ──
cd C:\Users\dustin.thomason\triton-back-end
$env:NODE_ENV = "local"
npx nest start --watch

# ── 3 alt. Triton (Git Bash — set AWS creds first) ──
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."
npm run dev

# ── 4. Atlas front-end (Terminal 3) ──
cd C:\Users\dustin.thomason\atlas-front-end
npm run dev:local
```

## Related documentation

Setup docs only tell you how to get the system running. For understanding **how the system actually works**, refer to these (documentation is spread across repo wikis, READMEs, and local runbooks — this section tries to collect the entry points in one place):

### GitHub Wikis

| Wiki | Key pages | URL pattern |
|---|---|---|
| Callisto back-end | Pending Jobs, domain model, job lifecycle | `https://github.com/planetdepos/callisto-back-end/wiki/*` |
| Triton back-end | Historical files, drive structure | `https://github.com/planetdepos/triton-back-end/wiki/*` |
| Atlas front-end | UI patterns, feature flags | `https://github.com/planetdepos/atlas-front-end/wiki/*` |
| Europa back-end | Audit/reporting | `https://github.com/planetdepos/europa-back-end/wiki/*` |

Specific pages referenced in this guide:

- [Pending Jobs](https://github.com/planetdepos/callisto-back-end/wiki/Pending-Jobs) — explains how the pending jobs system works, job status transitions, and how jobs flow through the system

### Repo READMEs

- `callisto-back-end/README.md` — migration commands, module structure, env variable reference
- `triton-back-end/README.md` — drive keys, S3 bucket mapping, file upload flow
- `atlas-front-end/README.md` — Quasar/Vite setup, dev scripts

### Local runbooks (this folder)

- [`dev-testing-prerequisites.md`](./dev-testing-prerequisites.md) — pre-flight checklist + AI-agent execution / manual-reproduction requirements (run this gate first)
- [`refresh-proceedings-demo.md`](./refresh-proceedings-demo.md) — end-to-end demo runbook for the PRDV-15619 "Refresh proceedings" button (Callisto + Atlas only, with the exact DB seeds and demo steps)
- [`callisto-local.mdc`](./callisto-local.mdc) — detailed Callisto-only setup and troubleshooting
- [`triton-local.mdc`](./triton-local.mdc) — Triton-only setup (reuses Callisto Postgres container)
- [`europa-local.mdc`](./europa-local.mdc) — Europa local setup
- [`SQLScript.mdc`](./SQLScript.mdc) — test job/task data script for DBeaver
