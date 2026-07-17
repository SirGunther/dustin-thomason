# Callisto + Atlas Local — Quickstart (drop-in, one shot)

**Purpose:** copy one block, run it in **Git Bash**, and both Callisto (API) and Atlas (UI) come up. No port-chasing. Every command verified on 2026-07-16 (exceptions called out inline).

Pairs with [callisto-local-teardown.md](./callisto-local-teardown.md) — **Part N here rebuilds what Part N there tore down.**

> **The port truth (read once):** `src/main.ts` binds `process.env.APP_PORT || 3001`, populated from **`.env`** (not `.env.local`). Repo default is `3004` (`.env.sample`). If `.env` and `.env.local` disagree, `.env` wins. The blocks below write the port into `.env`, `.env.local`, **and** Atlas so they can never drift.

---

## Part 1 — Full setup (from nothing: fresh pull, new branch, or after a Part 1 teardown)

Brings up **both** repos from scratch. Set the two values at the top, then run the whole block in Git Bash.

THIS STEP IS TO BE DONE SEPERATELY
export GITHUB_TOKEN=<your-PAT>     # must be SSO-authorized for the planetdepos org (both repos need it)


```bash
# ============================================================
#  Callisto + Atlas — FULL setup (Git Bash)
# ============================================================
PORT=3004                          # the ONE port knob — everything follows it

CALLISTO=/c/Users/dustin.thomason/callisto-back-end
ATLAS=/c/Users/dustin.thomason/atlas-front-end

# ---------- CALLISTO ----------
cd "$CALLISTO"
npm ci                              # needs GITHUB_TOKEN in this shell

# infra: start if present, else create (this is the fix for "no such container")
docker start callisto-postgres 2>/dev/null || docker run -d --name callisto-postgres \
  -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=callisto -p 5432:5432 postgres:16
docker start callisto-rabbitmq 2>/dev/null || docker run -d --name callisto-rabbitmq \
  -p 5672:5672 -p 15672:15672 rabbitmq:3-management
#   RabbitMQ vhosts (only when the broker starts cleanly — see troubleshooting if it crash-loops):
for i in $(seq 1 20); do docker exec callisto-rabbitmq rabbitmqctl await_startup >/dev/null 2>&1 && break; sleep 3; done
for vh in nova callisto; do
  docker exec callisto-rabbitmq rabbitmqctl add_vhost "$vh" 2>/dev/null
  docker exec callisto-rabbitmq rabbitmqctl set_permissions -p "$vh" guest ".*" ".*" ".*" 2>/dev/null
done
#   Broker topology Callisto EXPECTS to pre-exist (code uses createExchangeIfNotExists /
#   createQueueIfNotExists = false, i.e. passive checks only). Without these the app connects,
#   gets channel `not_found` errors, silently retries forever, and NEVER binds APP_PORT —
#   the log just stops after the "Registered handler ..." lines. rabbitmqadmin ships in the
#   management image, so no extra install:
for vh in nova callisto; do
  docker exec callisto-rabbitmq rabbitmqadmin -u guest -p guest -V "$vh" declare exchange name="$vh.events" type=topic durable=true
  docker exec callisto-rabbitmq rabbitmqadmin -u guest -p guest -V "$vh" declare exchange name="$vh.events.dlx" type=topic durable=true
done
for q in callisto.proceeding.file.video-transcode-completed.v1 callisto.notification.requested.v1; do
  docker exec callisto-rabbitmq rabbitmqadmin -u guest -p guest -V nova declare queue name="$q" durable=true
  docker exec callisto-rabbitmq rabbitmqadmin -u guest -p guest -V nova declare binding source=nova.events destination="$q" routing_key="$q"
done

# pin the port in BOTH callisto env files AND Atlas (kills all drift)
for f in "$CALLISTO/.env" "$CALLISTO/.env.local"; do
  if grep -qE '^APP_PORT=' "$f"; then sed -i "s/^APP_PORT=.*/APP_PORT=$PORT/" "$f"; else echo "APP_PORT=$PORT" >> "$f"; fi
done
sed -i '/CALLISTO_API_URL/d' "$ATLAS/.env.local"
echo "CALLISTO_API_URL=http://localhost:$PORT" >> "$ATLAS/.env.local"

# reset the local DB clean  ⚠ DESTRUCTIVE (wipes local Callisto data; fixes migration/schema inconsistencies)
docker exec callisto-postgres psql -U postgres -d postgres -c "DROP DATABASE IF EXISTS callisto WITH (FORCE);"
docker exec callisto-postgres psql -U postgres -d postgres -c "CREATE DATABASE callisto;"
docker exec callisto-postgres psql -U postgres -d callisto  -c "CREATE SCHEMA IF NOT EXISTS callisto;"

# free the port (reliable on Windows Git Bash; pkill -f does NOT work here), then start (migrations auto-run)
netstat -ano | grep -E ":$PORT .*LISTENING" | awk '{print $5}' | sort -u | while read pid; do taskkill //PID $pid //F 2>/dev/null; done
sleep 1
NODE_ENV=local nohup npm run start:dev > /tmp/callisto.log 2>&1 &

# ---------- ATLAS ----------
cd "$ATLAS"
npm ci                              # also needs GITHUB_TOKEN (Atlas uses private @planetdepos packages)
nohup npm run dev:local > /tmp/atlas.log 2>&1 &

# ---------- verify both ----------
sleep 55
echo "=== Callisto health ($PORT) ==="; curl.exe -s "http://localhost:$PORT/callisto/health"; echo ""
echo "=== Atlas (9000) ==="; curl.exe -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:9000

# ---------- seed dev dataset (the data Atlas actually displays) ----------
# Migrations (auto-run on app boot) only seed REFERENCE data (roles, permissions, job types).
# Business data (cases, jobs, proceedings, contacts) comes from dev-dataset-reset/*.sql —
# see src/typeorm/dev-dataset-reset/README.md. Must run AFTER Callisto health is OK
# (migrations create the tables on first boot). Scripts are idempotent + schema-qualified.
for f in "$CALLISTO"/src/typeorm/dev-dataset-reset/*.sql; do
  docker exec -i callisto-postgres psql -U postgres -d callisto -v ON_ERROR_STOP=1 < "$f" >/dev/null
done
echo "seeded cases: $(docker exec callisto-postgres psql -U postgres -d callisto -tAc 'SELECT count(*) FROM callisto.cases')"
# optional: layer feature-specific data from src/typeorm/dev-dataset-usecases/ (see its README)
```

