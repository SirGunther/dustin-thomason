# Callisto + Atlas Local — Quickstart (drop-in, one shot)

**Purpose:** copy one block, run it in **Git Bash**, and both Callisto (API) and Atlas (UI) come up. No port-chasing. Every command verified on 2026-07-16 (exceptions called out inline).

Pairs with [callisto-local-teardown.md](./callisto-local-teardown.md) — **Part N here rebuilds what Part N there tore down.**

> **The port truth (read once):** `src/main.ts` binds `process.env.APP_PORT || 3001`, populated from **`.env`** (not `.env.local`). Repo default is `3004` (`.env.sample`). If `.env` and `.env.local` disagree, `.env` wins. The blocks below write the port into `.env`, `.env.local`, **and** Atlas so they can never drift.

---

## Part 1 — Full setup (from nothing: fresh pull, new branch, or after a Part 1 teardown)

Brings up **both** repos from scratch. Set the two values at the top, then run the whole block in Git Bash.

```bash
# ============================================================
#  Callisto + Atlas — FULL setup (Git Bash)
# ============================================================
export GITHUB_TOKEN=<your-PAT>     # must be SSO-authorized for the planetdepos org (both repos need it)
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
```

Expected: Callisto `{"status":"ok",...}` and Atlas `HTTP 200`.

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
| **RabbitMQ crash-loops** `.erlang.cookie: eacces` | Docker Desktop volume-layer bug (fails even as root). Fixes, in order: **restart Docker Desktop**; if it persists, run Callisto without messaging — set `OUTBOX_ENABLED=false` in `.env.local`. The API and our file-length endpoint work fine without RabbitMQ (messaging/outbox only). |
| Atlas can't reach Callisto | `CALLISTO_API_URL` in `atlas-front-end/.env.local` must equal `http://localhost:<APP_PORT>`. Part 1 sets this automatically. |

Related: [callisto-local-teardown.md](./callisto-local-teardown.md) · [callisto-local.mdc](./callisto-local.mdc)