Expected: Callisto `{"status":"ok",...}`, Atlas `HTTP 200`, `seeded cases: 4`.

---

## Part 2 — Daily start (already set up: containers exist, deps installed)

```bash
export GITHUB_TOKEN=<your-PAT>
CALLISTO=/c/Users/dustin.thomason/callisto-back-end
ATLAS=/c/Users/dustin.thomason/atlas-front-end
PORT=$(grep -E '^APP_PORT=' "$CALLISTO/.env" | cut -d= -f2 | tr -d '[:space:]')

docker start callisto-postgres callisto-rabbitmq
cd "$CALLISTO"
netstat -ano | grep -E ":$PORT .*LISTENING" | awk '{print $5}' | sort -u | while read pid; do taskkill //PID $pid //F 2>/dev/null; done
sleep 1
NODE_ENV=local nohup npm run start:dev > /tmp/callisto.log 2>&1 &
cd "$ATLAS"
nohup npm run dev:local > /tmp/atlas.log 2>&1 &
sleep 55
echo "Callisto:"; curl.exe -s "http://localhost:$PORT/callisto/health"; echo ""
echo "Atlas:"; curl.exe -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:9000
```

## Watch logs

```bash
tail -f /tmp/callisto.log     # Callisto
tail -f /tmp/atlas.log        # Atlas
```

---

## Verify URLs (replace 3004 if you changed `PORT`)

| Check   | URL |
| ------- | --- |
| Callisto health | `http://localhost:3004/callisto/health` |
| Callisto swagger | `http://localhost:3004/callisto/swagger` |
| Atlas UI | `http://localhost:9000` |
| RabbitMQ UI | `http://localhost:15672` (guest/guest) |

## DBeaver (local Postgres)

| Field | Value |
| ----- | ----- |
| Host / Port | `localhost` / `5432` |
| Database | `callisto` |
| User / Password | `postgres` / `postgres` |
| Default schema | `callisto` (else `SET search_path TO callisto, public;`) |

---

## Troubleshooting (every failure hit building this)

| Symptom | Cause / Fix |
| ------- | ----------- |
| `no such container: callisto-postgres` | Containers were removed (Part 1 teardown). Use the `docker start … \|\| docker run …` lines in Part 1 — not bare `docker start`. |
| App on an unexpected port | Port comes from **`.env`** `APP_PORT` (not `.env.local`). Run the pin step, or `grep ^APP_PORT= .env`. |
| `401 Unauthorized` on `npm ci` | `export GITHUB_TOKEN=<PAT>` in the same Git Bash session (both repos). |
| `403 … SAML enforcement` | PAT not SSO-authorized: GitHub → Settings → Developer settings → PAT → **Configure SSO → authorize `planetdepos`**. |
| `nest` not found / `could not determine executable` | Dev deps missing — rerun `npm ci` (never `--omit=dev`). |
| `'rm' is not recognized` | You're in PowerShell/cmd. Use **Git Bash** (`start:dev` uses `rm -rf dist`). |
| `EADDRINUSE :PORT` | Old server still bound — run the port-scoped kill (`pkill -f "nest start"` does **not** work on Windows). |
| migration crash on boot (`"MP4 Video" not found`, etc.) | Inconsistent local DB. Run the Part 1 DB reset. |
| **Boot hangs silently** — log ends at `Registered handler …` / `Starting proceeding inbox poller`, `Application started` never appears, APP_PORT never binds, process stays alive | Broker topology missing. The app **passively checks** its exchanges/queues (`createExchangeIfNotExists: false`); `docker logs callisto-rabbitmq` shows `not_found: no exchange 'callisto.events'` / `no queue '…' in vhost 'nova'` and the connection manager retries forever, blocking `app.listen`. Run the **broker topology** block in Part 1 — the hung app recovers on its next retry (~60s), **no restart needed**. Verify with `docker exec callisto-rabbitmq rabbitmqctl list_connections user vhost state` → two `running` rows (`nova`, `callisto`). |
| **RabbitMQ crash-loops** `.erlang.cookie: eacces` | Docker Desktop volume-layer bug (fails even as root). Fixes, in order: **restart Docker Desktop**; if it persists, run Callisto without messaging — set `OUTBOX_ENABLED=false` in `.env.local`. The API and our file-length endpoint work fine without RabbitMQ (messaging/outbox only). |
| Atlas can't reach Callisto | `CALLISTO_API_URL` in `atlas-front-end/.env.local` must equal `http://localhost:<APP_PORT>`. Part 1 sets this automatically. |
| **DBeaver: `Navigator node '…table/xyz_NNNNN' not found`** | Expected after any Part 1 teardown/rebuild: DBeaver caches objects by Postgres OID, and the recreated DB has all-new OIDs, so every open tab/tree node is stale. Close stale editor tabs → right-click connection → **Invalidate/Reconnect** → **Refresh (F5)** → re-open tables. Part 2 (soft shutdown) never causes this. |
| **DBeaver shows no tables / empty results** | Two separate things: (1) tables live under database **callisto → Schemas → callisto** — not `public`, and not the `postgres` database; set the connection's Database field to `callisto` and refresh (F5). (2) After the Part 1 DB reset, migrations only restore **reference** data (roles, permissions, job types) — business tables (cases, jobs, proceedings, contacts) stay empty until the **seed dev dataset** step in Part 1 runs. Sanity check: `docker exec callisto-postgres psql -U postgres -d callisto -tAc "SELECT count(*) FROM callisto.cases;"` → 4 after seeding. |
| **Atlas UI loads but shows "No Data"** | Same cause as above: reference data exists (so the UI renders — dropdowns, types, roles) but business rows were wiped by the Part 1 DB reset and never re-seeded. Run the **seed dev dataset** step (Part 1, after health OK). Feature-specific scenarios: layer on scripts from `src/typeorm/dev-dataset-usecases/`. |

Related: [callisto-local-teardown.md](./callisto-local-teardown.md) · [callisto-local.mdc](./callisto-local.mdc)
